from dataclasses import dataclass
from typing import Self, Dict, Any, Tuple

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray, Logic, Range
from cocotb.handle import HierarchyObject, LogicArrayObject

from driver import Driver
from monitor import Monitor
from transfer import TransferRecord

@dataclass
class AxisPacketTransfer(TransferRecord):
    valid: Logic = 0
    last: Logic = 0
    first: Logic = 0
    drop: Logic = 0
    data: LogicArray = 0
    user: LogicArray | None = 0
    keep: Logic = 0
    
    meta: Dict[str, Any] | bytearray | None = None
    meta_valid: Logic = 0

    width: int = 0

    def from_bytes(self, data: bytearray) -> list[Self]:
        chunk_size = self.width // 8
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]

        remainder = len(data) % chunk_size
        full_keep = (1 << chunk_size) - 1
        last_keep = full_keep if remainder == 0 else (1 << remainder) - 1

        transfers = [
            AxisPacketTransfer(
                valid=Logic(1), 
                last=Logic(0), 
                first=Logic(0), 
                drop=Logic(0), 
                data=LogicArray.from_bytes(chunk, byteorder='little'), 
                user=None, 
                keep=LogicArray.from_unsigned(full_keep, self.width // 8), 
                meta_valid=Logic(0)
            ) for chunk in chunks]

        transfers[0].first = Logic(1)
        transfers[-1].last = Logic(1)
        transfers[-1].keep = LogicArray.from_unsigned(last_keep, self.width // 8)

        return transfers

    def to_bytes(self, transfers: list[Self]) -> bytearray:
        result = bytearray()

        for transfer in transfers:
            data = transfer.data
            keep = transfer.keep

            bytes_list = [data[i : i - 7] for i in range(data.range.left, data.range.right, -8)]
            bytes_list = list(reversed(bytes_list))

            keep_bits = [bit for bit in keep]
            keep_bits = list(reversed(keep_bits))

            bytes_list = [b for b, k in zip(bytes_list, keep_bits) if int(k) == 1]

            for byte in bytes_list:
                result += bytes([byte])

        return result

    def is_last(self) -> bool:
        return self.last == Logic(1)

class AxisPacketSourceBfm(Driver):
    def __init__(self, dut: HierarchyObject, name: str, clock: object):
        super().__init__()
        self.dut = dut
        self.name = name
        self.clock = clock

        self._map_signals()
        self._bus_width = len(self._signals['data'].range)
        self._record_type = AxisPacketTransfer(width=self._bus_width)
        
        self.start()

    def _map_signals(self):
        bus = self.dut._get(self.name)
        if bus == None:
            raise ValueError(f"Axis Packet bus {self.name} not found")

        ready_name = self.name + "_ready"
        
        if self.dut._get(ready_name) == None:
            raise ValueError(f"ready not found for {self.name}")
        
        self._signals['ready'] = self.dut._get(ready_name)
        
        self._signals['valid'] = bus.valid
        self._signals['last'] = bus.last
        self._signals['first'] = bus.first
        self._signals['drop'] = bus.drop
        self._signals['data'] = bus.data
        self._signals['user'] = bus.user
        self._signals['keep'] = bus.keep
        self._signals['meta_valid'] = bus.meta_valid

        meta_name = self.name + "_meta"
        self._signals['meta'] = self.dut._get(meta_name)

    async def transfer(self, transfer: AxisPacketTransfer):
        signal = self._signals['data']
        num_signal_bytes = len(signal) // 8
        num_transfer_bytes = len(transfer.data) // 8
        
        value = transfer.data.to_bytes(byteorder='little') + bytes(num_signal_bytes - num_transfer_bytes)
        self._signals['data'].value = LogicArray.from_bytes(value, byteorder='little')

        self._signals['valid'].value = 1
        self._signals['last'].value = transfer.last
        self._signals['first'].value = transfer.first
        self._signals['drop'].value = transfer.drop
        self._signals['keep'].value = transfer.keep


        meta = transfer.meta
        
        if transfer.user is not None:
            self._signals['user'].value = transfer.user
        
        if isinstance(self._signals['meta'], HierarchyObject) and isinstance(meta, Dict[str, Any]):
            raise ValueError("Dictionary meta values not yet implemented")
        elif isinstance(self._signals['meta'], LogicArrayObject) and isinstance(meta, bytes | bytearray):
            new_meta = int.from_bytes(meta, byteorder='little')
            self._signals['meta'].value = LogicArray.from_unsigned(new_meta, len(self._signals['meta'].value)) 
            self._signals['meta_valid'].value = Logic(1)
        elif meta is None:
            self._signals['meta_valid'].value = Logic(0)
        else:
            raise ValueError("Illegal meta value")

        await RisingEdge(self.clock)
        while self._signals['ready'].value != Logic(1):
            await RisingEdge(self.clock)
        
        self._signals['valid'].value = Logic(0)

    async def send_transfer(self, transfer: AxisPacketTransfer):
        await self._queue.put(transfer)
        return

    async def send(self, data: bytearray, meta: Dict[str, Any] | bytearray | None = None):
        transfers = AxisPacketTransfer(width=self._bus_width).from_bytes(data)
        for beat in transfers:
            beat.meta = meta
            await self.send_transfer(beat)

class AxisPacketSinkBfm(Monitor):
    def __init__(self, dut: HierarchyObject, name: str, clock: object):
        super().__init__()
        self.dut = dut
        self.name = name
        self.clock = clock

        self._map_signals()
        self._bus_width = len(self._signals['data'].range)
        self._record_type = AxisPacketTransfer(width=self._bus_width)

        self.start()

    def _map_signals(self):
        bus = self.dut._get(self.name)
        if bus == None:
            raise ValueError(f"Axis Packet bus {self.name} not found")

        ready_name = self.name + "_ready"
        
        if self.dut._get(ready_name) == None:
            raise ValueError(f"ready not found for {self.name}")
        
        self._signals['ready'] = self.dut._get(ready_name)
        
        self._signals['valid'] = bus.valid
        self._signals['last'] = bus.last
        self._signals['first'] = bus.first
        self._signals['drop'] = bus.drop
        self._signals['data'] = bus.data
        self._signals['user'] = bus.user
        self._signals['keep'] = bus.keep
        self._signals['meta_valid'] = bus.meta_valid

        meta_name = self.name + "_meta"
        self._signals['meta'] = self.dut._get(meta_name)

    async def transfer(self) -> AxisPacketTransfer:
        self._signals['ready'].value = Logic(1)

        await RisingEdge(self.clock)
        while self._signals['valid'].value != Logic(1):
            await RisingEdge(self.clock)


        transfer = AxisPacketTransfer(width=self._bus_width)
        transfer.data = self._signals['data'].value 
        transfer.last = self._signals['last'].value 
        transfer.first = self._signals['first'].value 
        transfer.drop = self._signals['drop'].value 
        transfer.keep = self._signals['keep'].value 
        transfer.valid = self._signals['valid'].value 
        transfer.user = self._signals['user'].value 

        meta = None
        if isinstance(self._signals['meta'], HierarchyObject):
            raise ValueError("Dictionary meta values not yet implemented")
        elif isinstance(self._signals['meta'], LogicArrayObject):
            if self._signals['meta'].value.is_resolvable:
                meta = self._signals['meta'].value.to_bytes(byteorder='little')
                transfer.meta_valid = Logic(1)
        elif self._signals['meta'] is None:
            pass
        else:
            raise ValueError("Illegal meta value")
        
        transfer.meta = meta

        self._signals['ready'].value = Logic(0)

        return transfer

    async def receive_transfer(self) -> AxisPacketTransfer: 
        transfer = await self._queue.get()
        return transfer

    async def receive(self) -> Tuple[bytearray, Dict[str, Any] | bytearray | None]:
        transfers = []
        meta = None

        while True:
            transfer = await self.receive_transfer()
            transfers.append(transfer)

            if transfer.is_last():
                meta = transfer.meta
                break

        data = AxisPacketTransfer(width=self._bus_width).to_bytes(transfers)

        return (data, meta)

        