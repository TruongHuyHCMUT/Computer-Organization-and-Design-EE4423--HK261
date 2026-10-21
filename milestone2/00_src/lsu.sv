module lsu (
    input logic         i_clk, i_rst_n,
    input logic         i_lsu_valid, 
    input logic         i_lsu_wren,

    input logic [2:0]   i_funct3,       // Load/Store type (LB/LH/LW/LBU/LHU/SB/SH/SW)
    input logic [31:0]  i_lsu_addr,     // Memory I/O Address
    input logic [31:0]  i_st_data,      // Store Data from CPU

    input logic [31:0]  i_dmem_rdata,   // Load Data from Dmem  
    output logic [31:0] o_dmem_addr,    // Address to Dmem
    output logic [31:0] o_dmem_wdata,   // Load Data to Dmem
    output logic [4:0]  o_dmem_bmsk,    // Byte mask sent to Dmem
    output logic        o_dmem_wren,    // Write Enable sent to Dmem

    output logic [31:0] o_ld_data       // Load Data to CPU
);
    
endmodule