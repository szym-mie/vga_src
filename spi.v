module spi (
    input wire Sclk,
    input wire Mosi,
    input wire CSel,
    output reg RecvByte,
    output wire RecvInt,
    output reg[7:0] DataOut = 1'b0
);

assign RecvInt = CSel;
reg[7:0] DataBuffer = 1'b0;
reg[2:0] PulseCnt = 1'b0;

always @(posedge Sclk) begin
    if (!CSel) begin 
        RecvByte <= PulseCnt == 3'b111 ? 1'b1 : 1'b0;
        PulseCnt <= PulseCnt + 1'b1;
        DataBuffer <= {DataBuffer[6:0], Mosi};
    end
end

endmodule
