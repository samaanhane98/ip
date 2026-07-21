import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, ReadOnly , NextTimeStep


class RamSdp:
	def __init__(self, dut, read_delay=0):
		self.dut = dut
		self.read_delay = read_delay

	async def write(self, address, data):
		self.dut.write_address.value = address
		self.dut.write_data.value = data
		self.dut.write_ena.value = 1

		await RisingEdge(self.dut.clk)

		self.dut.write_ena.value = 0

		return

	async def read(self, address):
		self.dut.read_address.value = address
		self.dut.read_ena.value = 1

		await RisingEdge(self.dut.clk)
		self.dut.read_ena.value = 0

		cycles = 0
		while True:
			await ReadOnly()
			valid = self.dut.read_valid.value == 1
			data = self.dut.read_data.value
			await NextTimeStep()
			if valid:
				return data
			cycles += 1
			await RisingEdge(self.dut.clk)


@cocotb.test()
async def ram_sdp_test(dut):
	ram = RamSdp(dut, 2)

	cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

	dut.reset.value = 1
	await ClockCycles(dut.clk, 50)
	dut.reset.value = 0
    
	for i in range(0xf):
		await ram.write(i, i)

	for i in range(0xf):
		val = await ram.read(i)
		assert i == val
		await ClockCycles(dut.clk, 1)

	await ClockCycles(dut.clk, 5)
