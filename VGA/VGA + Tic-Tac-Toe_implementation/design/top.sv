/*
===============================================================
🕹️ Tic-Tac-Toe VGA Game (SystemVerilog - FPGA Implementation)
===============================================================

Overview:
---------
This top-level module implements a full-featured Tic-Tac-Toe (X-O) game 
on an FPGA with VGA display output. It combines digital logic, 
edge-detected push button controls, and VGA signal generation to enable 
real-time gameplay between two players using physical buttons.

Core Features:
--------------
- Real-time VGA graphics using 800x600 resolution @ 72Hz refresh rate
- Cursor-based movement controlled by directional buttons
- 'Play' button to mark cells with X or O (using player turn logic)
- Internal game state tracking using bit vectors for X and O moves
- Win and tie detection logic for rows, columns, and diagonals
- ROM-based symbol rendering: X_ROM and O_ROM display graphics
- Edge detector modules eliminate button bouncing effects
- Uses pixel counters and synchronization signals for VGA timing

Inputs:
-------
- `clk`        : 100 MHz input clock
- `rst`        : Asynchronous reset signal
- `button_*`   : Five input buttons (up, down, left, right, play)

Outputs:
--------
- `winA`, `winB`, `tie` : Game outcome indicators
- `red`, `green`, `blue`: VGA color signals (4 bits per channel)
- `hsync`, `vsync`      : VGA horizontal and vertical sync pulses

Dependencies:
-------------
- edge_detector.sv   : Debounces button presses with rising edge detection
- X_ROM.sv / O_ROM.sv: Memory modules storing X and O character bitmaps
- Constraints file   : Pin mapping for VGA, clock, and push buttons

Target Board:
-------------
- Designed for use with a Nexys A7 FPGA development board

*/


module top(
    input logic clk,          // 100 MHz system clock
    input logic rst,          // Asynchronous reset

    // Player input buttons for navigation and playing a move
    input logic button_left,
    input logic button_right,
    input logic button_up,
    input logic button_down,
    input logic button_play,

    // Game outcome indicators
    output logic winA,        // 1 if Player A (X) wins
    output logic winB,        // 1 if Player B (O) wins
    output logic tie,         // 1 if game ends in a tie

    // VGA output signals
    output logic [3:0] red,   // Red channel (4-bit intensity)
    output logic [3:0] green, // Green channel
    output logic [3:0] blue,  // Blue channel
    output logic hsync,       // VGA horizontal sync pulse
    output logic vsync        // VGA vertical sync pulse
);

// ========== Game State Variables ==========

// Board state: each bit in rx/ro indicates one square on the 3x3 board
logic [8:0] rx;              // 9-bit vector representing X positions
logic [8:0] ro;              // 9-bit vector representing O positions

// Cursor position on the 3x3 grid (values from 0 to 2)
logic [1:0] cursor_x;
logic [1:0] cursor_y;

logic player_id;            // 0 = Player X's turn, 1 = Player O's turn
logic game_over;            // Becomes 1 once the game ends
logic [8:0] selected_sqr;   // Helper vector for tracking selected square (not core board state)

// ========== Win Detection Helper Variables ==========

logic [2:0] row_win_X, col_win_X; // X player: win per row/col
logic [2:0] row_win_O, col_win_O; // O player: win per row/col
logic [1:0] diag_win_X, diag_win_O; // Win in 2 diagonals

// Aggregated flags to indicate any win on rows, cols, or diagonals
logic win_in_rows_X, win_in_cols_X, win_in_diags_X;
logic win_in_rows_O, win_in_cols_O, win_in_diags_O;

// ========== VGA Symbol ROM Interface ==========

// X_ROM and O_ROM store 100x100 bitmap fonts for X and O
logic [6:0] addx;           // Vertical pixel index for X symbol
logic [99:0] datax;         // 100-bit horizontal bitmap for current line of X

logic [6:0] addo;           // Vertical pixel index for O symbol
logic [99:0] datao;         // 100-bit horizontal bitmap for current line of O

