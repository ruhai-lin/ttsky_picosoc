/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
//`timescale 1ns / 1ps
`include "sky130_sram_1rw_tiny.v"
`include "scan_chain_2ph.v"
`include "defs.v"
module tt_um_openram_top (
    `ifdef USE_POWER_PINS
      input VPWR,
      input VGND,
    `endif
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset

);

parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 32;
parameter WMASK_WIDTH = 4;
parameter SCAN_WIDTH = ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH;

  // All output pins must be assigned. If not used, assign to 0.

assign uio_out = 0;
assign uio_oe = 0;

wire [ADDR_WIDTH-1:0] addr;
wire [DATA_WIDTH-1:0] din;
wire [DATA_WIDTH-1:0] dout;
wire [WMASK_WIDTH-1:0] wmask;
wire [SCAN_WIDTH-1:0] scan_data_out;
wire scan_out;

wire scan_in, scan_enable, scan_mode, csb, web, sclka, sclkb;
assign web = ui_in[6];
assign csb = ui_in[5];
assign sclkb = ui_in[4];
assign sclka = ui_in[3];
assign scan_mode = ui_in[2]; //1 scan reg chain, 0 scan phase chain
assign scan_enable = ui_in[1]; //scan chain enable
assign scan_in = ui_in[0]; //input value

assign wmask = {uio_in[WMASK_WIDTH-1:0]};

assign uo_out[7:2] = 0;
assign uo_out[1] = scan_data_out[0];
assign uo_out[0] = scan_out;


sky130_sram_1rw_tiny SRAM 
    (
    `ifdef USE_POWER_PINS
    .vccd1(VPWR),
    .vssd1(VGND),
    `endif
     .clk0   (sclka), //SRAM USES A CLK 
     .csb0   (csb),
     .web0   (web),
     .wmask0 (wmask),
     .addr0  (addr),
     .din0   (din),
     .dout0  (dout)
);

scan_chain_2ph #(SCAN_WIDTH) scan_chain( //writes on B reads on A
    .phi1(sclka), //clk A
    .phi2(sclkb), //clk B
    .rst_n(rst_n),
    .scan_enable(scan_enable),
    .scan_mode(scan_mode),
    .scan_in(scan_in),
    .data_in({scan_data_out[SCAN_WIDTH-1:DATA_WIDTH],dout}), //clk A
    .scan_out(scan_out), //clk B
    .data_out(scan_data_out) //clkb B
);

assign addr = scan_data_out[SCAN_WIDTH-1:SCAN_WIDTH-ADDR_WIDTH];
assign din = scan_data_out[SCAN_WIDTH-ADDR_WIDTH-1:SCAN_WIDTH-DATA_WIDTH-ADDR_WIDTH];

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0, ui_in[7:4]};

endmodule
