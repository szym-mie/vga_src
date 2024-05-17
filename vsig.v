`timescale 1ns/1ps

// Video Signalling Generator - generate HSync, VSync, blanks video RGB output

module vsig #(
    parameter XWIDTH = 10,
    parameter YWIDTH = 10,
	 parameter HSMIN = 653,
	 parameter HSMAX = 749,
	 parameter VSMIN = 491,
	 parameter VSMAX = 493
) (
    input wire PixelClk,
    input wire[XWIDTH-1:0] PixelCnt,
    input wire[YWIDTH-1:0] LineCnt,
    input wire IsActHorz,
	 input wire IsActVert,
    output reg HSync,
    output reg VSync,
	 output wire Blank
);

assign Blank = !IsActHorz || !IsActVert;

always @(posedge PixelClk) begin
    if (PixelCnt == HSMIN) HSync <= 1'b0;
    if (PixelCnt == HSMAX) HSync <= 1'b1;

    if (LineCnt == VSMIN) VSync <= 1'b0;
    if (LineCnt == VSMAX) VSync <= 1'b1;
end

endmodule
