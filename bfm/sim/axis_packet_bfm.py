from __future__ import annotations

import dataclasses
import random
from typing import Optional

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep
from cocotb.queue import Queue


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _to_int(sig) -> int:
    """
    Convert a cocotb vector signal to int.
    Returns 0 for unresolved ('U','X',...) or null-range (-1 downto 0) vectors.
    """
    try:
        if len(sig.value) == 0:
            return 0
        return int(sig.value)
    except ValueError:
        return 0


def _to_bool(sig) -> bool:
    """
    Convert a cocotb STD_LOGIC signal to bool.
    Returns False for unresolved values.
    """
    try:
        return bool(sig.value)
    except ValueError:
        return False


# ---------------------------------------------------------------------------
# Packet dataclass
# ---------------------------------------------------------------------------

@dataclasses.dataclass
class AxisPacket:
    """
    Represents one complete AXI4-S burst.

    Attributes
    ----------
    data:       List of per-beat data words (ints).
    keep:       List of per-beat keep masks (ints).
    user:       List of per-beat user values (ints).
    first:      Assert the 'first' flag on the first beat.
    meta_valid: Assert 'meta_valid' on the first beat.
    """
    data:       list[int] = dataclasses.field(default_factory=list)
    keep:       list[int] = dataclasses.field(default_factory=list)
    user:       list[int] = dataclasses.field(default_factory=list)
    first:      bool = False
    meta_valid: bool = False

    def __repr__(self) -> str:
        return (
            f"AxisPacket("
            f"beats={len(self.data)}, "
            f"data={[hex(d) for d in self.data]}, "
            f"keep={[hex(k) for k in self.keep]}, "
            f"user={[hex(u) for u in self.user]}, "
            f"first={self.first}, "
            f"meta_valid={self.meta_valid})"
        )


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

class AxisPacketDriver:
    """
    Drives a t_axis_packet record input port.

    Parameters
    ----------
    dut:        cocotb DUT handle.
    clock:      Clock signal handle.
    prefix:     Name of the record port (e.g. ``"packet_in"``).
                Fields resolved as ``dut.<prefix>.valid``, etc.
                Ready resolved as ``dut.<prefix>_ready``.
    reset:      Optional active-high reset handle. Bus is idled while
                asserted.
    idle_prob:  Probability [0,1] of inserting a random idle cycle between
                beats (useful for back-pressure stress testing).
    """

    def __init__(
        self,
        dut: SimHandleBase,
        clock: SimHandleBase,
        prefix: str,
        reset: Optional[SimHandleBase] = None,
        idle_prob: float = 0.0,
    ) -> None:
        self._clk = clock
        self._reset = reset
        self._idle_prob = idle_prob

        rec = getattr(dut, prefix)
        self._valid = rec.valid
        self._last = rec.last
        self._first = rec.first
        self._data = rec.data
        self._keep = rec.keep
        self._user = rec.user
        self._meta_valid = rec.meta_valid
        self._ready = getattr(dut, f"{prefix}_ready")

        self._queue: Queue[AxisPacket] = Queue()
        self._idle()
        cocotb.start_soon(self._run())

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def send(self, packet: AxisPacket) -> None:
        """Enqueue a packet for transmission. Returns immediately."""
        await self._queue.put(packet)

    async def send_and_wait(self, packet: AxisPacket) -> None:
        """Enqueue a packet and block until it has been fully driven."""
        await self._queue.put(packet)
        await self._queue.join()

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _idle(self) -> None:
        """Drive all outputs to safe de-asserted values."""
        self._valid.value = 0
        self._last.value = 0
        self._first.value = 0
        self._data.value = 0
        self._keep.value = 0
        if len(self._user.value) > 0:  # guard against null-range
            self._user.value = 0
        self._meta_valid.value = 0

    def _in_reset(self) -> bool:
        return self._reset is not None and bool(self._reset.value)

    async def _run(self) -> None:
        while True:
            if self._in_reset():
                self._idle()
                await RisingEdge(self._clk)
                continue

            packet: AxisPacket = await self._queue.get()
            await self._drive(packet)

    async def _drive(self, packet: AxisPacket) -> None:
        beats = len(packet.data)
        if beats == 0:
            return

        for i, (data, keep, user) in enumerate(
            zip(packet.data, packet.keep, packet.user)
        ):
            is_first = i == 0
            is_last = i == beats - 1

            # Optional random idle beat
            if self._idle_prob > 0 and random.random() < self._idle_prob:
                self._idle()
                await RisingEdge(self._clk)

            self._valid.value = 1
            self._last.value = int(is_last)
            self._first.value = int(is_first and packet.first)
            self._data.value = data
            self._keep.value = keep
            if len(self._user.value) > 0:  # guard against null-range
                self._user.value = user
            self._meta_valid.value = int(is_first and packet.meta_valid)

            # Handshake: advance only when ready is high
            await RisingEdge(self._clk)
            await ReadOnly()
            while not self._ready.value:
                await NextTimeStep()
                await RisingEdge(self._clk)
                await ReadOnly()

            # Must exit ReadOnly before writing signals
            await NextTimeStep()

        self._idle()


