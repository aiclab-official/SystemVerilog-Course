// clk:      ___/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾
// rst_n:    __/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// tx_data:  --<DATA>-------------------------------------------------------------
// tx_start: __/‾‾‾‾\_____________________________________________________________
//             ↑
// Start pulse (one clock cycle)
//================================================================================
// tx_busy:  ______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______
//                 ↑                                                      ↑
//               Asserted                                            De-asserted
// tx:       ‾‾‾‾‾‾\_______/‾‾‾\_____/‾‾‾\_____/‾‾‾\_____/‾‾‾\_____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾
//          |      |       | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 |      |      |
//          | Idle | Start |                Data                   | Stop | Idle |

// UART Transmitter FSM Example
module uart_tx #(
    parameter CLK_FREQ = 100_000_000, // 100 MHz clock
    parameter BAUD_RATE = 115200,     // Standard baud rate
    parameter DW = 8                  // Standard data width
)(
    input  logic           clk_i,
    input  logic           rst_n_i,
    input  logic           tx_start,  // Start transmission
    input  logic [DW-1:0]  tx_data,   // Data to transmit
    output logic           tx_busy,   // Transmission in progress
    output logic           tx         // Serial output
);
    timeunit 1ns; timeprecision 1ps;
    // State encoding (one-hot)
    typedef enum logic [3:0] {
        IDLE  = 4'b0001,
        START = 4'b0010,
        DATA  = 4'b0100,
        STOP  = 4'b1000
    } state_t;

    // Preserve key UART TX internals for post-synthesis ILA probing.
    state_t current_state, next_state;
    
    // Baud rate generator
    localparam BAUD_COUNT = CLK_FREQ/BAUD_RATE;
    logic [$clog2(BAUD_COUNT)-1:0] baud_counter;
    logic baud_tick;

    // Bit counter
    logic [$clog2(DW)-1:0] bit_count;
    logic [DW-1:0] tx_shift_reg;

    // Baud rate generator
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            baud_counter <= '0;
        else if (baud_counter == BAUD_COUNT-1)
            baud_counter <= '0;
        else if (current_state != IDLE)
            baud_counter <= baud_counter + 1'b1;
    end

    assign baud_tick = (baud_counter == BAUD_COUNT-1);

    // State register
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Bit counter
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            bit_count <= '0;
        else if (current_state == IDLE)
            bit_count <= '0;
        else if (current_state == DATA && baud_tick)
            bit_count <= bit_count + 1'b1;
    end

    // Shift register
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            tx_shift_reg <= '1;
        else if (current_state == IDLE && tx_start)
            tx_shift_reg <= tx_data;
        else if (current_state == DATA && baud_tick)
            tx_shift_reg <= {1'b1, tx_shift_reg[DW-1:1]};
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE:
                if (tx_start)
                    next_state = START;
            START:
                if (baud_tick)
                    next_state = DATA;
            DATA:
                if (baud_tick && bit_count == DW-1)
                    next_state = STOP;
            STOP:
                if (baud_tick)
                    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Output logic (registered)
    // Drives tx from a flip-flop so it switches cleanly on the clock edge.
    // A combinatorial decode of one-hot current_state causes glitches in
    // post-implementation timing simulation: state bits have different routing
    // delays, so intermediary states (e.g. 4'b0000) briefly decode via
    // default to tx=1, producing a spurious pulse on the serial line.
    // Using next_state here shifts the output one cycle earlier to compensate
    // for the added register stage, preserving BAUD_COUNT-cycle bit widths.
    // In DATA, the next shift-reg value is used when baud_tick is active so
    // the new bit appears at the same cycle as the shift-register update.
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            tx <= 1'b1;
        else case (next_state)
            START:   tx <= 1'b0;
            DATA:    tx <= (current_state == DATA && baud_tick) ? tx_shift_reg[1]  // next bit after shift
                                                                : tx_shift_reg[0]; // current bit
            STOP:    tx <= 1'b1;
            default: tx <= 1'b1;
        endcase
    end

    assign tx_busy = (current_state != IDLE);

endmodule
