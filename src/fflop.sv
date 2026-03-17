/*******************************************************************************
 * Module: fflop
 * 
 * File Name: fflop.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Parameterized flip-flop with asynchronous active-low reset
 *     Default width is 32 bits
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module fflop #(
    parameter WIDTH = 32
) (
    input  logic             clk_i,
    input  logic             rst_n_i,
    input  logic [WIDTH-1:0] d_i,
    output logic [WIDTH-1:0] q_o
);
    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;
    
    logic [WIDTH-1:0] q;
  
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            q <= '0;
        end else begin
            q <= d_i;
        end
    end
  
    assign q_o = q;

endmodule