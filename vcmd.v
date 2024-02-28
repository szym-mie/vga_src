module vcmd (
    input wire CmdRecv,
    input wire CmdRecvInt,
    input wire[7:0] CmdIn
);

localparam Noop = 8'h00;
localparam BufSwap = 8'h01;
localparam SetNoInc = 8'h10; // TODO: later
localparam SetHInc = 8'h11; // TODO: later
localparam Set0 = 8'h12; // TODO: later
localparam SetX = 8'h20;
localparam SetY = 8'h30;
localparam Write1U = 8'h40; // TODO: later
localparam Write1P = 8'h41; // TODO: later
localparam WriteNU = 8'h42;
localparam WriteNP = 8'h43;

localparam Hold = 4'h0;
localparam ReadCmdId = 4'h1;
localparam ReadSetXH = 4'h2;
localparam ReadSetYH = 4'h3;
localparam ReadSetXL = 4'h4;
localparam ReadSetYL = 4'h5;

reg[3:0] State = 4'b0;

always @(posedge CmdRecv) begin
    
end
    
endmodule