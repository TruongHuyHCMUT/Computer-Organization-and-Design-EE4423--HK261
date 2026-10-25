`timescale 1ns / 1ps

module tb_milestone2;

  // ---------------------------------------------------------------------------
  // 1. Tham số & Cấu hình mô phỏng
  // ---------------------------------------------------------------------------
  localparam time CLK_PERIOD = 10ns;       // Chu kỳ xung clock 100 MHz
  localparam int  MAX_CYCLES = 2000;       // Giới hạn số chu kỳ tránh lặp vô tận (Watchdog)

  // ---------------------------------------------------------------------------
  // 2. Tín hiệu kết nối DUT (milestone2)
  // ---------------------------------------------------------------------------
  logic clk;
  logic rst_n;
  logic db_valid;

  int cycle_count       = 0;
  int dmem_write_count  = 0;
  int valid_pulse_count = 0;

  // ---------------------------------------------------------------------------
  // 3. Khởi tạo Top-Level DUT
  // ---------------------------------------------------------------------------
  milestone2 dut (
      .i_clk     (clk),
      .rst_n     (rst_n),
      .o_db_valid(db_valid)
  );

  // ---------------------------------------------------------------------------
  // 4. Bộ tạo xung Clock (100 MHz)
  // ---------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // ---------------------------------------------------------------------------
  // 5. Kiểm tra & Assertions giám sát phần cứng
  // ---------------------------------------------------------------------------
  // Cảnh báo nếu địa chỉ PC truy cập IMEM không căn lề Word (4-byte alignment)
  assert property (@(posedge clk) disable iff (!rst_n) (dut.imem_addr[1:0] == 2'b00))
    else $warning("[%0t] [WARNING] imem_addr = 0x%08h không chia hết cho 4!", $time, dut.imem_addr);

  // Báo lỗi nếu tín hiệu o_db_valid rơi vào trạng thái bất định (X hoặc Z) khi hết Reset
  assert property (@(posedge clk) disable iff (!rst_n) !$isunknown(db_valid))
    else $error("[%0t] [ERROR] o_db_valid rơi vào trạng thái bất định (X/Z)!", $time);

  // ---------------------------------------------------------------------------
  // 6. Monitor giám sát luồng lệnh và giao dịch bộ nhớ (Real-time Tracer)
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n) begin
      cycle_count++;

      // In vết thực thi lệnh trên từng chu kỳ (Single-Cycle)
      $display("[%0t] [CYCLE %4d] PC: 0x%08h | Instr: 0x%08h | db_valid: %b",
               $time, cycle_count, dut.imem_addr, dut.imem_data, db_valid);

      // Theo dõi nếu lệnh hiện tại thực hiện GHI xuống Data Memory (DMEM)
      if (dut.core_dmem_wren) begin
        dmem_write_count++;
        $display("   --> [DMEM WRITE #%0d] Addr: 0x%08h | WData: 0x%08h | ByteMask: %b",
                 dmem_write_count, dut.core_dmem_addr, dut.core_dmem_data, dut.core_dmem_bmsk);
      end

      // Theo dõi nếu lệnh hiện tại thực hiện ĐỌC từ Data Memory (DMEM)
      // (Đối với dmem asynchronous read, địa chỉ rơi vào dải hợp lệ 0x8008_0000 -> 0x8008_FFFF)
      if (!dut.core_dmem_wren && (dut.core_dmem_addr[31:16] == 16'h8008)) begin
        $display("   --> [DMEM READ ] Addr: 0x%08h | RData: 0x%08h",
                 dut.core_dmem_addr, dut.dmem_core_data);
      end

      // Ghi nhận số xung debug valid
      if (db_valid) begin
        valid_pulse_count++;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 7. Kịch bản chạy mô phỏng chính
  // ---------------------------------------------------------------------------
  initial begin
    // Khởi tạo trạng thái ban đầu
    rst_n = 1'b0;

    $display("==================================================================");
    $display(">>> KHOI DONG HE THONG: Testbench Top-Level Milestone 2 <<<");
    $display("==================================================================");

    // Kích hoạt Reset tích cực mức thấp (active-low) trong 5 chu kỳ clock
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    $display("[%0t] [SYSTEM RESET RELEASED] Core bat dau thuc thi firmware...", $time);

    // -------------------------------------------------------------------------
    // Vòng lặp chờ mô phỏng hoàn thành hoặc chạm ngưỡng Timeout
    // -------------------------------------------------------------------------
    fork
      // Nhánh 1: Cơ chế Timeout bảo vệ hệ thống tránh treo máy
      begin
        repeat (MAX_CYCLES) @(posedge clk);
        $display("\n[%0t] [TIMEOUT] Mo phong dat gioi han an toan %0d chu ky clock.", $time, MAX_CYCLES);
      end

      // Nhánh 2: Nhận diện điều kiện dừng linh hoạt của chương trình (Tùy chọn)
      begin
        // Ví dụ: Dừng lại khi hệ thống hoàn thành chuỗi lệnh hoặc gặp vòng lặp vô tận (self-loop / ECALL)
        @(posedge clk);
        forever @(posedge clk) begin
          // Nếu PC đứng yên tại 1 vị trí (chương trình hoàn thành và nhảy j .)
          if (dut.imem_addr == 32'h8000_0094) begin
            $display("\n[%0t] [END OF PROGRAM] Da thuc thi het danh sach lenh!", $time);
            break;
          end
        end
      end
    join_any
    disable fork;

    // -------------------------------------------------------------------------
    // 8. Báo cáo kết quả sau mô phỏng
    // -------------------------------------------------------------------------
    repeat (5) @(posedge clk);
    $display("\n==================================================================");
    $display("                     TONG KET KIEM TRA HE THONG                  ");
    $display("==================================================================");
    $display(" - Tong so chu ky da chay : %0d", cycle_count);
    $display(" - Tong so thao tac ghi DMEM: %0d", dmem_write_count);
    $display(" - So xung debug valid    : %0d", valid_pulse_count);
    $display(" - PC cuoi cung           : 0x%08h", dut.imem_addr);
    $display(" - Instruction cuoi cung  : 0x%08h", dut.imem_data);
    $display("==================================================================\n");

    $finish;
  end

endmodule