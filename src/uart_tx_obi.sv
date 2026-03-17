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
 /*
        UART_TX_OBI
 +-----------------------+
 |                       |
 |    OBI Interface      |
 |  +-----------------+  |
 |  | bus.addr[3:0]   |  |
 |  | bus.req         |  |
 |  | bus.we          |  |
 |  | bus.wdata[7:0]  |  |
 |  | bus.gnt         |  |
 |  | bus.rvalid      |  |
 |  | bus.rdata[31:0] |  |
 |  +-----------------+  |
 |           |           |
 |           v           |
 |      +---------+      |
 |      |         |      |
 |      |  FIFO   |      |
 |      | (32x8)  |      |
 |      |         |      |
 |      +---------+      |
 |           ^           |
 |           |           |
 |           v           |
 |      +----------+     |
 |      |          |     |
 |      |Controller|     |
 |      |          |     |
 |      +----------+     |
 |           ^           |
 |           |           |
 |           v           |
 |      +---------+      |
 |      |         |      |
 |      | UART TX |      |
 |      |         |      |
 |      +---------+      |
 |           |           |
 |           v           |
 |         tx_o          |
 |                       |
 +-----------------------+
 */
 module uart_tx_obi #(
    parameter WIDTH      = 8,
    parameter DEPTH      = 32,
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 115200
)(
    obi_if.slave  bus,
    input  logic  sel_i,  // Come from the address decoder
    output logic  tx_o    // UART TX output, connected to the outside world
);
    timeunit 1ns; timeprecision 1ps;
    // UART registers
    localparam UART_TX_DATA  = 4'h0;  // Write: TX data, Read: TX FIFO status
    //! Extra registers for control/status of the UART can be added here

    // Internal signals
    // Mark debug critical controller/UART handshake nets so they survive optimization
    // and are easy to find when connecting ILA probes.
    logic       full, empty, wr_en;
    logic [7:0] rdata;
    logic rd_en;
    logic tx_start;
    logic tx_busy;
    logic empty_dbg;

    assign empty_dbg = empty;
    //-----------------------------
    // OBI interface logic
    //-----------------------------
    // Write request
    always_comb begin
        bus.gnt = bus.req && sel_i;
        wr_en = 1'b0;

        if (bus.req && sel_i) begin
            if (bus.we) begin  // Write operation
                case (bus.addr[3:0])
                    UART_TX_DATA: wr_en = !full;
                endcase
            end
        end
    end

    // Read response
    always_ff @(posedge bus.clk_i or negedge bus.rst_n_i) begin
        if (!bus.rst_n_i) begin
            bus.rvalid <= 1'b0;
            bus.rdata  <= '0;
        end else begin
            bus.rvalid <= bus.req && !bus.we && sel_i;
            if (bus.req && !bus.we && sel_i) begin
                case (bus.addr[3:0])
                    UART_TX_DATA: bus.rdata <= {30'b0, full, empty};
                    default:      bus.rdata <= 32'b0;
                endcase
            end
        end
    end

    //-----------------------------
    // TX FIFO
    //-----------------------------
    (* keep_hierarchy = "yes", dont_touch = "yes" *) fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) tx_fifo (
        .clk_i    (bus.clk_i),
        .rst_n_i  (bus.rst_n_i),
        .wdata_i  (bus.wdata[7:0]),
        .wr_en_i  (wr_en),
        .full_o   (full),
        .rdata_o  (rdata),
        .rd_en_i  (rd_en),
        .empty_o  (empty)
    );
    //--------------------------------
    // TX FIFO controller
    //--------------------------------
    // tx_busy is asserted after rising edge of clock.
    // If we and(!tx_busy , !empty) then we will have a glitch in tx_start signal.
    // We added a register to prevent glitch in tx_start signal and remove the combinational loop.
    // Also the FIFO read data is availabe 1 clock cycle after the read request.
    (* keep_hierarchy = "yes", dont_touch = "yes" *) uart_tx_controller uart_tx_controller_ins (
        .clk_i       (bus.clk_i),
        .rst_n_i     (bus.rst_n_i),
        .fifo_empty_i(empty),
        .tx_busy_i   (tx_busy),
        .fifo_rd_en_o(rd_en),
        .tx_start_o  (tx_start)
    );

    //-----------------------------
    // UART TX
    //-----------------------------
    (* keep_hierarchy = "yes", dont_touch = "yes" *) uart_tx #(
    .CLK_FREQ    (CLK_FREQ),
    .BAUD_RATE   (BAUD_RATE),
    .DW          (WIDTH)
    ) uart_tx_ins (
        .clk_i   (bus.clk_i),
        .rst_n_i (bus.rst_n_i),
        .tx_start(tx_start),
        .tx_data (rdata),
        .tx_busy (tx_busy),
        .tx      (tx_o)
    );



endmodule