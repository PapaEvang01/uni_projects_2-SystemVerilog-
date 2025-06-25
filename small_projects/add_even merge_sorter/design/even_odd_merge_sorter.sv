//=====================================================================
// Module: even_odd_merge_sorter
// Description: Sorts 4 input values (A, B, C, D) using a sorting network
//              based on the Odd-Even Merge Sort structure. Produces:
//              - max:         maximum value
//              - second_max:  second largest value
//              - second_min:  second smallest value
//              - min:         minimum value
//=====================================================================
module even_odd_merge_sorter(
  input  logic [7:0] A,
  input  logic [7:0] B,
  input  logic [7:0] C,
  input  logic [7:0] D,
  output logic [7:0] max,
  output logic [7:0] second_max,
  output logic [7:0] second_min,
  output logic [7:0] min
);

  // Intermediate wires between sorter stages
  logic [7:0] sorter_1_max, sorter_1_min;
  logic [7:0] sorter_2_max, sorter_2_min;
  logic [7:0] sorter_3_min;
  logic [7:0] sorter_4_max;

  // Stage 1: Pairwise sorting
  sorter sorter_1 (A, B, sorter_1_max, sorter_1_min);
  sorter sorter_2 (C, D, sorter_2_max, sorter_2_min);

  // Stage 2: Compare max and min parts of previous pairs
  sorter sorter_3 (sorter_1_max, sorter_2_max, max, sorter_3_min);
  sorter sorter_4 (sorter_1_min, sorter_2_min, sorter_4_max, min);

  // Stage 3: Compare second-tier middle elements
  sorter sorter_5 (sorter_3_min, sorter_4_max, second_max, second_min);

endmodule
