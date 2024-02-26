`timescale 1ns/1ps
`include "counter.v"
`include "buffer.v"

module vga (
    input wire MainClkSrc,
    output wire[5:0] OutColor,
    output reg OutHsync,
    output reg OutVsync
);

wire PixelClkSrc;

initial OutHsync <= 1'b1;
initial OutVsync <= 1'b1;

wire[1:0] PixelClkSrcTmp;
counter #(2) PixelClkSrcCnt(MainClkSrc, 1'b0, PixelClkSrcTmp);

wire PixelReset;
wire[9:0] PixelCounter;
counter #(10) PixelClk(PixelClkSrc, PixelReset, PixelCounter);

wire LineReset;
wire[9:0] LineCounter;
counter #(10) LineClk(PixelReset, LineReset, LineCounter);

wire[5:0] BufferColor;
buffer #(2, 6) PixelBuffer(PixelClkSrc, 1'b0, PixelReset, 6'b0, BufferColor);

assign PixelClkSrc = PixelClkSrcTmp[1];
assign PixelReset = PixelCounter == 799 ? 1'b1 : 1'b0;
assign LineReset = PixelCounter == 799 && LineCounter == 524 ? 1'b1 : 1'b0;
assign OutColor = PixelCounter < 640 && LineCounter < 480 ? 6'b000010 : 6'b0;

always @(posedge PixelClkSrc) begin
    if (PixelCounter == 657) OutHsync <= 0;
    if (PixelCounter == 753) OutHsync <= 1;

    if (LineCounter == 491) OutVsync <= 0;
    if (LineCounter == 493) OutVsync <= 1;
end

endmodule