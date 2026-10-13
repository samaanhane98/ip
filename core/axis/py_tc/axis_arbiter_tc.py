import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly, Combine
from cocotb.handle import Freeze, Release

from test_harness import TestHarness, test

from axis_bfm import AxisSourceBfm, AxisSinkBfm, AxisTransfer


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)
        self.dut = dut
	
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())

        self.sink = AxisSinkBfm(self.dut, "stream_out", self.dut.clk)
        self.source_0 = AxisSourceBfm(self.dut, "stream_in_0", self.dut.clk)
        self.source_1 = AxisSourceBfm(self.dut, "stream_in_1", self.dut.clk)
        self.source_2 = AxisSourceBfm(self.dut, "stream_in_2", self.dut.clk)
        self.source_3 = AxisSourceBfm(self.dut, "stream_in_3", self.dut.clk)

        self.sources = [self.source_0, self.source_1, self.source_2, self.source_3]

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    #@test
    #async def test_001_write_test(self):
    #    amount = 0xf

    #    for index in range(amount):
    #        destination = index % 4
    #        data_length = random.randint(1, 255)
    #        data = random.randbytes(data_length)
    #        await self.sources[destination].send(data)
    #        recv = await self.sink.receive()
    #        assert recv.hex() == data.hex()

    # TODO: properly test algorithm
    @test
    async def test_002_write_test(self):
        amount = 0x10
        
        for index in range(amount):
            self.dut._log.info(index)

            payloads = [random.randbytes(random.randint(1, 255)) for _ in range(4)]

            task_0 = cocotb.start_soon(self.sources[0].send(payloads[0]))
            task_1 = cocotb.start_soon(self.sources[1].send(payloads[1]))
            task_2 = cocotb.start_soon(self.sources[2].send(payloads[2]))
            task_3 = cocotb.start_soon(self.sources[3].send(payloads[3]))

            await Combine(task_0, task_1, task_2, task_3)
        
            for i in range(4):
                recv = await self.sink.receive()
                try:
                    payloads.remove(recv)
                except:
                    assert False

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()
