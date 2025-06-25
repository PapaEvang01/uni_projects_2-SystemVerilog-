// Testbench for Trojan Module
// Simulates valid/ready communication and Trojan behavior (flush blocking)

module trojan_tb;

  parameter DW    = 16;
  parameter DEPTH = 4;

  // Clock and reset
  logic clk, rst;

  // Valid-ready handshake signals
  logic valid_i, ready_o;
  logic valid_o, ready_i;

  // Data lines
  logic [DW-1:0] din_i, dout_o;

  // Clock generator: 10ns period
  always begin
    clk = 1;
    #5;
    clk = 0;
    #5;
  end

  // Instantiate DUT
  trojan #(.DW(DW), .DEPTH(DEPTH)) DUT (
    .clk(clk),
    .rst(rst),
    .din_i(din_i),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .dout_o(dout_o),
    .valid_o(valid_o),
    .ready_i(ready_i)
  );

  // Initial test sequence
  initial begin
    $display("=== Starting Trojan Simulation ===");

    // Init signals
    rst      = 0;
    valid_i  = 0;
    ready_i  = 1;
    din_i    = 0;

    // Reset pulse
    @(posedge clk);
    rst <= 1;
    @(posedge clk);
    rst <= 0;
    @(posedge clk);

    // Sample push sequence
    push_data(16'hAAAA);
    push_data(16'hBBBB);
    push_data(16'hCCCC);

    // Trigger flush condition: valid_i = 0 → data should be blocked
    valid_i = 0;
    din_i   = 16'h1234;
    @(posedge clk);
    $display("FLUSHING: Data %h should be blocked", din_i);
    @(posedge clk);

    // Resume valid push
    push_data(16'hDDDD);
    push_data(16'hEEEE);

    $display("=== Simulation Complete ===");
    $stop();
  end

  // Task to push a single value
  task push_data(input [DW-1:0] value);
    begin
      valid_i <= 1;
      din_i   <= value;
      @(posedge clk);
      $strobe("@%0t: Sent %h | Output = %h | valid_o = %b", $time, value, dout_o, valid_o);
      valid_i <= 0;
      @(posedge clk);
    end
  endtask

endmodule
