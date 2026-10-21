# ==============================================================================
# Makefile for Synchronous Data Memory (dmem) Simulation
# ==============================================================================

SIM        = iverilog
SIM_FLAGS  = -g2012 -Wall

RTL_SRCS  ?= dmem.sv
TB_SRC    ?= tb_dmem_sync.sv

TARGET     = tb_dmem_sync.out
VCD_FILE   = tb_dmem_sync.vcd

.PHONY: all compile sim wave clean

all: sim

compile: $(TARGET)

$(TARGET): $(RTL_SRCS) $(TB_SRC)
	$(SIM) $(SIM_FLAGS) -o $(TARGET) $(RTL_SRCS) $(TB_SRC)

sim: $(TARGET)
	vvp $(TARGET)

wave: sim
	gtkwave $(VCD_FILE) &

clean:
	rm -f $(TARGET) $(VCD_FILE) *.log
