/*******************************************************************************
 * Module: fifo
 * 
 * File Name: fifo.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     FIFO
 *     - Configurable width and depth.
 *       - Depth must be a power of 2.
 *     - Asynchronous active-low reset.
 *     - Read and write operations are synchronous to the rising edge of the clock.
 *     - Writes are ignored when the FIFO is full.
 *     - Reads are ignored when the FIFO is empty.
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
 module fifo #(
    WIDTH = 32,
    DEPTH = 16
 )
 (
    input  logic             clk_i,
    input  logic             rst_n_i,
    //--------------------------------
    // Write
    input  logic [WIDTH-1:0] wdata_i,
    input  logic             wr_en_i,
    output logic             full_o,
    //--------------------------------
    // Read
    output logic [WIDTH-1:0] rdata_o,
    input  logic             rd_en_i,
    output logic             empty_o
 );
    timeunit 1ns; timeprecision 100ps;
    // Check if DEPTH is power of 2
    // Power of 2 means only one bit should be set (e.g. 2=10, 4=100, 8=1000, etc)
    initial begin : depth_power_of_2_check
        assert((DEPTH & (DEPTH-1)) == 0) else
            $error("FIFO depth must be a power of 2");
    end

    localparam ADDR_WIDTH = $clog2(DEPTH);
    // Preserve key FIFO internals for post-synthesis ILA probing.
    logic [ADDR_WIDTH-1:0] rptr, wptr;
    logic full, empty;
    logic last_was_read;

    // Register Array
    // (* ram_style = "distributed" *) for LUT RAM (async-read capable, good for small FIFOs)
    // (* ram_style = "block" *)       for BRAM     (sync read only, efficient for large FIFOs)
    // The read operation uses rdata_o <= mem[rptr] (registered), so both styles are valid.
    // Default: block RAM. Change to "distributed" for DEPTH < 64 to save BRAM resources.
    (* ram_style = "distributed" *) logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Write operation
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            wptr <= 0;
        end else begin
            if (wr_en_i && !full) begin
                mem[wptr] <= wdata_i;
                wptr      <= wptr + 1'b1;
            end
        end
    end

    // Read operation
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rptr <= 0;
        end else begin
            if (rd_en_i && !empty) begin
                rptr    <= rptr + 1'b1;
                rdata_o <= mem[rptr];
            end
        end
    end

    // assign rdata_o = mem[rptr];

    // Last operation tracker
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            last_was_read <= 1; // Initialize as empty
        end else begin
            if (rd_en_i && !empty) begin
                last_was_read <= 1;
            end else if (wr_en_i && !full) begin
                last_was_read <= 0;
            end else begin
                last_was_read <= last_was_read;
            end
        end
    end

    assign full    = (wptr == rptr) && !last_was_read; // Last operation was write
    assign empty   = (wptr == rptr) &&  last_was_read; // Last operation was read

    assign full_o  = full;
    assign empty_o = empty;


endmodule : fifo