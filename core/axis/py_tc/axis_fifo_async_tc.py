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
	
        cocotb.start_soon(Clock(self.dut.stream_out_clk, 10, unit="ns").start())
        cocotb.start_soon(Clock(self.dut.stream_in_clk, 11, unit="ns").start())

        self.source = AxisSourceBfm(self.dut.i_dut, "stream_in", self.dut.stream_in_clk)
        self.sink = AxisSinkBfm(self.dut.i_dut, "stream_out", self.dut.stream_out_clk)

    async def reset_tc(self, cycles = 10):
        self.dut.stream_in_reset.value = 1
        self.dut.stream_out_reset.value = 1
        self.dut.stream_out_ready.value = 0

        await ClockCycles(self.dut.stream_in_clk, cycles // 2)
        await ClockCycles(self.dut.stream_out_clk, cycles // 2)

        self.dut.stream_in_reset.value = 0
        self.dut.stream_out_reset.value = 0

        # A few cycles are necessary after reset
        await ClockCycles(self.dut.stream_in_clk, 5)
    
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

        await ClockCycles(self.dut.stream_in_clk, 1)

        write_level = self.dut.stream_in_level.value.to_unsigned()
        assert write_level == amount

        # Reset and enable for other tests
        await self.reset_tc()
        self.sink.start()

    @test
    async def test_002_read_test(self):
        amount = 0x10

        for i in range(amount):
            data_length = random.randint(1, 256)
            data = random.randbytes(data_length)

            await self.source.send(data)
            recv = await self.sink.receive()

            assert data.hex() == recv.hex()

    @test
    async def test_003_empty_full_test(self):
        # Explicitly disable sink so we can monitor the write level
        self.sink.stop()
        self.dut.stream_out_ready.value = 0

        assert self.dut.stream_in_empty.value

        amount = self.dut.g_depth.value
        for i in range(amount):
            await self.source.send(bytes(1))

        await RisingEdge(self.dut.stream_in_full)
        assert self.dut.stream_in_full.value

        # Drain FIFO
        self.sink.start()
        for _ in range(amount):
            _ = await self.sink.receive()

        await RisingEdge(self.dut.stream_out_empty)
        assert self.dut.stream_out_empty.value



@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()