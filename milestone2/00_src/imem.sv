module imem #(
    parameter logic [31:0]  START_ADDR = 32'h8000_0000,
    parameter int unsigned  ADDR_WIDTH  = 19,
    parameter string        PROGRAMFILE = ""
)(
    input logic         i_clk,
    input logic [31:0]  i_addr,
    output logic [31:0] o_data
);
    localparam int unsigned MEM_DEPTH = (1 << ADDR_WIDTH);
    logic [7:0] mem [0: MEM_DEPTH];

    initial begin
        $readmemh(PROGRAMFILE, mem);
    end
    
    always_comb begin
        o_data[7:0]   = mem[{i_addr[ADDR_WIDTH-1:2], 2'b00}];
        o_data[15:8]  = mem[{i_addr[ADDR_WIDTH-1:2], 2'b01}];
        o_data[23:16] = mem[{i_addr[ADDR_WIDTH-1:2], 2'b10}];
        o_data[31:24] = mem[{i_addr[ADDR_WIDTH-1:2], 2'b11}];
    end 
endmodule