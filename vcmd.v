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
localparam WriteNU = 8'h42; // TODO: later
localparam WriteNP = 8'h43;

localparam ReadCmdId = 4'h0;
localparam ReadSetXH = 4'h1;
localparam ReadSetYH = 4'h2;
localparam ReadSetXL = 4'h3;
localparam ReadSetYL = 4'h4;
localparam ReadByte1 = 4'h8;
localparam ReadByte2 = 4'h9;
localparam ReadByte3 = 4'hA;

reg[3:0] State = 4'b0;
reg[15:0] PositionX;
reg[15:0] PositionY;
reg[7:0] DataBuffer[3:0];

function [3:0]SelectCmd;
  input[7:0] CmdId;
  begin
    case (CmdId)
      Noop:
        SelectCmd = ReadCmdId;
      SetX:
        SelectCmd = ReadSetXH;
      SetY:
        SelectCmd = ReadSetYH;
      WriteNP:
        SelectCmd = ReadByte1; // TODO: buffer
    endcase
  end
endfunction

always @(posedge CmdRecv) begin
  case (State)
    ReadCmdId: 
      begin
        DataBuffer[0] <= 8'b0;
        DataBuffer[1] <= 8'b0;
        DataBuffer[2] <= 8'b0;
        DataBuffer[3] <= 8'b0;
        State <= SelectCmd(CmdIn);
      end
    ReadSetXH:
      begin
        PositionX[0] <= CmdIn;
        State <= ReadSetXL;
      end
    ReadSetXL:
      begin
        DataBuffer[1] <= CmdIn;
        State <= ReadCmdId;
      end
    ReadSetYH:
      begin
        DataBuffer[0] <= CmdIn;
        State <= ReadSetYL;
      end
    ReadSetYL:
      begin
        DataBuffer[1] <= CmdIn;
        State <= ReadCmdId;
      end
    ReadByte1:
      begin
        DataBuffer[0] <= CmdIn;
        State <= ReadByte2;
      end
    ReadByte2:
      begin
        DataBuffer[1] <= CmdIn;
        State <= ReadByte3;
      end
    ReadByte3:
      begin
        DataBuffer[2] <= CmdIn;
        State <= ReadCmdId;
      end
    default:
      State <= ReadCmdId;
  endcase
end
    
endmodule