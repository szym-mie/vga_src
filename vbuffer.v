`timescale 1ns/1ps

// TODO: add double buffer for memory reading
module vbuffer #(
    parameter IWIDTH = 2, // index width
    parameter BPP = 6, // bits per pixel
    parameter PSIZE = 4 // pixels stored
) (
    input wire PixelClk,
    input wire ReqWrite,
    input wire Blank,
    input wire[IWIDTH-1:0] ReadIndex,
    input wire[IWIDTH-1:0] WriteIndex,
    input wire[7:0] DataIn,
    output reg[BPP-1:0] VideoOut
);

parameter WSIZE = BPP * PSIZE / 8;

reg[7:0] WriteBuffer[WSIZE-1:0];
reg[BPP-1:0] Buffer[PSIZE-1:0];

always @(posedge PixelClk) begin
	 if (ReadIndex == 1'b0) begin
	 	  Buffer[3] = WriteBuffer[2][7:2];
		  Buffer[2] = { WriteBuffer[2][1:0], WriteBuffer[1][7:4] };
		  Buffer[1] = { WriteBuffer[1][3:0], WriteBuffer[0][7:6] };
		  Buffer[0] = WriteBuffer[0][5:0];
	 end
	 
    if (Blank) begin
	     VideoOut = 1'b0;
    end
    else VideoOut = Buffer[ReadIndex];
end
    
always @(posedge ReqWrite) begin
    WriteBuffer[WriteIndex] = DataIn;
end

endmodule