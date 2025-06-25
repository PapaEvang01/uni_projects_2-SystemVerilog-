// ====================================================
// Testbench for homework3.sv (Server FSM)
// Simulates student connect/disconnect scenarios
// ====================================================

module tb;

  // Clock and input/output signals
  logic clk;
  logic rst;
  logic [1:0] in;
  logic out;

  // Clock period
  localparam T = 20;

  // Instantiate DUT (Device Under Test)
  homework3 dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
  );

  // Clock generator
  always begin
    clk = 1'b1;
    #(T/2);
    clk = 1'b0;
    #(T/2);
  end

  // Test sequence
  initial begin
    $display("Starting Simulation...");
    $monitor($time, " | in=%b | out=%b", in, out);

    // Initial state
    rst = 1;
    in = 2'b00;
    @(posedge clk);

    // Release reset
    rst = 0;
    @(posedge clk);

    // Student 1 connects
    in = 2'b01;
    @(posedge clk);

    // Student 2 connects
    in = 2'b01;
    @(posedge clk);

    // Student 3 connects (should reach max connections)
    in = 2'b01;
    @(posedge clk);

    // Server should now block further connections
    in = 2'b01; // Try connecting again, no effect
    @(posedge clk);

    // One student disconnects
    in = 2'b10;
    @(posedge clk);

    // One more disconnect
    in = 2'b10;
    @(posedge clk);

    // Connect again (should allow it now)
    in = 2'b01;
    @(posedge clk);

    $display("Simulation Finished.");
    $stop;
  end

endmodule
