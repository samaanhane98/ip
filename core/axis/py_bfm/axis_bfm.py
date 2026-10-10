from dataclasses import dataclass
from typing import Self

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray, Logic, Range
from cocotb.handle import HierarchyObject, LogicArrayObject

from driver import Driver
from monitor import Monitor
from transfer import TransferRecord


@dataclass
class AxisTransfer(TransferRecord):
    tvalid : Logic = 0
    tlast  : Logic = 0
    tdata  : LogicArray = 0
    tuser  : LogicArray | None = 0
    tkeep  : LogicArray = 0

    width: int = 0

    def from_bytes(self, data: bytearray) -> list[Self]:
        chunk_size = self.width // 8
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]

        remainder = len(data) % chunk_size
        full_keep = (1 << chunk_size) - 1
        last_keep = full_keep if remainder == 0 else (1 << remainder) - 1


        transfers = [
            AxisTransfer(
                tvalid=1, 
                tlast=0, 
                tdata=LogicArray.from_bytes(chunk, byteorder='little'), 
                tuser=None, 
                tkeep=LogicArray.from_unsigned(full_keep, self.width // 8), 
            ) for chunk in chunks]


        transfers[-1].tlast = 1
        transfers[-1].tkeep = LogicArray.from_unsigned(last_keep, self.width // 8)

        return transfers

    def to_bytes(self, transfers: list[Self]) -> bytearray:
        result = bytearray()

        for transfer in transfers:
            tdata = transfer.tdata
            tkeep = transfer.tkeep

            bytes_list = [tdata[i : i - 7] for i in range(tdata.range.left, tdata.range.right, -8)]
            bytes_list = list(reversed(bytes_list))

            keep_bits = [bit for bit in tkeep]
            keep_bits = list(reversed(keep_bits))

            bytes_list = [b for b, k in zip(bytes_list, keep_bits) if int(k) == 1]

            for byte in bytes_list:
                result += bytes([byte])

        return result
    
    def is_last(self) -> bool:
        return self.tlast == 1
        


class AxisSourceBfm(Driver):
    def __init__(self, dut: object, name: str, clock: object):
        super().__init__()
        self.dut = dut
        self.name = name
        self.clock = clock

        self._map_signals()
        self._bus_width = len(self._signals['tdata'])
        self._record_type = AxisTransfer(width=self._bus_width)
        
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

    async def transfer(self, transfer: AxisTransfer):
        signal = self._signals['tdata']
        num_signal_bytes = len(signal) // 8
        num_transfer_bytes = len(transfer.tdata) // 8

        value = transfer.tdata.to_bytes(byteorder='little') + bytes(num_signal_bytes - num_transfer_bytes)
        self._signals['tdata'].value = LogicArray.from_bytes(value, byteorder='little')

        self._signals['tkeep'].value = transfer.tkeep
        self._signals['tlast'].value = transfer.tlast

        if transfer.tuser is not None:
            self._signals['tuser'].value = transfer.tuser

        self._signals['tvalid'].value = 1

        await RisingEdge(self.clock)
        while self._signals['ready'].value != 1:
            await RisingEdge(self.clock)

        self._signals['tvalid'].value = 0

    async def send_transfer(self, transfer: AxisTransfer):
        await self._queue.put(transfer)
        return

    async def send(self, data: bytearray):
        transfers = AxisTransfer(width=self._bus_width).from_bytes(data)
        for transfer in transfers:
            await self.transfer(transfer)

class AxisSinkBfm(Monitor):
    def __init__(self, dut: object, name: str, clock: object):
        super().__init__()
        self.dut = dut
        self.name = name
        self.clock = clock

        self._map_signals()
        self._bus_width = len(self._signals['tdata'].range)
        self._record_type = AxisTransfer(width=self._bus_width)

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

    async def transfer(self) -> AxisTransfer:
        self._signals['ready'].value = 1

        await RisingEdge(self.clock)
        while self._signals['tvalid'].value != 1:
            await RisingEdge(self.clock)

        transfer = AxisTransfer()
        transfer.tvalid = self._signals['tvalid'].value
        transfer.tlast = self._signals['tlast'].value
        transfer.tdata = self._signals['tdata'].value
        transfer.tuser = self._signals['tuser'].value
        transfer.tkeep = self._signals['tkeep'].value

        self._signals['ready'].value = 0

        return transfer

    async def receive_transfer(self) -> AxisTransfer:
        transfer = await self._queue.get()
        return transfer
        

    async def receive(self) -> bytearray:
        transfers = []

        while True:
            transfer = await self.receive_transfer()
            transfers.append(transfer)

            if transfer.is_last():
                break

        data = self._record_type.to_bytes(transfers)
        return data

        