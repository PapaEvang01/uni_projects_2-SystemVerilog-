/*
==============================================
    MoveGen.sv – Tic-Tac-Toe Automatic Player
==============================================

This module implements the decision-making logic for an automatic player (Player 'O') in a game of Tic-Tac-Toe.

Given the current board state (positions of X and O), the module generates the next move for player O
according to a structured strategy with decreasing priority:

1. Win:    If there's a move that completes a winning triplet, take it.
2. Block:  If the opponent is about to win, block that move.
3. Empty:  Otherwise, choose the first available empty cell.

Each strategy is encoded in a 9-bit output vector, where each bit corresponds to one of the 9 cells.
The first valid strategy (highest priority) that proposes a legal move is selected.

This is a purely combinational circuit and is designed to plug into a larger system handling the game logic.

Inputs:
  - x:     9-bit vector representing positions of X
  - o:     9-bit vector representing positions of O

Output:
  - newO:  9-bit vector representing the next move for O

*/

module MoveGen(
    input  logic [8:0] x,       // Current positions of player X
    input  logic [8:0] o,       // Current positions of player O
    output logic [8:0] newO     // Next move decision for player O
);

    // Internal signals representing possible strategies
    logic [8:0] win;    // Strategy 1: Winning move
    logic [8:0] block;  // Strategy 2: Blocking opponent
    logic [8:0] empty;  // Strategy 3: Pick first available empty cell

    logic [2:0] choice; // Priority indicator: 0 = win, 1 = block, 2 = empty

    always_comb begin
        // Initialize strategy vectors and choice
        win = 0;
        block = 0;
        empty = 0;
        choice = 2; // default to lowest priority: fill empty

        //------------------------
        // STRATEGY 1: Try to win
        //------------------------

        // Check all rows for a winning move
        if (o[0] && o[1] && ~x[2])       begin win[2] = 1; choice = 0; end
        else if (o[1] && o[2] && ~x[0])  begin win[0] = 1; choice = 0; end
        else if (o[2] && o[0] && ~x[1])  begin win[1] = 1; choice = 0; end

        else if (o[3] && o[4] && ~x[5])  begin win[5] = 1; choice = 0; end
        else if (o[5] && o[3] && ~x[4])  begin win[4] = 1; choice = 0; end
        else if (o[4] && o[5] && ~x[3])  begin win[3] = 1; choice = 0; end

        else if (o[6] && o[7] && ~x[8])  begin win[8] = 1; choice = 0; end
        else if (o[8] && o[6] && ~x[7])  begin win[7] = 1; choice = 0; end
        else if (o[7] && o[8] && ~x[6])  begin win[6] = 1; choice = 0; end

        // Check all columns for a winning move
        else if (o[0] && o[3] && ~x[6])  begin win[6] = 1; choice = 0; end
        else if (o[3] && o[6] && ~x[0])  begin win[0] = 1; choice = 0; end
        else if (o[6] && o[0] && ~x[3])  begin win[3] = 1; choice = 0; end

        else if (o[1] && o[4] && ~x[7])  begin win[7] = 1; choice = 0; end
        else if (o[7] && o[1] && ~x[4])  begin win[4] = 1; choice = 0; end
        else if (o[4] && o[7] && ~x[1])  begin win[1] = 1; choice = 0; end

        else if (o[2] && o[5] && ~x[8])  begin win[8] = 1; choice = 0; end
        else if (o[8] && o[2] && ~x[5])  begin win[5] = 1; choice = 0; end
        else if (o[5] && o[8] && ~x[2])  begin win[2] = 1; choice = 0; end

        // Check diagonals for a winning move
        else if (o[0] && o[4] && ~x[8])  begin win[8] = 1; choice = 0; end
        else if (o[4] && o[8] && ~x[0])  begin win[0] = 1; choice = 0; end
        else if (o[8] && o[0] && ~x[4])  begin win[4] = 1; choice = 0; end

        else if (o[2] && o[4] && ~x[6])  begin win[6] = 1; choice = 0; end
        else if (o[6] && o[2] && ~x[4])  begin win[4] = 1; choice = 0; end
        else if (o[4] && o[6] && ~x[2])  begin win[2] = 1; choice = 0; end

        //-----------------------------
        // STRATEGY 2: Try to block X
        //-----------------------------
        else if (x[0] && x[1] && ~o[2] && ~|block) begin block[2] = 1; choice = 1; end
        else if (x[1] && x[2] && ~o[0] && ~|block) begin block[0] = 1; choice = 1; end
        else if (x[2] && x[0] && ~o[1] && ~|block) begin block[1] = 1; choice = 1; end

        else if (x[3] && x[4] && ~o[5] && ~|block) begin block[5] = 1; choice = 1; end
        else if (x[5] && x[3] && ~o[4] && ~|block) begin block[4] = 1; choice = 1; end
        else if (x[4] && x[5] && ~o[3] && ~|block) begin block[3] = 1; choice = 1; end

        else if (x[6] && x[7] && ~o[8] && ~|block) begin block[8] = 1; choice = 1; end
        else if (x[8] && x[6] && ~o[7] && ~|block) begin block[7] = 1; choice = 1; end
        else if (x[7] && x[8] && ~o[6] && ~|block) begin block[6] = 1; choice = 1; end

        // Columns
        else if (x[0] && x[3] && ~o[6] && ~|block) begin block[6] = 1; choice = 1; end
        else if (x[3] && x[6] && ~o[0] && ~|block) begin block[0] = 1; choice = 1; end
        else if (x[6] && x[0] && ~o[3] && ~|block) begin block[3] = 1; choice = 1; end

        else if (x[1] && x[4] && ~o[7] && ~|block) begin block[7] = 1; choice = 1; end
        else if (x[7] && x[1] && ~o[4] && ~|block) begin block[4] = 1; choice = 1; end
        else if (x[4] && x[7] && ~o[1] && ~|block) begin block[1] = 1; choice = 1; end

        else if (x[2] && x[5] && ~o[8] && ~|block) begin block[8] = 1; choice = 1; end
        else if (x[8] && x[2] && ~o[5] && ~|block) begin block[5] = 1; choice = 1; end
        else if (x[5] && x[8] && ~o[2] && ~|block) begin block[2] = 1; choice = 1; end

        // Diagonals
        else if (x[0] && x[4] && ~o[8] && ~|block) begin block[8] = 1; choice = 1; end
        else if (x[4] && x[8] && ~o[0] && ~|block) begin block[0] = 1; choice = 1; end
        else if (x[8] && x[0] && ~o[4] && ~|block) begin block[4] = 1; choice = 1; end

        else if (x[2] && x[4] && ~o[6] && ~|block) begin block[6] = 1; choice = 1; end
        else if (x[6] && x[4] && ~o[2] && ~|block) begin block[2] = 1; choice = 1; end
        else if (x[2] && x[6] && ~o[4] && ~|block) begin block[4] = 1; choice = 1; end

        //-----------------------------------
        // STRATEGY 3: Pick first empty cell
        //-----------------------------------
        else if (~|win && ~|block) begin
            empty = 9'b111_111_111; // flag as ready to choose empty
            choice = 2;
        end

        //---------------------
        // Output newO decision
        //---------------------
        newO = 9'b0;
        for (int i = 0; i < 9; i++) begin
            if (choice == 0 && win[i])         newO[i] = 1;
            else if (choice == 1 && block[i])  newO[i] = 1;
            else if (choice == 2 && ~x[i] && ~o[i]) newO[i] = 1;
        end
    end

endmodule