// Instantiate ROMs for symbol display
O_ROM DUT6 (.address(addo), .data(datao));
X_ROM DUT7 (.address(addx), .data(datax));

// ========== Edge Detector Connections ==========

// Convert button press signals to single-pulse strobes on rising edges
edge_detector DUT1(.clk(clk), .rst(rst), .in(button_left),  .out(new_button_left));
edge_detector DUT2(.clk(clk), .rst(rst), .in(button_right), .out(new_button_right));
edge_detector DUT3(.clk(clk), .rst(rst), .in(button_up),    .out(new_button_up));
edge_detector DUT4(.clk(clk), .rst(rst), .in(button_down),  .out(new_button_down));
edge_detector DUT5(.clk(clk), .rst(rst), .in(button_play),  .out(new_button_play));



// ========================================
// Game Control Logic (cursor and selection)
// ========================================
always_ff @ (posedge clk) begin 

    // Reset the cursor position to top-left when reset is activated
	if (rst) begin 
		cursor_x = 0;
		cursor_y = 0;
	end 

    // Only allow movement and selection if the game is still in progress
	if (!game_over) begin 

        // ================================
        // Cursor Movement (wrap around 0–2)
        // ================================

		if (new_button_up) begin
			if (cursor_y > 0)
				cursor_y <= cursor_y - 1;   // Move up
			else
				cursor_y <= 2;              // Wrap to bottom
		end

		if (new_button_down) begin
			if (cursor_y < 2)
				cursor_y <= cursor_y + 1;   // Move down
			else
				cursor_y <= 0;              // Wrap to top
		end

		if (new_button_right) begin
			if (cursor_x < 2)
				cursor_x <= cursor_x + 1;   // Move right
			else
				cursor_x <= 0;              // Wrap to left
		end

		if (new_button_left) begin
			if (cursor_x > 0)
				cursor_x <= cursor_x - 1;   // Move left
			else
				cursor_x <= 2;              // Wrap to right
		end

        // ===========================
        // Square Selection on 'Play'
        // ===========================
		if (new_button_play == 1) begin 
			// Compute which square is currently highlighted by the cursor,
			// and set the corresponding bit in 'selected_sqr' to 1

			if (cursor_x == 0 && cursor_y == 0)
				selected_sqr[0] <= 1;
			if (cursor_x == 1 && cursor_y == 0)
				selected_sqr[1] <= 1;
			if (cursor_x == 2 && cursor_y == 0)
				selected_sqr[2] <= 1;

			if (cursor_x == 0 && cursor_y == 1)
				selected_sqr[3] <= 1;
			if (cursor_x == 1 && cursor_y == 1)
				selected_sqr[4] <= 1;
			if (cursor_x == 2 && cursor_y == 1)
				selected_sqr[5] <= 1;

			if (cursor_x == 0 && cursor_y == 2)
				selected_sqr[6] <= 1;
			if (cursor_x == 1 && cursor_y == 2)
				selected_sqr[7] <= 1;
			if (cursor_x == 2 && cursor_y == 2)
				selected_sqr[8] <= 1;
		end
	end
