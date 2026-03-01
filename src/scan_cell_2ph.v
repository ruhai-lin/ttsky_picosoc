// Single Scan Cell with Two-Phase Clock

`ifndef SCAN_CELL_2PH_GUARD
`define SCAN_CELL_2PH_GUARD
`include "defs.v"

module scan_cell_2ph (
    input wire phi1,        // Phase 1 clock read into clock A
    input wire phi2,        // Phase 2 clock read out of clock B
    input wire rst_n,       // Reset
    input wire scan_in,     // Scan data input
    input wire data_in,     // Functional data input
    input wire scan_enable, // Scan mode enable
    input wire scan_mode, //0 for scan in, 1 for data
    output reg data_out,     // Functional data output
    output reg scan_out 
);
    
    // Internal ffs
    reg primary_ff;
    reg secondary_ff;

    always @(posedge phi1 or negedge rst_n) begin
        if (!rst_n)
            primary_ff <= 1'b0;
        else if (scan_enable) begin
            if (scan_mode)
                primary_ff <= scan_in;
            else
                primary_ff <= secondary_ff;
        end
    end

    always @(posedge phi2 or negedge rst_n) begin
        if (!rst_n)
            secondary_ff <= 1'b0;
        else if (scan_enable) begin
            if (scan_mode)
                secondary_ff <= primary_ff;
            else
                secondary_ff <= data_in;
        end
    end
    
    // Outputs
    always @(*) begin
        data_out = secondary_ff;
        scan_out = secondary_ff;
    end
    
endmodule
`endif 