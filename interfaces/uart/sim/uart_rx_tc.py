import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer, ClockCycles

from uart_bfm import UartDriver


@cocotb.test()
async def uart_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset.value = 1
    await ClockCycles(dut.clk, 100)
    dut.reset.value = 0

    uart_source = UartDriver(dut.rx)

    await uart_source.send_bytes(bytes([0xAA, 0xBB, 0xCC]))

    await ClockCycles(dut.clk, 30000)

    # cocotb.log.info("data is %s", dut.data.value)
