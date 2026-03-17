// 1. Interface Definition - obi_if.sv
interface obi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)( input logic clk_i,
   input logic rst_n_i
);
    timeunit 1ns; timeprecision 1ps;
    // Signal declarations
    logic                    req;
    logic                    gnt;
    logic [ADDR_WIDTH-1:0]   addr;
    logic                    we;
    logic [DATA_WIDTH-1:0]   wdata;
    logic [DATA_WIDTH/8-1:0] be;
    logic                    rvalid;
    logic [DATA_WIDTH-1:0]   rdata;

    // Master modport (Initiator)
    modport master (
        input  clk_i, rst_n_i, 
        input  gnt, rvalid, rdata,
        output req, addr, we, wdata, be
    );

    // Slave modport (Target)
    modport slave (
        input  clk_i, rst_n_i, 
        input  req, addr, we, wdata, be,
        output gnt, rvalid, rdata
    );
endinterface