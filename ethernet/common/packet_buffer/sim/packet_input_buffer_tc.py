"""
Testcases for packet_input_buffer
==================================
DUT ports:
    clk              : IN  STD_LOGIC
    reset            : IN  STD_LOGIC
    packet_in        : IN  t_axis_packet_64
    packet_in_ready  : OUT STD_LOGIC
    packet_out       : OUT t_axis_packet_64
    packet_out_ready : IN  STD_LOGIC
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from axis_packet_bfm import AxisPacket, AxisPacketDriver, AxisPacketMonitor, AxisReadyDriver


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

ALL_KEEP = 0xFF  # All 8 bytes valid (64-bit bus)


async def reset_dut(dut, cycles: int = 4) -> None:
    dut.reset.value = 1
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)


def build_bfm(dut, always_ready: bool = True, bp_prob: float = 0.3):
    """Instantiate driver, monitor and ready driver. Returns (driver, monitor)."""
    driver = AxisPacketDriver(dut, dut.clk, prefix="packet_in",  reset=dut.reset)
    monitor = AxisPacketMonitor(dut, dut.clk, prefix="packet_out")
    AxisReadyDriver(dut, dut.clk, prefix="packet_out",
                    always_ready=always_ready, bp_prob=bp_prob)
    return driver, monitor


def check_packet(received: AxisPacket, expected: AxisPacket) -> None:
    assert received.data == expected.data, (
        f"Data mismatch:\n  got {[hex(d) for d in received.data]}\n"
        f"  expected {[hex(d) for d in expected.data]}"
    )
    assert received.keep == expected.keep, (
        f"Keep mismatch:\n  got {[hex(k) for k in received.keep]}\n"
        f"  expected {[hex(k) for k in expected.keep]}"
    )
    assert received.user == expected.user, (
        f"User mismatch:\n  got {[hex(u) for u in received.user]}\n"
        f"  expected {[hex(u) for u in expected.user]}"
    )
    assert received.first == expected.first,      "first flag mismatch"
    assert received.meta_valid == expected.meta_valid, "meta_valid flag mismatch"


# ---------------------------------------------------------------------------
# TC01 – Single beat packet
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc01_single_beat(dut):
    """Single-beat packet passes through unchanged."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver, monitor = build_bfm(dut, always_ready=True)

    pkt = AxisPacket(
        data=[0xDEAD_BEEF_CAFE_BABE],
        keep=[ALL_KEEP],
        user=[0x00],
        first=True,
        meta_valid=False,
    )

    await driver.send(pkt)
    received = await monitor.recv()

    cocotb.log.info(f"TC01 received: {received}")
    check_packet(received, pkt)


# ---------------------------------------------------------------------------
# TC02 – Multi-beat packet
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc02_multi_beat(dut):
    """Multi-beat packet passes through with correct beat order."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver, monitor = build_bfm(dut, always_ready=True)

    pkt = AxisPacket(
        data=[0x0102_0304_0506_0708,
              0x090A_0B0C_0D0E_0F10,
              0x1112_1314_1516_1718],
        keep=[ALL_KEEP, ALL_KEEP, 0x0F],   # last beat: 4 valid bytes
        user=[0x00, 0x00, 0x00],
        first=True,
        meta_valid=False,
    )

    await driver.send(pkt)
    received = await monitor.recv()

    cocotb.log.info(f"TC02 received: {received}")
    check_packet(received, pkt)


# ---------------------------------------------------------------------------
# TC03 – meta_valid flag
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc03_meta_valid(dut):
    """meta_valid is asserted on the first beat and preserved."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver, monitor = build_bfm(dut, always_ready=True)

    pkt = AxisPacket(
        data=[0xAAAA_BBBB_CCCC_DDDD, 0x1111_2222_3333_4444],
        keep=[ALL_KEEP, ALL_KEEP],
        user=[0x00, 0x00],
        first=True,
        meta_valid=True,
    )

    await driver.send(pkt)
    received = await monitor.recv()

    cocotb.log.info(f"TC03 received: {received}")
    assert received.meta_valid, "Expected meta_valid to be set on received packet"
    check_packet(received, pkt)


