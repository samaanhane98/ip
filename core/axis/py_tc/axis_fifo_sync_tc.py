import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

from axis_bfm import AxisSourceBfm, AxisSinkBfm, AxisBeat


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())

        self.source = AxisSourceBfm(self.dut.i_dut, "stream_in", self.dut.clk)
        self.sink = AxisSinkBfm(self.dut.i_dut, "stream_out", self.dut.clk)

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        # Explicitly disable sink so we can monitor the write level
        self.sink.stop()
        self.dut.stream_out_ready.value = 0

        amount = 0xf
        for index in range(amount):
            data = bytes([index])
            beat = AxisBeat(1, 1, data, 0, 1)
            await self.source.send_transfer(beat)

        await ClockCycles(self.dut.clk, 1)

        write_level = self.dut.wr_level.value.to_unsigned()
        assert write_level == amount

        self.sink.start()

    @test
    async def test_002_read_test(self):
        # TODO: FIFO is not empty after reset
        await self.reset_tc()

        amount = 0x10

        for i in range(amount):
            data_length = random.randint(1, 256)
            data = random.randbytes(data_length)

            await self.source.send(data)
            recv = await self.sink.receive()

            assert data.hex() == recv.hex()



@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()