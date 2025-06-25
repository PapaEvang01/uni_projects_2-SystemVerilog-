// ==========================================
// Module: checkTie
// Description: Checks if both players made
//              the same move in a 
//              Rock-Paper-Scissors game.
//
// Inputs:
//   - inA: 3-bit one-hot move of Player A
//   - inB: 3-bit one-hot move of Player B
//
// Output:
//   - Tie: High if both moves are identical
//
// Tie Rule:
//   - Tie is true if inA == inB (bitwise match)
// ==========================================

module checkTie(
    input  logic [2:0] inA,
    input  logic [2:0] inB,
    output logic       Tie
);

    logic [2:0] tie;

    assign tie[0] = (inA[0] == inB[0]);
    assign tie[1] = (inA[1] == inB[1]);
    assign tie[2] = (inA[2] == inB[2]);

    assign Tie = tie[0] & tie[1] & tie[2];

endmodule
