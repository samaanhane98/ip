import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly 

class FifoSync:
    def __init__(self, dut):
        self.dut = dut

    async def write(self, data):
        self.dut.write_data.value = data
        self.dut.write_valid.value = 1

        # Hold valid until the cycle where ready is actually seen high
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.write_ready.value == 1:
                break

        self.dut.write_valid.value = 0

    async def read(self):
        self.dut.read_ready.value = 1

        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.read_valid.value == 1:
                break

        data = self.dut.read_data.value
        self.dut.read_ready.value = 0

        return data

@cocotb.test()
async def ram_sdp_test(dut):
	fifo = FifoSync(dut)

	cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

	dut.reset.value = 1
	await ClockCycles(dut.clk, 50)
	dut.reset.value = 0
    
	for i in range(0xf):
		await fifo.write(i)

	for i in range(0x5):
		val = await fifo.read()
		print(val)
		await ClockCycles(dut.clk, 1)

	for i in range(0x5):
		await fifo.write(i)

	for i in range(0xf):
		val = await fifo.read()
		print(val)
		await ClockCycles(dut.clk, 1)

