import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

CLK_PERIOD_NS = 20          # 50 MHz
RESET_CYCLES  = 100
UART_CLKDIV   = 104         # firmware sets reg_uart_clkdiv = 104
UART_BIT_CLKS = UART_CLKDIV + 2   # 106 clock cycles per UART bit


async def uart_receive_byte(dut, bit_clks):
    """Wait for and decode one UART byte from ser_tx_out."""
    await FallingEdge(dut.ser_tx_out)
    await ClockCycles(dut.clk, bit_clks // 2)

    byte_val = 0
    for i in range(8):
        await ClockCycles(dut.clk, bit_clks)
        bit = int(dut.ser_tx_out.value)
        byte_val |= (bit << i)

    await ClockCycles(dut.clk, bit_clks)
    return byte_val


async def uart_collector(dut, char_list):
    """Background coroutine: continuously collects UART bytes."""
    line_buffer = ""
    while True:
        b = await uart_receive_byte(dut, UART_BIT_CLKS)
        char_list.append(b)

        if b == 10:
            # dut._log.info("UART: %s", line_buffer)
            line_buffer = ""
        elif b == 13:
            pass
        else:
            ch = chr(b) if 32 <= b < 127 else "<0x{:02x}>".format(b)
            line_buffer += ch


@cocotb.test(timeout_time=500, timeout_unit="ms")
async def test_picosoc_firmware(dut):
    """Boot PicoSoC firmware from SPI flash, verify banner after auto-Enter."""

    dut._log.info("Starting PicoSoC firmware test")

    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value    = 1
    dut.uio_in.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, RESET_CYCLES)
    dut.rst_n.value = 1
    dut._log.info("Reset released, running firmware (auto-Enter at 250k cycles)...")

    uart_chars = []
    cocotb.start_soon(uart_collector(dut, uart_chars))

    # tb.v auto-sends '\r' at 250k cycles post-reset.
    # Wait 750k cycles total: 250k boot + send + 500k for banner/menu.
    await ClockCycles(dut.clk, 750_000)

    output = bytes(uart_chars).decode("ascii", errors="replace")
    dut._log.info("Collected UART output (%d chars):\n%s", len(uart_chars), output)

    assert "Booting" in output, "Expected boot banner in UART output"
    dut._log.info("PASS - firmware booted and printed expected messages")
