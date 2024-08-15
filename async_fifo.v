module async_fifo (
    input  wire        read_clk,
    input  wire        write_clk,
    input  wire        reset,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [15:0] data_in,
    output reg  [15:0] data_out,
    output wire        fifo_full,
    output wire        fifo_empty,
    output reg         data_valid,
    output reg         fifo_overflow,
    output reg         fifo_underflow
);

parameter DATA_WIDTH = 16;
parameter FIFO_DEPTH = 32;
parameter ADDR_SIZE = 6;

reg [ADDR_SIZE-1:0] write_pointer, read_pointer;
reg [ADDR_SIZE-1:0] write_pointer_gray_s1, write_pointer_gray_s2;
reg [ADDR_SIZE-1:0] read_pointer_gray_s1, read_pointer_gray_s2;
reg [DATA_WIDTH-1:0] memory [FIFO_DEPTH-1:0];

// Binary to Gray code conversion
function [ADDR_SIZE-1:0] binary_to_gray;
    input [ADDR_SIZE-1:0] binary;
    begin
        binary_to_gray = binary ^ (binary >> 1);
    end
endfunction

// Write process
always @(posedge write_clk or posedge reset) begin
    if (reset) begin
        write_pointer <= 0;
    end else if (write_enable && !fifo_full) begin
        memory[write_pointer] <= data_in;
        write_pointer <= write_pointer + 1;
    end
end

// Read process
always @(posedge read_clk or posedge reset) begin
    if (reset) begin
        read_pointer <= 0;
        data_out <= 0;
    end else if (read_enable && !fifo_empty) begin
        data_out <= memory[read_pointer];
        read_pointer <= read_pointer + 1;
    end
end

// Synchronize write pointer to read clock
always @(posedge read_clk or posedge reset) begin
    if (reset) begin
        write_pointer_gray_s1 <= 0;
        write_pointer_gray_s2 <= 0;
    end else begin
        write_pointer_gray_s1 <= binary_to_gray(write_pointer);
        write_pointer_gray_s2 <= write_pointer_gray_s1;
    end
end

// Synchronize read pointer to write clock
always @(posedge write_clk or posedge reset) begin
    if (reset) begin
        read_pointer_gray_s1 <= 0;
        read_pointer_gray_s2 <= 0;
    end else begin
        read_pointer_gray_s1 <= binary_to_gray(read_pointer);
        read_pointer_gray_s2 <= read_pointer_gray_s1;
    end
end

// FIFO status signals
assign fifo_empty = (binary_to_gray(read_pointer) == write_pointer_gray_s2);
assign fifo_full = (write_pointer_gray_s2[ADDR_SIZE-1] != read_pointer_gray_s2[ADDR_SIZE-1])
                 && (write_pointer_gray_s2[ADDR_SIZE-2] != read_pointer_gray_s2[ADDR_SIZE-2])
                 && (write_pointer_gray_s2[ADDR_SIZE-3:0] == read_pointer_gray_s2[ADDR_SIZE-3:0]);

// Overflow and underflow detection
always @(posedge write_clk or posedge reset) begin
    if (reset) begin
        fifo_overflow <= 0;
    end else begin
        fifo_overflow <= fifo_full && write_enable;
    end
end

always @(posedge read_clk or posedge reset) begin
    if (reset) begin
        fifo_underflow <= 0;
        data_valid <= 0;
    end else begin
        fifo_underflow <= fifo_empty && read_enable;
        data_valid <= read_enable && !fifo_empty;
    end
end

endmodule
