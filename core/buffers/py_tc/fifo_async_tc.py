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

        # A few cycles are necessary after reset
        await ClockCycles(self.dut.wr_clk, 5)
    
    @test
    async def test_001_write_test(self):
        amount = 0xf
        for i in range(amount):
            await self.fifo.write(i)

        await ClockCycles(self.dut.wr_clk, 10)

        write_level = self.dut.wr_level.value.to_unsigned()
        assert write_level == amount

    @test
    async def test_002_read_test(self):
        amount = 0x10
        write_values = [i for i in range(amount)]
        for val in write_values:
            await self.fifo.write(val)

        read_values = []
        
        # Drain FIFO
        # For this test, we explicitly read amount times
        for _ in range(amount):
            rd_val = await self.fifo.read()
            read_values.append(rd_val)

        # Check amount
        assert len(read_values) == amount

        # Check data
        read_values = [x.to_unsigned() for x in read_values]
        assert read_values == write_values

    @test
    async def test_003_empty_full_test(self):
        assert self.dut.wr_empty.value

        amount = self.dut.g_depth.value
        write_values = [i for i in range(amount)]
        for val in write_values:
            await self.fifo.write(val)

        await RisingEdge(self.dut.wr_full)
        assert self.dut.wr_full.value

        # Drain FIFO
        # For this test, we explicitly read amount times
        for _ in range(amount):
            _ = await self.fifo.read()

        await RisingEdge(self.dut.rd_empty)
        assert self.dut.rd_empty.value


@cocotb.test()
async def ram_sdp_test(dut):
    harness = TestCase(dut)
    await harness.run_tests()