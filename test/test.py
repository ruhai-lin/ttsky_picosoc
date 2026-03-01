# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.types import LogicArray
from copy import copy

@cocotb.test()
async def test_project(dut):
    
    async def set_io():
        while True:
            await ClockCycles(dut.clk, 1)
            dut.ui_in.value = ui_in
            dut.uio_in.value = uio_in
            
            
    async def custom_clock():
        while True:
            ui_in[3] = 0
            ui_in[4] = 0
            await ClockCycles(dut.clk, 1)
            ui_in[3] = 0
            ui_in[4] = 1
            await ClockCycles(dut.clk, 1)
            ui_in[3] = 0
            ui_in[4] = 0
            await ClockCycles(dut.clk, 1)
            ui_in[3] = 1
            ui_in[4] = 0
            await ClockCycles(dut.clk, 1)
            
    dut._log.info("Start")

    ADDR_WIDTH = 4
    ADDR_VAL = 0x123
    DATA_WIDTH = 32
    DATA_VAL = 0x123456789
    SCAN_FF_WIDTH = (ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH)*2
    
    ui_in = LogicArray("10000000")
    dut.ui_in.value = ui_in
    scan_in = ui_in[0]
    scan_enable = ui_in[1]
    scan_mode = ui_in[2]
    sclka = ui_in[3]
    sclkb = ui_in[4]
    csb = ui_in[5]
    web = ui_in[6]
    
    uio_in = LogicArray("11111111")
    dut.uio_in.value = uio_in
    
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    
    dut._log.info("Create standard clock")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    dut._log.info("Create 2 phase clock")
    cocotb.start_soon(custom_clock())
    dut._log.info("set io")

    cocotb.start_soon(set_io())
    
    dut._log.info("step")

    await ClockCycles(dut.clk, 16)

    
    dut.rst_n.value = 1
    dut._log.info("Reset comp")
    dut._log.info("Begin")
    await ClockCycles(dut.clk, 16)
    
    # scan in scan reg
    ui_in[0] = 0 # scan in
    ui_in[1] = 1 # scan enable
    ui_in[2] = 1 # scan mode
    await ClockCycles(dut.clk, 4)

    dut._log.info("scan in addr")
    addr_bin = f'{ADDR_VAL:09b}'
    data_bin = f'{DATA_VAL:33b}'
    
    for i in range(0, ADDR_WIDTH):
        ui_in[0] = int(addr_bin[i])
        await ClockCycles(dut.clk, 4)
        
    for i in range(0, DATA_WIDTH):
        ui_in[0] = int(data_bin[i])
        await ClockCycles(dut.clk, 4)
        
    for i in range(0, DATA_WIDTH):
        ui_in[0] = 0
        await ClockCycles(dut.clk, 4) 
    await ClockCycles(dut.clk, 4) 
    
    # write to ram
    ui_in[1] = 0 # scan enable
    ui_in[6] = 0 # web
    ui_in[7] = 1 # spare_we
    dut._log.info("write to ram addr: 0xFF data:0xFFFFFFFF")
    await ClockCycles(dut.clk, 128)
    
    ui_in[6] = 1 # web
    ui_in[7] = 0 # spare we
    dut._log.info("enable web (turn off write)")
    await ClockCycles(dut.clk, 128)
    
    # read sram
    dut._log.info("read ram addr 0x12345")
    ui_in[0] = 0 #scan_in
    ui_in[1] = 1 #scan enable
    ui_in[2] = 0 #PHASE MODE
    await ClockCycles(dut.clk, 64)

    # test scanout addr and data
    ui_in[0] = 0 #scan_in
    ui_in[1] = 1 #scan enable
    ui_in[2] = 1 #SCAN MODE
    await ClockCycles(dut.clk, 4)

    for i in range(0, ADDR_WIDTH):
        found = dut.uo_out.value & 1
        expect = int(addr_bin[i])
        dut._log.info("checking addr bit {} found {} expected {}".format(i,found,expect))
        assert found == expect
        await ClockCycles(dut.clk, 4)
        
    for i in range(0, DATA_WIDTH):
        found = dut.uo_out.value & 1
        expect = int(data_bin[i])
        dut._log.info("checking data out {} found {} expected {}".format(i,found,expect))
        assert found == expect
        await ClockCycles(dut.clk, 4)
        
    for i in range(0, DATA_WIDTH):
        found = dut.uo_out.value & 1
        expect = int(data_bin[i])
        dut._log.info("checking data in {} found {} expected {}".format(i,found,expect))
        assert found == expect
        await ClockCycles(dut.clk, 4)


    
    
