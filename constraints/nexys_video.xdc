#==============================================================================
# XDC Constraints File
# Author: AICLAB
# Board: Nexys Video (Artix-7 XC7A200T)
# Description: Pin assignments and timing constraints
#==============================================================================
## Clock Signal
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports clk_i]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_i]

## UART TX output pin assignment: Pmod header JA
set_property -dict {PACKAGE_PIN AB22 IOSTANDARD LVCMOS33} [get_ports tx_o]
set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS33} [get_ports tx_o_watch]

## Reset Button (active low)
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS15} [get_ports rst_n_i]


## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

#==============================================================================
# Multicycle Path Constraints
#==============================================================================
# The design is multi-cycle (FSM states: FETCH→DECODE→JALR/BEQ/JAL).
# Paths from the instruction fetch register (written in FETCH) to the PC
# register (written 2 cycles later in JALR/BEQ/JAL) are 2-cycle paths.
# Without this, Vivado incorrectly requires these to meet a 1-cycle (10 ns)
# setup check, causing false violations.
set_multicycle_path -setup -from [get_cells {trixv_mc_inst/dp/fetch_1/q_reg[*]}] -to [get_cells {trixv_mc_inst/dp/pc_ff/q_reg[*]}] 2
set_multicycle_path -hold -from [get_cells {trixv_mc_inst/dp/fetch_1/q_reg[*]}] -to [get_cells {trixv_mc_inst/dp/pc_ff/q_reg[*]}] 1



