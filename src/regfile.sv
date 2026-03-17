/*******************************************************************************
 * Module: regfile
 * 
 * File Name: regfile.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     This file contains the implementation of the register module used
 *     in the AICLAB Trix-V-SC project. The register module is responsible
 *     for storing and providing access to data within the system.
 *     
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module regfile (
    input  logic        clk_i,
    input  logic        rst_n_i,
    input  logic [4:0]  raddr1_i,
    input  logic [4:0]  raddr2_i,
    input  logic [4:0]  waddr_i,
    input  logic [31:0] wdata_i,
    input  logic        wen_i,
    output logic [31:0] rdata1_o,
    output logic [31:0] rdata2_o
  );
    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;
  
    logic [31:0] regs [0:31];
  
    // Synchronous write
    always_ff @(posedge clk_i or negedge rst_n_i) begin
      if (!rst_n_i) begin
        for (int i = 0; i < 32; i++)
          regs[i] <= '0;
      end else if (wen_i && waddr_i != 0) begin
        regs[waddr_i] <= wdata_i;
      end
    end
  
    // Asynchronous reads
    assign rdata1_o = (raddr1_i == 0) ? '0 : regs[raddr1_i];
    assign rdata2_o = (raddr2_i == 0) ? '0 : regs[raddr2_i];
  
endmodule