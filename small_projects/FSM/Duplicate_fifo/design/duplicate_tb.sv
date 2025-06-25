// Testbench for duplicate_duth module

module duplicate_tb;

  // Parameters for Data Width and FIFO Depth
  parameter DW = 16;
  parameter DEPTH = 4;

  // Signals
  logic clk, rst;
  logic push, pop, full, empty;
  logic [DW-1:0] wd, rd;

  // Generate a 10ns period clock
  always begin
    clk = 1;
    #5ns;
    clk = 0;
    #5ns;
  end

  // Instantiate the DUT (Device Under Test)
  duplicate_duth 
  #(
    .DW(DW),
    .DEPTH(DEPTH)
  ) DUT (
    .clk(clk),
    .rst(rst),
    .push(push),
    .write_data(wd),
    .full(full),
    .pop(pop),
    .read_data(rd),
    .empty(empty)
  );

  // Simulation sequence
  initial begin
    $display("Starting Simulation");
    push <= 0;
    pop  <= 0;
    rst  <= 0;
    wd   <= 0;

    // Reset pulse
    @(posedge clk); 
    rst <= 1;
    @(posedge clk);
    rst <= 0;
    @(posedge clk);

    // ===== DEMO SEQUENCE USING TASKS =====
    PUSH(1);
    PUSH(2);
    PUSH(3);
    PUSH(4);
    PUSH(5); // This will be ignored if FIFO is full
    repeat(5) begin
      POP();
    end
    PUSH(5); // Additional push

    // ===== MANUAL SEQUENCE WITH INLINE CONTROL =====
    push <= 1; wd <= 7;  @(posedge clk);
    wd <= 14;            @(posedge clk);
    wd <= 4;             @(posedge clk);
    pop <= 1;  // Start reading

    // Read values while pushing simultaneously
    $strobe("Read data -> %d", rd); @(posedge clk);
    wd <= 13; $strobe("Read data -> %d", rd); @(posedge clk);
    wd <= 25; $strobe("Read data -> %d", rd); @(posedge clk);
    wd <= 32; $strobe("Read data -> %d", rd); @(posedge clk);
    wd <= 9;  $strobe("Read data -> %d", rd); @(posedge clk);

    // Stop pop and try to overflow
    pop <= 0;
    wd <= 21; @(posedge clk); // Overflow test
    wd <= 22; @(posedge clk);
    wd <= 23; @(posedge clk);
    wd <= 24;

    // Resume popping
    pop <= 1;
    @(posedge clk); $strobe("Read data -> %d", rd);
    wd <= 51;

    @(posedge clk); $strobe("Read data -> %d", rd);
    push <= 0; wd <= 21; // Push inactive

    @(posedge clk); $strobe("Read data -> %d", rd);
    wd <= 20;

    // Continue reading
    @(posedge clk); $strobe("Read data -> %d", rd);
    @(posedge clk); $strobe("Read data -> %d", rd);
    @(posedge clk); $strobe("Read data -> %d", rd);
    @(posedge clk); $strobe("Read data -> %d", rd);

    // FIFO now empty
    pop <= 0;
    @(posedge clk);

    $display("Simulation Finished");
    $stop();
  end

  // ===== TASK DEFINITIONS =====

  // Task to push a value into FIFO
  task PUSH(input [DW-1:0] X); 
    begin
      push <= 1;
      wd <= X;
      @(posedge clk);
      $strobe("@%0t: Fifo values are: %d, %d, %d, %d", $time, DUT.mem[0], DUT.mem[1], DUT.mem[2], DUT.mem[3]);
      push <= 0;
      @(posedge clk);
    end
  endtask

  // Task to pop a value from FIFO
  task POP(); 
    begin
      pop <= 1;
      $strobe("@%0t: Read data -> %d", $time, rd);
      @(posedge clk);
      pop <= 0;
      @(posedge clk);
    end
  endtask

endmodule
