# ==============================================================================
# Makefile for Exercise 3: Shifter Simulation
# ==============================================================================

SIM        = iverilog
SIM_FLAGS  = -g2012 -Wall

RTL_SRCS  ?= shifter.sv
TB_SRC    ?= tb_shifter.sv

TARGET     = tb_shifter.out
VCD_FILE   = tb_shifter.vcd

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
