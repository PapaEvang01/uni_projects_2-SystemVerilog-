
// Duplicate FIFO module: each data element must be read TWICE before being removed from the queue

module duplicate_duth
#(
    parameter int DW    = 16,  // Data width (bits)
    parameter int DEPTH = 4    // FIFO depth
)
(
    input  logic            clk,
    input  logic            rst,

    // Input channel
    input  logic[DW-1:0]    write_data, // Data to be written into FIFO
    input  logic            push,       // Write enable signal
    output logic            full,       // FIFO full flag

    // Output channel
    output logic[DW-1:0]    read_data,  // Data to be read from FIFO
    output logic            empty,      // FIFO empty flag
    input  logic            pop         // Read enable signal
);

    // Internal memory array: DEPTH rows of DW-bit data
    logic[DEPTH-1:0][DW-1:0]    mem;

    // Circular buffer pointers for write and read operations
    logic[DEPTH-1:0]            tail;
    logic[DEPTH-1:0]            head;

    // One-hot encoded counter for tracking how full the FIFO is
    logic[DEPTH:0]              status_cnt;

    // Duplicate read tracking: counts how many times current element has been read
    logic counter_for_head;

    // Output flags
    assign empty = status_cnt[0];       // FIFO is empty if lowest bit is 1
    assign full  = status_cnt[DEPTH];   // FIFO is full if highest bit is 1

    // =============================
    // WRITE POINTER (TAIL) UPDATE
    // =============================
    always_ff @ (posedge clk, posedge rst) begin: ff_tail
        if (rst) begin
            tail <= 0;
        end else begin
            // Advance tail if pushing (and either popping or not full)
            if (push && (pop || !full)) begin
                tail <= tail + 1;
                if (tail == DEPTH-1)
                    tail <= 0;
            end
        end
    end

    // =============================
    // READ POINTER (HEAD) UPDATE
    // =============================
    always_ff @ (posedge clk, posedge rst) begin: ff_head
        if (rst) begin
            head <= 0;
            counter_for_head <= 0;
        end else begin
            // Only read if pop signal is high and FIFO not empty
            if (pop && !empty) begin
                counter_for_head <= counter_for_head + 1;

                // Move to next head only after 2 reads
                if (counter_for_head == 2) begin
                    counter_for_head <= 0;
                    head <= head + 1;
                    if (head == DEPTH-1)
                        head <= 0;
                end
            end
        end
    end

    // =============================
    // STATUS COUNTER (ONE-HOT ENCODED)
    // =============================
    always_ff @ (posedge clk, posedge rst) begin: ff_status_cnt
        if (rst) begin
            status_cnt <= 1;  // Start with 1 active bit in LSB
        end else begin
            if (push & ~pop & ~full) begin
                // FIFO growing (increment): shift left
                status_cnt <= { status_cnt[DEPTH-1:0], 1'b0 };
            end else if (~push & pop & ~empty) begin
                // FIFO shrinking (decrement): shift right
                status_cnt <= { 1'b0, status_cnt[DEPTH:1] };
            end
        end
    end

    // =============================
    // DATA WRITE OPERATION
    // =============================
    always_ff @ (posedge clk) begin: ff_reg_dec
        if (push && (pop || !full)) begin
            mem[tail] <= write_data;
        end
    end

    // =============================
    // DATA READ OUTPUT
    // =============================
    assign read_data = mem[head]; // Read current head position (duplicated externally)

endmodule
