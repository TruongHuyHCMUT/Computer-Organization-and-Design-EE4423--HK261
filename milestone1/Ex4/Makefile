# ==============================================================================
# Makefile for Exercise 4: ALU Simulation
# ==============================================================================

SIM        = iverilog
SIM_FLAGS  = -g2012 -Wall

RTL_SRCS  ?= FA.sv alu.sv
TB_SRC    ?= tb_alu.sv

TARGET     = tb_alu.out
VCD_FILE   = tb_alu.vcd

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
