module singlecyle (

);

//=======================================
// RegFile 
//=======================================
    regfile u_regfile (
        .clk        (clk),
        .rst_n      (rst_n),
        .i_rd_wren  (),         // 1-bit
        .i_rd_addr  (),         // 5-bit
        .i_rs1_addr (),         // 5-bit
        .i_rs2_addr (),         // 5-bit
        .i_rd_data  (),         // 32-bit
        // output 
        .o_rs1_data (),         // 32-bit
        .o_rs2_data ()          // 32-bit
    );

//=======================================
// ImmGen 
//=======================================
    immgen u_immgen (
        .i_instr    (),
        .o_imm_out  ()
    );
//=======================================
// BRC 
//=======================================
    brc u_brc (
        .i_rs1_data     (),     // 32-bit
        .i_rs2_data     (),     // 32-bit
        .i_br_un        (),     
        .o_br_less      (),
        .o_br_equal     ()
    );
//=======================================
// ALU 
//=======================================
    alu u_alu (
        .i_op_a         (),     // 32-bit     
        .i_op_b         (),     // 32-bit
        .i_alu_op       (),     // 4-bit
        .o_alu_data     ()      // 32-bit
    );
//=======================================
// RegFile 
//=======================================
endmodule