end

    
// =======================================================
// Game Logic: Player Moves and Square Updates
// Handles alternating turns for players X and O
// Updates board state based on cursor position and play button
// =======================================================
always_ff @(posedge clk) begin 

    // Reset condition: clear the board and reset player turn to X
	if (rst) begin 
		ro <= 9'b000000000;       // Clear O's positions
		rx <= 9'b000000000;       // Clear X's positions
		player_id <= 0;           // X starts (0 = X, 1 = O)
	end 

    // If game is not over, allow player actions
	if (!game_over) begin 

        // ====================================================
        // Y = 0 → First row (top of the board)
        // ====================================================
		if (cursor_y == 0) begin

            // (0,0) = axis 0
			if (cursor_x == 0 && new_button_play == 1) begin 
				if (!ro[0] && !rx[0]) begin // square is free
					if (player_id == 0) begin
						rx[0] <= 1;      // X plays
						player_id <= 1; // Switch to O
					end 
					else begin
						ro[0] <= 1;      // O plays
						player_id <= 0; // Switch to X
					end 
				end
			end 

            // (1,0) = axis 1
			if (cursor_x == 1 && new_button_play == 1) begin 
				if (!ro[1] && !rx[1]) begin
					if (player_id == 0) begin
						rx[1] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[1] <= 1;
						player_id <= 0;
					end 
				end
			end

            // (2,0) = axis 2
			if (cursor_x == 2 && new_button_play == 1) begin 
				if (!ro[2] && !rx[2]) begin
					if (player_id == 0) begin
						rx[2] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[2] <= 1;
						player_id <= 0;
					end 
				end
			end 
		end 

        // ====================================================
        // Y = 1 → Second row (middle row)
        // ====================================================
		if (cursor_y == 1) begin

            // (0,1) = axis 3
			if (cursor_x == 0 && new_button_play == 1) begin 
				if (!ro[3] && !rx[3]) begin
					if (player_id == 0) begin
						rx[3] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[3] <= 1;
						player_id <= 0;
					end 
				end
			end

            // (1,1) = axis 4
			if (cursor_x == 1 && new_button_play == 1) begin 
				if (!ro[4] && !rx[4]) begin
					if (player_id == 0) begin
						rx[4] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[4] <= 1;
						player_id <= 0;
					end 
				end
			end

            // (2,1) = axis 5
			if (cursor_x == 2 && new_button_play == 1) begin 
				if (!ro[5] && !rx[5]) begin
					if (player_id == 0) begin
						rx[5] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[5] <= 1;
						player_id <= 0;
					end 
				end
			end 
		end 

        // ====================================================
        // Y = 2 → Third row (bottom of the board)
        // ====================================================
		if (cursor_y == 2) begin

            // (0,2) = axis 6
			if (cursor_x == 0 && new_button_play == 1) begin 
				if (!ro[6] && !rx[6]) begin
					if (player_id == 0) begin
						rx[6] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[6] <= 1;
						player_id <= 0;
					end 
				end
			end

            // (1,2) = axis 7
			if (cursor_x == 1 && new_button_play == 1) begin 
				if (!ro[7] && !rx[7]) begin
					if (player_id == 0) begin
						rx[7] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[7] <= 1;
						player_id <= 0;
					end 
				end
			end

            // (2,2) = axis 8
			if (cursor_x == 2 && new_button_play == 1) begin 
				if (!ro[8] && !rx[8]) begin
					if (player_id == 0) begin
						rx[8] <= 1;
						player_id <= 1;
					end 
					else begin
						ro[8] <= 1;
						player_id <= 0;
					end 
				end
			end 
		end 
	end 
end


