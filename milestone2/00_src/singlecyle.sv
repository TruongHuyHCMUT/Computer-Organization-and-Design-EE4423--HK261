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

// Program counter signal
    logic [31:0]    pc_next, pc_four, pc;

// Control unit signal 
    logic       pc_sel, rd_wren, instr_valid, br_un, opb_sel, mem_wren;
    logic [1:0] opa_sel, wb_sel;
    logic [3:0] mem_bmsk, alu_op;

//  Register file signals
    logic [4:0]     rs1_addr, rs2_addr, rd_addr;
    logic [31:0]    rs1_data, rs2_data;

//  ImmGen
    logic [31:0]    imm;

// ALU signal
    logic [31:0]    operand_a, operand_b;
    logic [31:0]    alu_data;

// BRC signal 
    logic       br_lt, br_eq;

// LSU signal
    logic [2:0]     funct3;
    logic [31:0]    ld_data;

// Write Back signal
    logic [31:0]    wb_data;
    logic           is_valid_instr;
//=======================================
// Instruction Fetch (IF) 
//=======================================
    logic [31:0]    alu_data_jalr;
    logic           is_jalr;

    assign is_jalr = (i_imem_rdata[6:0] == 7'b1100111);
    assign alu_data_jalr = {alu_data[31:1], 1'b0};

    FA_32bit u_adder4 (
        .A      (pc),
        .B      (32'h4),
        .Cin    (1'b0),
        .Sum    (pc_four),
        .Cout   ()
    );

    assign pc_next = (pc_sel == 1'b0) ? pc_four : (is_jalr ? alu_data_jalr : alu_data);

    pc u_pc (
        .i_clk  (i_clk),
        .i_rstn (i_rstn),
        .d      (pc_next),
        .q      (o_imem_addr)
    );
    assign pc = o_imem_addr;
//=======================================
// Instruction Decode (ID)
//=======================================
    assign rs1_addr = i_imem_rdata[19:15];
    assign rs2_addr = i_imem_rdata[24:20];
    assign rd_addr = i_imem_rdata[11:7];

    regfile u_regfile (
        .clk        (i_clk),
        .rst_n      (i_rstn),
        .i_rd_wren  (rd_wren),          // 1-bit
        .i_rd_addr  (rd_addr),          // 5-bit
        .i_rs1_addr (rs1_addr),         // 5-bit
        .i_rs2_addr (rs2_addr),         // 5-bit
        .i_rd_data  (wb_data),          // 32-bit
        // output 
        .o_rs1_data (rs1_data),         // 32-bit
        .o_rs2_data (rs2_data)          // 32-bit
    );

    immgen u_immgen (
        .i_instr    (i_imem_rdata),
        .o_imm_out  (imm)
    );

//=======================================
// Execute (EX) 
//=======================================
    brc u_brc (
        .i_rs1_data     (rs1_data),     // 32-bit
        .i_rs2_data     (rs2_data),     // 32-bit
        .i_br_un        (br_un),     
        .o_br_less      (br_lt),
        .o_br_equal     (br_eq)
    );
    assign operand_a = (opa_sel == 2'b00) ? rs1_data : (opa_sel == 2'b01) ? pc : (opa_sel == 2'b10) ? 32'b0 : 32'b0;       // o_opa_sel: 00=rs1, 01=PC, 10=zero
    assign operand_b = opb_sel ? imm : rs2_data;        // 0 == rs2_data, 1 == Use immediate for all except R-type
    alu u_alu (
        .i_op_a         (operand_a),     // 32-bit     
        .i_op_b         (operand_b),     // 32-bit
        .i_alu_op       (alu_op),       // 4-bit
        .o_alu_data     (alu_data)      // 32-bit
    );
//=======================================
// Memory Access (MEM) 
//=======================================
    assign funct3 = i_imem_rdata[14:12];
    lsu u_lsu (
        .i_lsu_wren     (mem_wren),
        .i_funct3       (funct3),           // 3-bit
        .i_lsu_addr     (alu_data),         // 32-bit
        .i_st_data      (rs2_data),         // 32-bit

        .i_dmem_rdata   (i_dmem_rdata),     // 32-bit
        .o_dmem_addr    (o_dmem_addr),      // 32-bit
        .o_dmem_wdata   (o_dmem_wdata),     // 32-bit
        .o_dmem_bmsk    (o_dmem_bmsk),      // 4-bit
        .o_dmem_wren    (o_dmem_wren),

        .o_ld_data      (ld_data)          // 32-bit
    );

//=======================================
// Write back to Register (WB) 
//=======================================
    // o_wb_sel: 00=ALU, 01=MEM, 10=PC+4
    assign wb_data = (wb_sel == 2'b00) ? alu_data :   // ALU result (R-type, I-type, LUI, AUIPC)
		            (wb_sel == 2'b01) ? ld_data :     // Memory/IO load data
		            (wb_sel == 2'b10) ? pc_four :     // PC+4 (return address for JAL/JALR)
                    32'd0;                            // Default (should not occur)

//=======================================
// Control Unit 
//=======================================
    control_unit u_fsm (
        //input 
        .i_instr    (i_imem_rdata), // 32-bit
        .i_br_equal (br_eq),     
        .i_br_less  (br_lt),
        //output
        .o_alu_op   (alu_op),       // 4-bit
        .o_pc_sel   (pc_sel),
        .o_rd_wren  (rd_wren),
        .o_br_un    (br_un),
        .o_opa_sel  (opa_sel),      // 2-bit
        .o_opb_sel  (opb_sel),
        .o_mem_wren (mem_wren),
        .o_mem_bmsk (mem_bmsk),     // 4-bit
        .o_wb_sel   (wb_sel),        // 2-bit
        
        .is_valid_instr (is_valid_instr)
    );
 
    assign o_db_valid = i_rstn & is_valid_instr;
endmodule

