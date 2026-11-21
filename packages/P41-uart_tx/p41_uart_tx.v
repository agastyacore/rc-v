// P41 Terminal output (UART)
// Memory-mapped I/O device, slot 0.
// Register 0: TXDATA (write a character)
// Register 1: TXSTATUS (bit 0 = ready)
// Register 15: package ID (41)
//
// A character is accepted only when the device is ready.
// After acceptance the device is busy for four clock cycles.
// tx_valid is a one-clock pulse for each accepted character.

module p41_uart_tx (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    output reg  tx_valid,
    output reg  [7:0] tx_char
);

    reg [2:0] busy_count;

    wire ready;
    wire write_txdata;
    wire accept_write;

    assign ready = (busy_count == 3'd0);
    assign write_txdata = sel && we && (ridx == 4'd0);
    assign accept_write = write_txdata && ready && !rst;

    // Read port is combinational: it does not wait for a clock edge.
    // Unimplemented registers read as zero.
    assign rdata =
        (ridx == 4'd1)  ? {31'd0, ready} :
        (ridx == 4'd15) ? 32'd41 :
                          32'd0;

    always @(posedge clk) begin
        if (rst) begin
            busy_count <= 3'd0;
            tx_valid   <= 1'b0;
            tx_char    <= 8'd0;
        end else begin
            // tx_valid is a pulse, not a level.
            tx_valid <= 1'b0;

            if (accept_write) begin
                tx_char    <= wdata[7:0];
                tx_valid   <= 1'b1;
                busy_count <= 3'd4;
            end else if (busy_count != 3'd0) begin
                busy_count <= busy_count - 3'd1;
            end
            // A write while busy is deliberately ignored.
        end
    end

endmodule
