module spi (
    input wire Sclk,
    input wire Mosi,
    input wire CSel,
    output reg DataRecv,
    output reg[7:0] DataOut = 1'b0
);

reg[7:0] DataBuffer = 1'b0;
reg[2:0] PulseCnt = 1'b0;

always @(posedge Sclk or posedge CSel) begin
    if (CSel) begin 
        PulseCnt = 1'b0;
    end else begin
		  DataBuffer = {DataBuffer[6:0], Mosi};
		  DataRecv = PulseCnt == 3'b111 ? 1'b1 : 1'b0;
		  if (DataRecv) DataOut = DataBuffer;
        PulseCnt = PulseCnt + 1'b1;
	 end
end

endmodule
