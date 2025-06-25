// ============================================
// Testbench for Network Switch
// ============================================
// This testbench checks whether the network_switch module
// correctly forwards data when only one request is active.
// ============================================

module testbench;

  logic [3:0] R;                     // Request lines
  logic [31:0] D [3:0];              // Input data
  logic [31:0] out;                  // Output

  // Instantiate Device Under Test (DUT)
  network_switch dut (
    .R(R),
    .D(D),
    .out(out)
  );

  // Test sequence
  initial begin
    $monitor($time, " R=%b, out=%h", R, out);
    $dumpfile("dump_wave.vcd");
    $dumpvars(0, testbench);

    // Case 1: No request active
    R = 4'b0000;
    D[0] = 32'hAAAA0000;
    D[1] = 32'hBBBB1111;
    D[2] = 32'hCCCC2222;
    D[3] = 32'hDDDD3333;
    #10;

    // Case 2: One request active - should forward D[2]
    R = 4'b0100;
    #10;

    // Case 3: Multiple requests active - output should be 0
    R = 4'b1100;
    #10;

    // Case 4: One request active - should forward D[0]
    R = 4'b0001;
    #10;

    // Case 5: One request active - should forward D[3]
    R = 4'b1000;
    #10;

    // Case 6: All requests active - output should be 0
    R = 4'b1111;
    #10;

    $finish;
  end

endmodule
