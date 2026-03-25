import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge, First
from cocotb.clock import Clock
from cocotb.utils import get_sim_time

from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Optional, Callable, Awaitable
import logging


# ---------------------------------------------------------------------------
# Public data types
# ---------------------------------------------------------------------------

class Parity(Enum):
    NONE = auto()
    EVEN = auto()
    ODD = auto()
    MARK = auto()   # parity bit always 1
    SPACE = auto()   # parity bit always 0


@dataclass
class UartConfig:
    baud_rate: int = 115_200
    data_bits: int = 8       # 5..9
    parity: Parity = Parity.NONE
    stop_bits: float = 1.0     # 1, 1.5, or 2

    @property
    def bit_period_ns(self) -> float:
        return 1e9 / self.baud_rate

    def _rounded_ps(self, bits: float) -> int:
        """Round to the nearest picosecond to avoid simulator precision warnings."""
        return round(self.bit_period_ns * bits * 1e3)

    def bit_time(self, bits: float = 1.0) -> Timer:
        return Timer(self._rounded_ps(bits), unit="ps")

    def half_bit_time(self) -> Timer:
        return Timer(self._rounded_ps(0.5), unit="ps")


@dataclass
class UartFrame:
    data: int
    parity_ok: bool = True
    framing_ok: bool = True
    timestamp_ns: float = 0.0

    def __repr__(self) -> str:
        status = []
        if not self.parity_ok:
            status.append("PARITY_ERR")
        if not self.framing_ok:
            status.append("FRAMING_ERR")
        tag = " [" + ", ".join(status) + "]" if status else ""
        return f"UartFrame(0x{self.data:02X}{tag} @{self.timestamp_ns:.1f}ns)"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _calc_parity(data: int, nbits: int, parity: Parity) -> Optional[int]:
    if parity == Parity.NONE:
        return None
    ones = bin(data & ((1 << nbits) - 1)).count("1")
    if parity == Parity.EVEN:
        return ones % 2          # make total even
    if parity == Parity.ODD:
        return (ones + 1) % 2    # make total odd
    if parity == Parity.MARK:
        return 1
    if parity == Parity.SPACE:
        return 0
    return None


# ---------------------------------------------------------------------------
# UartDriver
# ---------------------------------------------------------------------------

class UartDriver:
    """
    Drives a UART TX signal.

    Usage::

        driver = UartDriver(dut.uart_rxd, UartConfig(baud_rate=9600))
        await driver.send(0xA5)
        await driver.send_bytes(b"Hello")
    """

    def __init__(
        self,
        signal,
        config: UartConfig = UartConfig(),
        log: Optional[logging.Logger] = None,
    ):
        self._sig = signal
        self._cfg = config
        self._log = log or logging.getLogger(self.__class__.__name__)
        # Idle state: line high
        self._sig.value = 1

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def send(self, data: int) -> None:
        """Transmit a single UART frame (start + data + parity? + stop)."""
        cfg = self._cfg
        self._log.debug(f"TX 0x{data:02X}")

        # --- start bit (low) ---
        self._sig.value = 0
        await cfg.bit_time()

        # --- data bits (LSB first) ---
        for i in range(cfg.data_bits):
            self._sig.value = (data >> i) & 1
            await cfg.bit_time()

        # --- optional parity bit ---
        p = _calc_parity(data, cfg.data_bits, cfg.parity)
        if p is not None:
            self._sig.value = p
            await cfg.bit_time()

        # --- stop bit(s) (high) ---
        self._sig.value = 1
        await cfg.bit_time(cfg.stop_bits)

    async def send_bytes(self, data: bytes) -> None:
        """Transmit every byte in *data* back-to-back."""
        for byte in data:
            await self.send(byte)

    async def send_break(self, duration_bits: float = 13.0) -> None:
        """
        Drive a break condition (line low for > one full frame).
        The line is returned high afterwards.
        """
        self._log.debug(f"TX BREAK ({duration_bits} bits)")
        self._sig.value = 0
        await self._cfg.bit_time(duration_bits)
        self._sig.value = 1
        await self._cfg.bit_time(1)   # brief idle recovery


