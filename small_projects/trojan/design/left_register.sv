// Left Elastic Register Module
// ----------------------------------------------------------
// Acts as the sender-side register in an elastic pipeline.
// Receives input data (din_i), stores it in FIFO-style memory,
// and sends it forward based on valid/ready handshaking.
//

module left_register
#(
  parameter int DW_left    = 16,
  parameter int DEPTH_left = 4
)
(
  input  logic                  clk,
  input  logic                  rst,

  // Input channel
  input  logic [DW_left-1:0]    din_i,
  input  logic                  valid_i,
  output logic                  ready_o,

  // Output channel
  output logic [DW_left-1:0]    data_left,
  output logic                  vld_left,
  input  logic                  rdy_left
);

// FIFO memory and pointers
logic [DW_left-1:0] mem_left [0:DEPTH_left-1];
logic [$clog2(DEPTH_left)-1:0] head_left, tail_left;
logic [DEPTH_left:0] status_cnt_left;

// FIFO control signals
wire empty_left = (status_cnt_left == 0);
wire full_left  = (status_cnt_left == DEPTH_left);

assign vld_left  = ~empty_left;   // data valid when FIFO not empty
assign ready_o   = ~full_left;    // ready to receive if not full

// -------------------------------
// PUSH logic (write to FIFO)
// -------------------------------
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    tail_left <= 0;
  end else if (valid_i && ~full_left) begin
    mem_left[tail_left] <= din_i;
    tail_left <= (tail_left == DEPTH_left - 1) ? 0 : tail_left + 1;
  end
end

// -------------------------------
// POP logic (read from FIFO)
// -------------------------------
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    head_left <= 0;
  end else if (vld_left && rdy_left) begin
    head_left <= (head_left == DEPTH_left - 1) ? 0 : head_left + 1;
  end
end

assign data_left = mem_left[head_left];  // output from head of FIFO

// -------------------------------
// FIFO Occupancy Counter
// -------------------------------
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    status_cnt_left <= 0;
  end else begin
    case ({valid_i && ~full_left, vld_left && rdy_left})
      2'b10: status_cnt_left <= status_cnt_left + 1; // push only
      2'b01: status_cnt_left <= status_cnt_left - 1; // pop only
      default: status_cnt_left <= status_cnt_left;   // no change or both
    endcase
  end
end

endmodule
