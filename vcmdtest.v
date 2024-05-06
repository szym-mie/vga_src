`timescale 1ns / 1ps

module vcmdtest;

	// SPI 

	// Inputs
	reg Sclk;
	reg Mosi;
	reg CSel;

	// Outputs
	wire DataRecv;
	wire [7:0] DataOut;

	// Instantiate the Unit Under Test (UUT)
	spi Spi (
		.Sclk(Sclk), 
		.Mosi(Mosi), 
		.CSel(CSel), 
		.DataRecv(DataRecv), 
		.DataOut(DataOut)
	);
	
	task send_byte(input time PulseTime, input [7:0] Byte);
		begin
			CSel = 1'b0;
			send_pulse(PulseTime, (Byte>>7) & 1);
			send_pulse(PulseTime, (Byte>>6) & 1);
			send_pulse(PulseTime, (Byte>>5) & 1);
			send_pulse(PulseTime, (Byte>>4) & 1);
			send_pulse(PulseTime, (Byte>>3) & 1);
			send_pulse(PulseTime, (Byte>>2) & 1);
			send_pulse(PulseTime, (Byte>>1) & 1);
			send_pulse(PulseTime, (Byte>>0) & 1);
			CSel = 1'b1;
		end
	endtask
	
	task send_pulse(input time PulseTime, input Data);
		begin
			Mosi = Data;
			Sclk = 1'b1;
			#PulseTime;
			Sclk = 1'b0;
			#PulseTime;
		end
	endtask      

	// VCMD

	// Inputs
	reg [1:0] DataIndex;

	// Outputs
	wire [17:0] CmdMemAddr;
	wire [7:0] CmdDataOut;
	wire CmdDataRdy;

	// Instantiate the Unit Under Test (UUT)
	vcmd UUT (
		.CmdRecv(DataRecv), 
		.CmdIn(DataOut), 
		.MemAddr(CmdMemAddr), 
		.DataOut(CmdDataOut), 
		.DataIndex(CmdDataIndex), 
		.DataRdy(CmdDataRdy)
	);
	
	initial begin
		// Initialize Inputs
		Sclk = 0;
		Mosi = 0;
		CSel = 0;
		DataIndex = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		// Very fast SPI clock (50MHz)
		send_byte(10, 8'b01000001);
		send_byte(10, 8'b11000000);
		send_byte(10, 8'b11000000);
		send_byte(10, 8'b11000000);
		
		// Small delay between next pixel write
		#160;
		
		// Another byte at next location
		send_byte(10, 8'b01000001);
		send_byte(10, 8'b00000011);
		send_byte(10, 8'b00000011);
		send_byte(10, 8'b00000011);
	end
      
endmodule

