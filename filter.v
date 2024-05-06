`timescale 1ns / 1ps

module filter #(
	parameter STAGES = 8
) (
	input wire ClkIn,
	input wire SignalIn,
	output reg SignalOut
);

reg[STAGES-1:0] Stages;

wire AllHigh = &Stages;
wire AllLow = ~|Stages;

always @(posedge ClkIn) begin
	Stages <= { Stages[STAGES-2:0], SignalIn };
	if (AllHigh) begin
		SignalOut <= 1'b1;
	end
	if (AllLow) begin
		SignalOut <= 1'b0;
	end
end

endmodule
