// Address map parameters
module addr_decoder #(
    parameter DMEM_START = 12'h000,  // Data memory
    parameter DMEM_END   = 12'h3FF,
    parameter UART_START = 12'h400,  // UART registers
    parameter UART_END   = 12'h40F
)(
    input  logic [11:0] addr,
    output logic        sel_dmem,
    output logic        sel_uart
);
    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    assign sel_dmem = (addr >= DMEM_START) && (addr <= DMEM_END);
    assign sel_uart = (addr >= UART_START) && (addr <= UART_END);

endmodule