class UartMonitor:
    """
    Passively monitors a UART RX signal and decodes frames.

    Decoded frames are pushed onto an internal queue and optionally
    forwarded to a user-supplied callback.

    Usage::

        mon = UartMonitor(dut.uart_txd, UartConfig(baud_rate=9600))
        mon.start()
        ...
        frame = await mon.recv()        # blocking
        frame = mon.recv_nowait()       # non-blocking, returns None if empty
    """

    def __init__(
        self,
        signal,
        config: UartConfig = UartConfig(),
        callback: Optional[Callable[[UartFrame], Awaitable[None]]] = None,
        log: Optional[logging.Logger] = None,
    ):
        self._sig = signal
        self._cfg = config
        self._callback = callback
        self._log = log or logging.getLogger(self.__class__.__name__)
        self._queue = []
        self._waiters = []
        self._task = None
        self.error_count = 0

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self) -> None:
        """Spawn the background sampling coroutine."""
        if self._task is None:
            self._task = cocotb.start_soon(self._run())

    def stop(self) -> None:
        if self._task is not None:
            self._task.kill()
            self._task = None

    # ------------------------------------------------------------------
    # Receive API
    # ------------------------------------------------------------------

    async def recv(self) -> UartFrame:
        """Block until a frame arrives, then return it."""
        if self._queue:
            return self._queue.pop(0)
        evt = cocotb.triggers.Event()
        self._waiters.append(evt)
        await evt.wait()
        return self._queue.pop(0)

    def recv_nowait(self) -> Optional[UartFrame]:
        """Return the oldest queued frame without blocking, or None."""
        return self._queue.pop(0) if self._queue else None

    def recv_all_nowait(self) -> list:
        frames, self._queue = self._queue[:], []
        return frames

    @property
    def received(self) -> list:
        """Read-only snapshot of the current queue."""
        return list(self._queue)

    # ------------------------------------------------------------------
    # Internal sampling loop
    # ------------------------------------------------------------------

    async def _run(self) -> None:
        cfg = self._cfg
        self._log.debug("Monitor started")
        while True:
            # Wait for start bit (falling edge on idle-high line)
            await FallingEdge(self._sig)
            ts = get_sim_time(unit="ns")

            # Re-sample in the middle of the start bit to confirm it
            await cfg.half_bit_time()
            if self._sig.value != 0:
                self._log.warning("False start bit detected – ignoring")
                continue

            # Sample each data bit at the centre of its bit period
            data = 0
            for i in range(cfg.data_bits):
                await cfg.bit_time()
                bit = int(self._sig.value)
                data |= (bit << i)

            # Optional parity check
            parity_ok = True
            if cfg.parity != Parity.NONE:
                await cfg.bit_time()
                rx_parity = int(self._sig.value)
                expected = _calc_parity(data, cfg.data_bits, cfg.parity)
                parity_ok = (rx_parity == expected)
                if not parity_ok:
                    self._log.error(
                        f"Parity error on 0x{data:02X}: "
                        f"got {rx_parity}, expected {expected}"
                    )

            # Stop bit check
            await cfg.bit_time()
            stop_bit = int(self._sig.value)
            framing_ok = (stop_bit == 1)
            if not framing_ok:
                self._log.error(f"Framing error on 0x{data:02X}: stop bit was {stop_bit}")

            if not parity_ok or not framing_ok:
                self.error_count += 1

            frame = UartFrame(
                data=data,
                parity_ok=parity_ok,
                framing_ok=framing_ok,
                timestamp_ns=ts,
            )
            self._log.debug(f"RX {frame}")
            self._enqueue(frame)

            if self._callback is not None:
                await self._callback(frame)

    def _enqueue(self, frame: UartFrame) -> None:
        self._queue.append(frame)
        for evt in self._waiters:
            evt.set()
        self._waiters.clear()


# ---------------------------------------------------------------------------
# UartBfm  –  convenience wrapper
# ---------------------------------------------------------------------------

class UartBfm:
    """
    Combined UART BFM that owns both a driver and a monitor.

    Typical loopback testbench::

        bfm = UartBfm(
            tx_signal = dut.uart_rxd,   # BFM drives DUT's RX input
            rx_signal = dut.uart_txd,   # BFM monitors DUT's TX output
            config    = UartConfig(baud_rate=115200, parity=Parity.EVEN),
        )
        bfm.start()

        await bfm.send(0xA5)
        frame = await bfm.recv()
        assert frame.data == 0xA5
    """

    def __init__(
        self,
        tx_signal,
        rx_signal,
        config: UartConfig = UartConfig(),
        log: Optional[logging.Logger] = None,
    ):
        self._log = log or logging.getLogger("UartBfm")
        self.config = config
        self.driver = UartDriver(tx_signal, config, log=self._log.getChild("drv"))
        self.monitor = UartMonitor(rx_signal, config, log=self._log.getChild("mon"))

    def start(self) -> None:
        self.monitor.start()

    def stop(self) -> None:
        self.monitor.stop()

    # Delegate driver methods
    async def send(self, data: int) -> None: await self.driver.send(data)
    async def send_bytes(self, data: bytes) -> None: await self.driver.send_bytes(data)
    async def send_break(self, bits=13.0) -> None: await self.driver.send_break(bits)
    async def send_with_bad_parity(self, data) -> None: await self.driver.send_with_bad_parity(data)
    async def send_with_bad_stop(self, data) -> None: await self.driver.send_with_bad_stop(data)

    # Delegate monitor methods
    async def recv(self) -> UartFrame: return await self.monitor.recv()
    def recv_nowait(self) -> Optional[UartFrame]: return self.monitor.recv_nowait()
    def recv_all_nowait(self) -> list: return self.monitor.recv_all_nowait()

    @property
    def error_count(self) -> int:
        return self.monitor.error_count
