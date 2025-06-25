// Right Elastic Register Module
// ---------------------------------------
// Stores data in a FIFO-style buffer and allows data transfer based on
// valid/ready handshaking. Acts as the receiver-side register.
//


module right_register
#(
  parameter int DW_right    = 16,
  parameter int DEPTH_right = 4
)
(
  input  logic                  clk,
  input  logic                  rst,

  // Input channel
  input  logic [DW_right-1:0]   data_right,
  input  logic                  vld_right,
  output logic                  rdy_right,

  // Output channel
  output logic [DW_right-1:0]   dout_o,
  output logic                  valid_o,
  input  logic                  ready_i
);

// Internal memory and pointers
logic [DW_right-1:0] mem_right [0:DEPTH_right-1];
logic [$clog2(DEPTH_right)-1:0] head_right, tail_right;
logic [DEPTH_right:0] status_cnt_right;

wire empty_right = (status_cnt_right == 0);
wire full_right  = (status_cnt_right == DEPTH_right);

// Output valid if buffer is not empty
assign valid_o   = ~empty_right;
// We are ready to accept data if not full
assign rdy_right = ~full_right;

// Push (write to FIFO)
always_ff @(posedge clk) begin
  if (rst) begin
    tail_right <= 0;
  end else if (vld_right && ~full_right) begin
    mem_right[tail_right] <= data_right;
    tail_right <= (tail_right == DEPTH_right-1) ? 0 : tail_right + 1;
  end
end

// Pop (read from FIFO)
always_ff @(posedge clk) begin
  if (rst) begin
    head_right <= 0;
  end else if (valid_o && ready_i) begin
    head_right <= (head_right == DEPTH_right-1) ? 0 : head_right + 1;
  end
end

assign dout_o = mem_right[head_right];

// FIFO counter for empty/full logic
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    status_cnt_right <= 0;
  end else begin
    case ({vld_right && ~full_right, valid_o && ready_i})
      2'b10: status_cnt_right <= status_cnt_right + 1; // push only
      2'b01: status_cnt_right <= status_cnt_right - 1; // pop only
      default: status_cnt_right <= status_cnt_right;   // no change or simultaneous push/pop
    endcase
  end
end

endmodule
