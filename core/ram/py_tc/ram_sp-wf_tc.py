import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly, Combine
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())


    async def reset_tc(self, cycles = 10):
        #self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        #self.dut.reset.value = 0

    @test
    async def test_001_basic(self):
        await ClockCycles(self.dut.clk, 100)
        assert True


@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()