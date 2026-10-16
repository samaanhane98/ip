import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Combine

from data_bus_bfm import BusSourceBfm, BusSinkBfm, BusTransfer

from test_harness import TestHarness, test

class TestCase(TestHarness):
    def __init__(self, dut):
        super().__init__(dut)

        self.dut = dut

        self.source = BusSourceBfm(dut, 'in', self.dut.clk)
        self.sink = BusSinkBfm(dut, 'out', self.dut.clk)

        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    async def reset_tc(self, cycles = 10):
        self.dut.reset.value = 1
        self.dut.in_valid.value = 0
        self.dut.out_ready.value = 0

        await ClockCycles(self.dut.clk, cycles // 2)

        self.dut.reset.value = 0
    
    @test
    async def test_001_write_test(self):
        self.sink.throttle(low=2, high=4)
        self.source.throttle(low=1, high=5)

        data = random.randbytes(100)
        transfers = BusTransfer(width=len(self.dut.in_data)).from_bytes(data)
        for transfer in transfers:
            await self.source.send_transfer(transfer)

        recv_transfers = []
        for _ in range(len(transfers)):
            recv_transfers.append(await self.sink.receive_transfer())

        recv_data = BusTransfer(width=len(self.dut.out_data)).to_bytes(recv_transfers)
        assert recv_data.hex() == data.hex()

@cocotb.test()
async def main(dut):
    harness = TestCase(dut)
    await harness.run_tests()