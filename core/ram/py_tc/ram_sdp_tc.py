import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from test_harness import TestHarness, test


class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)

        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

        self.data_width = len(self.dut.wr_data)

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1

        await ClockCycles(self.dut.clk, cycles)

        self.dut.reset.value = 0

    async def write(self, addr, val):
        data = val
        if isinstance(data, (bytes, bytearray)):
            data = int.from_bytes(val, byteorder='little')

        self.dut.wr_addr.value = addr
        self.dut.wr_data.value = data
        self.dut.wr_ena.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.wr_ena.value = 0

    async def read(self, addr):
        self.dut.rd_addr.value = addr
        self.dut.rd_ena.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.rd_ena.value = 0
        await ClockCycles(self.dut.clk, 2)
        return self.dut.rd_data.value


    @test
    async def test_001_write_test(self):
        amount = 0xf
        for i in range(amount):
            await self.write(i, i**2)

        for i in range(amount):
            val = await self.read(i)
            assert val == i**2



@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()