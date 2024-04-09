`timescale 1ns/1ps

// TODO: add double buffer for memory reading
module vbuffer #(
    parameter IWIDTH = 2, // index width
    parameter BPP = 6, // bits per pixel
    parameter PSIZE = 4 // pixels stored
) (
    input wire Clk,
    input wire Write,
    input wire Blank,
    input wire[IWIDTH-1:0] ReadIndex,
    input wire[IWIDTH-1:0] WriteIndex,
    input wire[7:0] DataIn,
    output reg[BPP-1:0] VideoOut
);

reg[BPP-1:0] Buffer[PSIZE-1:0];

always @(posedge Clk) begin
    if (Write) begin

        Buffer[WriteIndex] <= DataIn;
    end
    if (Blank) VideoOut <= 1'b0;
    else VideoOut <= Buffer[ReadIndex];
end
    
endmodule