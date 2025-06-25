// ===========================================================
// Hamming Code (15,11) Encoder Module
// -----------------------------------------------------------
// This module implements a Hamming (15,11) encoder.
// It takes 11 serial input bits (`inp`) and encodes them into
// a 15-bit output with 4 parity bits (P1, P2, P4, P8).
//
// ➤ Inputs:
//   - clk : Clock signal
//   - rst : Reset signal
//   - inp : Serial input bit stream (1 bit at a time)
//
// ➤ Output:
//   - out : Serial output of the encoded 15-bit word
//
// ➤ Operation:
//   - Collects 11 input bits into a buffer
//   - Computes parity bits using Hamming logic
//   - Combines data + parity into a 15-bit word
//   - Shifts out the result bit-by-bit on each clock cycle
//
// Designed as part of a university exercise on error correction.
// ===========================================================

module hamming_core (
  input  logic clk,
  input  logic rst,
  input  logic inp,
  output logic out
);

// -----------------------------
// Internal Buffers & Counters
// -----------------------------

// Buffer to hold 11 input bits
logic [10:0] input_buffer;

// Buffer to hold 15-bit Hamming code output
logic [14:0] output_buffer;

// Counter for input bit collection (0 to 11)
logic [3:0] counter;

// Parity bits P1, P2, P4, P8
logic [3:0] parity;

// -----------------------------
// Input Collection & Parity Calculation
// -----------------------------
always_ff @(posedge clk) begin
  if (rst == 1'b1) begin
    input_buffer <= 11'b0;
    counter <= 4'b0;
  end else begin
    // Shift in next input bit from 'inp'
    input_buffer <= {input_buffer[9:0], inp};
    counter <= counter + 1;

    // Once 11 bits are collected, calculate parity and form output
    if (counter == 4'b1011) begin
      // Hamming (15,11) parity calculations
      parity[0] <= input_buffer[0] ^ input_buffer[1] ^ input_buffer[3] ^ input_buffer[4] ^ input_buffer[6] ^ input_buffer[8] ^ input_buffer[10]; // P1
      parity[1] <= input_buffer[0] ^ input_buffer[2] ^ input_buffer[3] ^ input_buffer[5] ^ input_buffer[6] ^ input_buffer[9] ^ input_buffer[10]; // P2
      parity[2] <= input_buffer[1] ^ input_buffer[2] ^ input_buffer[3] ^ input_buffer[7] ^ input_buffer[8] ^ input_buffer[9] ^ input_buffer[10]; // P4
      parity[3] <= input_buffer[4] ^ input_buffer[5] ^ input_buffer[6] ^ input_buffer[7] ^ input_buffer[8] ^ input_buffer[9] ^ input_buffer[10]; // P8

      // Format 15-bit output word with correct parity & data placement
      output_buffer <= {
        parity[0],         // P1 at bit 0
        parity[1],         // P2 at bit 1
        input_buffer[0],   // D1
        parity[2],         // P4 at bit 3
        input_buffer[1],   // D2
        input_buffer[2],   // D3
        input_buffer[3],   // D4
        parity[3],         // P8 at bit 7
        input_buffer[4],   // D5
        input_buffer[5],   // D6
        input_buffer[6],   // D7
        input_buffer[7],   // D8
        input_buffer[8],   // D9
        input_buffer[9],   // D10
        input_buffer[10]   // D11
      };
    end
  end
end

// -----------------------------
// Serial Output Logic
// -----------------------------

logic [3:0] out_counter;

always_ff @(posedge clk) begin
  if (rst == 1'b1) begin
    output_buffer <= 15'b0;
    out_counter <= 4'b0;
  end else begin
    // Once output is ready, send each bit serially
    if (out_counter == 4'b1111) begin
      out <= output_buffer[0];                    // Send LSB
      output_buffer <= {output_buffer[14:1], 1'b0}; // Shift left
      out_counter <= 4'b0000;
    end else begin
      out <= output_buffer[out_counter];          // Send current bit
      out_counter <= out_counter + 1;
    end
  end
end

endmodule
