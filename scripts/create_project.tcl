# Get the directory where this script is located
set script_dir [file dirname [file normalize [info script]]]

# Change to script directory
cd $script_dir

# Set project name and location
set project_name "project_1"
set project_dir "./vivado"

# Create project
create_project $project_name $project_dir -part xc7a200tsbg484-1 -force

# Add constraints file to the constraints fileset
add_files -fileset constrs_1 "../constraints/nexys_video.xdc"
set_property target_constrs_file ../constraints/nexys_video.xdc [current_fileset -constrset]

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add source files
add_files -fileset sources_1 [list \
    [file normalize ../src/typedefs.sv] \
    [file normalize ../src/obi_if.sv] \
    [file normalize ../src/adder.sv] \
    [file normalize ../src/alu.sv] \
    [file normalize ../src/muxN.sv] \
    [file normalize ../src/fflop.sv] \
    [file normalize ../src/fflopLD.sv] \
    [file normalize ../src/extend.sv] \
    [file normalize ../src/regfile.sv] \
    [file normalize ../src/memory.sv] \
    [file normalize ../src/controller_mc.sv] \
    [file normalize ../src/datapath_mc.sv] \
    [file normalize ../src/trixv_mc.sv] \
    [file normalize ../src/addr_decoder.sv] \
    [file normalize ../src/fifo.sv] \
    [file normalize ../src/uart_tx.sv] \
    [file normalize ../src/uart_tx_controller.sv] \
    [file normalize ../src/uart_tx_obi.sv] \
    [file normalize ../src/pbus_ctrl.sv] \
    [file normalize ../src/top_trixv_mc.sv] \
    [file normalize ../tb/trixv.imem] \
]

# Add testbench files
add_files -fileset sim_1 [list \
    [file normalize ../../common/tb_utils_pkg.sv] \
    [file normalize ../tb/test_trixv_mc_fibo.sv] \
    [file normalize ../tb/trixv.imem] \
]

set_property file_type {Memory File} [get_files [file normalize ../tb/trixv.imem]]

# Set top module
set_property top top_trixv_mc [get_filesets sources_1]
# test_trixv_mc_fibo is the post-synthesis compatible testbench:
#   - imem is preloaded via INIT_FILE
#   - ifdef POST_SYNTH guards skip internal array checks that don't exist in netlist
set_property top test_trixv_mc_fibo [get_filesets sim_1]

# -------------------------------------------------------------------------
# Post-synthesis functional simulation setup:
# Internal RTL arrays (mem, regs) are replaced by netlist primitives after
# synthesis and cannot be accessed from the testbench.
# To run post-synthesis simulation, define POST_SYNTH before launching:
#
#   In Vivado TCL console (run before launching post-synthesis sim):
#     set_property -name {xsim.compile.xvlog.more_options} \
#                  -value {-d POST_SYNTH} \
#                  -objects [get_filesets sim_1]
#
#   To restore behavioral simulation mode:
#     set_property -name {xsim.compile.xvlog.more_options} \
#                  -value {} \
#                  -objects [get_filesets sim_1]
# -------------------------------------------------------------------------

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

add_files -fileset sim_1 -norecurse  [file normalize ./test_trixv_mc_fibo_wave.wcfg]
set_property xsim.view [file normalize ./test_trixv_mc_fibo_wave.wcfg] [get_filesets sim_1]


puts "Project created successfully!"
