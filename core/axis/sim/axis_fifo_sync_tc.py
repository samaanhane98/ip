import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer, ClockCycles


@cocotb.test()
async def axis_fifo_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset.value = 1
    await ClockCycles(dut.clk, 50)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 50)

    # axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.reset)
    # axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk, dut.reset)

    # await axis_source.send([x for x in range(32)])
    # data = await axis_sink.read()

    # assert data == [x for x in range(32)]
