/*******************************************************************************
 * Module: pbus_ctrl
 * 
 * Description:
 *     Peripheral bus controller for TRIX-V processor
 *     Routes peripheral accesses and manages bus control signals
 *******************************************************************************/
 module pbus_ctrl #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 12
)(
    // Processor side interface
    input  logic [AWIDTH-1:0] dmem_addr_i,
    input  logic [DWIDTH-1:0] dmem_wdata_i,
    input  logic              sel_uart_i,
    input  logic              dmem_we_i,

    // Peripheral bus interface
    obi_if.master      pbus
);

    // Time scale and precision
    timeunit 1ns; timeprecision 100ps;

    // Route peripheral accesses
    always_comb begin
        pbus.addr  = dmem_addr_i;
        pbus.wdata = dmem_wdata_i;
        if (sel_uart_i & dmem_we_i) begin     //! It must be enabled only for one clock cycle
            pbus.req   = 1'b1;
            pbus.we    = 1'b1;
            pbus.be    = 4'b1111;
        end else begin
            pbus.req   = 1'b0;
            pbus.we    = 1'b0;
            pbus.be    = 4'b1111;
        end
    end

endmodule