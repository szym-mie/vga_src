// TODO: initial implementation
module vmmu #(
    parameter AWIDTH = 19,
    parameter DWIDTH = 8,
    parameter TSSIZE = 8 // amount of time slots
) (
    input wire MemClk,

    input wire[AWIDTH-1:0] ReqAddrSrc1,
    input wire[AWIDTH-1:0] ReqAddrSrc2,
    input wire[AWIDTH-1:0] ReqAddrSrc3,
    input wire[AWIDTH-1:0] ReqAddrSrc4,

    output reg[DWIDTH-1:0] ReqReadData1,
    output reg ReadDataRdy1,
    output reg[DWIDTH-1:0] ReqReadData2,
    output reg ReadDataRdy2,
    input wire[DWIDTH-1:0] ReqWriteData,
	 input wire HasWriteData,
	 output reg WriteDataRdy,

    output reg[AWIDTH-1:0] MemAddrPort, // phy memory ports
    inout wire[DWIDTH-1:0] MemDataPort,
    output wire MemWriteEnable,
    output wire MemOutputEnable
);

// memory time slot structure:
// bit 0   - read/write (0 = read, 1 = write)
// bit 1 - data dest/src (T - target id)
// bit 3:2 - address src (SS - source id)
// bit 6:4 - unused
// bit 7 - nop

parameter SlotsFile = "/home/ise/FPGA_SHARED/vga_src/slots.bin.mem";

reg[1:0] Phase = 1'b00;
reg MemNop = 1'b0;
reg WriteMode = 1'b0;
reg[7:0] Slots[TSSIZE-1:0];
reg[7:0] Slot;
reg[2:0] SlotIndex = 3'b000;

wire[7:0] ReqReadData;
reg[AWIDTH-1:0] NextAddr;

//initial begin
//    if (SlotsFile != "") $readmemb(SlotsFile, Slots);
//end

initial begin
	 Slots[0] = 8'b00000101; // write byte 1
    Slots[1] = 8'b10000101; // noop write byte 2
    Slots[2] = 8'b10000101; // noop write byte 3
	 Slots[3] = 8'b10000000; // noop
	 Slots[4] = 8'b10000000; // noop
    Slots[5] = 8'b00000000; // read byte 1
    Slots[6] = 8'b10000000; // noop read byte 2
    Slots[7] = 8'b10000000; // noop read byte 3
end

localparam PhaseAddressSetup = 2'b00;
localparam PhaseDirectionChange = 2'b01;
localparam PhaseDataSetup = 2'b10;
localparam PhaseDataSample = 2'b11;

assign MemDataPort = !MemWriteEnable ? ReqWriteData : 8'bzzzzzzzz;
assign ReqReadData = MemDataPort;

assign MemWriteEnable = !WriteMode | !WriteDataRdy;
assign MemOutputEnable = WriteMode;

always @(posedge MemClk) begin
    ReadDataRdy1 <= 1'b0;
	 ReadDataRdy2 <= 1'b0;
	 
	 case (Phase)
        PhaseAddressSetup: begin
            Slot <= Slots[SlotIndex];
            SlotIndex <= SlotIndex + 1'b1;

		      case (Slot[3:2])
                2'b00: MemAddrPort = ReqAddrSrc1;
                2'b01: MemAddrPort = ReqAddrSrc2;
                2'b10: MemAddrPort = ReqAddrSrc3;
                2'b11: MemAddrPort = ReqAddrSrc4;
            endcase
            WriteMode = Slot[0];
		      MemNop = Slot[7];
				if (WriteMode && !MemNop) WriteDataRdy = 1'b1;
		  end
        PhaseDirectionChange: begin
		      // empty
		  end
        PhaseDataSetup: begin
		      // empty
		  end
        PhaseDataSample: begin
		      WriteDataRdy = 1'b0;
		      if (!WriteMode && !MemNop) begin
                case (Slot[1])
                    1'b0: begin
                        ReqReadData1 <= ReqReadData;
			               ReadDataRdy1 <= 1'b1;
                    end
                    1'b1: begin
                        ReqReadData2 <= ReqReadData;
					         ReadDataRdy2 <= 1'b1;
                    end
                endcase
            end
		  end
	 endcase
	 
	 Phase <= Phase + 1;
end
    
endmodule