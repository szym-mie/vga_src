module spi (
    input wire Clk,
    input wire Sclk,
    input wire Mosi,
    input wire CSel,
    output reg DataRecv,
    output reg[7:0] DataOut
);
/*
reg[7:0] DataBuffer = 1'b0;
reg[2:0] PulseCnt = 1'b0;

always @(posedge Sclk or posedge CSel) begin
    if (CSel) begin
	 	  PulseCnt = 3'b000;
	 end else begin
	 	  DataBuffer = {DataBuffer[6:0], Mosi};
	     if (PulseCnt == 3'b111) begin
		      DataRecv <= 1;
            DataOut = DataBuffer;
        end else if (PulseCnt == 3'b010) begin
            DataRecv <= 0;
	     end
	     PulseCnt = PulseCnt + 1'b1;
	 end
end
*/

reg[2:0] SclkSample;
always @(posedge Clk) SclkSample <= { SclkSample[1:0], Sclk };

wire SclkRise = SclkSample[2:1] == 2'b01;
wire SclkFall = SclkSample[2:1] == 2'b10;

reg[2:0] CSelSample;
always @(posedge Clk) CSelSample <= { CSelSample[1:0], CSel };

wire CSelActive = ~CSelSample[1];
wire CSelRise = CSelSample[2:1] == 2'b01;
wire CSelFall = CSelSample[2:1] == 2'b10;

reg[1:0] MosiSample;
always @(posedge Clk) MosiSample <= {MosiSample[0], Mosi};

wire MosiData = MosiSample[1];

reg[2:0] BitCnt = 3'b000;

reg[7:0] ByteDataRecv = 8'b00000000;

always @(posedge Clk) begin
    if (CSelFall) begin
	     BitCnt <= 3'b000;
	 end else if (SclkRise) begin
	     BitCnt <= BitCnt + 3'b001;
		  ByteDataRecv <= {ByteDataRecv[6:0], MosiData};
	 end
end

always @(posedge Clk) begin
	 if (~CSelActive && (BitCnt == 3'b000)) begin
	     DataRecv <= 1'b1;
        DataOut <= ByteDataRecv;
	 end else begin
	     DataRecv <= 1'b0;
	 end
end

endmodule
