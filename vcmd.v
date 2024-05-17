`include "fifo.v"

module vcmd (
  input wire ByteRecvClk,
  input wire[7:0] ByteIn,
  input wire ReadOutClk,
  
  output wire HasReadData,
  output wire[18:0] AddrOut,
  output wire[7:0] DataOut
);

// TODO finish vcmd data

localparam Noop = 8'h00;
localparam SetXY = 8'h11;
localparam Write = 8'h20;

localparam ReadCmdId = 4'h0;
localparam ReadX = 4'h4;
localparam ReadY = 4'h5;
localparam ReadPixel = 4'h8;

reg[7:0] PosX = 1'b0;
reg[7:0] PosY = 1'b0;

reg[18:0] NextAddr = 1'b0;

reg[3:0] State = 1'b0;

wire BufferOverflow;
wire BufferUnderflow;
reg NextByte = 1'b0;
reg PushByte = 1'b0;
assign HasReadData = ~BufferUnderflow;

wire _BufferOverflow;
wire _BufferUnderflow;

reg[18:0] AddrIn;

fifo #(
  .BUFSIZE(4),
  .IWIDTH(2),
  .WWIDTH(8)
) DataFIFO (
  .DataIn(ByteIn),
  .ClkIn(PushByte),
  .DataOut(DataOut),
  .ClkOut(ReadOutClk),
  .IsEmpty(BufferUnderflow),
  .IsFull(BufferOverflow)
);

fifo #(
  .BUFSIZE(4),
  .IWIDTH(2),
  .WWIDTH(19)
) AddrFIFO (
  .DataIn(AddrIn),
  .ClkIn(PushByte),
  .DataOut(AddrOut),
  .ClkOut(ReadOutClk),
  .IsEmpty(_BufferUnderflow),
  .IsFull(_BufferOverflow)  
);

always @(negedge ByteRecvClk) begin
    PushByte <= 1'b1;
end


always @(posedge ByteRecvClk) begin
	 AddrIn <= NextAddr;
	 
    case (State)
      ReadCmdId: begin
		  case (ByteIn)
		    Noop: State <= ReadCmdId;
			 SetXY: State <= ReadX;
			 Write: State <= ReadPixel;
		  endcase
		end
      ReadX: begin
        PosX <= ByteIn;
        State <= ReadY;
      end
      ReadY: begin
        PosY <= ByteIn;
		  NextAddr <= { 2'b00, ByteIn[7:0], 1'b0, PosX[7:0] };
        State <= ReadCmdId;
      end
		ReadPixel: begin
		  PushByte <= !BufferOverflow;
		  State <= ReadCmdId;
		  NextAddr <= NextAddr + 1'b1;
		end
      default: State <= ReadCmdId;
    endcase
end

endmodule