// ==========================================================
// Game State Evaluation Block: Detects Wins or Ties
// ==========================================================
always_ff @(posedge clk) begin 
    if (rst) begin 
        // Reset all win/tie flags and game state
        winA      <= 0;
        winB      <= 0;
        tie       <= 0;
        game_over <= 0;
    end

    // ====================
    // Check Winning Conditions for Player X
    // ====================

    // Check all 3 rows for X (horizontal win)
    row_win_X[0] <= rx[0] & rx[1] & rx[2]; // Top row
    row_win_X[1] <= rx[3] & rx[4] & rx[5]; // Middle row
    row_win_X[2] <= rx[6] & rx[7] & rx[8]; // Bottom row
    win_in_rows_X <= |row_win_X;

    // Check all 3 columns for X (vertical win)
    col_win_X[0] <= rx[0] & rx[3] & rx[6]; // Left column
    col_win_X[1] <= rx[1] & rx[4] & rx[7]; // Center column
    col_win_X[2] <= rx[2] & rx[5] & rx[8]; // Right column
    win_in_cols_X <= |col_win_X;

    // Check both diagonals for X
    diag_win_X[0] <= rx[0] & rx[4] & rx[8]; // Top-left to bottom-right
    diag_win_X[1] <= rx[2] & rx[4] & rx[6]; // Top-right to bottom-left
    win_in_diags_X <= |diag_win_X;

    // ====================
    // Check Winning Conditions for Player O
    // ====================

    // Check all 3 rows for O
    row_win_O[0] <= ro[0] & ro[1] & ro[2];
    row_win_O[1] <= ro[3] & ro[4] & ro[5];
    row_win_O[2] <= ro[6] & ro[7] & ro[8];
    win_in_rows_O <= |row_win_O;

    // Check all 3 columns for O
    col_win_O[0] <= ro[0] & ro[3] & ro[6];
    col_win_O[1] <= ro[1] & ro[4] & ro[7];
    col_win_O[2] <= ro[2] & ro[5] & ro[8];
    win_in_cols_O <= |col_win_O;

    // Check both diagonals for O
    diag_win_O[0] <= ro[0] & ro[4] & ro[8];
    diag_win_O[1] <= ro[2] & ro[4] & ro[6];
    win_in_diags_O <= |diag_win_O;

    // ====================
    // Decide Game Outcome
    // ====================

    // Player X wins
    if (win_in_rows_X || win_in_cols_X || win_in_diags_X) begin
        winA      <= 1;
        game_over <= 1;
    end 

    // Player O wins
    else if (win_in_rows_O || win_in_cols_O || win_in_diags_O) begin 
        winB      <= 1;
        game_over <= 1;
    end 

    // No winner, but all squares filled → Tie
    else if (winA == 0 && winB == 0 &&
        ((rx[0] | ro[0]) & (rx[1] | ro[1]) & (rx[2] | ro[2]) &
         (rx[3] | ro[3]) & (rx[4] | ro[4]) & (rx[5] | ro[5]) &
         (rx[6] | ro[6]) & (rx[7] | ro[7]) & (rx[8] | ro[8]))) begin
        
        tie       <= 1;
        game_over <= 1;
    end
end


// ============================================================
// VGA Timing Generation
// Handles pixel clock division, horizontal and vertical counters,
// and generation of HSYNC / VSYNC signals for 800x600 @ 72Hz.
// ============================================================

logic pxlClk;

// Pixel clock divider: Convert 100MHz input clock to 50MHz pixel clock
always_ff @(posedge clk) begin
  if (rst)
    pxlClk <= 1'b1;  // Initialize to known state
  else
    pxlClk <= ~pxlClk;  // Toggle every cycle => divide by 2
end

// Horizontal (hs) and vertical (vs) pixel counters
logic [10:0] hs;  // Horizontal scan counter (0–1039)
logic [9:0]  vs;  // Vertical scan counter (0–665)

always_ff @(posedge clk) begin
  if (rst) begin
    hs <= 0;
    vs <= 0;
  end else begin
    if (pxlClk) begin
      hs <= hs + 1;

      // End of line reached
      if (hs >= 1039) begin
        hs <= 0;
        vs <= vs + 1;

        // End of frame reached
        if (vs >= 665)
          vs <= 0;
      end
    end
  end
end

// HSYNC and VSYNC signal generation (active low)
// Based on VGA timing spec for 800x600 @ 72Hz:
//   HSYNC pulse:   between pixel 856 and 975 (120 pixels)
//   VSYNC pulse:   between line 637 and 642  (6 lines)

assign hsync = (hs >= 856 && hs < 976) ? 1'b0 : 1'b1;
assign vsync = (vs >= 637 && vs < 643) ? 1'b0 : 1'b1;

  
// ==========================================================
// VGA Pixel Coloring Block (inside always_ff @(posedge clk))
// - Draws white grid lines between the squares
// - Highlights the selected square with a white cursor
// ==========================================================

