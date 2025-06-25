// ====================================================
// FSM: Server Resource Controller (homework3.sv)
// Description:
// Controls student connections to a shared server.
// Allows a maximum of 3 students to be connected.
// ----------------------------------------------------
// Inputs:
//   - clk  : system clock
//   - rst  : reset signal (async), resets FSM to S0
//   - in[1:0]:
//       in[0] = 1 → A student tries to connect
//       in[1] = 1 → A student disconnects
// Output:
//   - out : logic high (1) if new connections are allowed
//           logic low (0) if server is full (3 students)
// ====================================================

module homework3(
  input  logic clk,
  input  logic rst,
  input  logic [1:0] in,
  output logic out
);

  // FSM state encoding: S0 = 0 connected, S1 = 1, S2 = 2, S3 = 3 students
  typedef enum logic [1:0] {S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11} fsm_state;
  fsm_state state;

  // State transition logic
  always_ff @(posedge clk) begin
    if (rst)
      state <= S0;  // Reset: no students connected
    else begin
      case(state)
        S0: begin
          if (in[0]) state <= S1;  // 1 student connects
        end
        S1: begin
          if (in == 2'b10) state <= S0;  // 1 student disconnects
          else if (in == 2'b01) state <= S2;  // another connects
        end
        S2: begin
          if (in == 2'b10) state <= S1;  // 1 disconnects
          else if (in == 2'b01) state <= S3;  // another connects (3 total)
        end
        S3: begin
          if (in == 2'b10) state <= S2;  // 1 disconnects
        end
      endcase
    end
  end

  // Output logic: allow connections unless at S3
  assign out = ~(state == S3);

endmodule
