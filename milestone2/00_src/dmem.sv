// ============================================================================
// Module:        dmem
// Description:   32-bit Data Memory, byte-addressed, Little-Endian
//                - Capacity: 64 KiB (16384 words x 32 bits) with ADDR_WIDTH = 16
//                - Address:  0x8008_0000 -> 0x8008_FFFF (START_ADDR to + 2^ADDR_WIDTH - 1)
//                - Write:    Synchronous with 4-bit byte mask (i_bmsk[3:0])
//                - Read:     Asynchronous (combinational), out-of-range returns 0
// ============================================================================
module dmem #(
    parameter logic [31:0] START_ADDR = 32'h8008_0000,
    parameter int          ADDR_WIDTH = 16
) (
    input logic             i_clk, 
    input logic             i_wren,
    input logic  [3:0]      i_bmsk,
    input logic  [31:0]     i_addr, i_wdata,
    output logic [31:0]     o_rdata
);
    localparam int NUM_WORDS = 1 << (ADDR_WIDTH - 2);
    localparam int WORD_DEPTH = ADDR_WIDTH - 2;

    (* ramstyle = "M10K" *)
    logic [31:0] mem [0: NUM_WORDS - 1];

    logic                       addr_valid;
    logic [WORD_DEPTH - 1:0]    word_idx;

    always_comb begin
        case (i_addr[31:ADDR_WIDTH])
            START_ADDR[31:ADDR_WIDTH]:  addr_valid = 1'b1;
            default:                    addr_valid = 1'b0;
        endcase
    end 
    
    assign word_idx     = i_addr[ADDR_WIDTH-1:2]; 

    always_ff @(posedge i_clk) begin
        if(i_wren && addr_valid) begin
            if (i_bmsk[0]) mem[word_idx][7:0]   <= i_wdata[7:0];
            if (i_bmsk[1]) mem[word_idx][15:8]  <= i_wdata[15:8];
            if (i_bmsk[2]) mem[word_idx][23:16] <= i_wdata[23:16];
            if (i_bmsk[3]) mem[word_idx][31:24] <= i_wdata[31:24];
         end 
    end 

    always_comb begin
        if(addr_valid) begin
            o_rdata = mem[word_idx];
        end else begin
            o_rdata = 32'h0000_0000;
        end 
    end 

endmodule