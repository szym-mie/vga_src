`timescale 1ns/1ps
`include "vcounter.v"
`include "vbuffer.v"
`include "vmmu.v"

module vga (
    input wire MainClkSrc,
    output wire[18:0] MemAddr,
    inout wire[7:0] MemData,
	 output wire TestOut1,
	 output wire TestOut2,
    output wire MemWE,
    output wire MemOE,
    output wire[5:0] ColorOut,
    output reg HsyncOut,
    output reg VsyncOut,
    input wire Sclk,
    input wire Mosi,
    input wire CSel
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

// memory clock using synthesized clock@200MHz
DCM_SP #(
    .CLKIN_PERIOD(10), // 10ns
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(2.0), // not used
    .CLKFX_MULTIPLY(4),
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
reg CycleReadAddr = 1;

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

wire SpiByteRdy;
wire[7:0] SpiByteRecv;

reg[1:0] WriteBufferIndex = 1'b0; 

spi Spi (
    MemClkSrc,
    Sclk,
	 Mosi,
	 CSel,
	 SpiByteRdy,
	 SpiByteRecv
);

assign TestOut1 = SpiByteRdy;
assign TestOut2 = Sclk;

wire[7:0] ReadData;
wire[7:0] _ReadData;
wire ReadRdy;
wire _ReadRdy;

wire WriteDataOutClk;
wire HasWriteData;

wire[7:0] WriteData;
wire[18:0] WriteAddr;

reg[18:0] ReadAddr = 19'b000_0000_0000_0000_0000;

vcmd VideoCmd (
	 SpiByteRdy,
	 1'b1,
    SpiByteRecv,
	 WriteDataOutClk,
	 HasWriteData,
	 WriteAddr,
	 WriteData
);

vmmu #(
    .AWIDTH(19),
    .DWIDTH(8),
    .TSSIZE(8)
) VMMU (
    .MemClk(MemClkSrc),
    .ReqAddrSrc1(ReadAddr),
    .ReqAddrSrc2(WriteAddr),
    .ReqAddrSrc3(1'b0),
    .ReqAddrSrc4(1'b0),
    .ReqReadData1(ReadData),
    .ReadDataRdy1(ReadRdy),
    .ReqReadData2(_ReadData),
    .ReadDataRdy2(_ReadRdy),
    .ReqWriteData(WriteData),
	 .HasWriteData(HasWriteData),
	 .WriteDataRdy(WriteDataOutClk),
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
    .ReqWrite(ReadRdy), 
    .Blank(Blank), 
    .ReadIndex(PixelCounter[1:0]),
    .WriteIndex(WriteBufferIndex),
    .DataIn(ReadData), 
    .VideoOut(ColorOut)
);

always @(posedge PixelClkSrc) begin
    if (PixelCounter == 661) HsyncOut <= 0;
    if (PixelCounter == 757) HsyncOut <= 1;

    if (LineCounter == 491) VsyncOut <= 0;
    if (LineCounter == 493) VsyncOut <= 1;

    if (PixelCounter == 643) Blank <= 1;
    if (PixelCounter == 799 && LineCounter < 480) Blank <= 0;
end

always @(posedge ReadRdy) begin
	 if (WriteBufferIndex < 2)
	     WriteBufferIndex <= WriteBufferIndex + 1'b1;
	 else
	     WriteBufferIndex <= 1'b0;
		  
	 
    if (LineCounter == 524) ReadAddr <= 1'b0;
	 else if (!Blank) ReadAddr <= ReadAddr + 1'b1;
end

endmodule