// Two-Phase Clock Scan Chain (8-bit example)
`ifndef SCAN_CHAIN_2PH_GUARD
`define SCAN_CHAIN_2PH_GUARD
`include "scan_cell_2ph.v"

module scan_chain_2ph #(
    parameter CHAIN_LENGTH = 8
) (
    input wire phi1, //clk A
    input wire phi2, //clk B
    input wire rst_n,
    input wire scan_enable,
    input wire scan_mode,
    input wire scan_in,
    input wire [CHAIN_LENGTH-1:0] data_in, //clk A
    output wire scan_out, //clk B
    output wire [CHAIN_LENGTH-1:0] data_out //clkb B
);
    
    // Internal signals

    wire [CHAIN_LENGTH:0] scan_chain;
    
    // Connect scan chain input
    assign scan_chain[0] = scan_in;
    assign scan_out = scan_chain[CHAIN_LENGTH];
    
    // Generate scan cells
    genvar i;
    generate
        for (i = 0; i < CHAIN_LENGTH; i = i + 1) begin : scan_cells
            scan_cell_2ph scan_cell(
                .phi1(phi1),
                .phi2(phi2),
                .rst_n(rst_n),
                .scan_in(scan_chain[i]),
                .data_in(data_in[i]),
                .scan_enable(scan_enable),
                .scan_mode(scan_mode),
                .scan_out(scan_chain[i+1]),
                .data_out(data_out[i])
            );
        end
    endgenerate
    
endmodule

`endif 