`timescale 1ns/1ps

// Video Controller - read address generator

module vctl #(
    parameter XWIDTH = 10,
    parameter YWIDTH = 10,
	 parameter AWIDTH = 16,
    parameter XMAX = 799,
    parameter YMAX = 524,
	 parameter HDMIN = 3,
	 parameter HDMAX = 643,
	 parameter VDMIN = 524,
	 parameter VDMAX = 479
) (
    input wire PixelClk,
    output reg[XWIDTH-1:0] PixelCnt,
    output reg[YWIDTH-1:0] LineCnt,
	 output wire[AWIDTH-1:0] AddrOut,
	 output reg AddrClkOut,
	 output reg IsActHorz,
	 output reg IsActVert
);

initial PixelCnt <= 1'b0;
initial LineCnt <= 1'b0;
initial IsActHorz <= 1'b0;
initial IsActVert <= 1'b0;

assign AddrOut = { 2'b00, LineCnt[9:2], 1'b0, PixelCnt[9:2] };

always @(posedge PixelClk) begin
    if (PixelCnt == XMAX) begin
        PixelCnt <= 1'b0; 
	     if (LineCnt == YMAX) LineCnt <= 1'b0;
	     else LineCnt <= LineCnt + 1'b1;
	 end else PixelCnt <= PixelCnt + 1'b1;
	 
	 if (PixelCnt == HDMAX) IsActHorz <= 1'b0;
	 if (PixelCnt == HDMIN) IsActHorz <= 1'b1;
	 
	 if (LineCnt == VDMAX) IsActVert <= 1'b0;
	 if (LineCnt == VDMIN) IsActVert <= 1'b1;

	 if (&PixelCnt[1:0] && IsActHorz) AddrClkOut <= 1'b1;
	 else AddrClkOut <= 1'b0;
end

endmodule
