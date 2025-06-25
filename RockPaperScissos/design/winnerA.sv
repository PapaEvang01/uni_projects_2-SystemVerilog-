// ==========================================
// Module: winnerA
// Description: Determines if Player A wins 
//              in a Rock-Paper-Scissors game.
// 
// Inputs:
//   - inA: 3-bit one-hot move of Player A
//   - inB: 3-bit one-hot move of Player B
//
// Output:
//   - winA: High if Player A beats Player B
//
// Winning Rules:
//   - Paper (100) beats Rock (010)
//   - Rock  (010) beats Scissors (001)
//   - Scissors (001) beats Paper (100)
// ==========================================

module winnerA(
    input  logic [2:0] inA,
    input  logic [2:0] inB,
    output logic       winA
);

    logic checkA[2:0];

    assign checkA[0] = inA[2] & inB[1]; // A: Paper beats B: Rock
    assign checkA[1] = inA[1] & inB[0]; // A: Rock beats B: Scissors
    assign checkA[2] = inA[0] & inB[2]; // A: Scissors beats B: Paper

    assign winA = checkA[0] | checkA[1] | checkA[2];

endmodule
