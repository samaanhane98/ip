import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer, ClockCycles

from uart_bfm import UartMonitor


@cocotb.test()
async def uart_tx_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset.value = 1
    await ClockCycles(dut.clk, 100)
    dut.reset.value = 0

    uart_sink = UartMonitor(dut.tx)
    uart_sink.start()

    await ClockCycles(dut.clk, 100)

    dut.s_axis_tdata.value = 0xAA
    dut.s_axis_tvalid.value = 1

    await ClockCycles(dut.clk, 1)
    dut.s_axis_tvalid.value = 0

    frame = await uart_sink.recv()

    print(frame.data)
    assert frame.data == 0xAA
