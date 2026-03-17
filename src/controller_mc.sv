/*******************************************************************************
 * Module: controller
 * 
 * File Name: controller.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Controller of Multi-Cycle TRIX-V
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
module controller_mc 
    import typedefs::*; // Import package with alu_op_t
    (
        input  logic        clk_i,
        input  logic        rst_n_i,
        input  logic [6:0]  opcode_i,
        input  logic [2:0]  funct3_i,
        input  logic [6:0]  funct7_i,
        output logic        pc_ctrl_o,
        output logic        pc_jump_ctrl_o,
        output logic        pc_en_ctrl_o,
        output logic [2:0]  imm_ctrl_o,
        output logic        data2_alu_ctrl_o,
        output alu_op_t     alu_ctrl_o,
        output logic [1:0]  data_mux_ctrl_o,
        output logic        rf_wen_ctrl_o,
        input  logic        alu_zero_i,
        input  logic        alu_less_i,
        output logic        dmem_we_ctrl_o,
        output logic        fetch_en_ctrl_o
    );

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    logic cond;
    alu_op_t alu_op;
    typedef enum logic [3:0] {FETCH=0, DECODE, MEMADDR, MEMREAD, MEMWRITE, REGWRITE, 
                              EXECUTER, EXECUTEI, JALR, JWRITE,JAL, BEQ, ALUWRITE
                             } state_t;

    state_t current_state, next_state;
    //-------------------------------------------------------------------------
    always_comb begin
        case (funct3_i[2:0])
            3'b000:  cond = alu_zero_i;  // beq
            3'b001:  cond = ~alu_zero_i; // bne
            3'b100:  cond = alu_less_i;  // blt
            3'b101:  cond = ~alu_less_i; // bge
            default: cond = 1'b0;
        endcase
    end
    //-------------------------------------------------------------------------
    always_comb begin
        case(funct3_i[2:0]) // alu_op
            3'b000:
                if ({opcode_i[5], funct7_i[5]} == 2'b11)
                    alu_op = ALU_SUB;
                else
                    alu_op = ALU_ADD;
            3'b001: alu_op = ALU_SLL;
            3'b010: alu_op = ALU_SLT;
            3'b100: alu_op = ALU_XOR;
            3'b101:
                if (funct7_i[5] == 1'b0)
                    alu_op = ALU_SRL;
                else
                    alu_op = ALU_SRA;
            3'b110: alu_op = ALU_OR;
            3'b111: alu_op = ALU_AND;
            default: alu_op = ALU_ADD;
        endcase
    end
    //-------------------------------------------------------------------------
    always_comb begin
        case(opcode_i)
            OPCODE_LOAD:       imm_ctrl_o       = 3'b000;
            OPCODE_STORE:      imm_ctrl_o       = 3'b001;
            OPCODE_R_TYPE:     imm_ctrl_o       = 3'b000;
            OPCODE_I_TYPE_ALU: imm_ctrl_o       = 3'b000;
            OPCODE_JALR:       imm_ctrl_o       = 3'b000;
            OPCODE_JAL:        imm_ctrl_o       = 3'b100;
            OPCODE_BRANCH:     imm_ctrl_o       = 3'b010;
            default:           imm_ctrl_o       = 3'b000;
        endcase
    end
    //-------------------------------------------------------------------------
    // State register
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            current_state <= FETCH;
        end else begin
            current_state <= next_state;
        end
    end
    //-------------------------------------------------------------------------
    // Next state logic
    //-------------------------------------------------------------------------
    always_comb begin
        next_state = current_state;

        case (current_state)
            FETCH:                     next_state = DECODE;
            DECODE:
                case(opcode_i)
                    OPCODE_LOAD:       next_state = MEMADDR;
                    OPCODE_STORE:      next_state = MEMADDR;
                    OPCODE_R_TYPE:     next_state = EXECUTER;
                    OPCODE_I_TYPE_ALU: next_state = EXECUTEI;
                    OPCODE_JALR:       next_state = JALR;
                    OPCODE_JAL:        next_state = JAL;
                    OPCODE_BRANCH:     next_state = BEQ;
                    default:           next_state = FETCH;
                endcase
            MEMADDR:
                if(opcode_i[5])        next_state = MEMWRITE; // store
                else                   next_state = MEMREAD;  // load
            MEMREAD:                   next_state = REGWRITE;
            MEMWRITE:                  next_state = FETCH;
            REGWRITE:                  next_state = FETCH;
            EXECUTER:                  next_state = ALUWRITE;
            EXECUTEI:                  next_state = ALUWRITE;
            JALR:                      next_state = JWRITE;
            JAL:                       next_state = JWRITE;
            JWRITE:                    next_state = FETCH;
            BEQ:                       next_state = FETCH;
            ALUWRITE:                  next_state = FETCH;
            default:                   next_state = FETCH;
        endcase
    end
    //-------------------------------------------------------------------------
    // Output logic
    //-------------------------------------------------------------------------
    always_comb begin
        pc_ctrl_o        = 1'b0;
        data2_alu_ctrl_o = 1'b0;
        alu_ctrl_o       = ALU_ADD;
        data_mux_ctrl_o  = 2'b00;
        rf_wen_ctrl_o    = 1'b0;
        dmem_we_ctrl_o   = 1'b0;
        pc_jump_ctrl_o   = 1'b0;
        pc_en_ctrl_o     = 1'b0;
        fetch_en_ctrl_o  = 1'b0;

        case (current_state)
            FETCH: begin
                fetch_en_ctrl_o  = 1'b1;
            end
            DECODE: begin
                pc_en_ctrl_o     = 1'b1;
            end
            MEMADDR: begin
                data2_alu_ctrl_o = 1'b0;
                alu_ctrl_o       = ALU_ADD;
            end
            MEMREAD: begin
                dmem_we_ctrl_o   = 1'b0;
            end
            MEMWRITE: begin
                dmem_we_ctrl_o   = 1'b1;
            end
            REGWRITE: begin
                data_mux_ctrl_o  = 2'b01;
                rf_wen_ctrl_o    = 1'b1;
            end
            EXECUTER: begin
                data2_alu_ctrl_o = 1'b1;
                alu_ctrl_o       = alu_op;
            end
            EXECUTEI: begin

            end
            ALUWRITE: begin
                rf_wen_ctrl_o    = 1'b1;
            end
            BEQ: begin
                pc_ctrl_o        = cond;
                pc_en_ctrl_o     = cond;
                data2_alu_ctrl_o = 1'b1;
                alu_ctrl_o       = ALU_SUB;
            end
            JAL: begin
                pc_ctrl_o        = 1'b1;
                pc_en_ctrl_o     = 1'b1;
            end
            JALR: begin
                pc_ctrl_o        = 1'b1;
                pc_jump_ctrl_o   = 1'b1;
                pc_en_ctrl_o     = 1'b1;
            end
            JWRITE: begin
                data_mux_ctrl_o  = 2'b10;
                rf_wen_ctrl_o    = 1'b1;
            end
            default: begin
                pc_ctrl_o        = 1'b0;
                data2_alu_ctrl_o = 1'b0;
                alu_ctrl_o       = ALU_ADD;
                data_mux_ctrl_o  = 2'b00;
                rf_wen_ctrl_o    = 1'b0;
                dmem_we_ctrl_o   = 1'b0;
                pc_jump_ctrl_o   = 1'b0;
                pc_en_ctrl_o     = 1'b0;
                fetch_en_ctrl_o  = 1'b0;
            end
        endcase
    end
    //-------------------------------------------------------------------------
        

endmodule : controller_mc
