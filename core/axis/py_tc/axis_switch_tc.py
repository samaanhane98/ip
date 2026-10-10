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

        self.source = AxisSourceBfm(self.dut, "stream_in", self.dut.clk)
        self.sink_0 = AxisSinkBfm(self.dut, "stream_out_0", self.dut.clk)
        self.sink_1 = AxisSinkBfm(self.dut, "stream_out_1", self.dut.clk)
        self.sink_2 = AxisSinkBfm(self.dut, "stream_out_2", self.dut.clk)
        self.sink_3 = AxisSinkBfm(self.dut, "stream_out_3", self.dut.clk)

        self.sinks = [self.sink_0, self.sink_1, self.sink_2, self.sink_3]

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        amount = 0xf
        destination = 0

        for index in range(amount):
            data_length = random.randint(1, 255)
            destination = index % 4
            self.dut.select_output.value = destination
            data = random.randbytes(data_length)
            await self.source.send(data)
            recv = await self.sinks[destination].receive()
            assert recv.hex() == data.hex()

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()