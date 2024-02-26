`timescale 1ns/1ps

module counter #(
    parameter N = 8
) (
    input wire Clk,
    input wire Reset,
    output reg[N-1:0] Out
);

initial Out <= 0;

always @(posedge Clk) begin
    if (Reset) Out <= 0;
    else Out <= Out + 1'b1;
end

endmodule