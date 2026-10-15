# ==============================================================================
# Makefile for SystemVerilog Simulation
# ==============================================================================

# Simulator and Compiler Settings (Icarus Verilog)
SIM        = iverilog
SIM_FLAGS  = -g2012 -Wall

# Source Files
# Lưu ý: Gom tất cả các module RTL vào RTL_SRCS (hoặc đổi tên file phù hợp)
RTL_SRCS  ?= adder.sv
TB_SRC    ?= tb_adder.sv

# Output Files
TARGET     = tb_adder.out
VCD_FILE   = tb_adder.vcd

.PHONY: all compile sim wave clean help

# Targets
all: sim

# Bien dich
compile: $(TARGET)

$(TARGET): $(RTL_SRCS) $(TB_SRC)
	$(SIM) $(SIM_FLAGS) -o $(TARGET) $(RTL_SRCS) $(TB_SRC)

# Chay mo phong
sim: $(TARGET)
	vvp $(TARGET)

# Mo dang song (GTKWave)
wave: $(VCD_FILE)
	gtkwave $(VCD_FILE) &

# Dondep file rác / output
clean:
	rm -f $(TARGET) $(VCD_FILE) *.log

help:
	@echo "Huong dan su dung Makefile:"
	@echo "  make         : Bien dich va chay mo phong"
	@echo "  make compile : Chi bien dich mã nguon"
	@echo "  make sim     : Chay file mo phong"
	@echo "  make wave    : Mo GTKWave xem dang song (VCD)"
	@echo "  make clean   : Xoa cac file rác phat sinh"
