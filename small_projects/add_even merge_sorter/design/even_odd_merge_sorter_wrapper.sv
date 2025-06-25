//=====================================================================
// Module: even_odd_merge_sorter_wrapper
// Description: Adds input/output registers around the core sorting 
//              circuit to make the entire design synchronous.
//              This helps in meeting timing and pipelining.
//=====================================================================
module even_odd_merge_sorter_wrapper(
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  A,
  input  logic [7:0]  B,
  input  logic [7:0]  C,
  input  logic [7:0]  D,
  output logic [7:0]  max,
  output logic [7:0]  second_max,
  output logic [7:0]  second_min,
  output logic [7:0]  min
);

  // Input registers to capture inputs on rising edge
  logic [7:0] regA, regB, regC, regD;

  // Output registers to hold the sorted results
  logic [7:0] reg_max, reg_second_max, reg_second_min, reg_min;

  // Register inputs at the rising edge of clock
  always_ff @(posedge clk) begin
    if (rst) begin
      regA <= 8'b0;
      regB <= 8'b0;
      regC <= 8'b0;
      regD <= 8'b0;
    end else begin
      regA <= A;
      regB <= B;
      regC <= C;
      regD <= D;
    end
  end

  // Core sorting logic (purely combinational)
  even_odd_merge_sorter sorter_0(
    .A(regA),
    .B(regB),
    .C(regC),
    .D(regD),
    .max(reg_max),
    .second_max(reg_second_max),
    .second_min(reg_second_min),
    .min(reg_min)
  );

  // Output registers to store final sorted results
  always_ff @(posedge clk) begin
    if (rst) begin
      max        <= 8'b0;
      second_max <= 8'b0;
      second_min <= 8'b0;
      min        <= 8'b0;
    end else begin
      max        <= reg_max;
      second_max <= reg_second_max;
      second_min <= reg_second_min;
      min        <= reg_min;
    end
  end

endmodule
