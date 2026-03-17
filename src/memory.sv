/*******************************************************************************
 * Module: memory
 * 
 * File Name: memory.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     This module model a memory with addresses aligned to 32-bit words.
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module memory 
#(
    parameter DWIDTH = 32,  // Data width
    parameter AWIDTH = 32,  // Number of words
    parameter INIT_FILE = "" // Optional memory initialization file
)
(
    input  logic                    clk_i,
    input  logic [AWIDTH-1:0]       addr_i,
    input  logic [DWIDTH-1:0]       data_i,
    input  logic                    wr_en_i,
    input  logic                    sel_i,  // Come from the address decoder
    output logic [DWIDTH-1:0]       data_o
);

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    // Memory size
    localparam SIZE = 1 << (AWIDTH-2);

    // Memory array
    (* ram_style = "distributed" *) logic [DWIDTH-1:0] mem [0:SIZE-1];

    // Optional preload for simulation and FPGA memory initialization.
    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    // Write operation
    always @(posedge clk_i)
        if (wr_en_i && sel_i)
            mem[addr_i[AWIDTH-1:2]] <= data_i; // Word-aligned address

    // Read operation
    assign data_o = mem[addr_i[AWIDTH-1:2]];   // Word-aligned address

endmodule : memory
