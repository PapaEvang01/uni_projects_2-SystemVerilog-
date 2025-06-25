// Trojan Insertion Module
// --------------------------------------------------------------
// This module simulates a malicious hardware trojan that interrupts
// communication between two elastic registers (left and right).
// When `flush = 1`, all data is blocked from reaching the output.
//

module trojan
#(
  parameter int DW    = 16,
  parameter int DEPTH = 4
)
(
  input  logic              clk,
  input  logic              rst,

  // External input channel
  input  logic [DW-1:0]     din_i,
  input  logic              valid_i,
  output logic              ready_o,

  // External output channel
  output logic [DW-1:0]     dout_o,
  output logic              valid_o,
  input  logic              ready_i
);

  // Internal control signal
  logic flush;

  // Internal wires connecting left and right registers through Trojan
  logic [DW-1:0] data_left;
  logic         vld_left;
  logic         rdy_left;

  logic [DW-1:0] data_right;
  logic         vld_right;
  logic         rdy_right;

  // Instantiate left and right elastic registers
  left_register #(.DW_left(DW), .DEPTH_left(DEPTH)) DUT1 (
    .clk(clk),
    .rst(rst),
    .din_i(din_i),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .data_left(data_left),
    .vld_left(vld_left),
    .rdy_left(rdy_left)
  );

  right_register #(.DW_right(DW), .DEPTH_right(DEPTH)) DUT2 (
    .clk(clk),
    .rst(rst),
    .data_right(data_right),
    .vld_right(vld_right),
    .rdy_right(rdy_right),
    .dout_o(dout_o),
    .valid_o(valid_o),
    .ready_i(ready_i)
  );

  // Trojan Logic
  // --------------------------------------------------
  // When flush = 0 → normal operation (pass-through)
  // When flush = 1 → data is blocked (valid_o drops, ready_i ignored)

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      flush      <= 0;
      data_right <= '0;
      vld_right  <= 0;
      rdy_left   <= 0;
    end else begin
      // Set flush condition dynamically (example: triggered by no valid input)
      flush <= ~valid_i;

      if (flush == 0) begin
        // Normal operation: transfer data and handshake signals
        data_right <= data_left;
        vld_right  <= vld_left;
        rdy_left   <= rdy_right;
      end else begin
        // Trojan activated: suppress data
        data_right <= '0;
        vld_right  <= 0;
        rdy_left   <= 0;
      end
    end
  end

endmodule
