# TRIX-V-MC — Tiny RISC-V Multi-Cycle Processor (FPGA)

A **32-bit RISC-V RV32I multi-cycle processor** implemented in SystemVerilog and prototyped on the **Digilent Nexys Video** board (Xilinx Artix-7, XC7A200T).
The processor executes a pre-loaded Fibonacci firmware and transmits results over **UART** at 115 200 baud.

---

<figure>
  <img src="20. FPGA 2.jpeg" alt="FPGA Waveform (Improved the image qualiy by Nano Bnana)"  style="width: 50%">
</figure>

## Table of Contents

- [TRIX-V-MC — Tiny RISC-V Multi-Cycle Processor (FPGA)](#trix-v-mc--tiny-risc-v-multi-cycle-processor-fpga)
	- [Table of Contents](#table-of-contents)
	- [Features](#features)
	- [Architecture Overview](#architecture-overview)
		- [CPU Datapath Highlights](#cpu-datapath-highlights)
	- [Directory Structure](#directory-structure)
	- [Hardware Requirements](#hardware-requirements)
	- [Software Requirements](#software-requirements)
	- [Quick Start — Simulation](#quick-start--simulation)
		- [Post-Synthesis Functional Simulation](#post-synthesis-functional-simulation)
	- [Quick Start — FPGA Bitstream](#quick-start--fpga-bitstream)
	- [Connecting and Reading UART Output](#connecting-and-reading-uart-output)
		- [Using the Python decoder (recommended)](#using-the-python-decoder-recommended)
		- [Using CuteCom or VS Code Serial Monitor](#using-cutecom-or-vs-code-serial-monitor)
	- [Firmware (trixv.imem)](#firmware-trixvimem)
	- [Module Reference](#module-reference)
		- [`top_trixv_mc`](#top_trixv_mc)
		- [`uart_tx_obi`](#uart_tx_obi)
		- [`memory`](#memory)
	- [Timing Constraints](#timing-constraints)
	- [Pin Assignments (Nexys Video)](#pin-assignments-nexys-video)
	- [Simulation Modes](#simulation-modes)
	- [| **Post-synthesis** | `test_trixv_mc_fibo.sv` + `POST_SYNTH` define | Skips illegal direct array accesses; works with synthesised netlist |](#-post-synthesis--test_trixv_mc_fibosv--post_synth-define--skips-illegal-direct-array-accesses-works-with-synthesised-netlist-)
	- [License](#license)

---

## Features

- Full **RV32I** instruction set: R, I, S, B, J, U types
- **Multi-cycle FSM controller** with states: FETCH → DECODE → EXECUTE → MEMREAD / MEMWRITE → WRITEBACK
- Separate **instruction memory (IMEM)** and **data memory (DMEM)**, each 1 KB (1024 × 32-bit words)
- IMEM pre-loaded from a `.imem` hex file at synthesis time — no JTAG programming cable needed to load firmware
- **UART transmitter** (115 200 baud, 8N1) connected via an **OBI peripheral bus**
- 32-deep × 8-bit **synchronous FIFO** between CPU and UART to decouple clock domains
- Targeted and validated on **Nexys Video (Artix-7 XC7A200T)** at 100 MHz
- Vivado project auto-generated from a single **TCL script** — no GUI steps required
- Self-checking **SystemVerilog testbench** runnable with the free **Vivado simulator (XSIM)**
- Python helper script `read_fibo.py` to decode raw UART bytes into annotated Fibonacci output

---

## Architecture Overview

```
	top_trixv_mc
	┌───────────────────────────────────────────────────────────┐
	│                                                           │
	│   ┌─────────────────────────────┐                         │
	│   │                             │                         │
	│   │                             │   ┌──────────────────┐  │
	│   │                             │   │     IMEM         │  │
	│   │         trixv_mc            │──►│  memory.sv       │  │
	│   │  ┌───────────┐  ┌────────┐  │   │  (INIT_FILE)     │  │
	│   │  │controller │  │datapath│  │   └──────────────────┘  │
	│   │  │    _mc    │◄─│  _mc   │  │                         |
	│   │  └───────────┘  └────────┘  │   ┌──────────────────┐  │
	│   │                             │   │     DMEM         │  │
	│   │                             │──►│  memory.sv       │  │
	│   │                             │   └──────────────────┘  │
	│   │                             │                         │
	│   └──────────────┬──────────────┘                         │
	│                  │ OBI pbus                               │
	│                  ▼                                        │
	│          ┌───────────────┐                                │
	│          │  addr_decoder │                                │
	│          └───────┬────────┘                               │
	│                  │ sel_uart                               │
	│                  ▼                                        │
	│         ┌──────────────────┐                              │
	│         │   uart_tx_obi    │                              │
	│         │  ┌────────────┐  │                              │
	│         │  │    FIFO    │  │                              │
	│         │  │  (32 × 8)  │  │                              │
	│         │  └─────┬──────┘  │                              │
	│         │  ┌─────▼──────┐  │                              │
	│         │  │ controller │  │                              │
	│         │  └─────┬──────┘  │                              │
	│         │  ┌─────▼──────┐  │                              │
	│         │  │  uart_tx   │  │                              │
	│         │  └────────────┘  │                              │
	│         └────────┬─────────┘                              │
	│                  │ tx_o  (Pmod JA, Pin AB22)              │
	└──────────────────┼────────────────────────────────────────┘
					   ▼
				USB-TTL adapter ──► PC serial terminal
```

### CPU Datapath Highlights

| Stage | Action |
|---|---|
| **FETCH** | PC → IMEM address; latch instruction |
| **DECODE** | Decode opcode/funct3/funct7; read register file; extend immediate |
| **EXECUTE** | ALU operation; compute branch/jump target |
| **MEMREAD / MEMWRITE** | Load/store to DMEM or peripheral bus |
| **WRITEBACK** | Write ALU result, load data, or PC+4 back to register file |

---

## Directory Structure

```
trix-FPGA/
├── constraints/
│   └── nexys_video.xdc       # Pin assignments
├── scripts/
│   ├── Makefile               # Simulation targets: compile / elaborate / simulate / wave
│   ├── create_project.tcl     # Auto-creates Vivado project (run once)
│   ├── filelist.f             # Source file list for XSIM
│   ├── read_fibo.py           # Python UART decoder — prints annotated Fibonacci output
│   ├── run_xvlog.sh           # Optional shell wrapper for xvlog
│   ├── test_trixv_mc_fibo_wave.wcfg   # Waveform config for fibo testbench
│   └── xsim_cfg.tcl           # XSIM TCL batch script
├── src/
│   ├── top_trixv_mc.sv        # Top-level integration module
│   ├── trixv_mc.sv            # RISC-V core (controller + datapath wrapper)
│   ├── controller_mc.sv       # Multi-cycle FSM controller
│   ├── datapath_mc.sv         # Datapath (PC, regfile, ALU, muxes, pipeline regs)
│   ├── memory.sv              # Shared IMEM/DMEM model (supports INIT_FILE preload)
│   ├── regfile.sv             # 32 × 32-bit register file (x0 hardwired to 0)
│   ├── alu.sv                 # 32-bit ALU (add/sub/and/or/xor/slt/sltu/shift)
│   ├── extend.sv              # Immediate sign-extension unit
│   ├── fflop.sv               # D flip-flop with async reset
│   ├── fflopLD.sv             # D flip-flop with load enable and async reset
│   ├── muxN.sv                # Parametric N-input mux
│   ├── adder.sv               # Generic adder
│   ├── addr_decoder.sv        # Peripheral address decoder
│   ├── obi_if.sv              # OBI (Open Bus Interface) SystemVerilog interface
│   ├── pbus_ctrl.sv           # Peripheral bus controller
│   ├── fifo.sv                # Synchronous FIFO (depth/width parametric)
│   ├── uart_tx.sv             # UART transmitter FSM
│   ├── uart_tx_controller.sv  # UART TX FIFO controller (glitch-free tx_start)
│   ├── uart_tx_obi.sv         # Top UART peripheral (OBI + FIFO + controller + TX)
│   └── typedefs.sv            # Shared type definitions (alu_op_t enum, etc.)
├── tb/
│   ├── test_trixv_mc_fibo.sv  # Self-checking testbench — runs Fibonacci firmware
│   ├── trixv.imem             # Fibonacci firmware (RV32I hex, 40 iterations)
│   └── main.c                 # Original C source of the Fibonacci firmware
└── README.md
```

---

## Hardware Requirements

| Item | Details |
|---|---|
| FPGA Board | **Digilent Nexys Video** (Artix-7 XC7A200T-SBG484-1) |
| Serial Adapter | USB-to-TTL 3.3 V cable (e.g. FTDI FT232, CP2102, CH340) |
| Connection | TX pin → Pmod **JA** header, pin **AB22** on the board |
| PC Interface | Any USB port |

> **Note:** The board operates at 3.3 V on the Pmod headers. Do not use a 5 V TTL adapter without a level shifter.

---

## Software Requirements

| Tool | Version | Purpose |
|---|---|---|
| **Vivado** | 2024.1 or newer (tested on 2024.2) | Synthesis, implementation, bitstream, simulation |
| **Python 3** | 3.8+ | `read_fibo.py` UART decoder |
| **pyserial** | any recent | Python UART reader (`pip install pyserial`) |

Vivado must be sourced in your shell:
```bash
source /tools/Xilinx/Vivado/2024.2/settings64.sh
```

On **Linux**, add your user to the `dialout` group to access `/dev/ttyUSB0` without `sudo`:
```bash
sudo usermod -aG dialout $USER
# log out and log back in, then:
sudo systemctl disable --now ModemManager   # prevents port grabs
```

---

## Quick Start — Simulation

```bash
cd scripts/

# Compile + elaborate + simulate (all in one)
make

# Open interactive waveform viewer
make wave

# Clean simulation outputs
make clean
```

A successful run prints:
```
All tests PASSED!
```

### Post-Synthesis Functional Simulation

After running synthesis in Vivado, enable the `POST_SYNTH` compile flag in the Vivado TCL console before launching simulation:
```tcl
set_property -name {xsim.compile.xvlog.more_options} \
						 -value {-d POST_SYNTH} \
						 -objects [get_filesets sim_1]
```
This disables direct register-file and memory array accesses in the testbench that are not available in the synthesised netlist.

---

## Quick Start — FPGA Bitstream

**Step 1 — Create the Vivado project (once only):**
```bash
cd scripts/
vivado -mode batch -source create_project.tcl
```
This creates `scripts/vivado/project_1.xpr`.

**Step 2 — Open the project in Vivado GUI:**
```bash
vivado scripts/vivado/project_1.xpr &
```

**Step 3 — Run implementation and generate bitstream:**
In the Vivado Flow Navigator: *Run Synthesis → Run Implementation → Generate Bitstream*

**Step 4 — Program the board:**
Connect the Nexys Video over USB, then in Vivado: *Open Hardware Manager → Auto Connect → Program Device*

The firmware is embedded in the bitstream via the IMEM `INIT_FILE` parameter — no separate firmware programming step is needed.

---

## Connecting and Reading UART Output

| Setting | Value |
|---|---|
| Port (Linux) | `/dev/ttyUSB0` (or `/dev/ttyUSB1` — check `dmesg`) |
| Baud rate | **115 200** |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Flow control | None |

### Using the Python decoder (recommended)

```bash
cd scripts/
python3 read_fibo.py              # uses /dev/ttyUSB0 at 115200 by default
python3 read_fibo.py /dev/ttyUSB1 115200   # explicit port and baud
```

Example output:
```
 i   raw byte     actual Fib(i)  status
---  --------    -------------  --------------------
1    0x01 (  1)             1    OK
2    0x01 (  1)             1    OK
3    0x02 (  2)             2    OK
...  
13   0xE9 (233)           233    OK
14   0x79 (121)           377    OK (truncated — full value = 377)
```

> **Why truncation?** The UART peripheral only transmits `wdata[7:0]` (LSB of each 32-bit CPU write). Fibonacci values ≤ 255 (F1–F13) are exact; F14 and beyond wrap modulo 256.

### Using CuteCom or VS Code Serial Monitor

Select **ASCII or Decimal** display mode (not HEX) and set 8N1, 115200 baud.

---

## Firmware (trixv.imem)

`tb/trixv.imem` contains the pre-assembled RV32I machine code for the Fibonacci demo.
The original C source is in `tb/main.c`.

The firmware:
1. Initialises stack pointer to the top of data memory (`sp = 1020`)
2. Computes the first **40 Fibonacci numbers** iteratively
3. Writes each result to the UART peripheral address (`0x400`) via a `sw` instruction

---

## Module Reference

### `top_trixv_mc`
Top-level integration module.

| Parameter | Default | Description |
|---|---|---|
| `DWIDTH` | 32 | Data bus width |
| `MEM_AW` | 10 | Memory address width (1 KB = 2¹⁰ words) |
| `AWIDTH` | 12 | Peripheral address width |
| `IMEM_INIT_FILE` | `"trixv.imem"` | Instruction memory initialisation file |

| Port | Direction | Description |
|---|---|---|
| `clk_i` | input | 100 MHz system clock |
| `rst_n_i` | input | Active-low async reset |
| `tx_o` | output | UART serial output |

### `uart_tx_obi`
UART peripheral with OBI interface.

| Parameter | Default | Description |
|---|---|---|
| `WIDTH` | 8 | FIFO data width |
| `DEPTH` | 32 | FIFO depth (entries) |
| `CLK_FREQ` | 100 000 000 | System clock frequency (Hz) |
| `BAUD_RATE` | 115 200 | UART baud rate |

**Register map** (accessed via OBI write to peripheral base address `0x400`):

| Offset | Access | Description |
|---|---|---|
| `0x0` | W | Write byte to TX FIFO |
| `0x0` | R | Read FIFO status: `{30'b0, full, empty}` |

### `memory`
Shared instruction/data memory model.

| Parameter | Default | Description |
|---|---|---|
| `DWIDTH` | 32 | Word width |
| `AWIDTH` | 32 | Address width |
| `INIT_FILE` | `""` | Optional `$readmemh` initialisation file |

Word-aligned, synchronous write, asynchronous (combinational) read. Synthesises as distributed (LUT) RAM.

---

## Timing Constraints

Clock: **100 MHz** (10 ns period).


---

## Pin Assignments (Nexys Video)

| Signal | FPGA Pin | I/O Standard | Description |
|---|---|---|---|
| `clk_i` | R4 | LVCMOS33 | 100 MHz on-board oscillator |
| `rst_n_i` | G4 | LVCMOS15 | CPU RESET button (active low) |
| `tx_o` | AB22 | LVCMOS33 | UART TX → Pmod JA |

---

## Simulation Modes

| Mode | Testbench | Notes |
|---|---|---|
| **Behavioral (fibo)** | `test_trixv_mc_fibo.sv` | Loads firmware via `INIT_FILE`; checks UART TX output |
| **Post-synthesis** | `test_trixv_mc_fibo.sv` + `POST_SYNTH` define | Skips illegal direct array accesses; works with synthesised netlist |
---

## License

Copyright © AICLAB. All rights reserved.

