`timescale 1ns / 1ps

`include "spi.v"

module spitest;

	// Inputs
	reg Sclk;
	reg Mosi;
	reg CSel;

	// Outputs
	wire DataRecv;
	wire [7:0] DataOut;

	// Instantiate the Unit Under Test (UUT)
	spi UUT (
		.Sclk(Sclk), 
		.Mosi(Mosi), 
		.CSel(CSel), 
		.DataRecv(DataRecv), 
		.DataOut(DataOut)
	);
	
	task send_byte(input time PulseTime, input [7:0] Byte);
		begin
			CSel = 1'b0;
			// for (j = 0; j < 8; j = j + 1)
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

	initial begin
		// Initialize Inputs
		Sclk = 0;
		Mosi = 0;
		CSel = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		send_byte(10, 8'b01000001);
		send_byte(10, 8'b11000000);
		send_byte(10, 8'b11000000);
		send_byte(10, 8'b11000000);
	end
      
endmodule

