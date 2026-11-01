import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly, with_timeout
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

from axis_bfm import AxisSourceBfm, AxisSinkBfm, AxisTransfer


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())

        self.source = AxisSourceBfm(self.dut, "stream_in", self.dut.clk)
        self.sink = AxisSinkBfm(self.dut, "stream_out", self.dut.clk)

        self.source.throttle(random.randint(1, 10), random.randint(1, 10))
        self.sink.throttle(random.randint(1, 10), random.randint(1, 10))

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1
        self.dut.drop.value = 0

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0

    async def set_drop(self, cycles):
        self.dut.drop.value = 0
        await ClockCycles(self.dut.clk, cycles)
        self.dut.drop.value = 1

    
    @test
    async def test_001_write_test(self):
        amount = 0x10

        check_data = []

        for i in range(amount):
            data_length = random.randint(1, 64)
            data = random.randbytes(data_length)
            check_data.append(data)

            await self.source.send(data)

        for i in range(amount):
            recv = await self.sink.receive()

            assert check_data[i].hex() == recv.hex(), f"{check_data[i].hex()} != {recv.hex()}"

    @test
    async def test_002_drop_test(self):
        amount = 0x10

        for i in range(amount):
            self.dut.drop.value = 0
            data_length = random.randint(20, 128)
            data = random.randbytes(data_length)

            if random.randint(0, 1):
                await self.source.send(data)
                recv = await self.sink.receive()
                assert data.hex() == recv.hex(), f"{data.hex()} != {recv.hex()}"
            else:
                # 1 byte per cycle
                drop_time = random.randint(1, data_length - 1)
                cocotb.start_soon(self.set_drop(drop_time))
                await self.source.send(data, blocking=True)
                recv = await self.sink.receive(timeout=1e3) 
                assert recv == None, f'Expected: None, received: {recv.hex()}'

            await ClockCycles(self.dut.clk, 1) # weir queue problem

        # Drop in last cycle
        self.dut.drop.value = 0
        data_length = 40
        data = random.randbytes(data_length)
        transfers = AxisTransfer(width=8).from_bytes(data)
        for index, transfer in enumerate(transfers):
            if index != len(transfers) - 1:
                await self.source.transfer(transfer)

        self.dut.drop.value = 1
        await self.source.transfer(transfers[-1])
        recv = await self.sink.receive(timeout=1e3) 
        assert recv == None, f'Expected: None, received: {recv.hex()}'

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()
