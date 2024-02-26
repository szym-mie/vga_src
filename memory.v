module memory #(
    parameter A = 18, // page address width
    parameter P = 1 // page mux bits
) (
    input wire[A-1:0] Address,
    input wire[P-1:0] PageMux,
    input wire[7:0] DataIn,
    input wire Clk,
    input wire Read,
    input wire Write,
    output reg[7:0] DataOut
    // TODO: connect to pins, define UFC
    // output wire[A-1:0] MemAddress,
    // output wire[P-1:0] MemPageMux,
    // output wire[7:0] MemData
);

reg[1:0] State;
localparam Free = 2'b00;
localparam PendingRead = 2'b01;
localparam PendingWrite = 2'b10;

initial DataOut <= 1'b0;

always @(posedge Read or posedge Write) begin

end

endmodule