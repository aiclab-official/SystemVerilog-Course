/*******************************************************************************
 * Module: extend
 * 
 * File Name: extend.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Sign-extended or zero-extended the immediate value
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module extend
(
    input  logic [ 2:0] imm_ctrl_i,
    input  logic [31:0] instr_i,
    output logic [31:0] imm_o
);

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    always_comb
        case (imm_ctrl_i)
            3'b000:  imm_o = {{20{instr_i[31]}} , instr_i[31:20]};                                    // I-type Instruction
            3'b001:  imm_o = {{20{instr_i[31]}} , instr_i[31:25] , instr_i[11:7]};                    // S-type Instruction
            3'b010:  imm_o = {{20{instr_i[31]}} , instr_i[7] , instr_i[30:25] , instr_i[11:8], 1'b0}; // B-type Instruction
            3'b011:  imm_o = {instr_i[31:12], 12'b0};                                                 // U-type Instruction
            3'b100:  imm_o = {{12{instr_i[31]}} , instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}; // J-type Instruction
            default: imm_o = 0;
        endcase

endmodule : extend

