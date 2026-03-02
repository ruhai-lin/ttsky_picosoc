`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // --- Flash interface extracted from TT wrapper pin mapping ---
  wire flash_csb    = uo_out[1];
  wire flash_clk_o  = uo_out[2];
  wire flash_io0_oe = uo_out[3];
  wire flash_io1_oe = uo_out[4];
  wire flash_io2_oe = uo_out[5];
  wire flash_io3_oe = uo_out[6];
  wire flash_io0_do = uo_out[7];
  wire flash_io1_do = uio_out[0];
  wire flash_io2_do = uio_out[1];
  wire flash_io3_do = uio_out[2];

  wire flash_io0 = flash_io0_oe ? flash_io0_do : 1'bz;
  wire flash_io1 = flash_io1_oe ? flash_io1_do : 1'bz;
  wire flash_io2 = flash_io2_oe ? flash_io2_do : 1'bz;
  wire flash_io3 = flash_io3_oe ? flash_io3_do : 1'bz;

  // --- UART RX line fed to DUT ---
  reg ser_rx_reg;
  initial ser_rx_reg = 1'b1;

  wire [7:0] ui_in = {3'b000, flash_io3, flash_io2, flash_io1, flash_io0, ser_rx_reg};
  wire ser_tx_out = uo_out[0];

  // --- Auto UART sender (pure Verilog, no VPI dependency) ---
  //
  // After SEND_DELAY clock cycles post-reset, sends the byte SEND_BYTE
  // over ser_rx_reg using UART timing matching firmware clkdiv=104.
  //
  // cocotb controls SEND_DELAY and SEND_BYTE via register writes.

  localparam UART_BIT_CLKS = 106;
  localparam SEND_DELAY    = 250_000;
  localparam SEND_BYTE     = 8'h0D;   // '\r'

  reg [31:0] send_wait_cnt;
  reg  [3:0] send_phase;     // 0=wait, 1=start, 2..9=data, 10=stop, 11=done
  reg [31:0] send_bit_cnt;
  reg        send_done;

  initial begin
    send_wait_cnt = 0;
    send_phase    = 0;
    send_bit_cnt  = 0;
    send_done     = 0;
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      ser_rx_reg    <= 1;
      send_wait_cnt <= 0;
      send_phase    <= 0;
      send_bit_cnt  <= 0;
      send_done     <= 0;
    end else if (!send_done) begin
      case (send_phase)
        4'd0: begin // WAIT
          send_wait_cnt <= send_wait_cnt + 1;
          if (send_wait_cnt == SEND_DELAY - 1) begin
            ser_rx_reg <= 0; // start bit
            send_bit_cnt <= 0;
            send_phase <= 4'd1;
          end
        end
        4'd1: begin // START BIT
          if (send_bit_cnt == UART_BIT_CLKS - 1) begin
            ser_rx_reg <= SEND_BYTE[0];
            send_bit_cnt <= 0;
            send_phase <= 4'd2;
          end else
            send_bit_cnt <= send_bit_cnt + 1;
        end
        4'd2:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[1]; send_bit_cnt<=0; send_phase<=4'd3;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd3:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[2]; send_bit_cnt<=0; send_phase<=4'd4;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd4:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[3]; send_bit_cnt<=0; send_phase<=4'd5;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd5:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[4]; send_bit_cnt<=0; send_phase<=4'd6;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd6:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[5]; send_bit_cnt<=0; send_phase<=4'd7;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd7:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[6]; send_bit_cnt<=0; send_phase<=4'd8;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd8:  begin if (send_bit_cnt==UART_BIT_CLKS-1) begin ser_rx_reg<=SEND_BYTE[7]; send_bit_cnt<=0; send_phase<=4'd9;  end else send_bit_cnt<=send_bit_cnt+1; end
        4'd9: begin // LAST DATA BIT done → STOP
          if (send_bit_cnt == UART_BIT_CLKS - 1) begin
            ser_rx_reg <= 1; // stop bit
            send_bit_cnt <= 0;
            send_phase <= 4'd10;
          end else
            send_bit_cnt <= send_bit_cnt + 1;
        end
        4'd10: begin // STOP BIT
          if (send_bit_cnt == UART_BIT_CLKS - 1) begin
            send_done <= 1;
            send_phase <= 4'd11;
          end else
            send_bit_cnt <= send_bit_cnt + 1;
        end
        default: ; // DONE
      endcase
    end
  end

  // --- SPI Flash model ---
  spiflash spiflash (
    .csb(flash_csb),
    .clk(flash_clk_o),
    .io0(flash_io0),
    .io1(flash_io1),
    .io2(flash_io2),
    .io3(flash_io3)
  );

  // --- UART decoder (prints received characters via $display) ---
  localparam UART_HALF_BIT = 53;
  reg [7:0] uart_buf;

  always begin
    @(negedge ser_tx_out);
    repeat (UART_HALF_BIT) @(posedge clk);

    repeat (8) begin
      repeat (UART_HALF_BIT) @(posedge clk);
      repeat (UART_HALF_BIT) @(posedge clk);
      uart_buf = {ser_tx_out, uart_buf[7:1]};
    end

    repeat (UART_HALF_BIT) @(posedge clk);
    repeat (UART_HALF_BIT) @(posedge clk);

    if (uart_buf == 13)
      $write("\n");
    else if (uart_buf == 10)
      ;
    else if (uart_buf < 32 || uart_buf >= 127)
      $write("<%0d>", uart_buf);
    else
      $write("%c", uart_buf);
  end

  // --- DUT ---
  tt_um_picosoc tt_um_picosoc_inst (
`ifdef GL_TEST
    .VPWR(VPWR),
    .VGND(VGND),
`endif
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
  );

endmodule
