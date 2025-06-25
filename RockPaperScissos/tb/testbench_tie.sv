// ==========================================
// Testbench: testbench_tie
// Purpose:   Verifies the checkTie module
// ==========================================

`timescale 1ns/1ps

module testbench_tie;

    logic [2:0] inA; 
    logic [2:0] inB;
    logic       Tie;

    // Device Under Test (DUT)
    checkTie dut (
        .inA(inA),
        .inB(inB),
        .Tie(Tie)
    );

    initial begin
        $monitor($time, " inA=%b, inB=%b, Tie=%b", inA, inB, Tie);

        // Waveform dump for GTKWave
        $dumpfile("dump_wave.vcd");
        $dumpvars(1, testbench_tie);

        // Test Cases
        inA = 3'b000; inB = 3'b000; #10;  // Not valid but tie
        inA = 3'b001; inB = 3'b001; #10;  // Tie: scissors
        inA = 3'b010; inB = 3'b010; #10;  // Tie: rock
        inA = 3'b100; inB = 3'b100; #10;  // Tie: paper
        inA = 3'b001; inB = 3'b010; #10;  // Not a tie
        inA = 3'b010; inB = 3'b100; #10;  // Not a tie

        $finish;
    end

endmodule
