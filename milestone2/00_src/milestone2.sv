module milestone2 (
    input logic     i_clk, rst_n
);
// IMEM Signal
    logic [31:0]    imem_addr, imem_data;
// DMEM Signal
    logic [31:0]    core_dmem_addr, core_dmem_data, dmem_core_data;
    logic [3:0]     core_dmem_bmsk;
    logic           core_dmem_wren;

    imem #(
        .START_ADDR (32'h8000_0000),
        .ADDR_WIDTH (19),
        .PROGRAMFILE("")
    ) u_imem (
        .i_clk      (i_clk),
        .i_addr     (imem_addr),         // 32-bit
        .o_data     (imem_data)          // 32-bit
    );

    singlecyle u_riscv (
        // Global signal
        .i_clk          (i_clk),
        .i_rstn         (rst_n),
        // Instruction Fetch Interface
        .i_imem_rdata   (imem_data),
        .o_imem_addr    (imem_addr),
        // Data Memory Interface
        .i_dmem_rdata   (dmem_core_data),
        .o_dmem_addr    (core_dmem_addr),
        .o_dmem_wdata   (core_dmem_data),
        .o_dmem_bmsk    (core_dmem_bmsk),
        .o_dmem_wren    (core_dmem_wren),
        // Debug Inteface 
        .o_db_valid     ()
    );

    dmem #(
        .START_ADDR (32'h8008_0000),
        .ADDR_WIDTH (16)
    ) u_dmem (
        .i_clk      (i_clk),
        .i_wren     (core_dmem_wren),
        .i_bmsk     (core_dmem_bmsk),         // 4-bit
        .i_addr     (core_dmem_addr),         // 32-bit
        .i_wdata    (core_dmem_data),         // 32-bit
        .o_rdata    (dmem_core_data)          // 32-bit
    );

endmodule
