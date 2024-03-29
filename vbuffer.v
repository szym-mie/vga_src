`timescale 1ns/1ps

// TODO: add double buffer for memory reading
module vbuffer #(
    parameter AWIDTH = 2, // address width
    parameter BPP = 6, // bits per pixel
    parameter PSIZE = 4 // pixels stored
) (
    input wire Clk,
    input wire Write,
    input wire Blank,
    input wire[AWIDTH-1:0] ReadAddress,
    input wire[AWIDTH-1:0] WriteAddress,
    input wire[BPP-1:0] DataIn,
    output reg[BPP-1:0] VideoOut
);

reg[BPP-1:0] Buffer[PSIZE-1:0];

// FIXME: TEST
//initial begin
//	$readmemb("test1.mem", Buffer);
//end

always @(posedge Clk) begin
    Buffer[0] <= 6'b000000;
	 Buffer[1] <= 6'b000011;
	 Buffer[2] <= 6'b001100;
	 Buffer[3] <= 6'b110000;
    if (Write) begin
        Buffer[WriteAddress] <= DataIn;
    end
    if (Blank) VideoOut <= 1'b0;
    else VideoOut <= Buffer[ReadAddress];
end
    
endmodule