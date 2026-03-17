/*******************************************************************************
 * Module: trixv_sc
 * 
 * File Name: trixv_sc.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Single Cycle Processor
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
module trixv_mc 
    import typedefs::*; // Import package with alu_op_t
    #(
        parameter DWIDTH = 32,  // Data width
        parameter AWIDTH = 10   // Address width
    )
    (
        input  logic              clk_i,
        input  logic              rst_n_i,
        input  logic [DWIDTH-1:0] imem_rdata_i,
        output logic [AWIDTH-1:0] imem_addr_o,
        output logic              imem_wen_o,
        input  logic [DWIDTH-1:0] dmem_rdata_i,
        output logic [DWIDTH-1:0] dmem_wdata_o,
        output logic [AWIDTH-1:0] dmem_addr_o,
        output logic              dmem_wen_o
    );

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    // Internal signals
    logic [DWIDTH-1:0] dmem_rdata, dmem_wdata;
    logic [AWIDTH-1:0] imem_addr, dmem_addr;
    logic              imem_wen, dmem_wen;
    logic [6:0]        opcode, funct3, funct7;
    logic              pc_ctrl, pc_jump_ctrl, pc_en_ctrl;
    logic              data2_alu_ctrl, rf_wen_ctrl, alu_zero, alu_less, dmem_we_ctrl;
    logic [2:0]        imm_ctrl;
    logic [1:0]        data_mux_ctrl;
    alu_op_t           alu_ctrl;
    logic [DWIDTH-1:0] instr_fetch;
    logic              fetch_en_ctrl;

    // Datapath
    datapath_mc #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) dp
    (
        .clk_i           (clk_i),
        .rst_n_i         (rst_n_i),
        .imem_addr_o     (imem_addr),
        .imem_rdata_i    (imem_rdata_i),
        .dmem_addr_o     (dmem_addr),
        .dmem_wdata_o    (dmem_wdata),
        .dmem_rdata_i    (dmem_rdata),
        .pc_ctrl_i       (pc_ctrl),
        .pc_jump_ctrl_i  (pc_jump_ctrl),
        .pc_en_ctrl_i    (pc_en_ctrl),
        .imm_ctrl_i      (imm_ctrl),
        .data2_alu_ctrl_i(data2_alu_ctrl),
        .alu_ctrl_i      (alu_ctrl),
        .data_mux_ctrl_i (data_mux_ctrl),
        .rf_wen_ctrl_i   (rf_wen_ctrl),
        .fetch_en_ctrl_i (fetch_en_ctrl),
        .alu_zero_ctrl_o (alu_zero),
        .alu_less_ctrl_o (alu_less),
        .instr_fetch_o   (instr_fetch)
    );

    // Controller
    controller_mc ctrl (
        .clk_i           (clk_i),
        .rst_n_i         (rst_n_i),
        .opcode_i        (instr_fetch[6:0]),
        .funct3_i        (instr_fetch[14:12]),
        .funct7_i        (instr_fetch[31:25]),
        .pc_ctrl_o       (pc_ctrl),
        .pc_jump_ctrl_o  (pc_jump_ctrl),
        .pc_en_ctrl_o    (pc_en_ctrl),
        .imm_ctrl_o      (imm_ctrl),
        .data2_alu_ctrl_o(data2_alu_ctrl),
        .alu_ctrl_o      (alu_ctrl),
        .data_mux_ctrl_o (data_mux_ctrl),
        .rf_wen_ctrl_o   (rf_wen_ctrl),
        .alu_zero_i      (alu_zero),
        .alu_less_i      (alu_less),
        .dmem_we_ctrl_o  (dmem_we_ctrl),
        .fetch_en_ctrl_o (fetch_en_ctrl)
    );

    assign imem_addr_o  = imem_addr;
    assign imem_wen_o   = 1'b0;
    assign dmem_addr_o  = dmem_addr;
    assign dmem_wen_o   = dmem_we_ctrl;
    assign dmem_wdata_o = dmem_wdata;
    assign dmem_rdata   = dmem_rdata_i;

endmodule
