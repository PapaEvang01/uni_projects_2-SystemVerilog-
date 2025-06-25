// ==========================================
// Module: winnerB
// Description: Determines if Player B wins 
//              in a Rock-Paper-Scissors game.
//
// Inputs:
//   - inA: 3-bit one-hot move of Player A
//   - inB: 3-bit one-hot move of Player B
//
// Output:
//   - winB: High if Player B beats Player A
//
// Winning Rules:
//   - Paper (100) beats Rock (010)
//   - Rock  (010) beats Scissors (001)
//   - Scissors (001) beats Paper (100)
// ==========================================

module winnerB(
    input  logic [2:0] inA,
    input  logic [2:0] inB,
    output logic       winB
);

    logic checkB[2:0];

    assign checkB[0] = inB[2] & inA[1]; // B: Paper beats A: Rock
    assign checkB[1] = inB[1] & inA[0]; // B: Rock beats A: Scissors
    assign checkB[2] = inB[0] & inA[2]; // B: Scissors beats A: Paper

    assign winB = checkB[0] | checkB[1] | checkB[2];

endmodule
