from dataclasses import dataclass
from typing import Self


import cocotb
from cocotb.triggers import RisingEdge
from cocotb.queue import Queue


@dataclass
class AxisBeat:
    tvalid : int = 0
    tlast  : int = 0
    tdata  : int = 0
    tuser  : int = 0
    tkeep  : int = 0

    @staticmethod
    def into_beats(data: bytearray, bus_width: int) -> list[Self]:
        chunk_size = bus_width // 8
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]

        remainder = len(data) % chunk_size
        full_keep = (1 << chunk_size) - 1
        last_keep = full_keep if remainder == 0 else (1 << remainder) - 1

        beats = [AxisBeat(tvalid=1, tlast=0, tdata=chunk, tuser=0, tkeep=full_keep) for chunk in chunks]

        beats[-1].tlast = 1
        beats[-1].tkeep = last_keep

        return beats

    @staticmethod
    def to_bytes(beats: list[Self]) -> bytearray:
        result = bytearray()

        for beat in beats:
            tdata = beat.tdata
            tkeep = beat.tkeep

            bytes_list = [tdata[i : i - 7] for i in range(tdata.range.left, tdata.range.right, -8)]
            bytes_list = list(reversed(bytes_list))


            keep_bits = [bit for bit in tkeep]
            keep_bits = list(reversed(keep_bits))

            bytes_list = [b for b, k in zip(bytes_list, keep_bits) if int(k) == 1]

            for byte in bytes_list:
                result += bytes([byte])

        return result
        


class AxisSourceBfm:
    def __init__(self, dut: object, name: str, clock: object):
        self.dut = dut
        self.name = name
        self.clock = clock

        self._queue = Queue[AxisBeat]()
        self._coro = None

        self._signals = {}
        self._map_signals()
        self._bus_width = len(self._signals['tdata'].range)

        self.start()

    def _map_signals(self):
        bus = self.dut._get(self.name)
        if bus == None:
            raise ValueError(f"Axis bus {self.name} not found")

        ready_name = self.name + "_ready"
        
        if self.dut._get(ready_name) == None:
            raise ValueError(f"ready not found for {self.name}")

        self._signals['ready'] = self.dut._get(ready_name)
        
        self._signals['tvalid'] = bus.tvalid
        self._signals['tlast'] = bus.tlast
        self._signals['tdata'] = bus.tdata
        self._signals['tuser'] = bus.tuser
        self._signals['tkeep'] = bus.tkeep

    def start(self) -> None:
        if self._coro is not None:
            raise RuntimeError("Source already started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        if self._coro is None:
            raise RuntimeError("Sink never started")
        self._coro.cancel()
        self._coro = None

    async def _run(self) -> None:
        while True:
            transfer = await self._queue.get()
            await self.send_transfer(transfer)

    async def send_transfer(self, beat: AxisBeat):
        self._signals['tdata'].value = int.from_bytes(beat.tdata, byteorder='little')
        self._signals['tkeep'].value = beat.tkeep
        self._signals['tlast'].value = beat.tlast
        self._signals['tuser'].value = beat.tuser
        self._signals['tvalid'].value = 1

        await RisingEdge(self.clock)
        while self._signals['ready'].value != 1:
            await RisingEdge(self.clock)

        self._signals['tvalid'].value = 0

    async def send(self, data: bytearray):
        beats = AxisBeat.into_beats(data, self._bus_width)
        
        for beat in beats:
            await self._queue.put(beat)

class AxisSinkBfm:
    def __init__(self, dut: object, name: str, clock: object):
        self.dut = dut
        self.name = name
        self.clock = clock

        self._queue = Queue[AxisBeat]()
        self._coro = None

        self._signals = {}
        self._map_signals()
        self._bus_width = len(self._signals['tdata'].range)

        self.start()

    def _map_signals(self):
        bus = self.dut._get(self.name)
        if bus == None:
            raise ValueError(f"Axis bus {self.name} not found")

        ready_name = self.name + "_ready"
        
        if self.dut._get(ready_name) == None:
            raise ValueError(f"ready not found for {self.name}")

        self._signals['ready'] = self.dut._get(ready_name)
        
        self._signals['tvalid'] = bus.tvalid
        self._signals['tlast'] = bus.tlast
        self._signals['tdata'] = bus.tdata
        self._signals['tuser'] = bus.tuser
        self._signals['tkeep'] = bus.tkeep

    def start(self) -> None:
        if self._coro is not None:
            raise RuntimeError("Sink already started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        if self._coro is None:
            raise RuntimeError("Sink never started")
        self._coro.cancel()
        self._coro = None

    async def _run(self) -> None:
        while True:
            transfer = await self.receive_transfer()
            await self._queue.put(transfer)

    async def receive_transfer(self) -> AxisBeat:
        self._signals['ready'].value = 1

        await RisingEdge(self.clock)
        while self._signals['tvalid'].value != 1:
            await RisingEdge(self.clock)

        self._signals['ready'].value = 0

        return AxisBeat(
            tvalid=self._signals['tvalid'].value,
            tlast=self._signals['tlast'].value,
            tdata=self._signals['tdata'].value,
            tuser=self._signals['tuser'].value,
            tkeep=self._signals['tkeep'].value,
        )

    async def receive(self) -> bytearray:
        beats = []

        while True:
            beat = await self._queue.get()
            beats.append(beat)

            if beat.tlast == 1:
                break

        data = AxisBeat.to_bytes(beats)
        return data

        