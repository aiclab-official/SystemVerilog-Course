/*******************************************************************************
 * Module: muxN
 * 
 * File Name: muxN.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     N-to-1 Multiplexer module implementation in SystemVerilog.
 *     Generic multiplexer that can be parameterized for different data widths
 *     and number of input ports.
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/

module muxN #(
    parameter int N = 4,                  // Number of inputs
    parameter int WIDTH = 32              // Bit width of each input/output
) (
    input  logic [0:N-1][WIDTH-1:0] d_i,  // 2D packed array input: {d_i[0], d_i[1], ..., d_i[N-1]}
    input  logic [$clog2(N)-1:0] sel_i,   // Select signal
    output logic [WIDTH-1:0]     y_o      // Output
);

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    always_comb begin
        if (sel_i < N) begin  // Valid selection
            y_o = d_i[sel_i];
        end else begin
            y_o = '0;  // Default output
        end
    end

endmodule
