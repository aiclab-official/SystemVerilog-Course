/*******************************************************************************
 * Module: datapath
 * 
 * File Name: datapath.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Data path of TRIX-V
 *     
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   Amir   2025-05-05  Initial version
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module datapath_mc
    import typedefs::*; // Import package with alu_op_t
    #(
        parameter DWIDTH = 32,  // Data width
        parameter AWIDTH = 10   // Address width
    )
    (
        input  logic              clk_i,
        input  logic              rst_n_i,
        output logic [AWIDTH-1:0] imem_addr_o,
        input  logic [DWIDTH-1:0] imem_rdata_i,
        output logic [AWIDTH-1:0] dmem_addr_o,
        output logic [DWIDTH-1:0] dmem_wdata_o,
        input  logic [DWIDTH-1:0] dmem_rdata_i,
        input  logic              pc_ctrl_i,
        input  logic              pc_en_ctrl_i,
        input  logic              pc_jump_ctrl_i,
        input  logic [ 2:0]       imm_ctrl_i,
        input  logic              data2_alu_ctrl_i,
        input  alu_op_t           alu_ctrl_i,
        input  logic [ 1:0]       data_mux_ctrl_i,
        input  logic              rf_wen_ctrl_i,
        input  logic              fetch_en_ctrl_i,
        output logic              alu_zero_ctrl_o,  // For beq
        output logic              alu_less_ctrl_o,  // For blt
        output logic [DWIDTH-1:0] instr_fetch_o
    );

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    logic [DWIDTH-1:0] pc, pc_next, pc4, pc_jump, pc_jalr, pc_fetch, pc4_fetch, pc_jump_execute;
    logic [DWIDTH-1:0] imm_ext;
    logic [DWIDTH-1:0] alu_result, alu_result_execute;
    logic [DWIDTH-1:0] data1, data2, rf_rd_data2, rf_wdata, data1_decode, rf_rd_data2_decode;
    logic [DWIDTH-1:0] instr, instr_fetch;
    logic [DWIDTH-1:0] dmem_rdata_memory;

    //-------------------------------------------------------------------------
    // Fetch
    //-------------------------------------------------------------------------
    muxN #(2) pc_next_mux(.sel_i(pc_ctrl_i),.d_i({pc4, pc_jalr}), .y_o(pc_next));

    fflopLD #(32) pc_ff(.clk_i, .rst_n_i, .d_i(pc_next), .en_i(pc_en_ctrl_i), .q_o(pc));

    assign imem_addr_o = pc[AWIDTH-1:0];

    adder #(32) pc_adder4(.a_i(pc), .b_i(4), .result_o(pc4));

    assign instr = imem_rdata_i;
    assign instr_fetch_o = instr_fetch;

    fflopLD #(32) fetch_1(clk_i, rst_n_i, instr, fetch_en_ctrl_i, instr_fetch);
    fflopLD #(32) fetch_2(clk_i, rst_n_i, pc   , fetch_en_ctrl_i, pc_fetch);
    fflopLD #(32) fetch_3(clk_i, rst_n_i, pc4  , fetch_en_ctrl_i, pc4_fetch);
    //-------------------------------------------------------------------------
    // Decode
    //-------------------------------------------------------------------------
    // Register File
    regfile rf(
        .clk_i,
        .rst_n_i,
        .raddr1_i(instr_fetch[19:15]),
        .raddr2_i(instr_fetch[24:20]),
        .waddr_i(instr_fetch[11:7]),
        .wdata_i(rf_wdata),
        .wen_i(rf_wen_ctrl_i),
        .rdata1_o(data1),
        .rdata2_o(rf_rd_data2)
    );

    // Immediate Extender
    extend imm_extender(
        .imm_ctrl_i(imm_ctrl_i),
        .instr_i(instr_fetch),
        .imm_o(imm_ext)
    );
    fflopLD #(32) decode_1(clk_i, rst_n_i, data1      , 1'b1, data1_decode);
    fflopLD #(32) decode_2(clk_i, rst_n_i, rf_rd_data2, 1'b1, rf_rd_data2_decode);
    //-------------------------------------------------------------------------
    // Execute
    //-------------------------------------------------------------------------
    // ALU
    muxN #(2) alu_mux(
        .sel_i(data2_alu_ctrl_i),
        .d_i({imm_ext, rf_rd_data2_decode}),
        .y_o(data2)
    );
    
    alu # (32) alu(
        .a_i(data1_decode),
        .b_i(data2),
        .alu_op_i(alu_ctrl_i),
        .result_o(alu_result),
        .zero_o(alu_zero_ctrl_o),
        .less_o(alu_less_ctrl_o)
    );

    adder #(32) pc_adder_jump(
        .a_i(pc_fetch),
        .b_i(imm_ext),
        .result_o(pc_jump)
    );
    
    fflopLD #(32) execute_1(clk_i, rst_n_i, pc_jump   , 1'b1, pc_jump_execute);
    fflopLD #(32) execute_2(clk_i, rst_n_i, alu_result, 1'b1, alu_result_execute);
    //-------------------------------------------------------------------------
    // Memory
    //-------------------------------------------------------------------------
    muxN #(2) pc_jump_mux(
        .sel_i(pc_jump_ctrl_i),
        .d_i({pc_jump_execute, alu_result_execute}), // use registered ALU result to break long path to pc_ff
        .y_o(pc_jalr)
    );

    assign dmem_addr_o  = alu_result_execute[AWIDTH-1:0];
    assign dmem_wdata_o = rf_rd_data2;

    fflopLD #(32) memory_1(clk_i, rst_n_i, dmem_rdata_i, 1'b1, dmem_rdata_memory);
    //-------------------------------------------------------------------------
    // WriteRegister
    //-------------------------------------------------------------------------
    muxN #(3) rf_wdata_mux(
        .sel_i(data_mux_ctrl_i),
        .d_i({alu_result_execute, dmem_rdata_memory, pc4_fetch}),
        .y_o(rf_wdata)
    );

endmodule
