//======================================================================
// Module: even_odd_merge_sorter_tb
// Description: Testbench for verifying the 4-element sorting network
//              implemented in even_odd_merge_sorter_wrapper.
//======================================================================
module even_odd_merge_sorter_tb;

  parameter MEM_SIZE = 30;  // Number of test cases loaded from file

  // Clock and reset
  logic clk, rst;

  // Input and output signals for the sorting module
  logic [7:0] A;
  logic [7:0] B;
  logic [7:0] C;
  logic [7:0] D;
  logic [7:0] max;
  logic [7:0] second_max;
  logic [7:0] second_min;
  logic [7:0] min;

  // Memory to hold test vectors (64-bit = 4 x 8-bit numbers packed)
  logic [63:0] test_memory[0:MEM_SIZE-1];
  integer i;

  // Clock generation: 10 ns clock period (50 MHz)
  always begin
    clk <= 1;
    #5ns;
    clk <= 0;
    #5ns;
  end

  // Instantiate the design under test
  even_odd_merge_sorter_wrapper sorter_0 (
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .C(C),
    .D(D),
    .max(max),
    .second_max(second_max),
    .second_min(second_min),
    .min(min)
  );

  // Initial block: test execution
  initial begin
    // Monitor output continuously
    $monitor($time, " max=%h, second_max=%h, second_min=%h, min=%h", max, second_max, second_min, min);

    $display("Loading test vectors from file...");
    $readmemh("test.tv", test_memory);  // Load test data from file (hex format)

    // Apply reset
    rst <= 1;
    repeat(2) @(posedge clk);
    rst <= 0;

    // Apply inputs from test vectors one per clock cycle
    for (i = 0; i < MEM_SIZE; i = i + 1) begin
      {A, B, C, D} = test_memory[i];  // Unpack 4 inputs from memory word
      @(posedge clk);
    end

    // Wait a few cycles for output to settle
    repeat(5) @(posedge clk);

    $stop();  // End simulation
  end

endmodule
