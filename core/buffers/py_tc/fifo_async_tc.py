import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 


from test_harness import TestHarness, test

from fifo_async import FifoASync

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)

        self.fifo = FifoASync(dut)
	
        cocotb.start_soon(Clock(dut.wr_clk, 10, unit="ns").start())
        cocotb.start_soon(Clock(dut.rd_clk, 11, unit="ns").start())

    async def reset_tc(self, cycles = 10):
        self.dut.wr_reset.value = 1
        self.dut.rd_reset.value = 1
        self.dut.wr_valid.value = 0
        self.dut.rd_ready.value = 0

        await ClockCycles(self.dut.wr_clk, cycles // 2)
        await ClockCycles(self.dut.rd_clk, cycles // 2)

        self.dut.wr_reset.value = 0
        self.dut.rd_reset.value = 0
    
    @test
    async def test_001_write_test(self):
        amount = 0xf
        for i in range(amount):
            await self.fifo.write(i)

        await ClockCycles(self.dut.wr_clk, 10)

        write_level = self.dut.wr_level.value.to_unsigned()
        assert write_level == amount

@cocotb.test()
async def ram_sdp_test(dut):
    harness = TestCase(dut)
    await harness.run_tests()