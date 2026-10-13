import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly, Combine
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

from axis_packet_bfm import AxisPacketSourceBfm, AxisPacketSinkBfm, AxisPacketTransfer


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())

        self.sink = AxisPacketSinkBfm(self.dut, "packet_out", self.dut.clk)
        self.source_0 = AxisPacketSourceBfm(self.dut, "packet_in_0", self.dut.clk)
        self.source_1 = AxisPacketSourceBfm(self.dut, "packet_in_1", self.dut.clk)
        self.source_2 = AxisPacketSourceBfm(self.dut, "packet_in_2", self.dut.clk)
        self.source_3 = AxisPacketSourceBfm(self.dut, "packet_in_3", self.dut.clk)

        self.sources = [self.source_0, self.source_1, self.source_2, self.source_3]

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        amount = 0x10

        for index in range(amount):
            destination = index % 4
            data_length = random.randint(1, 255)
            data = random.randbytes(data_length)
            meta = random.randbytes(4)
            await self.sources[destination].send(data, meta)
            recv, recv_meta = await self.sink.receive()
            assert recv.hex() == data.hex()
            assert recv_meta.hex() == meta.hex()

    @test
    async def test_002_write_test(self):
        amount = 0x10
        
        for index in range(amount):
            payloads = [random.randbytes(random.randint(1, 255)) for _ in range(4)]
            metas = [random.randbytes(4) for _ in range(4)]

            task_0 = cocotb.start_soon(self.sources[0].send(payloads[0], metas[0]))
            task_1 = cocotb.start_soon(self.sources[1].send(payloads[1], metas[1]))
            task_2 = cocotb.start_soon(self.sources[2].send(payloads[2], metas[2]))
            task_3 = cocotb.start_soon(self.sources[3].send(payloads[3], metas[3]))

            await Combine(task_0, task_1, task_2, task_3)
        
            for i in range(4):
                recv, recv_meta = await self.sink.receive()
                payloads.remove(recv)
                metas.remove(recv_meta)

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()
