module transmitter(
    input  wire [7:0] data_in,
    input  wire       Tx_en,
    input  wire       clk_50m,
    input  wire       clken,
    output reg        Tx,
    output wire       Tx_busy
);
    initial Tx = 1'b1;

    parameter TX_STATE_IDLE  = 2'b00;
    parameter TX_STATE_START = 2'b01;
    parameter TX_STATE_DATA  = 2'b10;
    parameter TX_STATE_STOP  = 2'b11;

    reg [7:0] data    = 8'h00;
    reg [2:0] bit_pos = 3'h0;
    reg [1:0] state   = TX_STATE_IDLE;

    always @(posedge clk_50m) begin
        case (state)
            TX_STATE_IDLE: begin
                Tx <= 1'b1;
                if (Tx_en) begin
                    state   <= TX_STATE_START;
                    data    <= data_in;
                    bit_pos <= 3'h0;
                end
            end

            TX_STATE_START: begin
                if (clken) begin
                    Tx    <= 1'b0;   // start bit
                    state <= TX_STATE_DATA;
                end
            end

            TX_STATE_DATA: begin
                if (clken) begin
                    Tx      <= data[bit_pos];
                    bit_pos <= bit_pos + 1'b1;
                    if (bit_pos == 3'h7)
                        state <= TX_STATE_STOP;
                end
            end

            TX_STATE_STOP: begin
                if (clken) begin
                    Tx    <= 1'b1;   // stop bit
                    state <= TX_STATE_IDLE;
                end
            end

            default: begin
                Tx    <= 1'b1;
                state <= TX_STATE_IDLE;
            end
        endcase
    end

    assign Tx_busy = (state != TX_STATE_IDLE);
endmodule