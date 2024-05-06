`include "fifo.v"

module vcmd (
  input wire ByteRecvClk,
  input wire DataModeEnable,
  input wire[7:0] ByteIn,
  input wire ReadOutClk,
  
  output wire HasReadData,
  output wire[18:0] AddrOut,
  output wire[7:0] DataOut
);

// TODO finish vcmd data

localparam Noop = 8'h00;
localparam SetAddr = 8'h01;

localparam ReadCmdId = 4'h0;
localparam SetAddrPage = 4'h4;
localparam SetAddrHigh = 4'h5;
localparam SetAddrLow = 4'h6;

reg[18:0] NextAddr = 1'b0;
reg[18:0] ReadAddr = 1'b0;

reg[3:0] State = 1'b0;

wire BufferOverflow;
wire BufferUnderflow;
wire PushByte = ~BufferOverflow && DataModeEnable && ByteRecvClk;
assign HasReadData = ~BufferUnderflow;

wire _BufferOverflow;
wire _BufferUnderflow;

fifo #(
  .BUFSIZE(8),
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
  .BUFSIZE(8),
  .WWIDTH(19)
) AddrFIFO (
  .DataIn(NextAddr),
  .ClkIn(PushByte),
  .DataOut(AddrOut),
  .ClkOut(ReadOutClk),
  .IsEmpty(_BufferUnderflow),
  .IsFull(_BufferOverflow)  
);

function [3:0] SelectCmd(input[7:0] CmdId);
  begin
    case (CmdId)
      Noop: SelectCmd = ReadCmdId;
      SetAddr: SelectCmd = SetAddrPage;
    endcase
  end
endfunction

always @(posedge ByteRecvClk) begin
  if (DataModeEnable) begin
    NextAddr <= NextAddr + 1'b1;
  end else begin
    case (State)
      ReadCmdId: State <= SelectCmd(ByteIn);
      SetAddrPage: begin
        ReadAddr[18:16] <= ByteIn[2:0];
        State <= SetAddrHigh;
      end
      SetAddrHigh: begin
        ReadAddr[15:8] <= ByteIn;
        State <= SetAddrLow;
      end
	   SetAddrLow: begin
        ReadAddr[7:0] <= ByteIn;
        NextAddr <= ReadAddr;		  
        State <= ReadCmdId;
	   end
      default: State <= ReadCmdId;
    endcase
  end
end

endmodule