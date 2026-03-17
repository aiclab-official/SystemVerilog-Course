# Directories
SIM_DIR = outputs
CURR_DIR = $(shell pwd)

# Get testbench name from filelist (strips path and .sv extension)
TB_NAME = $(basename $(notdir $(shell grep "test_" filelist.f | grep -v "#" | tail -n1)))

# Tool options
XVLOG_OPTS = --incr --relax -L uvm
XELAB_OPTS = --incr --debug typical --relax --mt 8 -L xil_defaultlib -L uvm -L unisims_ver -L unimacro_ver -L secureip -L xpm

# Targets
.PHONY: all clean compile elaborate simulate wave

all: simulate

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

setup: $(SIM_DIR)
	cp ../tb/trixv.imem .

compile: setup
	@echo "##### COMPILING SystemVerilog #####"
	xvlog $(XVLOG_OPTS) -sv -f filelist.f 2>&1 | tee $(SIM_DIR)/compile.log

elaborate: compile
	@echo "##### ELABORATING #####"
	xelab $(XELAB_OPTS) $(TB_NAME) -snapshot $(TB_NAME)_sim -log $(SIM_DIR)/elaborate.log

simulate: elaborate
	@echo "##### RUNNING SIMULATION #####"
	xsim $(TB_NAME)_sim -tclbatch xsim_cfg.tcl -log $(SIM_DIR)/simulate.log

wave: simulate
	@echo "##### OPENING WAVEFORM #####"
	xsim --gui $(TB_NAME)_sim.wdb -view $(TB_NAME)_wave.wcfg

clean:
	rm -rf $(SIM_DIR)
	rm -f *.jou *.log *.pb *.wdb
	rm -rf xsim.dir
	rm -f trixv.imem
	rm -rf .Xil

# Caution: This target will remove the entire vivado directory. Use with care.
clean-all: clean
	@if [ -d "./vivado" ]; then \
		VIVADO_DIR="$$(realpath ./vivado)"; \
		if [ -z "$$VIVADO_DIR" ] || [ "$$VIVADO_DIR" = "/" ]; then \
			echo "Refusing to remove unsafe vivado path: $$VIVADO_DIR"; \
			exit 1; \
		fi; \
		echo "Removing $$VIVADO_DIR"; \
		rm -rf -- "$$VIVADO_DIR"; \
	else \
		echo "Skipping vivado cleanup (directory not found)"; \
	fi