# ---------------------------------------------------------------------------
# TC04 – user field
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc04_user_field(dut):
    """user field on the first beat is preserved."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver, monitor = build_bfm(dut, always_ready=True)

    pkt = AxisPacket(
        data=[0x0000_0000_0000_0001, 0x0000_0000_0000_0002],
        keep=[ALL_KEEP, ALL_KEEP],
        user=[0xDEAD_BEEF, 0x0000_0000],
        first=True,
    )

    await driver.send(pkt)
    received = await monitor.recv()

    cocotb.log.info(f"TC04 received: {received}")
    assert received.user[0] == pkt.user[0], (
        f"user[0] mismatch: got {hex(received.user[0])}, "
        f"expected {hex(pkt.user[0])}"
    )


# ---------------------------------------------------------------------------
# TC05 – Multiple sequential packets
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc05_sequential_packets(dut):
    """Send N packets back-to-back and verify all arrive in order."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver, monitor = build_bfm(dut, always_ready=True)

    N = 8
    packets = [
        AxisPacket(
            data=[i * 0x0101_0101_0101_0101,
                  i * 0x0202_0202_0202_0202],
            keep=[ALL_KEEP, ALL_KEEP],
            user=[i, 0],
            first=True,
        )
        for i in range(1, N + 1)
    ]

    for pkt in packets:
        await driver.send(pkt)

    for i, expected in enumerate(packets):
        received = await monitor.recv()
        cocotb.log.info(f"TC05 packet {i}: {received}")
        check_packet(received, expected)


# ---------------------------------------------------------------------------
# TC06 – Back-pressure from sink
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc06_back_pressure(dut):
    """Packet still arrives correctly when the sink randomly deasserts ready."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver, monitor = build_bfm(dut, always_ready=False, bp_prob=0.5)

    pkt = AxisPacket(
        data=[0xFEED_FACE_DEAD_BEEF,
              0x0BAD_C0DE_1234_5678,
              0xCAFE_BABE_9ABC_DEF0],
        keep=[ALL_KEEP, ALL_KEEP, ALL_KEEP],
        user=[0x00, 0x00, 0x00],
        first=True,
        meta_valid=True,
    )

    await driver.send(pkt)
    received = await monitor.recv()

    cocotb.log.info(f"TC06 received: {received}")
    check_packet(received, pkt)


# ---------------------------------------------------------------------------
# TC07 – Idle gaps between beats (driver-side)
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc07_driver_idle_gaps(dut):
    """Packet arrives correctly when the driver inserts random idle cycles."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    # Use a driver with idle_prob so it randomly deasserts valid mid-packet
    driver = AxisPacketDriver(dut, dut.clk, prefix="packet_in",
                              reset=dut.reset, idle_prob=0.4)
    monitor = AxisPacketMonitor(dut, dut.clk, prefix="packet_out")
    AxisReadyDriver(dut, dut.clk, prefix="packet_out", always_ready=True)

    pkt = AxisPacket(
        data=[0x1111_1111_1111_1111,
              0x2222_2222_2222_2222,
              0x3333_3333_3333_3333,
              0x4444_4444_4444_4444],
        keep=[ALL_KEEP] * 4,
        user=[0x00] * 4,
        first=True,
    )

    await driver.send(pkt)
    received = await monitor.recv()

    cocotb.log.info(f"TC07 received: {received}")
    check_packet(received, pkt)


# ---------------------------------------------------------------------------
# TC08 – Back-pressure and idle gaps combined
# ---------------------------------------------------------------------------

@cocotb.test()
async def tc08_combined_stress(dut):
    """Multiple packets with both driver idle gaps and sink back-pressure."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    driver = AxisPacketDriver(dut, dut.clk, prefix="packet_in",
                              reset=dut.reset, idle_prob=0.3)
    monitor = AxisPacketMonitor(dut, dut.clk, prefix="packet_out")
    AxisReadyDriver(dut, dut.clk, prefix="packet_out",
                    always_ready=False, bp_prob=0.4)

    N = 4
    packets = [
        AxisPacket(
            data=[0xDEAD_0000_0000_0000 | i,
                  0xBEEF_0000_0000_0000 | i],
            keep=[ALL_KEEP, ALL_KEEP],
            user=[i, 0],
            first=True,
            meta_valid=(i % 2 == 0),
        )
        for i in range(N)
    ]

    for pkt in packets:
        await driver.send(pkt)

    for i, expected in enumerate(packets):
        received = await monitor.recv()
        cocotb.log.info(f"TC08 packet {i}: {received}")
        check_packet(received, expected)
