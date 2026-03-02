# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
# picosoc.v must be before picorv32.v (macro order)
PROJECT_SOURCES = picosoc.v picorv32.v spimemio.v simpleuart.v spiflash.v tt_um_picosoc.v

FIRMWARE_DIR := $(PWD)/firmware

# Use an existing firmware image. We assume firmware/firmware.hex is already
# present and do not rebuild it during normal simulation.
PLUSARGS += +firmware=$(FIRMWARE_DIR)/firmware.hex

# Ensure 'sim' (defined by cocotb Makefile.sim) is the default target.
.DEFAULT_GOAL := sim

$(FIRMWARE_DIR)/firmware.hex:
	$(MAKE) -C $(FIRMWARE_DIR) firmware.hex

ifneq ($(GATES),yes)

# RTL simulation:
# Use a separate build directory to avoid permission issues with any
# previously-generated sim_build owned by root.
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
# 64B SRAM behavioral model (for simulation only; synthesis uses blackbox)
VERILOG_SOURCES += $(SRC_DIR)/macros/sky130_sram_1rw_tiny.v

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test
MODULE ?= $(COCOTB_TEST_MODULES)
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
