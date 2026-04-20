import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer, ClockCycles

from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor)


def random_pause(probability=0.2):
    """Randomly pause each cycle with given probability"""
    while True:
        yield random.random() < probability


@cocotb.test()
async def axis_output_buffer_tc(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset.value = 1
    await ClockCycles(dut.clk, 100)
    dut.reset.value = 0

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.reset)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk, dut.reset)

    axis_sink.set_pause_generator(random_pause(0.2))

    await axis_source.send([x for x in range(32)])
    data = await axis_sink.read()

    assert data == [x for x in range(32)]
