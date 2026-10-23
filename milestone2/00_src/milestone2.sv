module milestone2 (
    input logic     i_clk, rst_n
);


    imem #(
        .START_ADDR (32'h8000_0000),
        .ADDR_WIDTH (19),
        .PROGRAMFILE("")
    ) u_imem (
        .i_clk      (i_clk),
        .i_addr     (),         // 32-bit
        .o_data     ()          // 32-bit
    );


    singlecyle u_riscv (
        // Global signal
        .i_clk          (i_clk),
        .i_rstn         (rst_n),
        // Instruction Fetch Interface
        .i_imem_rdata   (),
        .o_imem_addr    (),
        // Data Memory Interface
        .i_dmem_rdata   (),
        .o_dmem_addr    (),
        .o_dmem_wdata   (),
        .o_dmem_bmsk    (),
        .o_dmem_wren    (),
        // Debug Inteface 
        .o_db_valid     ()
    );

    dmem #(
        .START_ADDR (32'h8008_0000),
        .ADDR_WIDTH (16)
    ) u_dmem (
        .i_clk      (i_clk),
        .i_wren     (rst_n),
        .i_bmsk     (),         // 4-bit
        .i_addr     (),         // 32-bit
        .i_wdata    (),         // 32-bit
        .o_rdata    ()          // 32-bit
    );

endmodule
