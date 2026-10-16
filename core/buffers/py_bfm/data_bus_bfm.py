import random
from dataclasses import dataclass
from typing import Self

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.types import LogicArray, Logic, Range
from cocotb.handle import HierarchyObject, LogicArrayObject

from driver import Driver
from monitor import Monitor
from transfer import TransferRecord

@dataclass
class BusTransfer(TransferRecord):
    data  : LogicArray = 0
    valid : LogicArray = 0

    width: int = 0

    def from_bytes(self, data: bytearray) -> list[Self]:
        chunk_size = self.width // 8
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]

        transfers = [
            BusTransfer(
                valid=1, 
                data=LogicArray.from_bytes(chunk, byteorder='little'), 
            ) for chunk in chunks]

        return transfers

    def to_bytes(self, transfers: list[Self]) -> bytearray:
        result = bytearray()

        for transfer in transfers:
            data = transfer.data

            bytes_list = [data[i : i - 7] for i in range(data.range.left, data.range.right, -8)]
            bytes_list = list(reversed(bytes_list))

            for byte in bytes_list:
                result += bytes([byte])

        return result
    
    # Does not have last
    def is_last(self) -> bool:
        return True

class BusSourceBfm(Driver):
    def __init__(self, dut: object, name: str, clock: object):
        super().__init__()
        self.dut = dut
        self.name = name
        self.clock = clock

        self._map_signals()
        self._bus_width = len(self._signals['data'])
        self._record_type = BusTransfer(width=self._bus_width)
        
        self.start()

    def _map_signals(self):
        data_name = self.name + "_data"
        if self.dut._get(data_name) == None:
            raise ValueError(f"data not found for {self.name}")

        valid_name = self.name + "_valid"
        if self.dut._get(valid_name) == None:
            raise ValueError(f"valid not found for {self.name}")

        ready_name = self.name + "_ready"
        
        if self.dut._get(ready_name) == None:
            raise ValueError(f"ready not found for {self.name}")

        self._signals['data'] = self.dut._get(data_name)
        self._signals['valid'] = self.dut._get(valid_name)
        self._signals['ready'] = self.dut._get(ready_name)

    def throttle(self, low, high):
        if (low < 0 or high == 0):
            raise ValueError("Invalid throttle value")

        self.valid_list = [1] * high + [0] * low
        self.valid_pointer = 0

    def is_valid(self) -> bool:
        if self.valid_pointer > len(self.valid_list) - 1:
            raise ValueError("Invalid valid pointer value")

        valid = self.valid_list[self.valid_pointer]
        self.valid_pointer = (self.valid_pointer + 1) % len(self.valid_list)
        return bool(valid)


    async def transfer(self, transfer: BusTransfer):
        while True:
            if not self.is_valid():
                await ClockCycles(self.clock, 1)
            else:
                signal = self._signals['data']
                num_signal_bytes = len(signal) // 8
                num_transfer_bytes = len(transfer.data) // 8

                value = transfer.data.to_bytes(byteorder='little') + bytes(num_signal_bytes - num_transfer_bytes)
                self._signals['data'].value = LogicArray.from_bytes(value, byteorder='little')

                self._signals['valid'].value = 1

                await RisingEdge(self.clock)
                while self._signals['ready'].value != 1:
                    await RisingEdge(self.clock)

                self._signals['valid'].value = 0
                return

    async def send_transfer(self, transfer: BusTransfer):
        await self._queue.put(transfer)

    async def send(self, data: bytearray):
        transfers = BusTransfer(width=self._bus_width).from_bytes(data)
        for transfer in transfers:
            await self.transfer(transfer)

class BusSinkBfm(Monitor):
    def __init__(self, dut: object, name: str, clock: object):
        super().__init__()
        self.dut = dut
        self.name = name
        self.clock = clock

        self._map_signals()
        self._bus_width = len(self._signals['data'].range)
        self._record_type = BusTransfer(width=self._bus_width)

        self.start()

    def _map_signals(self):
        data_name = self.name + "_data"
        if self.dut._get(data_name) == None:
            raise ValueError(f"data not found for {self.name}")

        valid_name = self.name + "_valid"
        if self.dut._get(valid_name) == None:
            raise ValueError(f"valid not found for {self.name}")

        ready_name = self.name + "_ready"
        
        if self.dut._get(ready_name) == None:
            raise ValueError(f"ready not found for {self.name}")

        self._signals['data'] = self.dut._get(data_name)
        self._signals['valid'] = self.dut._get(valid_name)
        self._signals['ready'] = self.dut._get(ready_name)

    def throttle(self, low=0, high=1):
        if (low < 0 or high == 0):
            raise ValueError("Invalid throttle value")

        self.ready_list = [1] * high + [0] * low
        self.ready_pointer = 0

    def is_ready(self) -> bool: 
        if self.ready_pointer > len(self.ready_list) - 1:
            raise ValueError("Invalid ready pointer value")

        ready = self.ready_list[self.ready_pointer]
        self.ready_pointer = (self.ready_pointer + 1) % len(self.ready_list)
        return bool(ready)

    async def transfer(self):
        while True:
            if not self.is_ready():
                await ClockCycles(self.clock, 1)
            else:
                self._signals['ready'].value = 1

                await RisingEdge(self.clock)
                while self._signals['valid'].value != 1:
                    await RisingEdge(self.clock)

                transfer = BusTransfer()
                transfer.valid = self._signals['valid'].value
                transfer.data = self._signals['data'].value

                self._signals['ready'].value = 0

                return transfer

    async def receive_transfer(self) -> BusTransfer:
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

