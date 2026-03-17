/*******************************************************************************
 * Module: top_trixv_sc
 * 
 * File Name: top_trixv_sc.sv
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
module top_trixv_mc
    import typedefs::*; // Import package with alu_op_t
    #(
        parameter DWIDTH  = 32,  // Data width
        parameter MEM_AW  = 10,  // Memory Address width
        parameter AWIDTH  = 12,  // Address width
        parameter IMEM_INIT_FILE = "trixv.imem"
    )
    (
        input  logic              clk_i,
        input  logic              rst_n_i,
        output logic              tx_o,
        output logic              tx_o_watch
    );
    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    // Internal signals
    logic [DWIDTH-1:0] imem_data, dmem_rdata, dmem_wdata;
    logic [AWIDTH-1:0] imem_addr, dmem_addr;
    logic              imem_wen, dmem_wen;
    logic [6:0]        opcode, funct3, funct7;
    logic              pc_ctrl, pc_jump_ctrl, data2_alu_ctrl, rf_wen_ctrl, alu_zero, alu_less, dmem_we_ctrl;
    logic [2:0]        imm_ctrl;
    logic [1:0]        data_mux_ctrl;
    alu_op_t           alu_ctrl;
    logic              sel_dmem, sel_uart;

    // Address decoder
    addr_decoder addr_decoder_inst (
        .addr    (dmem_addr[AWIDTH-1:0]),
        .sel_dmem(sel_dmem),
        .sel_uart(sel_uart)
    );

    // Instruction Memory
    memory #(
        .DWIDTH(DWIDTH),
        .AWIDTH(MEM_AW),
        .INIT_FILE(IMEM_INIT_FILE)
    ) imem (
        .clk_i  (clk_i),
        .addr_i (imem_addr[MEM_AW-1:0]),
        .data_i (32'b0),
        .wr_en_i(1'b0),
        .sel_i  (1'b1),
        .data_o (imem_data)
    );

    // Data Memory
    memory #(
        .DWIDTH(DWIDTH),
        .AWIDTH(MEM_AW),
        .INIT_FILE("")
    ) dmem (
        .clk_i  (clk_i),
        .addr_i (dmem_addr[MEM_AW-1:0]),
        .data_i (dmem_wdata),
        .wr_en_i(dmem_we_ctrl),
        .sel_i  (sel_dmem),
        .data_o (dmem_rdata)
    );

    // Peripheral bus
    obi_if #(
        .ADDR_WIDTH(AWIDTH),
        .DATA_WIDTH(DWIDTH)
    ) pbus (
        .clk_i  (clk_i),
        .rst_n_i(rst_n_i)
    );

    // Peripheral bus controller
    pbus_ctrl #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) pbus_ctrl_inst (
        .dmem_addr_i (dmem_addr),
        .dmem_wdata_i(dmem_wdata),
        .sel_uart_i  (sel_uart),
        .dmem_we_i   (dmem_we_ctrl),
        .pbus        (pbus)
    );

    // Peripheral Bus
    uart_tx_obi uart_tx_obi_inst (
        .bus  (pbus),
        .sel_i(sel_uart & dmem_we_ctrl),
        .tx_o (tx_o)
    );

    assign tx_o_watch = tx_o; // For waveform monitoring

    // Single Cycle Processor
    trixv_mc # (
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    )
    trixv_mc_inst (
        .clk_i       (clk_i),
        .rst_n_i     (rst_n_i),
        .imem_rdata_i(imem_data),
        .imem_addr_o (imem_addr),
        .imem_wen_o  (imem_wen),
        .dmem_rdata_i(dmem_rdata),
        .dmem_wdata_o(dmem_wdata),
        .dmem_addr_o (dmem_addr),
        .dmem_wen_o  (dmem_we_ctrl)
    );

endmodule
