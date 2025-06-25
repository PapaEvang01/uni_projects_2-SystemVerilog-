// ==========================================
// Testbench: PanelDisplay_tb
// Purpose:   Simulates VGA output of PanelDisplay
//            module and logs one full frame
// ==========================================

module PanelDisplay_tb;

    // Set to 0 to disable VGA output logging
    parameter logic VGA_LOG = 1;

    // ==========================================
    // TESTBENCH VARIABLES
    // ==========================================
    integer fileout;
    integer frame_cnt = 0;
    logic write_frame;
    string s;

    // ==========================================
    // DUT SIGNALS
    // ==========================================
    logic clk;
    logic rst;
    logic       vga_hsync;
    logic       vga_vsync;
    logic [3:0] vga_red;
    logic [3:0] vga_green;
    logic [3:0] vga_blue;

    // ==========================================
    // DUT INSTANTIATION
    // ==========================================
    PanelDisplay vga (
        .clk(clk), 
        .rst(rst), 
        .hsync(vga_hsync), 
        .vsync(vga_vsync),
        .red(vga_red), 
        .green(vga_green),
        .blue(vga_blue)
    );

    // ==========================================
    // 100 MHz Clock Generation (Period: 10ns)
    // ==========================================
    always begin
        clk = 0;
        #5ns;
        clk = 1;
        #5ns;
    end

    // ==========================================
    // Main Test Sequence
    // ==========================================
    initial begin
        $timeformat(-9, 0, " ns", 6);
        $display("Starting simulation...\n");
        RESET();
        $display("Reset complete, writing VGA frame...\n");
        WRITE_FRAME();
        $stop;
    end

    // ==========================================
    // Reset Task
    // ==========================================
    task RESET();
        rst <= 1;
        repeat(2) @(posedge clk);
        rst <= 0;
        repeat(10) @(posedge clk);
    endtask

    // ==========================================
    // Trigger frame write
    // ==========================================
    task WRITE_FRAME();
        write_frame <= 1;
        @(negedge write_frame);
        @(posedge clk);
    endtask

    // ==========================================
    // Log one full VGA frame when vsync falls
    // Frame length: 1385280 clocks = 1040 x 666
    // ==========================================
    always @(negedge vga_vsync) begin
        if (write_frame) begin
            if (VGA_LOG == 1) begin
                s.itoa(frame_cnt);	
                fileout = $fopen({"vga_frame_", s, ".txt"});

                repeat (1385280) begin
                    @(posedge clk);
                    $fdisplay(fileout, "%t: %b %b %b %b %b", 
                              $time, vga_hsync, vga_vsync, vga_red, vga_green, vga_blue);
                end

                @(negedge clk); 
                $fclose(fileout);
                frame_cnt++;
            end else begin
                repeat (1385280) @(posedge clk);
                @(negedge clk);
            end

            write_frame <= 0;
        end
    end

endmodule
