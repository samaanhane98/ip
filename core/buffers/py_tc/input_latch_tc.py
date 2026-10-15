import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Combine


from test_harness import TestHarness, test

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)

        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1
        self.dut.in_valid.value = 0
        self.dut.out_ready.value = 0

        await ClockCycles(self.dut.clk, cycles // 2)

        self.dut.reset.value = 0

    async def write(self, data):
        if random.randint(0, 1):
            self.dut.in_valid.value = 0
            await ClockCycles(self.dut.clk, random.randint(1, 6))

        self.dut.in_data.value = data
        self.dut.in_valid.value = 1

        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.in_ready.value == 1:
                break


    async def read(self):
        if random.randint(0, 1):
            self.dut.out_ready.value = 0
            await ClockCycles(self.dut.clk, random.randint(1, 6))

        self.dut.out_ready.value = 1

        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.out_valid.value == 1:
                break

        data = self.dut.out_data.value
        return data
    
    @test
    async def test_001_write_test(self):
        amount = 0xf
        for i in range(amount):
            wr_handle = cocotb.start_soon(self.write(i))
            rd_handle = cocotb.start_soon(self.read())
            await Combine(wr_handle, rd_handle)

            val = rd_handle.result()
            assert val == i



        #assert write_level == amount

    #@test
    #async def test_002_read_test(self):
    #    amount = 0x10
    #    write_values = [i for i in range(amount)]
    #    for val in write_values:
    #        await self.fifo.write(val)

    #    read_values = []
        
    #    # Drain FIFO
    #    # For this test, we explicitly read amount times
    #    for _ in range(amount):
    #        rd_val = await self.fifo.read()
    #        read_values.append(rd_val)

    #    # Check amount
    #    assert len(read_values) == amount

    #    # Check data
    #    read_values = [x.to_unsigned() for x in read_values]
    #    assert read_values == write_values

    #@test
    #async def test_003_empty_full_test(self):
    #    assert self.dut.wr_empty.value

    #    amount = self.dut.g_depth.value
    #    write_values = [i for i in range(amount)]
    #    for val in write_values:
    #        await self.fifo.write(val)

    #    await RisingEdge(self.dut.wr_full)
    #    assert self.dut.wr_full.value

    #    # Drain FIFO
    #    # For this test, we explicitly read amount times
    #    for _ in range(amount):
    #        _ = await self.fifo.read()

    #    await RisingEdge(self.dut.rd_empty)
    #    assert self.dut.rd_empty.value


@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()