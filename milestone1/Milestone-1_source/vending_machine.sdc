# Timing Constraints for vending_machine
create_clock -name i_clk -period 20.000 [get_ports {i_clk}]
derive_clock_uncertainty
