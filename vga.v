`timescale 1ns/1ps
`include "vctl.v"
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
    output wire HsyncOut,
    output wire VsyncOut,
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
    .CLK_FEEDBACK("1X"),
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

wire ActHorz;
wire ActVert;
wire[18:0] PixelAddr;
reg CycleReadAddr = 1;

wire[9:0] PixelCnt;
wire[9:0] LineCnt;

vctl #(
    .XWIDTH(10),
    .YWIDTH(10),
	 .AWIDTH(19),
    .XMAX(799),
    .YMAX(524),
	 .HDMIN(3),
	 .HDMAX(643),
	 .VDMIN(524),
	 .VDMAX(479)
) VideoCtl (
    .PixelClk(PixelClkSrc),
    .PixelCnt(PixelCnt),
    .LineCnt(LineCnt),
	 .AddrOut(PixelAddr),
	 .AddrClkOut(),
	 .IsActHorz(ActHorz),
	 .IsActVert(ActVert)
);

vsig #(
    .XWIDTH(10),
	 .YWIDTH(10)
) VideoSig (
    .PixelClk(PixelClkSrc),
    .PixelCnt(PixelCnt),
    .LineCnt(LineCnt),
	 .IsActHorz(ActHorz),
	 .IsActVert(ActVert),
	 .HSync(HsyncOut),
	 .VSync(VsyncOut),
	 .Blank(Blank)
);

wire SpiByteRdy;
wire[7:0] SpiByteRecv;

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
    .ReqAddrSrc1(PixelAddr),
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
    .BPP(6)
) VideoBuffer (
    .PixelClk(PixelClkSrc), 
    .ReqWrite(ReadRdy), 
    .Blank(Blank), 
    .DataIn(ReadData), 
    .VideoOut(ColorOut)
);

endmodule
