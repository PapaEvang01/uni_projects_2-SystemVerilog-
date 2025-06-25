//=======================================================
// Module: sorter
// Description: Compares two 8-bit input values and outputs
//              the maximum and minimum of the two.
//=======================================================
module sorter (
  input  logic [7:0] A,     // First 8-bit input value
  input  logic [7:0] B,     // Second 8-bit input value
  output logic [7:0] max,   // Output: Maximum of A and B
  output logic [7:0] min    // Output: Minimum of A and B
);

  // Combinational logic for comparing A and B
  always_comb begin
    if (A > B) begin
      max = A;
      min = B;
    end else begin
      max = B;
      min = A;
    end
  end

endmodule
