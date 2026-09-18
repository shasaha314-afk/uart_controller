module receiver(
    input  wire       Rx,
    input  wire       Rx_en,
    output reg        ready,
    input  wire       ready_clr,
    input  wire       clk_50m,
    input  wire       clken,
    output reg  [7:0] data
);
    initial begin
        ready = 1'b0;
        data  = 8'h00;
    end

    parameter RX_STATE_IDLE  = 2'b00;
    parameter RX_STATE_START = 2'b01;
    parameter RX_STATE_DATA  = 2'b10;
    parameter RX_STATE_STOP  = 2'b11;

    reg [1:0] state   = RX_STATE_IDLE;
    reg [3:0] sample  = 4'd0;   // counts Rxclk_en pulses (0-15 = one bit period)
    reg [3:0] bit_pos = 4'd0;
    reg [7:0] scratch = 8'd0;

    always @(posedge clk_50m) begin

        // ready_clr is synchronous, checked every cycle
        if (ready_clr)
            ready <= 1'b0;

        if (clken && Rx_en) begin
            case (state)

                // Wait in IDLE until line goes low (start bit)
                RX_STATE_IDLE: begin
                    if (!Rx) begin
                        state  <= RX_STATE_START;
                        sample <= 4'd0;
                    end
                end

                // Confirm start bit: wait 8 Rxclk pulses to reach midpoint
                RX_STATE_START: begin
                    if (sample == 4'd7) begin
                        // We are now at the midpoint of the start bit
                        if (!Rx) begin
                            // Valid start bit confirmed
                            state   <= RX_STATE_DATA;
                            sample  <= 4'd0;
                            bit_pos <= 4'd0;
                            scratch <= 8'd0;
                        end else begin
                            // False start (glitch), go back to idle
                            state  <= RX_STATE_IDLE;
                            sample <= 4'd0;
                        end
                    end else begin
                        sample <= sample + 1'b1;
                    end
                end

                // Sample each data bit at its midpoint (every 16 Rxclk pulses)
                RX_STATE_DATA: begin
                    if (sample == 4'd15) begin
                        // Midpoint of this data bit
                        scratch[bit_pos[2:0]] <= Rx;
                        sample  <= 4'd0;
                        bit_pos <= bit_pos + 1'b1;
                        if (bit_pos == 4'd7)
                            state <= RX_STATE_STOP;
                    end else begin
                        sample <= sample + 1'b1;
                    end
                end

                // Wait to midpoint of stop bit, verify it's high, output data
                RX_STATE_STOP: begin
                    if (sample == 4'd15) begin
                        if (Rx) begin
                            data  <= scratch;
                            ready <= 1'b1;
                        end
                        state  <= RX_STATE_IDLE;
                        sample <= 4'd0;
                    end else begin
                        sample <= sample + 1'b1;
                    end
                end

                default: state <= RX_STATE_IDLE;
            endcase
        end
    end
endmodule