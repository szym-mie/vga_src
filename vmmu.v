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
    output reg[DWIDTH-1:0] ReqReadData2,
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

parameter SlotsFile = "slots.bin.mem";

reg [7:0] Slots[TSSIZE-1:0];
reg [7:0] Slot;
reg [2:0] SlotIndex = 3'b000;

initial begin
    if (SlotsFile != "") $readmemb(SlotsFile, Slots);
end

assign MemDataPort = !MemWriteEnable ? ReqWriteData : 8'bzzzzzzzz;

always @(posedge MemClk) begin
    if (MemWriteEnable) begin
        case (Slot[1])
            1'b0: ReqReadData1 = MemDataPort;
            1'b1: ReqReadData2 = MemDataPort;
        endcase
    end

    Slot = Slots[SlotIndex];
    SlotIndex = SlotIndex + 1'b1;
    MemOutputEnable = 1'b0;
    if (!Slot[7]) begin
        case (Slot[3:2])
            2'b00: MemAddrPort = ReqAddrSrc1;
            2'b01: MemAddrPort = ReqAddrSrc2;
            2'b10: MemAddrPort = ReqAddrSrc3;
            2'b11: MemAddrPort = ReqAddrSrc4;
        endcase
        MemWriteEnable = !Slot[0];
    end
end
    
endmodule