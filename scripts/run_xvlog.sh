#!/bin/bash
# Vivado Simulator scripted flow Part:
# https://www.itsembedded.com/dhd/vivado_sim_1/

# Make executable
# chmod +x run_sim.sh

# Create simulation directory
SIM_DIR="outputs"
mkdir -p $SIM_DIR

CURR_DIR=$(pwd)

cp ../tb/trixv.imem .

# set xvlog options
xvlog_opts="--incr --relax  -L uvm"
xelab_opts="--incr --debug typical --relax --mt 8  -L xil_defaultlib -L uvm -L unisims_ver -L unimacro_ver -L secureip -L xpm"

# Compile
echo "##### COMPILING SystemVerilog #####"
xvlog $xvlog_opts -sv -f filelist.f 2>&1 | tee $SIM_DIR/compile.log

# Elaborate (-debug typical enables debugging)
echo "##### ELABORATING #####"
xelab $xelab_opts test_trixv_sc_fibo -snapshot test_trixv_sc_fibo_sim -log $SIM_DIR/elaborate.log

# Simulate
echo "##### RUNNING SIMULATION #####"
xsim test_trixv_sc_fibo_sim -tclbatch xsim_cfg.tcl -log $SIM_DIR/simulate.log
echo
echo "##### OPENING WAVEFORM #####"
# xsim --gui test_trixv_sc_fibo_sim.wdb -view test_trixv_sc_fibo_sim.wcfg

exit 0
