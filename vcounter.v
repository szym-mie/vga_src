`timescale 1ns/1ps

module vcounter #(
    parameter XBITS = 8,
    parameter YBITS = 8,
    parameter XMAX = 255,
    parameter YMAX = 255
) (
    input wire Clk,
    output reg[XBITS-1:0] PixelCounter,
    output reg[YBITS-1:0] LineCounter
);

initial PixelCounter <= 1'b0;
initial LineCounter <= 1'b0;

always @(posedge Clk) begin
    if (PixelCounter < XMAX) PixelCounter <= PixelCounter + 1'b1;
    else begin
        PixelCounter <= 1'b0;
        if (LineCounter < YMAX) LineCounter <= LineCounter + 1'b1;
        else LineCounter <= 1'b0;
    end
end

endmodule