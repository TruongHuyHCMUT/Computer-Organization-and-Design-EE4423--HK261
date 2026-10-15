# ==============================================================================
# Makefile for Register File Simulation
# ==============================================================================

SIM        = iverilog
SIM_FLAGS  = -g2012 -Wall

RTL_SRCS  ?= decoder.sv dff.sv regfile.sv
TB_SRC    ?= tb_regfile.sv

TARGET     = tb_regfile.out
VCD_FILE   = tb_regfile.vcd

.PHONY: all compile sim wave clean

all: sim

compile: $(TARGET)

$(TARGET): $(RTL_SRCS) $(TB_SRC)
	$(SIM) $(SIM_FLAGS) -o $(TARGET) $(RTL_SRCS) $(TB_SRC)

sim: $(TARGET)
	vvp $(TARGET)

wave: $(VCD_FILE)
	gtkwave $(VCD_FILE) &

clean:
	rm -f $(TARGET) $(VCD_FILE) *.log
