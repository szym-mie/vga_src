`timescale 1ns/1ps

// TODO: add double buffer for memory reading
module buffer #(
    parameter A = 2, // address width
    parameter B = 6, // bits per pixel
    parameter P = 4 // pixels stored
) (
    input wire Read,
    input wire Write,
    input wire Reset,
    input wire[B-1:0] DataIn,
    output reg[B-1:0] DataOut
);

reg[B-1:0] Buffer[P-1:0];
reg[A-1:0] WriteAddress;
reg[A-1:0] ReadAddress;

initial WriteAddress <= 1'b0;
initial ReadAddress <= 1'b0;

// FIXME: TEST
initial Buffer[0] <= 6'b000000;
initial Buffer[1] <= 6'b000001;
initial Buffer[2] <= 6'b000010;
initial Buffer[3] <= 6'b000011;

always @(posedge Read or posedge Write or posedge Reset) begin
    if (Reset) begin
        WriteAddress <= 1'b0;
        ReadAddress <= 1'b0;
    end else begin
        if (Read) begin
            DataOut <= Buffer[ReadAddress];
            if (ReadAddress == P - 1) ReadAddress <= 1'b0;
            else ReadAddress <= ReadAddress + 1'b1;
        end

        if (Write) begin
			   Buffer[WriteAddress] <= DataIn;
            if (WriteAddress == P - 1) WriteAddress <= 1'b0;
            else WriteAddress <= WriteAddress + 1'b1;
        end
    end
end
    
endmodule