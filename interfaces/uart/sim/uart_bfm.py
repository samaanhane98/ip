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
