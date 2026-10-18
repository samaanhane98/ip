import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Combine, Timer

from data_bus_bfm import BusSourceBfm, BusSinkBfm, BusTransfer

from test_harness import TestHarness, test

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)

        self.dut = dut

        self.source = BusSourceBfm(dut, 'wr', self.dut.wr_clk)
        self.sink = BusSinkBfm(dut, 'rd', self.dut.rd_clk)

    async def reset_tc(self, cycles = 10):
        return

    async def read(self):
        while self.dut.rd_valid.value != 1:
            await RisingEdge(self.dut.rd_clk)
    
    @test
    async def test_001_write_test(self):
        while True:
            for _ in range(15):
                self.dut.wr_data.value = 0x0
                self.dut.wr_valid.value = 0
                await RisingEdge(self.dut.wr_clk)
            
            data = random.randbytes(random.randint(20, 200))
            transfers = BusTransfer(width=len(self.dut.rd_data)).from_bytes(data)
            for transfer in transfers:
                await self.source.send_transfer(transfer)

            recv_transfers = []
            for _ in range(len(transfers)):
                recv_transfers.append(await self.sink.receive_transfer())

            recv_data = BusTransfer(width=len(self.dut.wr_data)).to_bytes(recv_transfers)
            assert recv_data.hex() == data.hex()
            


@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()