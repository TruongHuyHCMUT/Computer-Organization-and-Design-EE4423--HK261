// ============================================================================
// Module:        regfile
// Description:   32 x 32-bit General Purpose Register File (x0 to x31)
//                - Read Ports:  2 asynchronous (combinational) read ports
//                               (i_rs1_addr -> o_rs1_data, i_rs2_addr -> o_rs2_data)
//                - Write Port:  1 synchronous write port on posedge i_clk
//                               enabled by i_rd_wren to i_rd_addr
//                - Reset:       Asynchronous active-low (i_rstn), clears all registers
//                - Register x0: Hardwired to zero (read returns 0, writes ignored)
// ============================================================================
module regfile (
    input logic         clk, rst_n,
    input logic         i_rd_wren,
    input logic [4:0]   i_rs1_addr, i_rs2_addr,
    input logic [4:0]   i_rd_addr,
    input logic [31:0]  i_rd_data,
    output logic [31:0] o_rs1_data, o_rs2_data
);
    logic [31:0] w_reg [31:0];
    logic [31:0] w_en;
    decoder dec_inst (.A0(i_rd_addr[0]), .A1(i_rd_addr[1]), .A2(i_rd_addr[2]), .A3(i_rd_addr[3]), .A4(i_rd_addr[4]), .En(i_rd_wren), .D(w_en));

    // 32-bit register
    dff_32bit x0 (.clk (clk), .rst_n (rst_n), .en (w_en[0]), .d (32'h0), .q (w_reg[0]));
    dff_32bit x1 (.clk (clk), .rst_n (rst_n), .en (w_en[1]), .d (i_rd_data), .q (w_reg[1]));
    dff_32bit x2 (.clk (clk), .rst_n (rst_n), .en (w_en[2]), .d (i_rd_data), .q (w_reg[2]));
    dff_32bit x3 (.clk (clk), .rst_n (rst_n), .en (w_en[3]), .d (i_rd_data), .q (w_reg[3]));
    dff_32bit x4 (.clk (clk), .rst_n (rst_n), .en (w_en[4]), .d (i_rd_data), .q (w_reg[4]));
    dff_32bit x5 (.clk (clk), .rst_n (rst_n), .en (w_en[5]), .d (i_rd_data), .q (w_reg[5]));
    dff_32bit x6 (.clk (clk), .rst_n (rst_n), .en (w_en[6]), .d (i_rd_data), .q (w_reg[6]));
    dff_32bit x7 (.clk (clk), .rst_n (rst_n), .en (w_en[7]), .d (i_rd_data), .q (w_reg[7]));
    dff_32bit x8 (.clk (clk), .rst_n (rst_n), .en (w_en[8]), .d (i_rd_data), .q (w_reg[8]));
    dff_32bit x9 (.clk (clk), .rst_n (rst_n), .en (w_en[9]), .d (i_rd_data), .q (w_reg[9]));
    dff_32bit x10 (.clk (clk), .rst_n (rst_n), .en (w_en[10]), .d (i_rd_data), .q (w_reg[10]));
    dff_32bit x11 (.clk (clk), .rst_n (rst_n), .en (w_en[11]), .d (i_rd_data), .q (w_reg[11]));
    dff_32bit x12 (.clk (clk), .rst_n (rst_n), .en (w_en[12]), .d (i_rd_data), .q (w_reg[12]));
    dff_32bit x13 (.clk (clk), .rst_n (rst_n), .en (w_en[13]), .d (i_rd_data), .q (w_reg[13]));
    dff_32bit x14 (.clk (clk), .rst_n (rst_n), .en (w_en[14]), .d (i_rd_data), .q (w_reg[14]));
    dff_32bit x15 (.clk (clk), .rst_n (rst_n), .en (w_en[15]), .d (i_rd_data), .q (w_reg[15]));
    dff_32bit x16 (.clk (clk), .rst_n (rst_n), .en (w_en[16]), .d (i_rd_data), .q (w_reg[16]));
    dff_32bit x17 (.clk (clk), .rst_n (rst_n), .en (w_en[17]), .d (i_rd_data), .q (w_reg[17]));
    dff_32bit x18 (.clk (clk), .rst_n (rst_n), .en (w_en[18]), .d (i_rd_data), .q (w_reg[18]));
    dff_32bit x19 (.clk (clk), .rst_n (rst_n), .en (w_en[19]), .d (i_rd_data), .q (w_reg[19]));
    dff_32bit x20 (.clk (clk), .rst_n (rst_n), .en (w_en[20]), .d (i_rd_data), .q (w_reg[20]));
    dff_32bit x21 (.clk (clk), .rst_n (rst_n), .en (w_en[21]), .d (i_rd_data), .q (w_reg[21]));
    dff_32bit x22 (.clk (clk), .rst_n (rst_n), .en (w_en[22]), .d (i_rd_data), .q (w_reg[22]));
    dff_32bit x23 (.clk (clk), .rst_n (rst_n), .en (w_en[23]), .d (i_rd_data), .q (w_reg[23]));
    dff_32bit x24 (.clk (clk), .rst_n (rst_n), .en (w_en[24]), .d (i_rd_data), .q (w_reg[24]));
    dff_32bit x25 (.clk (clk), .rst_n (rst_n), .en (w_en[25]), .d (i_rd_data), .q (w_reg[25]));
    dff_32bit x26 (.clk (clk), .rst_n (rst_n), .en (w_en[26]), .d (i_rd_data), .q (w_reg[26]));
    dff_32bit x27 (.clk (clk), .rst_n (rst_n), .en (w_en[27]), .d (i_rd_data), .q (w_reg[27]));
    dff_32bit x28 (.clk (clk), .rst_n (rst_n), .en (w_en[28]), .d (i_rd_data), .q (w_reg[28]));
    dff_32bit x29 (.clk (clk), .rst_n (rst_n), .en (w_en[29]), .d (i_rd_data), .q (w_reg[29]));
    dff_32bit x30 (.clk (clk), .rst_n (rst_n), .en (w_en[30]), .d (i_rd_data), .q (w_reg[30]));
    dff_32bit x31 (.clk (clk), .rst_n (rst_n), .en (w_en[31]), .d (i_rd_data), .q (w_reg[31]));

    always_comb begin
        case (i_rs1_addr)
            5'd0: o_rs1_data = w_reg[0];
            5'd1: o_rs1_data = w_reg[1];
            5'd2: o_rs1_data = w_reg[2];
            5'd3: o_rs1_data = w_reg[3];
            5'd4: o_rs1_data = w_reg[4];
            5'd5: o_rs1_data = w_reg[5];
            5'd6: o_rs1_data = w_reg[6];
            5'd7: o_rs1_data = w_reg[7];
            5'd8: o_rs1_data = w_reg[8];
            5'd9: o_rs1_data = w_reg[9];
            5'd10: o_rs1_data = w_reg[10];
            5'd11: o_rs1_data = w_reg[11];
            5'd12: o_rs1_data = w_reg[12];
            5'd13: o_rs1_data = w_reg[13];
            5'd14: o_rs1_data = w_reg[14];
            5'd15: o_rs1_data = w_reg[15];
            5'd16: o_rs1_data = w_reg[16];
            5'd17: o_rs1_data = w_reg[17];
            5'd18: o_rs1_data = w_reg[18];
            5'd19: o_rs1_data = w_reg[19];
            5'd20: o_rs1_data = w_reg[20];
            5'd21: o_rs1_data = w_reg[21];
            5'd22: o_rs1_data = w_reg[22];
            5'd23: o_rs1_data = w_reg[23];
            5'd24: o_rs1_data = w_reg[24];
            5'd25: o_rs1_data = w_reg[25];
            5'd26: o_rs1_data = w_reg[26];
            5'd27: o_rs1_data = w_reg[27];
            5'd28: o_rs1_data = w_reg[28];
            5'd29: o_rs1_data = w_reg[29];
            5'd30: o_rs1_data = w_reg[30];
            5'd31: o_rs1_data = w_reg[31];
        endcase
    end

    always_comb begin
        case (i_rs2_addr)
            5'd0: o_rs2_data = w_reg[0];
            5'd1: o_rs2_data = w_reg[1];
            5'd2: o_rs2_data = w_reg[2];
            5'd3: o_rs2_data = w_reg[3];
            5'd4: o_rs2_data = w_reg[4];
            5'd5: o_rs2_data = w_reg[5];
            5'd6: o_rs2_data = w_reg[6];
            5'd7: o_rs2_data = w_reg[7];
            5'd8: o_rs2_data = w_reg[8];
            5'd9: o_rs2_data = w_reg[9];
            5'd10: o_rs2_data = w_reg[10];
            5'd11: o_rs2_data = w_reg[11];
            5'd12: o_rs2_data = w_reg[12];
            5'd13: o_rs2_data = w_reg[13];
            5'd14: o_rs2_data = w_reg[14];
            5'd15: o_rs2_data = w_reg[15];
            5'd16: o_rs2_data = w_reg[16];
            5'd17: o_rs2_data = w_reg[17];
            5'd18: o_rs2_data = w_reg[18];
            5'd19: o_rs2_data = w_reg[19];
            5'd20: o_rs2_data = w_reg[20];
            5'd21: o_rs2_data = w_reg[21];
            5'd22: o_rs2_data = w_reg[22];
            5'd23: o_rs2_data = w_reg[23];
            5'd24: o_rs2_data = w_reg[24];
            5'd25: o_rs2_data = w_reg[25];
            5'd26: o_rs2_data = w_reg[26];
            5'd27: o_rs2_data = w_reg[27];
            5'd28: o_rs2_data = w_reg[28];
            5'd29: o_rs2_data = w_reg[29];
            5'd30: o_rs2_data = w_reg[30];
            5'd31: o_rs2_data = w_reg[31];
        endcase
    end
endmodule