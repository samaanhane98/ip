import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

from axis_packet_bfm import AxisPacketSourceBfm, AxisPacketSinkBfm 


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())

        self.source = AxisPacketSourceBfm(self.dut, "packet_in", self.dut.clk)
        self.sink_0 = AxisPacketSinkBfm(self.dut, "packet_out_0", self.dut.clk)
        self.sink_1 = AxisPacketSinkBfm(self.dut, "packet_out_1", self.dut.clk)
        self.sink_2 = AxisPacketSinkBfm(self.dut, "packet_out_2", self.dut.clk)
        self.sink_3 = AxisPacketSinkBfm(self.dut, "packet_out_3", self.dut.clk)

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
            meta = random.randbytes(1)
            await self.source.send(data, meta)
            recv, recv_meta = await self.sinks[destination].receive()
            assert recv.hex() == data.hex()
            assert int.from_bytes(recv_meta, byteorder='little') == int.from_bytes(meta, byteorder='little')

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()