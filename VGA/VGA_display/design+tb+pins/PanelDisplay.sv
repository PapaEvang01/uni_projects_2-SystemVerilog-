// ==========================================
// Module: PanelDisplay
// Description: VGA controller that displays 
//              4 colored rectangles on a 
//              800x600 screen @ 72Hz
// Target: Nexys A7 FPGA (100 MHz clock)
// ==========================================

module PanelDisplay (
    input  logic clk,             // 100 MHz input clock
    input  logic rst,             // Asynchronous reset
    output logic hsync,          // Horizontal sync signal
    output logic vsync,          // Vertical sync signal
    output logic [3:0] red,      // 4-bit Red channel
    output logic [3:0] green,    // 4-bit Green channel
    output logic [3:0] blue      // 4-bit Blue channel
);

    // =====================================
    // Clock Divider: 100 MHz → 50 MHz
    // Used as the pixel clock
    // =====================================
    logic pxlClk;

    always_ff @(posedge clk) begin
        if (rst)
            pxlClk <= 1'b1;
        else
            pxlClk <= ~pxlClk;
    end

    // =====================================
    // Pixel Counters: Horizontal (hc) and Vertical (vc)
    // Used to track current pixel position
    // =====================================
    logic [10:0] hc; // horizontal counter (0–1039)
    logic [9:0]  vc; // vertical counter (0–665)

    always_ff @(posedge clk) begin
        if (rst) begin
            hc <= 0;
            vc <= 0;
        end else if (pxlClk) begin
            hc <= hc + 1;

            // End of line: reset horizontal, increment vertical
            if (hc >= 1039) begin
                hc <= 0;
                vc <= vc + 1;

                // End of frame: reset vertical
                if (vc >= 665)
                    vc <= 0;
            end
        end
    end

    // =====================================
    // HSYNC and VSYNC Generation
    // Active low during sync pulse window
    // Timings based on 800x600 @ 72Hz standard
    // =====================================
    assign hsync = (hc >= 856 && hc < 976) ? 1'b0 : 1'b1;  // HSYNC pulse: 120 pixels wide
    assign vsync = (vc >= 637 && vc < 642) ? 1'b0 : 1'b1;  // VSYNC pulse: 5 lines wide

    // =====================================
    // RGB Output: Draw 4 rectangles
    // Each condition lights pixels based on hc/vc position
    // =====================================

    // RED: Top-left and Bottom-right quadrants
    assign red = ((hc >= 100 && hc < 400 && vc < 300) || 
                  (hc >= 400 && hc < 700 && vc >= 300 && vc < 600)) ? 4'b1111 : 4'b0000;

    // GREEN: Top-right and Bottom-right quadrants
    assign green = ((hc >= 400 && hc < 700 && vc < 300) || 
                    (hc >= 400 && hc < 700 && vc >= 300 && vc < 600)) ? 4'b1111 : 4'b0000;

    // BLUE: Bottom-left and Bottom-right quadrants
    assign blue = ((hc >= 100 && hc < 400 && vc >= 300 && vc < 600) || 
                   (hc >= 400 && hc < 700 && vc >= 300 && vc < 600)) ? 4'b1111 : 4'b0000;

endmodule
