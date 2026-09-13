from cocotb.triggers import RisingEdge

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