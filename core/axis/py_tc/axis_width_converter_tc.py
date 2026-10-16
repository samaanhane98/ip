import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

from axis_bfm import AxisSourceBfm, AxisSinkBfm, AxisTransfer


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())

        self.source = AxisSourceBfm(self.dut.i_dut, "stream_in", self.dut.clk)
        self.sink = AxisSinkBfm(self.dut.i_dut, "stream_out", self.dut.clk)

        #self.source.throttle(1, 5)
        #self.sink.throttle(3, 2)

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        amount = 0x20

        check_data = []

        self.sink.throttle(2, 10)
        self.source.throttle(3, 20)

        for i in range(amount):
            data_length = random.randint(6, 64)
            data = random.randbytes(data_length)
            check_data.append(data)

            #self.source.throttle(3, 7)

            await self.source.send(data)
        for i in range(amount):
            recv = await self.sink.receive()

            assert check_data[i].hex() == recv.hex()

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()