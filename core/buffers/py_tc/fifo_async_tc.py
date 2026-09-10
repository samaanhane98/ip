import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 

class FifoASync:
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
                break

        data = self.dut.rd_data.value
        self.dut.rd_ready.value = 0

        return data

@cocotb.test()
async def ram_sdp_test(dut):
	fifo = FifoASync(dut)

	cocotb.start_soon(Clock(dut.wr_clk, 10, unit="ns").start())
	cocotb.start_soon(Clock(dut.rd_clk, 11, unit="ns").start())

	dut.wr_reset.value = 1

	dut.wr_valid.value = 0
	dut.rd_ready.value = 0
	await ClockCycles(dut.wr_clk, 50)
	dut.wr_reset.value = 0
    
	#for i in range(0xf):
	#	await fifo.write(i)

	#await ClockCycles(dut.clk, 1)
	#print(dut.wr_level.value.to_unsigned())

	#for i in range(0x5):
	#	val = await fifo.read()
	#	await ClockCycles(dut.clk, 1)

	#await ClockCycles(dut.clk, 1)
	#print(dut.rd_level.value.to_unsigned())

	#cocotb.end_test()