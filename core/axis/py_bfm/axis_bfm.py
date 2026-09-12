from dataclasses import dataclass

import cocotb
from cocotb.triggers import RisingEdge

@dataclass
class AxisBeat:
    tvalid : int = 0;
    tlast  : int = 0;
    tdata  : int = 0;
    tuser  : int = 0;
    tkeep  : int = 0;

    @staticmethod
    def into_beats(data: bytearray, bus_width: int) -> list:
        chunk_size = bus_width // 8
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]

        remainder = len(data) % chunk_size
        full_keep = (1 << chunk_size) - 1
        last_keep = full_keep if remainder == 0 else (1 << remainder) - 1

        beats = list(
            map(
                lambda chunk: AxisBeat(tvalid=1, tlast=0, tdata=chunk, tuser=0, tkeep=full_keep), 
                chunks
            )
        )

        beats[-1].tlast = 1
        beats[-1].tkeep = last_keep

        return beats

class AxisSourceBfm:
    def __init__(self, dut: object, name: str, clock: object):
        self.dut = dut
        self.name = name
        self.clock = clock

        self._signals = {}
        self._map_signals()
        self._bus_width = len(self._signals['tdata'].range)

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
            await self.send_transfer(beat)