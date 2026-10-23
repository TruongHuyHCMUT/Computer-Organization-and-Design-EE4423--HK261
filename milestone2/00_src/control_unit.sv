module control_unit (
    input logic [31:0]  i_instr,
    input logic         i_br_equal,
    input logic         i_br_less,
    // output 
    output logic [3:0]  o_alu_op,
    output logic        o_pc_sel,
    output logic        o_rd_wren,
    output logic        o_br_un,
    output logic [1:0]  o_opa_sel,
    output logic        o_opb_sel,
    output logic        o_mem_wren,
    output logic [3:0]  o_mem_bmsk,
    output logic [1:0]  o_wb_sel,

    output logic        is_valid_instr
);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    
    assign opcode = i_instr[6:0];
    assign funct3 = i_instr[14:12];
    assign funct7 = i_instr[31:25];

    assign is_valid_instr = (opcode == 0000011) |       // Load (LB, LH, LW, LBU, LHU)
                            (opcode == 0010011) |       // OP-IMM (ADDI, SLTI, ANDI...)
                            (opcode == 0010111) |       // AUIPC
                            (opcode == 0100011) |       // Store (SB, SH, SW)
                            (opcode == 0110011) |       // OP-Reg (ADD, SUB, SLL...)
                            (opcode == 0110111) |       // LUI
                            (opcode == 1100011) |       // Branch (BEQ, BNE, BLT...)
                            (opcode == 1100111) |       // JALR
                            (opcode == 1101111);         // JAL
//===============================================
// Instantiate
//================================================
    MainDecode u_maindecode (
        .opcode     (opcode),               // 7-bit
        .funct3     (funct3),               // 3-bit
        .i_br_less  (i_br_less),
        .i_br_equal (i_br_equal),
        // Output
        .o_pc_sel   (o_pc_sel),
        .o_rd_wren  (o_rd_wren),
        .o_br_un    (o_br_un),
        .o_opa_sel  (o_opa_sel),            // 2-bit
        .o_opb_sel  (o_opb_sel),
        .o_mem_wren (o_mem_wren),
        .o_mem_bmsk (o_mem_bmsk),           // 4-bit
        .o_wb_sel   (o_wb_sel)              // 2-bit
    );

    ALUDecoder u_aludecode (
        .opcode     (opcode),               // 7-bit
        .funct3     (funct3),               // 3-bit
        .funct7     (funct7),               // 7-bit
        .alu_op     (o_alu_op)              // 4-bit
    );      
endmodule

