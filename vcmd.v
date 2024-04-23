module vcmd (
  input wire CmdRecv,
  input wire[7:0] CmdIn,
  
  output reg[18:0] MemOutAddr,
  output wire[7:0] DataOut,  
  input wire[1:0] DataIndex,
  input wire HoldUpdate,
  output reg DataRdy
);

reg[11:0] PositionX = 0;
reg[11:0] PositionY = 0;

localparam Noop = 8'h00;
localparam BufSwap = 8'h01;
localparam SetNoInc = 8'h10; // TODO: later
localparam SetHInc = 8'h11; // TODO: later
localparam Set0 = 8'h12; // TODO: later
localparam SetX = 8'h2x;
localparam SetY = 8'h3x;
localparam Write1U = 8'h40;
localparam Write1P = 8'h41; // TODO: later
localparam WriteNU = 8'h42; // TODO: later
localparam WriteNP = 8'h43; // TODO: later

localparam ReadCmdId = 4'h0;
localparam ReadSetXH = 4'h1;
localparam ReadSetYH = 4'h2;
localparam ReadSetXL = 4'h3;
localparam ReadSetYL = 4'h4;
localparam ReadByte1 = 4'h8;
localparam ReadByte2 = 4'h9;
localparam ReadByte3 = 4'hA;

reg[3:0] State = 0;
reg[7:0] DataBuffer[2:0];
reg[7:0] DataOutBuffer[2:0];

reg[18:0] MemAddr = 0;
reg[18:0] NextMemAddr = 0;

function [3:0] SelectCmd(input [7:0] CmdId);
  begin
    casex (CmdId)
      Noop:
        SelectCmd = ReadCmdId;
      SetX:
		  begin
		    PositionX[11:8] = CmdId[3:0];
			 SelectCmd = ReadSetXL;
		  end
      SetY:
		  begin
		    PositionY[11:8] = CmdId[3:0];
			 SelectCmd = ReadSetYL;
		  end
      Write1P:
		  begin
          SelectCmd = ReadByte1; // TODO: buffer
          NextMemAddr = NextMemAddr + 3;
		    if (MemAddr >= 230_400) NextMemAddr = 0;
		  end
    endcase
  end
endfunction

assign DataOut = DataOutBuffer[DataIndex];

always @(posedge CmdRecv) begin
  case (State)
    ReadCmdId: 
      begin
        State = SelectCmd(CmdIn);
      end
    ReadSetXL:
      begin
        PositionX[7:0] = CmdIn;
		  NextMemAddr = PositionY * 480 + PositionX * 3;
        State = ReadCmdId;
      end
    ReadSetYL:
      begin
        PositionY[7:0] = CmdIn;
		  NextMemAddr = PositionY * 480 + PositionX * 3;
        State = ReadCmdId;
      end
    ReadByte1:
      begin
        DataBuffer[0] = CmdIn;
        State = ReadByte2;
      end
    ReadByte2:
      begin
        DataBuffer[1] = CmdIn;
		  DataRdy = 1'b0;
        State = ReadByte3;
      end
    ReadByte3:
      begin
        DataBuffer[2] = CmdIn;
        MemAddr = NextMemAddr - 3;
		  DataRdy = 1'b1;
        State = ReadCmdId;
      end
    default:
      State = ReadCmdId;
  endcase
end

always @(negedge HoldUpdate) begin
  if (DataRdy) begin
    MemOutAddr = MemAddr;
    DataOutBuffer[0] = DataBuffer[0];
    DataOutBuffer[1] = DataBuffer[1];
    DataOutBuffer[2] = DataBuffer[2];
  end
end

endmodule