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

    output reg[AWIDTH-1:0] MemAddrPort, // phy memory ports
    inout wire[DWIDTH-1:0] MemDataPort,
    output reg MemWriteEnable,
    output reg MemOutputEnable
);

// memory time slot structure:
// bit 0   - read/write (0 = read, 1 = write)
// bit 1 - data dest/src (T - target id)
// bit 3:2 - address src (SS - source id)
// bit 6:4 - unused
// bit 7 - nop

parameter SlotsFile = "/home/ise/FPGA_SHARED/vga_src/slots.bin.mem";

reg Phase = 1'b0;
reg [7:0] Slots[TSSIZE-1:0];
reg [7:0] Slot;
reg [2:0] SlotIndex = 3'b000;

wire[7:0] ReqReadData;

wire MemNop = Slot[7];

//initial begin
//    if (SlotsFile != "") $readmemb(SlotsFile, Slots);
//end

initial begin
    Slots[0] = 8'b10000000; // noop write byte 1
    Slots[1] = 8'b10000000; // noop write byte 2
    Slots[2] = 8'b10000000; // noop write byte 3
    Slots[3] = 8'b10000000; // noop write byte 4
    Slots[4] = 8'b10000000; // noop write byte 5
    Slots[5] = 8'b00000000; // read byte 1
    Slots[6] = 8'b00000000; // read byte 2
    Slots[7] = 8'b00000000; // read byte 3
end


assign MemDataPort = !MemWriteEnable ? ReqWriteData : 8'bzzzzzzzz;
//assign MemDataPort = !MemWriteEnable ? ReqWriteData : 8'b00000000;
assign ReqReadData = MemDataPort;


always @(posedge MemClk) begin
    ReadDataRdy1 = 1'b0;
	 ReadDataRdy2 = 1'b0;
	 
	 if (Phase) begin
        if (MemWriteEnable && !MemNop) begin
            case (Slot[1])
                1'b0: begin
                    ReqReadData1 = ReqReadData;
			           ReadDataRdy1 = 1'b1;
                end
                1'b1: begin
                    ReqReadData2 = ReqReadData;
					     ReadDataRdy2 = 1'b1;
                end
            endcase
        end

        Slot = Slots[SlotIndex];
        SlotIndex = SlotIndex + 1'b1;
        MemOutputEnable = 1'b0; // kind of not needed?
	 end
	 else
	 begin
	     case (Slot[3:2])
            2'b00: MemAddrPort = ReqAddrSrc1;
            2'b01: MemAddrPort = ReqAddrSrc2;
            2'b10: MemAddrPort = ReqAddrSrc3;
            2'b11: MemAddrPort = ReqAddrSrc4;
        endcase
        MemWriteEnable = !Slot[0];
	 end
	 
	 Phase = Phase + 1;
end
    
endmodule