# ---------------------------------------------------------------------------
# Monitor
# ---------------------------------------------------------------------------

class AxisPacketMonitor:
    """
    Passively observes a t_axis_packet record port and reassembles complete
    packets from individual beats.

    Completed packets are pushed to ``self.queue``.

    Parameters
    ----------
    dut:    cocotb DUT handle.
    clock:  Clock signal handle.
    prefix: Name of the record port (e.g. ``"packet_out"``).
            Ready resolved as ``dut.<prefix>_ready``.
    """

    def __init__(
        self,
        dut: SimHandleBase,
        clock: SimHandleBase,
        prefix: str,
    ) -> None:
        self._clk = clock

        rec = getattr(dut, prefix)
        self._valid = rec.valid
        self._last = rec.last
        self._first = rec.first
        self._data = rec.data
        self._keep = rec.keep
        self._user = rec.user
        self._meta_valid = rec.meta_valid
        self._ready = getattr(dut, f"{prefix}_ready")

        self.queue: Queue[AxisPacket] = Queue()
        cocotb.start_soon(self._run())

    async def recv(self) -> AxisPacket:
        """Block until a complete packet has been received and return it."""
        return await self.queue.get()

    async def _run(self) -> None:
        current: Optional[AxisPacket] = None

        while True:
            await RisingEdge(self._clk)
            await ReadOnly()

            # Only capture beats where the handshake is complete
            if not (self._valid.value and self._ready.value):
                continue

            is_first = _to_bool(self._first)
            is_last = _to_bool(self._last)
            meta_valid = _to_bool(self._meta_valid)
            data = _to_int(self._data)
            keep = _to_int(self._keep)
            user = _to_int(self._user)

            if current is None:
                current = AxisPacket(first=is_first, meta_valid=meta_valid)

            current.data.append(data)
            current.keep.append(keep)
            current.user.append(user)

            if is_last:
                await self.queue.put(current)
                current = None


# ---------------------------------------------------------------------------
# Ready driver (sink side)
# ---------------------------------------------------------------------------

class AxisReadyDriver:
    """
    Drives the ready signal on a sink port.

    Parameters
    ----------
    dut:          cocotb DUT handle.
    clock:        Clock signal handle.
    prefix:       Record port name (e.g. ``"packet_out"``).
                  Drives ``dut.<prefix>_ready``.
    always_ready: Permanently assert ready when True.
    bp_prob:      Per-cycle probability of deasserting ready (back-pressure).
                  Only used when ``always_ready=False``.
    """

    def __init__(
        self,
        dut: SimHandleBase,
        clock: SimHandleBase,
        prefix: str,
        always_ready: bool = True,
        bp_prob: float = 0.3,
    ) -> None:
        self._clk = clock
        self._always_ready = always_ready
        self._bp_prob = bp_prob
        self._ready = getattr(dut, f"{prefix}_ready")
        self._ready.value = 1
        cocotb.start_soon(self._run())

    async def _run(self) -> None:
        while True:
            await RisingEdge(self._clk)
            if self._always_ready:
                self._ready.value = 1
            else:
                self._ready.value = 0 if random.random() < self._bp_prob else 1
