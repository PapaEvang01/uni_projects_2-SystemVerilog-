/*
===============================================================
    Tic-Tac-Toe with VGA & AI – Top-Level Module (top.sv)
===============================================================

Description:
------------
This is the main top-level module for a hardware-based Tic-Tac-Toe game 
implemented on an FPGA with VGA display. It supports a human vs. AI player mode.

Key Features:
- VGA output for board rendering and player symbols
- Cursor control with input buttons (Up/Down/Left/Right/Play)
- ROM-based rendering for 'X' and 'O' characters
- AI-controlled opponent using MoveGen logic
- Game state tracking, win/tie detection

Author: Vaggelis Paps
Target Board: Nexys A7 (or compatible)
Resolution: 800x600 @ 72Hz
*/

//==========================
// Module Interface
//==========================
module top(
	input logic clk,            // Main system clock
	input logic rst,            // Reset signal (clears game state)

	// Input buttons for human player navigation
	input logic button_left,
	input logic button_right,
	input logic button_up,
	input logic button_down,
    input logic button_play,   // Confirm square placement

	// Output game result flags
	output logic winA,         // Player X wins
	output logic winB,         // Player O (AI) wins
	output logic tie,          // Game ends in a tie

	// VGA color and sync signals
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue,
	output logic hsync,
	output logic vsync
);

//==========================
// Game Logic Variables
//==========================

// 9-bit bitmaps for player positions (1 bit per square)
logic [8:0] rx;               // Squares occupied by player X
logic [8:0] ro;               // Squares occupied by player O

// Cursor position (3x3 grid)
logic [1:0] cursor_x;
logic [1:0] cursor_y;

logic player_id;             // Tracks whose turn it is (0: X, 1: O)
logic game_over;             // Game over flag
logic [8:0] selected_sqr;    // Square that was selected for a move

//==========================
// Win/Tie Detection Variables
//==========================
logic [2:0] row_win_X, col_win_X;   // Winning lines for X
logic [2:0] row_win_O, col_win_O;   // Winning lines for O
logic [1:0] diag_win_X, diag_win_O; // Diagonal win flags
logic win_in_rows_X, win_in_cols_X, win_in_diags_X;
logic win_in_rows_O, win_in_cols_O, win_in_diags_O;

//==========================
// VGA ROM Access for 'X' and 'O'
//==========================
logic [6:0] addx, addo;        // Vertical line address (row)
logic [99:0] datax, datao;     // Pixel line bitmap (100 bits wide)

O_ROM DUT6 (.address(addo), .data(datao));  // ROM for drawing O
X_ROM DUT7 (.address(addx), .data(datax));  // ROM for drawing X

