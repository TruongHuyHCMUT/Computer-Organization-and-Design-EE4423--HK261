module imem #(
    parameter logic [31:0]  START_ADDR = 32'h8000_0000,
    parameter int unsigned  ADDR_WIDTH  = 19,
    parameter string        PROGRAMFILE = ""
)(
    input logic         i_clk,
    input logic [31:0]  i_addr,
    output logic [31:0] o_data
);
    localparam int unsigned MEM_DEPTH = 1 << (ADDR_WIDTH - 2);
    logic [31:0] imem [0:MEM_DEPTH-1];

    logic [31:0]    addr_offset;
    assign addr_offset = i_addr - START_ADDR;
    
    logic [ADDR_WIDTH-3:0] word_idx;
    assign word_idx = addr_offset[ADDR_WIDTH-1:2];

    assign o_data = imem[word_idx];
    
    initial begin
        $readmemh(PROGRAMFILE, imem);
    end

endmodule