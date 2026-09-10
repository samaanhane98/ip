import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 

from test_harness import TestHarness, test

class FifoSync:
    def __init__(self, dut):
        self.dut = dut

    async def write(self, data):
        self.dut.wr_data.value = data
        self.dut.wr_valid.value = 1

        # Hold valid until the cycle where ready is actually seen high
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.wr_ready.value == 1:
                break

        self.dut.wr_valid.value = 0

    async def read(self):
        self.dut.rd_ready.value = 1

        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.rd_valid.value == 1:
                data = self.dut.rd_data.value
                break

        self.dut.rd_ready.value = 0

        return data

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)

        self.fifo = FifoSync(dut)
	
        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1
        self.dut.wr_valid.value = 0
        self.dut.rd_ready.value = 0

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        amount = 0xf
        for i in range(amount):
            await self.fifo.write(i)

        await ClockCycles(self.dut.clk, 1)

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
            await RisingEdge(self.dut.clk)

            rd_val = await self.fifo.read()
            read_values.append(rd_val)

        # Check amount
        assert len(read_values) == amount

        # Check data
        read_values = [x.to_unsigned() for x in read_values]
        assert read_values == write_values

    @test
    async def test_003_empty_full_test(self):
        assert self.dut.empty.value

        amount = self.dut.g_depth.value
        write_values = [i for i in range(amount)]
        for val in write_values:
            await self.fifo.write(val)

        await RisingEdge(self.dut.clk)
        assert self.dut.full.value

        # Drain FIFO
        # For this test, we explicitly read amount times
        for _ in range(amount):
            await RisingEdge(self.dut.clk)

            _ = await self.fifo.read()

        await RisingEdge(self.dut.clk)
        assert self.dut.empty.value

    @test
    async def test_004_level_test(self):
        pass

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()