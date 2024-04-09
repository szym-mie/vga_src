`timescale 1ns/1ps
`include "vcounter.v"
`include "vbuffer.v"
`include "vmmu.v"

module vga (
    input wire MainClkSrc,
    output wire[18:0] MemAddr,
    inout wire[7:0] MemData,
    output wire MemWE,
    output wire MemOE,
    output wire[5:0] ColorOut,
    output reg HsyncOut,
    output reg VsyncOut,
    input wire Sclk,
    input wire Mosi,
    input wire Csel
);

wire PixelClkIbufg;
wire PixelClkBufg;
wire PixelClkDcmOut;
wire PixelClkSrc;

wire PixelDcmRst;
wire[7:0] PixelDcmStatus;
wire PixelDcmLocked;
wire PixelDcmClkFxStopped = PixelDcmStatus[2];

assign PixelDcmRst = PixelDcmClkFxStopped & ~PixelDcmLocked;

wire MemClkIbufg;
wire MemClkBufg;
wire MemClkDcmOut;
wire MemClkSrc;

wire MemDcmRst;
wire[7:0] MemDcmStatus;
wire MemDcmLocked;
wire MemDcmClkFxStopped = MemDcmStatus[2];

assign MemDcmRst = MemDcmClkFxStopped & ~MemDcmLocked;

IBUFG MainClkIbufgInst(
    .I(MainClkSrc),
    .O(MainClkIbufg)
);

// pixel clock using synthesized clock@25MHz
DCM_SP #(
    .CLKIN_PERIOD(10), // 10ns
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(2.0), // not used
    .CLKFX_MULTIPLY(2),
    .CLKFX_DIVIDE(8)
) PixelClkDcmInst (
    .CLKIN(MainClkIbufg),
    .CLKFB(1'b0),
    .RST(PixelDcmRst),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLKDV(),
    .CLKFX(PixelClkDcmOut),
    .CLKFX180(),
    .STATUS(PixelDcmStatus),
    .LOCKED(PixelDcmLocked),
    .PSDONE(),
    .DSSEN(1'b0)
);

BUFG PixelClkBufgInst (
    .I(PixelClkDcmOut),
    .O(PixelClkSrc)
);

// memory clock using synthesized clock@100MHz
DCM_SP #(
    .CLKIN_PERIOD(10), // 10ns
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(2.0), // not used
    .CLKFX_MULTIPLY(2),
    .CLKFX_DIVIDE(2) // 4 for 50MHz
) MemClkDcmInst (
    .CLKIN(MainClkIbufg),
    .CLKFB(1'b0),
    .RST(MemDcmRst),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLKDV(),
    .CLKFX(MemClkDcmOut),
    .CLKFX180(),
    .STATUS(MemDcmStatus),
    .LOCKED(MemDcmLocked),
    .PSDONE(),
    .DSSEN(1'b0)
);

BUFG MemClkBufgInst (
    .I(MemClkDcmOut),
    .O(MemClkSrc)
);

initial HsyncOut <= 1'b1;
initial VsyncOut <= 1'b1;

reg Blank = 0;
wire[9:0] PixelCounter;
wire[9:0] LineCounter;

vcounter #(
    .XBITS(10),
    .YBITS(10),
    .XMAX(799),
    .YMAX(524)
) VideoCounter (
    PixelClkSrc,
    PixelCounter,
    LineCounter
);


reg[18:0] ReqAddr1 = 19'b000_0000_0000_0000_0000;
reg[18:0] ReqAddr2 = 19'b000_0000_0000_0000_0001;
reg[18:0] ReqAddr3 = 19'b000_0000_0000_0000_0010;
reg[18:0] ReqAddr4 = 19'b000_0000_0000_0000_0000;

wire[7:0] ReqRead1;
wire[7:0] ReqRead2;
wire ReadRdy1;
wire ReadRdy2;

reg[7:0] ReqWrite = 8'b00_00_11_00;

reg[1:0] WriteBufferIndex = 1'b0; 

vmmu #(
    .AWIDTH(19),
    .DWIDTH(8),
    .TSSIZE(8)
) VMMU (
    .MemClk(MemClkSrc),
    .ReqAddrSrc1(ReqAddr1),
    .ReqAddrSrc2(ReqAddr2),
    .ReqAddrSrc3(ReqAddr3),
    .ReqAddrSrc4(ReqAddr4),
    .ReqReadData1(ReqRead1),
    .ReadDataRdy1(ReadRdy1),
    .ReqReadData2(ReqRead2),
    .ReadDataRdy2(ReadRdy2),
    .ReqWriteData(ReqWrite),
    .MemAddrPort(MemAddr),
    .MemDataPort(MemData),
    .MemWriteEnable(MemWE),
    .MemOutputEnable(MemOE)
);

vbuffer #(
    .IWIDTH(2), 
    .BPP(6),
    .PSIZE(4)
) VideoBuffer (
    .PixelClk(PixelClkSrc), 
    .ReqWrite(ReadRdy1), 
    .Blank(Blank), 
    .ReadIndex(PixelCounter[1:0]),
    .WriteIndex(WriteBufferIndex),
    .DataIn(ReqRead1), 
    .VideoOut(ColorOut)
);

always @(posedge PixelClkSrc) begin
    if (PixelCounter == 657) HsyncOut <= 0;
    if (PixelCounter == 753) HsyncOut <= 1;

    if (LineCounter == 491) VsyncOut <= 0;
    if (LineCounter == 493) VsyncOut <= 1;

    if (PixelCounter == 640) Blank <= 1;
    if (PixelCounter == 799 && LineCounter < 480) Blank <= 0;
end

always @(posedge ReadRdy1) begin
	 if (WriteBufferIndex < 2)
	     WriteBufferIndex <= WriteBufferIndex + 1'b1;
	 else
	     WriteBufferIndex <= 1'b0;
end

always @(posedge ReadRdy1) begin
    ReqAddr1 = ReqAddr1 + 1'b1;
//	 ReqAddr2 = ReqAddr2 + 1'b1;
//	 ReqAddr3 = ReqAddr3 + 1'b1;
end

endmodule