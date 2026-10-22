module lsu (
    input logic         i_lsu_wren,

    input logic [2:0]   i_funct3,       // Load/Store type (LB/LH/LW/LBU/LHU/SB/SH/SW)
    input logic [31:0]  i_lsu_addr,     // Memory I/O Address
    input logic [31:0]  i_st_data,      // Store Data from CPU

    input logic [31:0]  i_dmem_rdata,   // Load Data from Dmem  
    output logic [31:0] o_dmem_addr,    // Address to Dmem
    output logic [31:0] o_dmem_wdata,   // Load Data to Dmem
    output logic [3:0]  o_dmem_bmsk,    // Byte mask sent to Dmem
    output logic        o_dmem_wren,    // Write Enable sent to Dmem

    output logic [31:0] o_ld_data       // Load Data to CPU
);
//============================================================================
// Misalignment Detection
//============================================================================
    logic           misaligned_flag;
    always_comb begin
        misaligned_flag = 1'b0;
        case (i_funct3)
            3'b001, 3'b101: misaligned_flag = i_lsu_addr[0];        // SH/LH: misaligned if addr[0] != 0
            3'b010:         misaligned_flag = |i_lsu_addr[1:0];     // SW/LW: misaligned if addr[1:0] != 00
            default:        misaligned_flag = 1'b0;                 // SB/LB: never misaligned
        endcase
    end
//============================================================================
// Store Data Processing
//============================================================================
    always_comb begin
        o_dmem_bmsk = 4'b0000;
        o_dmem_wdata = 32'h0;

        if ( i_lsu_wren && !misaligned_flag) begin
            case (i_funct3) 
                3'b000: begin       // SB - Store byte
                    case (i_lsu_addr[1:0])
                        2'b00: o_dmem_bmsk = 4'b0001;  // Byte 0 (bits [7:0])
                        2'b01: o_dmem_bmsk = 4'b0010;  // Byte 1 (bits [15:8])
                        2'b10: o_dmem_bmsk = 4'b0100;  // Byte 2 (bits [23:16])
                        2'b11: o_dmem_bmsk = 4'b1000;  // Byte 3 (bits [31:24])
                    endcase
                    o_dmem_wdata = {4{i_st_data[7:0]}};
                end 

                3'b001: begin       // SH - Store halfword (must be 2-byte aligned)
                    if (!i_lsu_addr[0]) begin
                        case (i_lsu_addr[1])
                            1'b0: o_dmem_bmsk = 4'b0011;  // Halfword 0 (bits [15:0])
                            1'b1: o_dmem_bmsk = 4'b1100;  // Halfword 1 (bits [31:16])
                        endcase 
                    end
                    o_dmem_wdata = {2{i_st_data[15:0]}};
                end 

                3'b010: begin       // SW - Store word (must be 4-byte aligned)
                    if(i_lsu_addr[1:0] == 2'b00) begin 
                        o_dmem_bmsk = 4'b1111;
                        o_dmem_wdata = i_st_data;
                    end 
                end
                
                default: o_dmem_bmsk = 4'b0000;  // Invalid funct3
            endcase 
        end 
    end 

//============================================================================
// Load Data Processing 
//============================================================================
    logic [7:0]     selected_data_byte;
    logic [15:0]    selected_data_half;
    logic [31:0]    extend_data_byte;
    logic [31:0]    extend_data_half;
    logic           is_unsigned;

    always_comb begin
        case (i_lsu_addr[1:0])
            2'b00: selected_data_byte = i_dmem_rdata[7:0];
            2'b01: selected_data_byte = i_dmem_rdata[15:8];
            2'b10: selected_data_byte = i_dmem_rdata[23:16];
            2'b11: selected_data_byte = i_dmem_rdata[31:24];
        endcase 
    end 

    always_comb begin 
        case (i_lsu_addr[1])
            1'b0: selected_data_half = i_dmem_rdata[15:0];
            1'b1: selected_data_half = i_dmem_rdata[31:16];
        endcase  
    end

    assign is_unsigned = (i_funct3 == 3'b100) | (i_funct3 == 3'b101);  // LBU or LHU
    assign extend_data_byte = is_unsigned ? {24'b0, selected_data_byte} : {{24{selected_data_byte[7]}}, selected_data_byte};
    assign extend_data_half = is_unsigned ? {16'b0, selected_data_half} : {{16{selected_data_half[15]}}, selected_data_half};

    always_comb begin
        if (misaligned_flag) begin
            o_ld_data = 32'h0;
        end else begin 
            case (i_funct3[1:0])
                2'b00: o_ld_data = extend_data_byte;    // LB, LBU
                2'b01: o_ld_data = extend_data_half;    // LH, LHU
                2'b10: o_ld_data = i_dmem_rdata;        // LW
                default: o_ld_data = 32'h0;
            endcase
        end 
    end 

    assign o_dmem_addr = i_lsu_addr;
    assign o_dmem_wren = i_lsu_wren && !misaligned_flag;
endmodule