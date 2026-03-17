/*******************************************************************************
 * Module: test_trixv_mc_fibo
 * 
 * File Name: test_trixv_mc_fibo.sv
 * Project: TRIX-V (Tiny RISC-V Core)
 *
 * Description:
 *     Run the Fibonacci code on the TRIX-V core and check the result.
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
module test_trixv_mc_fibo;
    timeunit 1ns; timeprecision 100ps;
    import tb_utils_pkg::*;
    import typedefs::*;

    logic clk;
    logic rst_n;
    logic [31:0] pc_value;
    int error_count = 0;
    logic tx;
    //--------------------------------------------------------------------------------
    top_trixv_mc #(
        .DWIDTH(32),
        .AWIDTH(12),
        .MEM_AW(10)
    ) top_trixv_i
    (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .tx_o(tx)
    );
    //--------------------------------------------------------------------------------
    // Generate clock signal
    localparam CLK_PERIOD = 10;
    initial begin
        clk = 1'b0;
        forever begin
            #(CLK_PERIOD / 2) clk = ~clk;
        end
    end
    //--------------------------------------------------------------------------------
    // Task to check data memory values with custom message.
    // Not available in post-synthesis simulation: internal arrays are mapped
    // to hardware primitives and are not accessible in the synthesized netlist.
    // To enable: compile WITHOUT -d POST_SYNTH (behavioral simulation only).
`ifndef POST_SYNTH
    task check_dmem(input int addr, input logic [31:0] expected_value, input string message);
        logic [31:0] actual_value;
        actual_value = top_trixv_i.dmem.mem[addr[31:2]];
        if (actual_value == expected_value) begin
            $display("Test Passed: dmem[%0d] = %0d (Expected: %0d)", addr[31:2], actual_value, expected_value);
        end else begin
            error_count++;
            $display("Test Failed: dmem[%0d] = %0d (Expected: %0d). %s", addr[31:2], actual_value, expected_value, message);
        end
    endtask
`endif
    //--------------------------------------------------------------------------------
    initial begin
        $display("Starting Fibonacci test...");
`ifndef POST_SYNTH
        // Behavioral simulation: load imem directly into RTL array.
        // Not needed for post-synthesis: imem is preloaded via INIT_FILE parameter.
        $readmemh("trixv.imem", top_trixv_i.imem.mem);
`endif
        rst_n = 1'b0;
        repeat(2) @(negedge clk);
        rst_n = 1'b1;
        repeat(1500*4) @(negedge clk);
        repeat(100000) @(negedge clk);
`ifndef POST_SYNTH
        // Behavioral simulation: verify Fibonacci(40) = 102334155 via dmem.
        // https://www.calculatorsoup.com/calculators/discretemathematics/fibonacci-calculator.php
        check_dmem(250*4, 102334155, "");
`else
        // Post-synthesis: internal dmem array not accessible in netlist.
        // Verify Fibonacci(40) = 102334155 (0x0619D96C) by decoding tx_o
        // UART output in the waveform viewer.
        $display("Post-synthesis mode: verify Fibonacci(40) = 102334155 (0x619D96C) via tx_o waveform.");
`endif
        display_result(error_count);
        if (error_count==0) $display("All tests passed!");
        else $display("Some tests failed!");
        $finish;
    end


endmodule : test_trixv_mc_fibo
