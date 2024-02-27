`timescale 1ns/1ps
`include "vcounter.v"
`include "vbuffer.v"

module vga (
    input wire MainClkSrc,
    output wire[5:0] OutColor,
    output reg OutHsync,
    output reg OutVsync
);

wire PixelClkIbufg;
wire PixelClkBufg;
wire PixelClkDcmOut;
wire PixelClkSrc;

wire DcmRst;
wire[7:0] DcmStatus;
wire DcmLocked;
wire DcmClkFxStopped = DcmStatus[2];

assign DcmRst = DcmClkFxStopped & ~DcmLocked;

IBUFG PixelClkIbufgInst(
    .I(MainClkSrc),
    .O(MainClkIbufg)
);

// using synthesized clock@25MHz
DCM_SP #(
    .CLKIN_PERIOD(10), // 10ns
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(2.0), // not used
    .CLKFX_MULTIPLY(2),
    .CLKFX_DIVIDE(8)
) PixelClkDcmInst (
    .CLKIN(MainClkIbufg),
    .CLKFB(1'b0),
    .RST(DcmRst),
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
    .STATUS(DcmStatus),
    .LOCKED(DcmLocked),
    .PSDONE(),
    .DSSEN(1'b0)
);

BUFG PixelClkBufgInst (
    .I(PixelClkDcmOut),
    .O(PixelClkSrc)
);

initial OutHsync <= 1'b1;
initial OutVsync <= 1'b1;

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

vbuffer #(
    .AWIDTH(2), 
    .BPP(6),
    .PSIZE(4)
) VideoBuffer (
    PixelClkSrc, 
    1'b0, 
    Blank, 
    PixelCounter[1:0],
    2'b0,
    6'b0, 
    OutColor
);

always @(posedge PixelClkSrc) begin
    if (PixelCounter == 657) OutHsync <= 0;
    if (PixelCounter == 753) OutHsync <= 1;

    if (LineCounter == 491) OutVsync <= 0;
    if (LineCounter == 493) OutVsync <= 1;

    if (PixelCounter == 640) Blank <= 1;
    if (PixelCounter == 799 && LineCounter < 480) Blank <= 0;
    // if (PixelCounter < 640 && LineCounter < 480) OutColor <= 6'b000011;
    // else OutColor <= 6'b0;
end

endmodule