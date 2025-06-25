// ============================================
// Network Switch - One-Request Data Forwarder
// ============================================
// This module models a simple network switch where 4 input data lines (D[0] to D[3])
// share a common output port. Each input is associated with a request signal R[i].
// If exactly one R[i] is active, the corresponding D[i] is routed to the output.
// If no requests or multiple requests are active, the output is zeroed.
// ============================================

module network_switch(
  input  logic [3:0] R,              // Request lines (R[0] to R[3])
  input  logic [31:0] D [3:0],       // Data inputs (D[0] to D[3])
  output logic [31:0] out            // Output: Data from the selected input or 0
);

  logic [1:0] selected_index;        // Stores index of the active request
  integer i;
  int count;                         // Counts how many requests are active

  always_comb begin
    count = 0;
    selected_index = 0;

    // Count active requests and store the index of the last seen active request
    for (i = 0; i < 4; i++) begin
      if (R[i]) begin
        selected_index = i;
        count++;
      end
    end

    // Forward data only if exactly one request is active
    if (count == 1)
      out = D[selected_index];
    else
      out = 32'b0;  // If 0 or multiple requests, output is zero
  end

endmodule
