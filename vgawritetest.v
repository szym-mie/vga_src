`timescale 1ns / 1ps

module vgawritetest;

	// Inputs
	reg MainClkSrc;
	reg Sclk;
	reg Mosi;
	reg CSel;

	// Outputs
	wire [18:0] MemAddr;
	wire MemWE;
	wire MemOE;
	wire [5:0] ColorOut;
	wire HsyncOut;
	wire VsyncOut;

	reg [8:0] Counter = 8'h00;

	// Bidirs
	wire [7:0] MemData;
	
	assign MemData = Counter[8:1];

	// Instantiate the Unit Under Test (UUT)
	vga uut (
		.MainClkSrc(MainClkSrc), 
		.MemAddr(MemAddr), 
		.MemData(MemData), 
		.MemWE(MemWE), 
		.MemOE(MemOE), 
		.ColorOut(ColorOut), 
		.HsyncOut(HsyncOut), 
		.VsyncOut(VsyncOut), 
		.Sclk(Sclk), 
		.Mosi(Mosi), 
		.CSel(CSel)
	);
	
	task send_byte(input time PulseTime, input [7:0] Byte);
		begin
			CSel = 1'b0;
			// for (j = 0; j < 8; j = j + 1)
			#PulseTime;
			send_pulse(PulseTime, (Byte>>7) & 1);
			send_pulse(PulseTime, (Byte>>6) & 1);
			send_pulse(PulseTime, (Byte>>5) & 1);
			send_pulse(PulseTime, (Byte>>4) & 1);
			send_pulse(PulseTime, (Byte>>3) & 1);
			send_pulse(PulseTime, (Byte>>2) & 1);
			send_pulse(PulseTime, (Byte>>1) & 1);
			send_pulse(PulseTime, (Byte>>0) & 1);
			Sclk = 1'b0;
			#PulseTime;
			CSel = 1'b1;
			#PulseTime;
		end
	endtask
	
	task send_pulse(input time PulseTime, input Data);
		begin
			Mosi = Data;
			Sclk = 1'b0;
			#PulseTime;
			Sclk = 1'b1;
			#PulseTime;
		end
	endtask
	
	initial begin
		// Initialize Clock
		MainClkSrc = 0;
		forever #5 MainClkSrc = ~MainClkSrc;
	end

	initial begin
		// Initialize Inputs
		Sclk = 0;
		Mosi = 0;
		CSel = 0;

		// Wait 100 ns for global reset to finish
		#500;
        
		// Add stimulus here
		// Very fast SPI clock (100MHz)
		send_byte(10, 8'b11000000);
		send_byte(10, 8'b11000000);
		send_byte(10, 8'b11000000);
		
		// Small delay between next pixel write
		#160;
		
		// Another byte at next location
		send_byte(10, 8'b00000011);
		send_byte(10, 8'b00000011);
		send_byte(10, 8'b00000011);
	end
	
	always @(posedge MainClkSrc) Counter <= Counter + 1'b1;
      
endmodule

