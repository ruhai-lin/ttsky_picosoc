/*
 * Tiny Tapeout wrapper for PicoSoC (PicoRV32 + SPI flash + UART)
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_picosoc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

	//---------- PicoSoC interface ----------
	wire        iomem_valid;
	wire        iomem_ready;
	wire [ 3:0] iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	wire [31:0] iomem_rdata;

	wire        ser_tx;
	wire        ser_rx;

	wire        flash_csb;
	wire        flash_clk;
	wire        flash_io0_oe, flash_io1_oe, flash_io2_oe, flash_io3_oe;
	wire        flash_io0_do, flash_io1_do, flash_io2_do, flash_io3_do;
	wire        flash_io0_di, flash_io1_di, flash_io2_di, flash_io3_di;

	// External iomem tie-off: only respond outside the internal peripheral range
	// (0x0200_0xxx holds SPI-config and UART registers handled inside picosoc)
	assign iomem_ready = iomem_valid && (iomem_addr[31:24] != 8'h02);
	assign iomem_rdata = 32'h0;

	// IRQ inputs (unused for now)
	wire        irq_5 = 1'b0;
	wire        irq_6 = 1'b0;
	wire        irq_7 = 1'b0;

	//---------- Pin mapping ----------
	// Dedicated outputs: UART TX + Flash control/data
	assign uo_out[0]   = ser_tx;
	assign uo_out[1]   = flash_csb;
	assign uo_out[2]   = flash_clk;
	assign uo_out[3]   = flash_io0_oe;
	assign uo_out[4]   = flash_io1_oe;
	assign uo_out[5]   = flash_io2_oe;
	assign uo_out[6]   = flash_io3_oe;
	assign uo_out[7]   = flash_io0_do;

	// Dedicated inputs: UART RX + Flash data in
	assign ser_rx         = ui_in[0];
	assign flash_io0_di   = ui_in[1];
	assign flash_io1_di   = ui_in[2];
	assign flash_io2_di   = ui_in[3];
	assign flash_io3_di   = ui_in[4];
	// ui_in[5:7] unused

	// Bidirectional: Flash IO1/IO2/IO3 data out (we only drive out; board can wire to flash)
	assign uio_out[0] = flash_io1_do;
	assign uio_out[1] = flash_io2_do;
	assign uio_out[2] = flash_io3_do;
	assign uio_out[3] = 1'b0;
	assign uio_out[4] = 1'b0;
	assign uio_out[5] = 1'b0;
	assign uio_out[6] = 1'b0;
	assign uio_out[7] = 1'b0;
	assign uio_oe[0]  = 1'b1;   // output
	assign uio_oe[1]  = 1'b1;
	assign uio_oe[2]  = 1'b1;
	assign uio_oe[3]  = 1'b0;
	assign uio_oe[4]  = 1'b0;
	assign uio_oe[5]  = 1'b0;
	assign uio_oe[6]  = 1'b0;
	assign uio_oe[7]  = 1'b0;

	//---------- PicoSoC instance ----------
	picosoc picosoc_inst (
		.clk            (clk),
		.resetn          (rst_n),

		.iomem_valid     (iomem_valid),
		.iomem_ready     (iomem_ready),
		.iomem_wstrb     (iomem_wstrb),
		.iomem_addr      (iomem_addr),
		.iomem_wdata     (iomem_wdata),
		.iomem_rdata     (iomem_rdata),

		.irq_5           (irq_5),
		.irq_6           (irq_6),
		.irq_7           (irq_7),

		.ser_tx          (ser_tx),
		.ser_rx          (ser_rx),

		.flash_csb       (flash_csb),
		.flash_clk       (flash_clk),
		.flash_io0_oe    (flash_io0_oe),
		.flash_io1_oe    (flash_io1_oe),
		.flash_io2_oe    (flash_io2_oe),
		.flash_io3_oe    (flash_io3_oe),
		.flash_io0_do    (flash_io0_do),
		.flash_io1_do    (flash_io1_do),
		.flash_io2_do    (flash_io2_do),
		.flash_io3_do    (flash_io3_do),
		.flash_io0_di    (flash_io0_di),
		.flash_io1_di    (flash_io1_di),
		.flash_io2_di    (flash_io2_di),
		.flash_io3_di    (flash_io3_di)
	);

endmodule
