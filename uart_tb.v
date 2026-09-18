module uart_tb();
    reg [7:0] data;
    reg clk = 0, enable = 0, Rx_en = 0, ready_clr = 0;
    wire Tx_busy, ready;
    wire [7:0] Rx_data;
    wire loopback;

    uart test_uart(
        .data_in(data), .Tx_en(enable), .clk_50m(clk),
        .Tx(loopback), .Tx_busy(Tx_busy), .Rx(loopback),
        .ready(ready), .ready_clr(ready_clr),
        .Rx_en(Rx_en), .data_out(Rx_data)
    );

    always #10 clk = ~clk;  // 50 MHz

    task send_byte;
        input [7:0] byte;
        begin
            data   = byte;
            enable = 1;
            wait (Tx_busy == 1);
            enable = 0;
            wait (Tx_busy == 0);
            wait (ready == 1);
            $display("Sent: %h  Received: %h  %s",
                     byte, Rx_data,
                     (Rx_data == byte) ? "PASS" : "FAIL");
            ready_clr = 1; #40 ready_clr = 0; #500;
        end
    endtask

    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tb);
        pass_count = 0;
        fail_count = 0;
        Rx_en = 1; #200;
        for (i = 0; i < 256; i = i + 1) begin
            data   = i[7:0];
            enable = 1;
            wait (Tx_busy == 1);
            enable = 0;
            wait (Tx_busy == 0);
            wait (ready == 1);
            if (Rx_data == i[7:0])
                pass_count = pass_count + 1;
            else
                fail_count = fail_count + 1;
            $display("Sent: %h  Received: %h  %s",
                     i[7:0], Rx_data,
                     (Rx_data == i[7:0]) ? "PASS" : "FAIL");
            ready_clr = 1; #40 ready_clr = 0; #500;
        end
        $display("----------------------------------------");
        $display("TOTAL: %0d PASS, %0d FAIL out of 256 bytes", pass_count, fail_count);
        $display("Data integrity: %0d%%", (pass_count * 100) / 256);
        $finish;
    end
endmodule