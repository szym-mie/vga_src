`timescale 1ns / 1ps

// dummy memory intended for testing
// because of small amount of data being tested it has a small size of 256B

module vmmudummy;

	// Inputs
	reg MemClk;
	reg [18:0] ReqAddrSrc1;
	reg [18:0] ReqAddrSrc2;
	reg [18:0] ReqAddrSrc3;
	reg [18:0] ReqAddrSrc4;
	reg [7:0] ReqWriteData;
	reg WriteDataTrig;

	// Outputs
	wire [7:0] ReqReadData1;
	wire ReadDataRdy1;
	wire [7:0] ReqReadData2;
	wire ReadDataRdy2;
	wire WriteDataRdy;
	wire [18:0] MemAddrPort;
	wire MemWriteEnable;
	wire MemOutputEnable;

	// Bidirs
	wire [7:0] MemDataPort;

	// Instantiate the Unit Under Test (UUT)
	vmmu uut (
		.MemClk(MemClk), 
		.ReqAddrSrc1(ReqAddrSrc1), 
		.ReqAddrSrc2(ReqAddrSrc2), 
		.ReqAddrSrc3(ReqAddrSrc3), 
		.ReqAddrSrc4(ReqAddrSrc4), 
		.ReqReadData1(ReqReadData1), 
		.ReadDataRdy1(ReadDataRdy1), 
		.ReqReadData2(ReqReadData2), 
		.ReadDataRdy2(ReadDataRdy2), 
		.ReqWriteData(ReqWriteData), 
		.WriteDataTrig(WriteDataTrig), 
		.WriteDataRdy(WriteDataRdy), 
		.MemAddrPort(MemAddrPort), 
		.MemDataPort(MemDataPort), 
		.MemWriteEnable(MemWriteEnable), 
		.MemOutputEnable(MemOutputEnable)
	);
	
	// physical dummy memory interface
	reg [7:0] DummyMem[255:0] = 0;
	
	always @(posedge MemWriteEnable) begin
		MemDataPort = 8'bzzzzzzzz;
		#10;
		MemDataPort = DummyMem[MemAddrPort[7:0]];
	end

	initial begin
		// Initialize Inputs
		MemClk = 0;
		ReqAddrSrc1 = 0;
		ReqAddrSrc2 = 0;
		ReqAddrSrc3 = 0;
		ReqAddrSrc4 = 0;
		ReqWriteData = 0;
		WriteDataTrig = 0;
	end
      
endmodule

