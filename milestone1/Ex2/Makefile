SIM        = iverilog
SIM_FLAGS  = -g2012 -Wall

RTL_SRCS  ?= comparator.sv
TB_SRC    ?= tb_comparator.sv

TARGET     = tb_comparator.out
VCD_FILE   = tb_comparator.vcd

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
