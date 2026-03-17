/*******************************************************************************
 * Module: memory
 * 
 * File Name: memory.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Arithmetic Logic Unit
 *
 *
 * Modification History:
 * Ver   Who    Date        Changes
 * ----  -----  ----------  -----------------------------------------------
 * 1.0   
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module alu
    import typedefs::*; // Import package with alu_op_t
    #(
        parameter WIDTH = 32
    )
    (
        input  logic [WIDTH-1:0] a_i,
        input  logic [WIDTH-1:0] b_i,
        input  alu_op_t          alu_op_i,
        output logic [WIDTH-1:0] result_o,
        output logic             zero_o,
        output logic             less_o      // New output for blt instruction
    );

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;
    
    always_comb
        case (alu_op_i)
            ALU_ADD: result_o = a_i + b_i;
            ALU_SUB: result_o = a_i - b_i;
            ALU_AND: result_o = a_i & b_i;
            ALU_OR:  result_o = a_i | b_i;
            ALU_XOR: result_o = a_i ^ b_i;
            ALU_SLT: result_o = (a_i < b_i) ? 1 : 0; // Set to 1 if a < b
            ALU_SLL: result_o = a_i << b_i[4:0];     // Shift Left  Logical by b_i[4:0]
            ALU_SRL: result_o = a_i >> b_i[4:0];     // Shift Right Logical by b_i[4:0]
            ALU_SRA: result_o = signed'(a_i) >>> signed'(b_i[4:0]);    // Shift Right Arithmetic by b_i[4:0]
            default: result_o = 0;
        endcase

    assign zero_o = (result_o == 0);
    assign less_o = signed'(a_i) < signed'(b_i);    // Signed comparison for blt

endmodule : alu