//======================================================
// edge_detector.sv
//======================================================
// This module detects a rising edge on a digital input signal.
//
// When the input `in` transitions from 0 to 1 (low to high),
// the output `out` becomes 1 for a single clock cycle,
// indicating that a rising edge has occurred.
//
// The module uses a simple 2-bit shift register to store
// the current and previous value of the input.
//
//======================================================

module edge_detector(
  input  logic clk,      // Clock signal
  input  logic rst,      // Asynchronous reset

  input  logic in,       // Input signal to monitor
  output logic out       // Output goes high on rising edge of `in`
);

  logic [1:0] s_reg;     // Shift register to hold input history

  // On every clock edge, update the shift register
  always_ff @(posedge clk) begin
    if (rst)
      s_reg <= 2'b0;     // Reset both previous and current values to 0
    else begin
      s_reg[1] <= s_reg[0];  // Store previous value
      s_reg[0] <= in;        // Store current value
    end
  end

  // Output is high only when previous input was 0 and current is 1
  assign out = ~s_reg[1] & s_reg[0];

endmodule
