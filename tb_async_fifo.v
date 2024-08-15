module tb_async_fifo;

// Testbench signals
reg         read_clk;
reg         write_clk;
reg         reset;
reg         read_enable;
reg         write_enable;
reg  [15:0] data_in;
wire [15:0] data_out;
wire        fifo_full;
wire        fifo_empty;
wire        data_valid;
wire        fifo_overflow;
wire        fifo_underflow;

// FIFO instance
async_fifo #(
    .DATA_WIDTH(16),
    .FIFO_DEPTH(32),
    .ADDR_SIZE(6)
) uut (
    .read_clk(read_clk),
    .write_clk(write_clk),
    .reset(reset),
    .read_enable(read_enable),
    .write_enable(write_enable),
    .data_in(data_in),
    .data_out(data_out),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .data_valid(data_valid),
    .fifo_overflow(fifo_overflow),
    .fifo_underflow(fifo_underflow)
);

// Clock generation
initial begin
    read_clk = 0;
    write_clk = 0;
    forever #5 read_clk = ~read_clk; // 10 ns period for read clock
end

initial begin
    forever #5 write_clk = ~write_clk; // 10 ns period for write clock
end

// Test sequence
initial begin
    // Initialize signals
    reset = 1;
    read_enable = 0;
    write_enable = 0;
    data_in = 16'h0;

    // Apply reset
    #10;
    reset = 0;

    // Test 1: Write data into FIFO
    #10;
    data_in = 16'hAAAA;
    write_enable = 1;
    #10;
    write_enable = 0;

    // Test 2: Read data from FIFO
    #20;
    read_enable = 1;
    #10;
    read_enable = 0;

    // Test 3: Check for empty condition
    #20;
    read_enable = 1;
    #10;
    read_enable = 0;

    // Test 4: Write more data
    #20;
    data_in = 16'h5555;
    write_enable = 1;
    #10;
    write_enable = 0;

    // Test 5: Read data again
    #20;
    read_enable = 1;
    #10;
    read_enable = 0;

    // Test 6: Check overflow and underflow
    #10;
    write_enable = 1;
    data_in = 16'hFFFF;
    #10;
    write_enable = 0;

    // Check overflow
    #20;
    read_enable = 1;
    #10;
    read_enable = 0;

    // Test completed
    #30;
    $stop;
end

// Monitor signals
initial begin
    $monitor("Time = %0t, Reset = %b, Write Enable = %b, Read Enable = %b, Data In = %h, Data Out = %h, FIFO Full = %b, FIFO Empty = %b, Data Valid = %b, FIFO Overflow = %b, FIFO Underflow = %b",
             $time, reset, write_enable, read_enable, data_in, data_out, fifo_full, fifo_empty, data_valid, fifo_overflow, fifo_underflow);
end

endmodule
