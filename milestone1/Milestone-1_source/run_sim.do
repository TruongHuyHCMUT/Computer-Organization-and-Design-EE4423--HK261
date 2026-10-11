# ModelSim DO script for Vending Machine Simulation
# Usage:
#   vsim -do run_sim.do

# Create and map work library
vlib work
vmap work work

# Compile SystemVerilog sources
vlog -sv vending_machine.sv tb_vending_machine.sv

# Elaborate top-level testbench
vsim -t 1ps -voptargs="+acc" work.tb_vending_machine

# Add waveforms
add wave -divider "CLK & RESET"
add wave -color "Yellow" /tb_vending_machine/clk
add wave -divider "COIN INPUTS"
add wave -color "Cyan"   /tb_vending_machine/nickle
add wave -color "Blue"   /tb_vending_machine/dime
add wave -color "Magenta" /tb_vending_machine/quarter
add wave -divider "OUTPUTS"
add wave -color "Green"  /tb_vending_machine/soda
add wave -color "Orange" -radix binary /tb_vending_machine/change
add wave -divider "FSM INTERNAL"
add wave -color "White"  /tb_vending_machine/dut/state_q
add wave -color "Gray"   /tb_vending_machine/dut/state_d

# Run simulation
run -all

# Zoom full in GUI
wave zoom full
