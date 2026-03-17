# Packages first
../../common/tb_utils_pkg.sv
../src/typedefs.sv

# Interfaces next
../src/obi_if.sv

# RTL files
../src/adder.sv
../src/alu.sv
../src/muxN.sv
../src/fflop.sv
../src/fflopLD.sv
../src/extend.sv
../src/regfile.sv
../src/memory.sv
../src/controller_mc.sv
../src/datapath_mc.sv
../src/trixv_mc.sv
../src/addr_decoder.sv
../src/fifo.sv
../src/uart_tx.sv
../src/uart_tx_controller.sv
../src/uart_tx_obi.sv
../src/pbus_ctrl.sv

# Top level modules
../src/top_trixv_mc.sv

# Testbenches last
../tb/test_trixv_mc_fibo.sv
