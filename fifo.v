module fifo #(
    parameter BUFSIZE = 16, // buffer size
    parameter IWIDTH = 4, // buffer index width
    parameter WWIDTH = 8 // memory word width
) (
    input wire[WWIDTH-1:0] DataIn,
    output reg[WWIDTH-1:0] DataOut,
    
    input wire ClkIn,
    input wire ClkOut,

    output wire IsFull,
    output wire IsEmpty
);

reg[WWIDTH-1:0] Buffer[BUFSIZE-1:0];
reg[IWIDTH-1:0] InIndex = 1'b0, OutIndex = 1'b0;

assign IsFull = InIndex + 1 == OutIndex;
assign IsEmpty = InIndex == OutIndex;

always @(posedge ClkIn) begin
    if (!IsFull) begin
        Buffer[InIndex] <= DataIn;
        InIndex <= InIndex < BUFSIZE-1 ? InIndex + 1 : 0;
    end
end

always @(posedge ClkOut) begin
    if (!IsEmpty) begin
	     DataOut <= Buffer[OutIndex];
        OutIndex <= OutIndex < BUFSIZE-1 ? OutIndex + 1 : 0;
    end
end

endmodule