import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test
from axis_packet_bfm import AxisPacketSourceBfm, AxisPacketSinkBfm, AxisPacketBeat

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut

        self.source = AxisPacketSourceBfm(dut, 'packet_in', dut.clk)
        self.sink = AxisPacketSinkBfm(dut, 'packet_out', dut.clk)
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())


    async def reset_tc(self, cycles = 100):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        await self.source.send(data=random.randbytes(0x10), meta=bytes([0xff]))
        await ClockCycles(self.dut.clk, 1000)
        recv = await self.sink.receive()
        print(recv)
        #print(meta.hex())


@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()