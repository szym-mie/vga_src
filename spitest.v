`timescale 1ns / 1ps

module spitest;

	// Inputs
	reg Clk = 1'b0;
	reg Sclk = 1'b0;
	reg Mosi = 1'b0;
	reg CSel = 1'b1;

	// Outputs
	wire DataRecv;
	wire [7:0] DataOut;
	
	initial forever
		#2 Clk <= ~Clk;

	// Instantiate the Unit Under Test (UUT)
	spi UUT (
	   .Clk(Clk),
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
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		send_byte(40, 8'b01000001);
		send_byte(40, 8'b11000000);
		send_byte(40, 8'b11000000);
		send_byte(40, 8'b11000000);
	
		#500;
		
		send_byte(40, 8'b01000001);
		send_byte(40, 8'b11000000);
		send_byte(40, 8'b11000000);
		send_byte(40, 8'b11000000);
	end
      
endmodule

