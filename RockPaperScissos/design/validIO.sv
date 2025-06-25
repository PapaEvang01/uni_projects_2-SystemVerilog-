// ==========================================
// Module: validIO
// Description: Validates both players’ moves 
//              in a Rock-Paper-Scissors game.
//
// Inputs:
//   - inA: 3-bit one-hot move of Player A
//   - inB: 3-bit one-hot move of Player B
//
// Output:
//   - valid: High only if both inputs are 
//            valid one-hot encoded moves.
//
// Valid Move Criteria:
//   - Exactly one bit should be high (e.g., 001, 010, 100)
//   - Rejects 000, 111, or multiple bits set (e.g., 011, 110, etc.)
// ==========================================

module validIO(
    input  logic [2:0] inA,
    input  logic [2:0] inB,
    output logic       valid
);

    logic [5:0] valid_AB;

    // Player A checks
    assign valid_AB[0] = inA[0] ^ inA[1] ^ inA[2];   // Only one bit set (parity-like)
    assign valid_AB[1] = inA[0] & inA[1] & inA[2];   // Reject 111
    assign valid_AB[2] = inA[0] | inA[1] | inA[2];   // Reject 000

    // Player B checks
    assign valid_AB[3] = inB[0] ^ inB[1] ^ inB[2];
    assign valid_AB[4] = inB[0] & inB[1] & inB[2];
    assign valid_AB[5] = inB[0] | inB[1] | inB[2];

    // Final valid signal = All conditions satisfied
    assign valid = valid_AB[0] & ~valid_AB[1] & valid_AB[2] &
                   valid_AB[3] & ~valid_AB[4] & valid_AB[5];

endmodule
