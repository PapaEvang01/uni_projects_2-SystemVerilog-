// ==========================================
// Testbench: testbench_winA
// Purpose:   Verifies the winnerA module
// ==========================================

`timescale 1ns/1ps

module testbench_winA;

    logic [2:0] inA; 
    logic [2:0] inB;
    logic       winA;

    // Device Under Test (DUT)
    winnerA dut (
        .inA(inA),
        .inB(inB),
        .winA(winA)
    );

    initial begin
        $monitor($time, " inA=%b, inB=%b, winA=%b", inA, inB, winA);

        // Waveform dump for GTKWave
        $dumpfile("dump_wave.vcd");
        $dumpvars(1, testbench_winA);

        // Test Cases
        inA = 3'b001; inB = 3'b100; #10; // A: Scissors beats B: Paper → winA = 1
        inA = 3'b010; inB = 3'b001; #10; // A: Rock beats B: Scissors → winA = 1
        inA = 3'b100; inB = 3'b010; #10; // A: Paper beats B: Rock → winA = 1

        inA = 3'b100; inB = 3'b001; #10; // A: Paper vs Scissors → winA = 0
        inA = 3'b010; inB = 3'b100; #10; // A: Rock vs Paper → winA = 0
        inA = 3'b001; inB = 3'b010; #10; // A: Scissors vs Rock → winA = 0

        $finish;
    end

endmodule