//==========================
// Edge Detection for Button Inputs
//==========================
edge_detector DUT1(.clk(clk), .rst(rst), .in(button_left),  .out(new_button_left));
edge_detector DUT2(.clk(clk), .rst(rst), .in(button_right), .out(new_button_right));
edge_detector DUT3(.clk(clk), .rst(rst), .in(button_up),    .out(new_button_up));
edge_detector DUT4(.clk(clk), .rst(rst), .in(button_down),  .out(new_button_down));
edge_detector DUT5(.clk(clk), .rst(rst), .in(button_play),  .out(new_button_play));


    //==========================
    // AI Move Generator
    //==========================
    // The MoveGen module analyzes the current state of the board (X and O positions)
    // and outputs a proposed next move for player O (the AI). The move is encoded
    // as a 9-bit signal with a '1' in the position the AI wants to play.
    logic [8:0] newO;
    MoveGen DUT8(.x(rx), .o(ro), .newO(newO));

    //=====================================
    // Cursor Control & Player Input Logic
    //=====================================
    // This always_ff block handles:
    // - Initial reset of the cursor
    // - Navigation via button presses
    // - Selecting a square on button_play
    // - Cursor wraps around the board edges
    always_ff @ (posedge clk) begin 
	  
        // Reset cursor position to top-left
		if (rst) begin 
			cursor_x = 0;
			cursor_y = 0;
		end 

        // If game is still active (not over)
		if (!game_over) begin 

            // Navigate UP — wrap to bottom if at top
			if (new_button_up) begin
				if (cursor_y > 0)
				    cursor_y <= cursor_y - 1;
				else 
				    cursor_y <= 2;
			end

            // Navigate DOWN — wrap to top if at bottom
		    if (new_button_down) begin
			    if (cursor_y < 2)
			        cursor_y <= cursor_y + 1;
			    else 
			        cursor_y <= 0;
            end

            // Navigate RIGHT — wrap to leftmost column
			if (new_button_right) begin
			    if (cursor_x < 2)
			        cursor_x <= cursor_x + 1;
			    else  
			        cursor_x <= 0;
            end

            // Navigate LEFT — wrap to rightmost column
			if (new_button_left) begin
			    if (cursor_x > 0)
			        cursor_x <= cursor_x - 1;
			    else  
			        cursor_x <= 2;
            end

            // Select the current square on 'play' button
            if (new_button_play == 1) begin 
                if (cursor_x == 0 && cursor_y == 0) selected_sqr[0] <= 1;
                if (cursor_x == 1 && cursor_y == 0) selected_sqr[1] <= 1;
                if (cursor_x == 2 && cursor_y == 0) selected_sqr[2] <= 1;
                if (cursor_x == 0 && cursor_y == 1) selected_sqr[3] <= 1;
                if (cursor_x == 1 && cursor_y == 1) selected_sqr[4] <= 1;
                if (cursor_x == 2 && cursor_y == 1) selected_sqr[5] <= 1;
                if (cursor_x == 0 && cursor_y == 2) selected_sqr[6] <= 1;
                if (cursor_x == 1 && cursor_y == 2) selected_sqr[7] <= 1;
                if (cursor_x == 2 && cursor_y == 2) selected_sqr[8] <= 1;
            end
	    end 
	end


    
    //=================================================
    // Player Move Logic (X is manual, O is automatic)
    //=================================================
    always_ff @(posedge clk) begin 
    
        //=========================
        // Game Reset: Clear Board
        //=========================
        if (rst) begin 
            ro <= 9'b000000000;  // Clear O moves
            rx <= 9'b000000000;  // Clear X moves
            player_id <= 0;      // Start with player X
        end 

        //=========================
        // Game Active: Handle Moves
        //=========================
        if (!game_over) begin 

            //=========================
            // Player X (Manual Input)
            //=========================
            if (player_id == 0) begin

                // --- Y = 0 (Top Row) ---
                if (cursor_y == 0) begin
                    if (cursor_x == 0 && new_button_play && !ro[0] && !rx[0]) begin
                        rx[0] <= 1; player_id <= 1;
                    end
                    if (cursor_x == 1 && new_button_play && !ro[1] && !rx[1]) begin
                        rx[1] <= 1; player_id <= 1;
                    end
                    if (cursor_x == 2 && new_button_play && !ro[2] && !rx[2]) begin
                        rx[2] <= 1; player_id <= 1;
                    end
                end

                // --- Y = 1 (Middle Row) ---
                if (cursor_y == 1) begin
                    if (cursor_x == 0 && new_button_play && !ro[3] && !rx[3]) begin
                        rx[3] <= 1; player_id <= 1;
                    end
                    if (cursor_x == 1 && new_button_play && !ro[4] && !rx[4]) begin
                        rx[4] <= 1; player_id <= 1;
                    end
                    if (cursor_x == 2 && new_button_play && !ro[5] && !rx[5]) begin
                        rx[5] <= 1; player_id <= 1;
                    end
                end

                // --- Y = 2 (Bottom Row) ---
                if (cursor_y == 2) begin
                    if (cursor_x == 0 && new_button_play && !ro[6] && !rx[6]) begin
                        rx[6] <= 1; player_id <= 1;
                    end
                    if (cursor_x == 1 && new_button_play && !ro[7] && !rx[7]) begin
                        rx[7] <= 1; player_id <= 1;
                    end
                    if (cursor_x == 2 && new_button_play && !ro[8] && !rx[8]) begin
                        rx[8] <= 1; player_id <= 1;
                    end
                end
            end

            //=========================
            // Player O (AI Move)
            //=========================
            else if (player_id == 1) begin
                ro <= newO;         // Accept AI's move
                player_id <= 0;     // Switch back to X
            end
        end
    end

    //=======================================================
    // Winner Detection Logic (Player A = X, Player B = O)
    //=======================================================
    always_ff @(posedge clk) begin 
      
        //-------------------------------
        // Reset: Clear game status flags
        //-------------------------------
        if (rst) begin 
            winA      <= 0;  // X wins
            winB      <= 0;  // O wins
            tie       <= 0;
            game_over <= 0;
        end

        //-------------------------------
        // Check Win Conditions for X
        //-------------------------------

        // Rows
        row_win_X[0]    <= rx[0] & rx[1] & rx[2];
        row_win_X[1]    <= rx[3] & rx[4] & rx[5];
        row_win_X[2]    <= rx[6] & rx[7] & rx[8];
        win_in_rows_X   <= |row_win_X;

        // Columns
        col_win_X[0]    <= rx[0] & rx[3] & rx[6];
        col_win_X[1]    <= rx[1] & rx[4] & rx[7];
        col_win_X[2]    <= rx[2] & rx[5] & rx[8];
        win_in_cols_X   <= |col_win_X;

        // Diagonals
        diag_win_X[0]   <= rx[0] & rx[4] & rx[8];
        diag_win_X[1]   <= rx[2] & rx[4] & rx[6];
        win_in_diags_X  <= |diag_win_X;

        //-------------------------------
        // Check Win Conditions for O
        //-------------------------------

        // Rows
        row_win_O[0]    <= ro[0] & ro[1] & ro[2];
        row_win_O[1]    <= ro[3] & ro[4] & ro[5];
        row_win_O[2]    <= ro[6] & ro[7] & ro[8];
        win_in_rows_O   <= |row_win_O;

        // Columns
        col_win_O[0]    <= ro[0] & ro[3] & ro[6];
        col_win_O[1]    <= ro[1] & ro[4] & ro[7];
        col_win_O[2]    <= ro[2] & ro[5] & ro[8];
        win_in_cols_O   <= |col_win_O;

        // Diagonals
        diag_win_O[0]   <= ro[0] & ro[4] & ro[8];
        diag_win_O[1]   <= ro[2] & ro[4] & ro[6];
        win_in_diags_O  <= |diag_win_O;

        //-------------------------------
        // Declare Winner or Tie
        //-------------------------------

        if (win_in_rows_X || win_in_cols_X || win_in_diags_X) begin
            winA      <= 1;
            game_over <= 1;
        end 
        else if (win_in_rows_O || win_in_cols_O || win_in_diags_O) begin 
            winB      <= 1;
            game_over <= 1;
        end 
        else if (
            !winA && !winB &&
            (rx[0]|ro[0]) & (rx[1]|ro[1]) & (rx[2]|ro[2]) &
            (rx[3]|ro[3]) & (rx[4]|ro[4]) & (rx[5]|ro[5]) &
            (rx[6]|ro[6]) & (rx[7]|ro[7]) & (rx[8]|ro[8])
        ) begin 
            tie       <= 1;
            game_over <= 1;
        end
    end


    //=======================================================
    // VGA Pixel Clock Divider
    // Generates a slower pixel clock from the main system clock
    //=======================================================
    logic pxlClk;

    always_ff @(posedge clk) begin
        if (rst) begin 
            pxlClk <= 1'b1;
        end else begin 
            pxlClk <= ~pxlClk; // Toggle every clock edge to divide by 2
        end
    end


    //=======================================================
    // Horizontal (hs) and Vertical (vs) Counters
    // Generate pixel coordinates and handle screen scanning
    //=======================================================
    logic [10:0] hs; // Horizontal pixel counter (0–1039 for 800x600@72Hz)
    logic [9:0]  vs; // Vertical line counter (0–665)

    always_ff @(posedge clk) begin
        if (rst) begin
            hs <= 0;
            vs <= 0;
        end 
        else if (pxlClk) begin
            hs <= hs + 1;

            if (hs >= 1039) begin
                hs <= 0;
                vs <= vs + 1;

                if (vs >= 665)
                    vs <= 0;
            end
        end
    end

    //=======================================================
    // Synchronization Pulses for VGA
    // hsync and vsync timing based on standard VGA @ 72Hz
    //=======================================================
    assign hsync = (hs >= 856 && hs < 976) ? 1'b0 : 1'b1; // Active low during pulse
    assign vsync = (vs >= 637 && vs < 643) ? 1'b0 : 1'b1;


    //===========================================================
    // VGA Color Logic Block
    // Handles:
    // 1. Drawing the white grid lines (gaps between squares)
    // 2. Drawing the cursor highlight based on (cursor_x, cursor_y)
    //===========================================================
    always_ff @(posedge clk) begin 
        // ---------- Draw Grid Lines ----------
        // Vertical lines at x ≈ 289 and 494
        // Horizontal lines at y ≈ 189 and 394
        if ((hs >= 289 && hs < 304) || (hs >= 494 && hs < 509) || 
            ((vs >= 189 && vs < 204) && (hs >= 100 && hs < 700)) ||
            ((vs >= 394 && vs < 409) && (hs >= 100 && hs < 700))) 
        begin
            red   <= 4'b1111;
            green <= 4'b1111;
            blue  <= 4'b1111;
        end 

        // ---------- Draw Cursor ----------
        // Each 'if' checks if the current pixel lies within the 20x20 pixel block
        // that corresponds to the active cursor position (9 total positions)
        else if ((hs >= 110 && hs < 130) && (vs >= 10 && vs < 30) && (cursor_x == 0) && (cursor_y == 0)) begin
            red <= green <= blue <= 4'b1111; // cursor (0,0)
        end
        else if ((hs >= 315 && hs < 335) && (vs >= 10 && vs < 30) && (cursor_x == 1) && (cursor_y == 0)) begin
            red <= green <= blue <= 4'b1111; // cursor (1,0)
        end
        else if ((hs >= 520 && hs < 540) && (vs >= 10 && vs < 30) && (cursor_x == 2) && (cursor_y == 0)) begin
            red <= green <= blue <= 4'b1111; // cursor (2,0)
        end
        else if ((hs >= 110 && hs < 130) && (vs >= 215 && vs < 235) && (cursor_x == 0) && (cursor_y == 1)) begin
            red <= green <= blue <= 4'b1111; // cursor (0,1)
        end
        else if ((hs >= 315 && hs < 335) && (vs >= 215 && vs < 235) && (cursor_x == 1) && (cursor_y == 1)) begin
            red <= green <= blue <= 4'b1111; // cursor (1,1)
        end
        else if ((hs >= 520 && hs < 540) && (vs >= 215 && vs < 235) && (cursor_x == 2) && (cursor_y == 1)) begin
            red <= green <= blue <= 4'b1111; // cursor (2,1)
        end
        else if ((hs >= 110 && hs < 130) && (vs >= 420 && vs < 440) && (cursor_x == 0) && (cursor_y == 2)) begin
            red <= green <= blue <= 4'b1111; // cursor (0,2)
        end
        else if ((hs >= 315 && hs < 335) && (vs >= 420 && vs < 440) && (cursor_x == 1) && (cursor_y == 2)) begin
            red <= green <= blue <= 4'b1111; // cursor (1,2)
        end
        else if ((hs >= 520 && hs < 540) && (vs >= 420 && vs < 440) && (cursor_x == 2) && (cursor_y == 2)) begin
            red <= green <= blue <= 4'b1111; // cursor (2,2)
        end

        // ---------- Default: black background ----------
        else begin 
            red   <= 4'b0000;
            green <= 4'b0000;
            blue  <= 4'b0000;
        end
    end

	      		
    //===============================================================
    // VGA Symbol Rendering: Drawing 'X' symbols from ROM
    //===============================================================
    // This block checks if the current VGA pixel lies within one of the
    // 9 Tic-Tac-Toe grid squares. If the square contains an 'X' (rx[i] == 1),
    // then it fetches the appropriate line from X_ROM and displays it.
    // Each square is 100x100 pixels and has a fixed top-left corner.

    // -------- Square [0] - Top-left (0,0) --------
    if ((hs >= 145) && (hs < 245) && (vs >= 45) && (vs < 145) && rx[0]) begin
        addx <= vs - 45;
        if (datax[hs - 145] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [1] - Top-middle (1,0) --------
    else if ((hs >= 350) && (hs < 450) && (vs >= 45) && (vs < 145) && rx[1]) begin
        addx <= vs - 45;
        if (datax[hs - 350] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [2] - Top-right (2,0) --------
    else if ((hs >= 555) && (hs < 655) && (vs >= 45) && (vs < 145) && rx[2]) begin
        addx <= vs - 45;
        if (datax[hs - 555] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [3] - Middle-left (0,1) --------
    else if ((hs >= 145) && (hs < 245) && (vs >= 250) && (vs < 350) && rx[3]) begin
        addx <= vs - 250;
        if (datax[hs - 145] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [4] - Center (1,1) --------
    else if ((hs >= 350) && (hs < 450) && (vs >= 250) && (vs < 350) && rx[4]) begin
        addx <= vs - 250;
        if (datax[hs - 350] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [5] - Middle-right (2,1) --------
    else if ((hs >= 555) && (hs < 655) && (vs >= 250) && (vs < 350) && rx[5]) begin
        addx <= vs - 250;
        if (datax[hs - 555] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [6] - Bottom-left (0,2) --------
    else if ((hs >= 145) && (hs < 245) && (vs >= 455) && (vs < 555) && rx[6]) begin
        addx <= vs - 455;
        if (datax[hs - 145] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [7] - Bottom-middle (1,2) --------
    else if ((hs >= 350) && (hs < 450) && (vs >= 455) && (vs < 555) && rx[7]) begin
        addx <= vs - 455;
        if (datax[hs - 350] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    // -------- Square [8] - Bottom-right (2,2) --------
    else if ((hs >= 555) && (hs < 655) && (vs >= 455) && (vs < 555) && rx[8]) begin
        addx <= vs - 455;
        if (datax[hs - 555] == 0)
            {red, green, blue} <= 12'b0;
        else
            {red, green, blue} <= 12'b111111111111;
    end

    //===============================================================
    // VGA Symbol Rendering: Drawing 'O' symbols from ROM
    //===============================================================
    // For each grid square (0 to 8), this block checks if an 'O' was placed
    // (ro[i] == 1), and if so, reads a line from O_ROM and sets the RGB values
    // according to the ROM pattern.
    // ---------------------------------------------------------------
    // Layout:
    // Square 0: Top-left     (hs 145–245, vs  45–145)
    // Square 1: Top-center   (hs 350–450, vs  45–145)
    // Square 2: Top-right    (hs 555–655, vs  45–145)
    // Square 3: Mid-left     (hs 145–245, vs 250–350)
    // Square 4: Center       (hs 350–450, vs 250–350)
    // Square 5: Mid-right    (hs 555–655, vs 250–350)
    // Square 6: Bot-left     (hs 145–245, vs 455–555)
    // Square 7: Bot-center   (hs 350–450, vs 455–555)
    // Square 8: Bot-right    (hs 555–655, vs 455–555)

    // ------ Square 0 ------
    if ((hs >= 145) && (hs < 245) && (vs >= 45) && (vs < 145) && ro[0]) begin
        addo <= vs - 45;
        {red, green, blue} <= (datao[hs - 145]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 1 ------
    else if ((hs >= 350) && (hs < 450) && (vs >= 45) && (vs < 145) && ro[1]) begin
        addo <= vs - 45;
        {red, green, blue} <= (datao[hs - 350]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 2 ------
    else if ((hs >= 555) && (hs < 655) && (vs >= 45) && (vs < 145) && ro[2]) begin
        addo <= vs - 45;
        {red, green, blue} <= (datao[hs - 555]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 3 ------
    else if ((hs >= 145) && (hs < 245) && (vs >= 250) && (vs < 350) && ro[3]) begin
        addo <= vs - 250;
        {red, green, blue} <= (datao[hs - 145]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 4 ------
    else if ((hs >= 350) && (hs < 450) && (vs >= 250) && (vs < 350) && ro[4]) begin
        addo <= vs - 250;
        {red, green, blue} <= (datao[hs - 350]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 5 ------
    else if ((hs >= 555) && (hs < 655) && (vs >= 250) && (vs < 350) && ro[5]) begin
        addo <= vs - 250;
        {red, green, blue} <= (datao[hs - 555]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 6 ------
    else if ((hs >= 145) && (hs < 245) && (vs >= 455) && (vs < 555) && ro[6]) begin
        addo <= vs - 455;
        {red, green, blue} <= (datao[hs - 145]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 7 ------
    else if ((hs >= 350) && (hs < 450) && (vs >= 455) && (vs < 555) && ro[7]) begin
        addo <= vs - 455;
        {red, green, blue} <= (datao[hs - 350]) ? 12'hFFF : 12'h000;
    end
    // ------ Square 8 ------
    else if ((hs >= 555) && (hs < 655) && (vs >= 455) && (vs < 555) && ro[8]) begin
        addo <= vs - 455;
        {red, green, blue} <= (datao[hs - 555]) ? 12'hFFF : 12'h000;
    end


endmodule