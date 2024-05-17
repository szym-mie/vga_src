`timescale 1ns/1ps

module vbuffer #(
    parameter BPP = 6 // bits per pixel
) (
    input wire PixelClk,
    input wire ReqWrite,
    input wire Blank,
    input wire[7:0] DataIn,
    output reg[BPP-1:0] VideoOut
);

reg[BPP-1:0] Pixel = 6'b00_00_00;

always @(posedge PixelClk) begin
    if (Blank) VideoOut <= 1'b0;
    else VideoOut <= Pixel;
end
    
always @(negedge ReqWrite) begin
    Pixel = DataIn[BPP-1:0];
end

endmodule