// =============================================================
// Hamming Code (15,11) Testbench
// -------------------------------------------------------------
// This testbench verifies the functionality of the Hamming (15,11)
// encoder by applying multiple 11-bit input examples and comparing
// the 15-bit serial output against expected encoded values.
//
// ➤ Features:
//   - Predefined input vectors (10 examples)
//   - Corresponding expected Hamming-encoded outputs
//   - Serial input/output communication
//   - Automated pass/fail verification for each case
//
// Designed for use with the `hamming_core` encoder module
// =============================================================

module hamming_tb;

localparam EXAMPLES = 10;
int error_cnt;

logic clk, rst, inp, out;

// Test vector arrays
logic [10:0] ex_inp  [EXAMPLES-1:0];  // input messages
logic [14:0] ref_out [EXAMPLES-1:0];  // expected outputs

logic [10:0] inp_stream;   // serial input buffer
logic [14:0] out_stream;   // serial output buffer

// Instantiate the DUT (Design Under Test)
hamming_core DUT(
  .clk (clk),
  .rst (rst),
  .inp (inp),
  .out (out)
);

// Clock generation: 20ns clock period
always begin
  clk = 1'b1; #10ns;
  clk = 1'b0; #10ns;
end

initial begin  
  $display("~~~ Starting the simulation! ~~~"); 
  INITIALIZE();
  
  for (int ex=0; ex<EXAMPLES; ex++) begin
    RUN_EXAMPLE(ex);
    repeat(20) @(posedge clk);  // wait before next test
  end
  
  $display("\n%2d/%2d Passed!", EXAMPLES-error_cnt, EXAMPLES);
  $display("~~~ End of simulation! ~~~"); 
  $stop();
end

// ==========================================
// TASK: Load input/output test vectors
// ==========================================
task INITIALIZE();
    error_cnt = 0;

    ex_inp[0]  = 11'b01010010011;  ref_out[0] = 15'b110101010010011;
    ex_inp[1]  = 11'b10011110101;  ref_out[1] = 15'b111010011110101;
    ex_inp[2]  = 11'b10110001010;  ref_out[2] = 15'b110010110001010;
    ex_inp[3]  = 11'b10101010101;  ref_out[3] = 15'b010110101010101;
    ex_inp[4]  = 11'b00000000110;  ref_out[4] = 15'b001100000000110;
    ex_inp[5]  = 11'b11111111100;  ref_out[5] = 15'b100111111111100;
    ex_inp[6]  = 11'b00000000011;  ref_out[6] = 15'b011000000000011;
    ex_inp[7]  = 11'b00011100011;  ref_out[7] = 15'b101100011100011;
    ex_inp[8]  = 11'b11110000000;  ref_out[8] = 15'b000011110000000;
    ex_inp[9]  = 11'b00000001111;  ref_out[9] = 15'b011100000001111;
endtask

// ==========================================
// TASK: Reset DUT and load input stream
// ==========================================
task RESET(logic [10:0] is);
  rst <= 1'b1;
  out_stream <= 15'b0;
  inp_stream <= is;
  repeat(5) @(posedge clk);
  rst <= 1'b0;
endtask

// ==========================================
// TASK: Serially send a bit of input stream
// ==========================================
task SEND_BIT(int indx);
  inp <= inp_stream[indx];
  @(posedge clk);
endtask

// ==========================================
// TASK: Serially read a bit of output stream
// ==========================================
task READ_BIT();
  out_stream[13:0] <= out_stream[14:1];
  out_stream[14] <= out;
  @(posedge clk);
endtask

// ==========================================
// TASK: Execute a complete encoding test
// ==========================================
task RUN_EXAMPLE(int ID);
  $display("Running example No.%1d", ID);
  RESET(ex_inp[ID]);
  
  // Feed 11 input bits serially
  for (int i=0; i<11; i++)
    SEND_BIT(i);
  
  @(posedge clk);  // small wait before output

  // Read output serially until full word is received
  for (int i=0; i<100; i++) begin
    READ_BIT();
    if (out_stream[10:0] == inp_stream)
      break;
  end
  
  // Check result against expected output
  if (ref_out[ID] !== out_stream) begin
    $display("  Validation failed!");
    $display("  Received: %b, while expecting %b", out_stream, ref_out[ID]);
    error_cnt++;
  end else begin
    $display("  Output Stream: {%b}%b   -> Pass!!!", out_stream[14:11], out_stream[10:0]);
  end
endtask

endmodule
