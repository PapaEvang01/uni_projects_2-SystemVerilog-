// ==========================================
// Testbench: testbench_valid
// Purpose:   Verifies the validIO module
// ==========================================

`timescale 1ns/1ps

module testbench_valid;

    logic [2:0] inA; 
    logic [2:0] inB;
    logic       valid;

    // Device Under Test (DUT)
    validIO dut (
        .inA(inA),
        .inB(inB),
        .valid(valid)
    );

    initial begin
        $monitor($time, " inA=%b, inB=%b, valid=%b", inA, inB, valid);

        // Waveform dump for GTKWave
        $dumpfile("dump_wave.vcd");
        $dumpvars(1, testbench_valid);

        // Valid inputs (one-hot each)
        inA = 3'b001; inB = 3'b100; #10; // Valid: Scissors vs Paper
        inA = 3'b010; inB = 3'b001; #10; // Valid: Rock vs Scissors
        inA = 3'b100; inB = 3'b010; #10; // Valid: Paper vs Rock

        // Invalid A inputs
        inA = 3'b000; inB = 3'b001; #10; // Invalid: A didn't play
        inA = 3'b101; inB = 3'b001; #10; // Invalid: A played two options
        inA = 3'b111; inB = 3'b001; #10; // Invalid: A played all

        // Invalid B inputs
        inA = 3'b001; inB = 3'b000; #10; // Invalid: B didn't play
        inA = 3'b001; inB = 3'b011; #10; // Invalid: B played two options
        inA = 3'b001; inB = 3'b111; #10; // Invalid: B played all

        $finish;
    end

endmodule