module MainDecode (
    input logic [6:0]   opcode,
    input logic [2:0]   funct3,
    input logic         i_br_less, 
    input logic         i_br_equal,

    output logic        o_pc_sel,       // pc signal
    output logic        o_rd_wren,      // regfile signal
    output logic        o_br_un,        // brc signal (signed or unsigned)
    output logic [1:0]  o_opa_sel,      
    output logic        o_opb_sel,
    output logic        o_mem_wren,     // lsu enable signal
    output logic [3:0]  o_mem_bmsk,     // lsu mask signal   
    output logic [1:0]  o_wb_sel
);
//==========================================================================
// One-hot opcode decode 
//==========================================================================
    logic is_rtype;   // 0110011
	logic is_itype;   // 0010011
	logic is_load;    // 0000011
	logic is_store;   // 0100011
	logic is_branch;  // 1100011
	logic is_jal;     // 1101111
	logic is_jalr;    // 1100111
	logic is_lui;     // 0110111
	logic is_auipc;   // 0010111

    assign is_rtype  = (opcode == 7'b0110011);
	assign is_itype  = (opcode == 7'b0010011);
	assign is_load   = (opcode == 7'b0000011);
	assign is_store  = (opcode == 7'b0100011);
	assign is_branch = (opcode == 7'b1100011);
	assign is_jal    = (opcode == 7'b1101111);
	assign is_jalr   = (opcode == 7'b1100111);
	assign is_lui    = (opcode == 7'b0110111);
	assign is_auipc  = (opcode == 7'b0010111);

//==========================================================================
// Control signal generation using simple OR logic
//==========================================================================
    // o_rd_wren: All except STORE and BRANCH write to register
	assign o_rd_wren = is_rtype | is_itype | is_load | is_jal | is_jalr | is_lui | is_auipc;

    // mem_wren: Only STORE writes to memory
	assign o_mem_wren = is_store;

    // opb_sel: Use immediate for all except R-type
	assign o_opb_sel = is_itype | is_load | is_store | is_branch | is_jal | is_jalr | is_lui | is_auipc;

    // o_wb_sel: 00=ALU, 01=MEM, 10=PC+4
	assign o_wb_sel[0] = is_load;                    // bit 0: load uses memory
	assign o_wb_sel[1] = is_jal | is_jalr;           // bit 1: jumps use PC+4

    // o_opa_sel: 00=rs1, 01=PC, 10=zero
	assign o_opa_sel[0] = is_branch | is_jal | is_auipc;    // bit 0: branch/jal/auipc use PC
	assign o_opa_sel[1] = is_lui;                           // bit 1: LUI uses zero
//==========================================================================
// Branch logic - only for BRANCH instructions
//==========================================================================
    always_comb begin
        if (is_branch) begin
            o_br_un = ~(funct3[2:1] == 2'b11);
            case (funct3) 
                3'b000: o_pc_sel = i_br_equal;          // BEQ : take if equal
                3'b001: o_pc_sel = ~i_br_equal;         // BNE: take if not equal
                3'b100: o_pc_sel = i_br_less;           // BLT: take if less than  
                3'b101: o_pc_sel = ~i_br_less;          // BGE: take if greater than or equal 
                3'b110: o_pc_sel = i_br_less;           // BLTU: take if less than (unsigned)
                3'b111: o_pc_sel = ~i_br_less;          // BGEU: take if greater than or equal (unsigned)
                default: o_pc_sel = 1'b0;
            endcase
        end else begin
            // Non-branch: JAL/JALR always jump, others sequential
            o_pc_sel = is_jal | is_jalr;
			o_br_un = 1'b0;  // Don't care for non-branches
        end 
    end 

endmodule

module ALUDecoder (
    input logic [6:0]   opcode,
    input logic [2:0]   funct3,
    input logic [6:0]   funct7,
    output logic [3:0]  alu_op  
);
    always_comb begin
        case (opcode)
            // R-type: Register-register ALU operations
            7'b0110011: begin
                case(funct3) 
                    3'b000: alu_op = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000; // SUB if funct7[5]=1, else ADD
                    3'b001: alu_op = 4'b0010; // SLL  - Shift left logical
                    3'b010: alu_op = 4'b0011; // SLT  - Set less than (signed)
                    3'b011: alu_op = 4'b0100; // SLTU - Set less than unsigned
                    3'b100: alu_op = 4'b0101; // XOR  - Bitwise XOR
                    3'b101: alu_op = (funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // SRA if funct7[5]=1, else SRL
                    3'b110: alu_op = 4'b1000; // OR   - Bitwise OR
                    3'b111: alu_op = 4'b1001; // AND  - Bitwise AND
                    default: alu_op = 4'b1111; // Invalid
                endcase
            end

            // I-type: Immediate ALU operations
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI  - Add immediate
                    3'b010: alu_op = 4'b0011; // SLTI  - Set less than immediate (signed)
                    3'b011: alu_op = 4'b0100; // SLTIU - Set less than immediate unsigned
                    3'b100: alu_op = 4'b0101; // XORI  - XOR immediate
                    3'b110: alu_op = 4'b1000; // ORI   - OR immediate
                    3'b111: alu_op = 4'b1001; // ANDI  - AND immediate
                    3'b001: alu_op = 4'b0010; // SLLI  - Shift left logical immediate
                    3'b101: alu_op = (funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // SRAI if funct7[5]=1, else SRLI
                    default: alu_op = 4'b1111; // Invalid
                endcase
            end
            // Memory operations: Use ALU to compute address (rs1 + immediate)
            7'b0000011: alu_op = 4'b0000; // LOAD:  address = rs1 + imm
            7'b0100011: alu_op = 4'b0000; // STORE: address = rs1 + imm

            // Control flow: Use ALU to compute target address
            7'b1100011: alu_op = 4'b0000; // BRANCH: target = PC + imm (comparison done in BRC)
            7'b1101111: alu_op = 4'b0000; // JAL:    target = PC + imm
            7'b1100111: alu_op = 4'b0000; // JALR:   target = rs1 + imm

            // Upper immediate operations: Use ALU for addition
            7'b0110111: alu_op = 4'b0000; // LUI:   result = 0 + imm (imm already shifted)
            7'b0010111: alu_op = 4'b0000; // AUIPC: result = PC + imm

            default: alu_op = 4'b1111; // NOP/invalid instruction
        endcase 
    end 
endmodule