always_ff @(posedge clk) begin
  // --------------------------------------------------------
  // Draw grid lines (horizontal and vertical white bands)
  // - Vertical dividers between squares
  // - Horizontal dividers between rows
  // --------------------------------------------------------
  if (
      (hs >= 289 && hs < 304) ||  // Vertical line 1
      (hs >= 494 && hs < 509) ||  // Vertical line 2
      (vs >= 189 && vs < 204 && hs >= 100 && hs < 700) ||  // Horizontal line 1
      (vs >= 394 && vs < 409 && hs >= 100 && hs < 700)     // Horizontal line 2
     ) begin
    red   <= 4'b1111;
    green <= 4'b1111;
    blue  <= 4'b1111;
  end else begin
    // Default background (black)
    red   <= 4'b0000;
    green <= 4'b0000;
    blue  <= 4'b0000;
  end

  // --------------------------------------------------------
  // Cursor Highlight (White Rectangle)
  // Shows current player selection on a 3x3 grid
  // Based on `cursor_x` and `cursor_y` position
  // --------------------------------------------------------

  // Top row (y = 0)
  if ((cursor_y == 0) && (
      (cursor_x == 0 && hs >= 110 && hs < 130 && vs >= 10  && vs < 30) ||
      (cursor_x == 1 && hs >= 315 && hs < 335 && vs >= 10  && vs < 30) ||
      (cursor_x == 2 && hs >= 520 && hs < 540 && vs >= 10  && vs < 30)
     )) begin
    red <= 4'b1111; green <= 4'b1111; blue <= 4'b1111;
  end

  // Middle row (y = 1)
  else if ((cursor_y == 1) && (
      (cursor_x == 0 && hs >= 110 && hs < 130 && vs >= 215 && vs < 235) ||
      (cursor_x == 1 && hs >= 315 && hs < 335 && vs >= 215 && vs < 235) ||
      (cursor_x == 2 && hs >= 520 && hs < 540 && vs >= 215 && vs < 235)
     )) begin
    red <= 4'b1111; green <= 4'b1111; blue <= 4'b1111;
  end

  // Bottom row (y = 2)
  else if ((cursor_y == 2) && (
      (cursor_x == 0 && hs >= 110 && hs < 130 && vs >= 420 && vs < 440) ||
      (cursor_x == 1 && hs >= 315 && hs < 335 && vs >= 420 && vs < 440) ||
      (cursor_x == 2 && hs >= 520 && hs < 540 && vs >= 420 && vs < 440)
     )) begin
    red <= 4'b1111; green <= 4'b1111; blue <= 4'b1111;
  end
end


	      		
// =======================================
// VGA Rendering for X Symbols on Grid
// =======================================
// For each 3x3 square, if it's marked by player X (rx[i] == 1),
// we fetch the correct line from the ROM (X_ROM) and use it
// to draw the X pixel-by-pixel.

// Each square is 100x100 pixels.
// ROM address is set by the vertical coordinate (vs - offset).
// The horizontal pixel (hs - offset) is used to index into the ROM's data word.

