/*******************************************************************************
 * Module: controller
 * 
 * File Name: controller.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Controller of TRIX-V
 *     
 *
 *
 * Modification History:
 * Ver   Who      Date        Changes
 * ----  ------   ----------  -----------------------------------------------
 * 1.0   AICLAB   2025-05-05  Initial version
 *
 * Copyright (c) AICLAB. All rights reserved.
 *******************************************************************************/
module uart_tx_controller (
    input  logic        clk_i,
    input  logic        rst_n_i,
    // FIFO interface
    input  logic        fifo_empty_i,
    output logic        fifo_rd_en_o,
    // UART interface
    input  logic        tx_busy_i,
    output logic        tx_start_o
    
);
    timeunit 1ns; timeprecision 100ps;

    typedef enum logic [1:0] {
        IDLE,
        FIFO_RD,
        TX_START,
        WAIT
    } state_t;

    // Preserve FSM nets for post-synthesis ILA probing.
    state_t current_state, next_state;

    // Next state logic
    always_comb begin
        next_state = current_state;
        case(current_state)
            IDLE: begin
                if ((!fifo_empty_i) & (!tx_busy_i)) begin
                    next_state = FIFO_RD;
                end
            end
            FIFO_RD: begin
                next_state = TX_START;
            end
            TX_START: begin
                next_state = WAIT;
            end
            WAIT: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase        
    end

    // State register
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Output logic
    assign fifo_rd_en_o = (current_state == FIFO_RD);
    assign tx_start_o   = (current_state == TX_START);

endmodule : uart_tx_controller