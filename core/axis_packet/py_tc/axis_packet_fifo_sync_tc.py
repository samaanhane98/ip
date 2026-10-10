import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 
from cocotb.types import LogicArray, Logic, Range
from cocotb.handle import Freeze, Release 

from test_harness import TestHarness, test
from axis_packet_bfm import AxisPacketSourceBfm, AxisPacketSinkBfm, AxisPacketTransfer

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
        ## Explicitly disable sink so we can monitor the write level
        self.sink.stop()
        self.dut.packet_out_ready.value = Logic(0)

        amount = 0xf
        for index in range(amount):
            data = bytes([index])
            await self.source.send(data, bytes([0xf]))

        await ClockCycles(self.dut.clk, 100)

        write_level = self.dut.packet_in_level.value.to_unsigned()
        assert write_level == amount

        ## Reset and enable for other tests
        await self.reset_tc()
        self.sink.start()

    @test
    async def test_002_read_test(self):
        amount = 0x10

        depth = self.dut.g_depth.value
        for i in range(amount):
            data_length = random.randint(1, depth)
            data = random.randbytes(data_length)
            meta = bytes([i])

            await self.source.send(data, meta)
            recv, recv_meta = await self.sink.receive()

            assert data.hex() == recv.hex()
            assert int.from_bytes(meta, byteorder='little') == int.from_bytes(recv_meta, byteorder='little')

    @test
    async def test_003_empty_full_test(self):
        # Explicitly disable sink so we can monitor the write level
        self.sink.stop()
        self.dut.packet_out_ready.value = 0

        assert self.dut.empty.value

        amount = self.dut.g_depth.value
        for i in range(amount):
            await self.source.send(bytes([i]), bytes([i]))

        await RisingEdge(self.dut.full)
        assert self.dut.full.value

        # Drain FIFO
        self.sink.start()
        for _ in range(amount):
            await self.sink.receive()

        await RisingEdge(self.dut.empty)
        assert self.dut.empty.value


@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()