module singlecyle (
    // Global signal
    input logic         i_clk,
    input logic         i_rstn,
    // Instruction Fetch Interface
    input logic [31:0]  i_imem_rdata,
    output logic [31:0] o_imem_addr,
    // Data Memory Interface
    input logic [31:0]  i_dmem_rdata,
    output logic [31:0] o_dmem_addr,
    output logic [31:0] o_dmem_wdata,
    output logic [3:0]  o_dmem_bmsk,
    output logic        o_dmem_wren,
    // Debug Inteface 
    output logic        o_db_valid
);

//=======================================
// Instruction Fetch (IF) 
//=======================================
    
//=======================================
// Instruction Decode (ID)
//=======================================
    regfile u_regfile (
        .clk        (i_clk),
        .rst_n      (i_rstn),
        .i_rd_wren  (),         // 1-bit
        .i_rd_addr  (),         // 5-bit
        .i_rs1_addr (),         // 5-bit
        .i_rs2_addr (),         // 5-bit
        .i_rd_data  (),         // 32-bit
        // output 
        .o_rs1_data (),         // 32-bit
        .o_rs2_data ()          // 32-bit
    );

    immgen u_immgen (
        .i_instr    (),
        .o_imm_out  ()
    );

//=======================================
// Execute (EX) 
//=======================================
    brc u_brc (
        .i_rs1_data     (),     // 32-bit
        .i_rs2_data     (),     // 32-bit
        .i_br_un        (),     
        .o_br_less      (),
        .o_br_equal     ()
    );

    alu u_alu (
        .i_op_a         (),     // 32-bit     
        .i_op_b         (),     // 32-bit
        .i_alu_op       (),     // 4-bit
        .o_alu_data     ()      // 32-bit
    );
//=======================================
// Memory Access (MEM) 
//=======================================
    lsu u_lsu (
        .i_lsu_wren     (),
        .i_funct3       (),
        .i_lsu_addr     (),
        .i_st_data      (),

        .i_dmem_rdata   (),
        .o_dmem_addr    (),
        .o_dmem_wdata   (),
        .o_dmem_bmsk    (),
        .o_dmem_wren    (),

        .o_ld_data      ()
    );

//=======================================
// Write back to Register (WB) 
//=======================================


//=======================================
// Control Unit 
//=======================================
    control_unit u_fsm (
        //input 
        .i_instr    (),     // 32-bit
        .i_br_equal (),     
        .i_br_less  (),
        //output
        .o_alu_op   (),     // 4-bit
        .o_pc_sel   (),
        .o_rd_wren  (),
        .o_br_un    (),
        .o_opa_sel  (),     // 2-bit
        .o_opb_sel  (),
        .o_mem_wren (),
        .o_mem_bmsk (),     // 4-bit
        .o_wb_sel   ()      // 2-bit
    );

endmodule