//// Square 0 (Top-left)
if ((hs >= 145) && (hs < 245) && (vs >= 45) && (vs < 145) && rx[0]) begin
    addx <= vs - 45;
    if (datax[hs - 145] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 1 (Top-center)
if ((hs >= 350) && (hs < 450) && (vs >= 45) && (vs < 145) && rx[1]) begin
    addx <= vs - 45;
    if (datax[hs - 350] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 2 (Top-right)
if ((hs >= 555) && (hs < 655) && (vs >= 45) && (vs < 145) && rx[2]) begin
    addx <= vs - 45;
    if (datax[hs - 555] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 3 (Middle-left)
if ((hs >= 145) && (hs < 245) && (vs >= 250) && (vs < 350) && rx[3]) begin
    addx <= vs - 250;
    if (datax[hs - 145] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 4 (Middle-center)
if ((hs >= 350) && (hs < 450) && (vs >= 250) && (vs < 350) && rx[4]) begin
    addx <= vs - 250;
    if (datax[hs - 350] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 5 (Middle-right)
if ((hs >= 555) && (hs < 655) && (vs >= 250) && (vs < 350) && rx[5]) begin
    addx <= vs - 250;
    if (datax[hs - 555] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 6 (Bottom-left)
if ((hs >= 145) && (hs < 245) && (vs >= 455) && (vs < 555) && rx[6]) begin
    addx <= vs - 455;
    if (datax[hs - 145] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 7 (Bottom-center)
if ((hs >= 350) && (hs < 450) && (vs >= 455) && (vs < 555) && rx[7]) begin
    addx <= vs - 455;
    if (datax[hs - 350] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end

//// Square 8 (Bottom-right)
if ((hs >= 555) && (hs < 655) && (vs >= 455) && (vs < 555) && rx[8]) begin
    addx <= vs - 455;
    if (datax[hs - 555] == 1) {red, green, blue} <= 12'hFFF;
    else                      {red, green, blue} <= 12'h000;
end




    //////==============================================
    ////// VGA Rendering for O Symbols on Grid
    //////==============================================
    // Similar to the X rendering, this block draws O symbols
    // from the O_ROM memory. Each square is 100x100 pixels.
    // If a square is marked by player O (ro[i] == 1), we:
    // 1. Set the ROM address based on vertical pixel (vs - offset)
    // 2. Use the horizontal pixel (hs - offset) to check the bit
    // 3. If ROM bit is 1 => draw white pixel (O shape)
    //    Else => draw black background

    // Square 0 (Top-left)
    if ((hs >= 145) && (hs < 245) && (vs >= 45) && (vs < 145) && ro[0]) begin
        addo <= vs - 45;
        {red, green, blue} <= datao[hs - 145] ? 12'hFFF : 12'h000;
    end

    // Square 1 (Top-center)
    if ((hs >= 350) && (hs < 450) && (vs >= 45) && (vs < 145) && ro[1]) begin
        addo <= vs - 45;
        {red, green, blue} <= datao[hs - 350] ? 12'hFFF : 12'h000;
    end

    // Square 2 (Top-right)
    if ((hs >= 555) && (hs < 655) && (vs >= 45) && (vs < 145) && ro[2]) begin
        addo <= vs - 45;
        {red, green, blue} <= datao[hs - 555] ? 12'hFFF : 12'h000;
    end

    // Square 3 (Middle-left)
    if ((hs >= 145) && (hs < 245) && (vs >= 250) && (vs < 350) && ro[3]) begin
        addo <= vs - 250;
        {red, green, blue} <= datao[hs - 145] ? 12'hFFF : 12'h000;
    end

    // Square 4 (Middle-center)
    if ((hs >= 350) && (hs < 450) && (vs >= 250) && (vs < 350) && ro[4]) begin
        addo <= vs - 250;
        {red, green, blue} <= datao[hs - 350] ? 12'hFFF : 12'h000;
    end

    // Square 5 (Middle-right)
    if ((hs >= 555) && (hs < 655) && (vs >= 250) && (vs < 350) && ro[5]) begin
        addo <= vs - 250;
        {red, green, blue} <= datao[hs - 555] ? 12'hFFF : 12'h000;
    end

    // Square 6 (Bottom-left)
    if ((hs >= 145) && (hs < 245) && (vs >= 455) && (vs < 555) && ro[6]) begin
        addo <= vs - 455;
        {red, green, blue} <= datao[hs - 145] ? 12'hFFF : 12'h000;
    end

    // Square 7 (Bottom-center)
    if ((hs >= 350) && (hs < 450) && (vs >= 455) && (vs < 555) && ro[7]) begin
        addo <= vs - 455;
        {red, green, blue} <= datao[hs - 350] ? 12'hFFF : 12'h000;
    end

    // Square 8 (Bottom-right)
    if ((hs >= 555) && (hs < 655) && (vs >= 455) && (vs < 555) && ro[8]) begin
        addo <= vs - 455;
        {red, green, blue} <= datao[hs - 555] ? 12'hFFF : 12'h000;
    end

endmodule