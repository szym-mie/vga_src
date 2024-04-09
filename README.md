# VGA output

## Display

This module works in standard VGA mode of 640x480 at 60Hz monitor refresh rate.

Full specification:

```
pixel clock: 25MHz
-0.7% deviation from ideal 25.175MHz

pixel mode: RGB222 6bpp
max analog color output voltage: 0.6V
sync signal level: 3.3V
```

## Hardware

---
### CAUTION

SPI connection requires 3.3V voltage level for safe operation

---

Apart from standard VGA connector, there is a SPI connection:

```
[  GND ]--(1)
< CSEL ]--(2)
< MOSI ]--(3)
< SCLK ]--(4)
```

FPGA:
```
MIMAS SPARTAN6 MODULE
```

Memory:
```
IS61LV5128AL 512K x 8 HIGH-SPEED CMOS STATIC RAM
access max time: 10, 12ns
full read/write max time: <20ns 
```

## Video memory

### Layout - pixel blocks and block pointers

Framebuffer video RAM pixels are stored in RGB222 (6bpp) pixel format so that every 4 pixels can be stored in 3 bytes
of memory. Thus a memory controller requires 4 pixels to be written at once, to eliminate costly reads from memory,
with an aligment requirement of starting column index being a multiple of 4.

A block pointer consists of line index, and horizontal block index. Line index is the same as display row, while the horizontal block index works differently - 
it tells which block from the start of the row is selected. Getting starting display column number can be obtained by multiplying horizontal block index by 4.

```
     0    1    2    3
     |    |    |    |
  0 -+----+----+----+-/
     |1234|5678|XXXX| \
  1 -+----+----+----+-/
     ~~~~~~~~~~~~~~~~~
```

### Time frames and slots

Because of the underlying pixel format 3 reads are required for each 4 bytes displyed. With each pixel being displayed every 40ns, a single time frame has duration of 160ns.

A proper settling time for every read/write with 10ns memory is closer to 20ns due to AC characteristics of both memory chip and the internal FPGA port drivers as well as the connection between both. The 10ns timing indicates minimal time to start the actual input/output phase just after obtaining valid address.

This leaves the MMU with 8 time slots in each frame, 3 of which being the mandatory pixel block fetch. Other 5 of those slots
can be freely used, currently for writing to the other buffer. This would make it possible for each frame to be completely different, giving a possibility of true 60Hz video being presented. 

Nevertheless due to practical reasons, a limiting factor might be the SPI interface, along with the most likely lower frequency of the microcontroller driving the display controller.

SPI data, due to lower data throuput (clock is assumed max. 100MHz) can be written in one time frame.

## Modules

- spi.v - 8-bit SPI receiver with rudimentary transfer status
- vbuffer.v - video output buffer unit, reads pixels through VMMU to hold buffer
- vcmd.v - video command processor, interacts with received data from SPI
- vcounter.v - video output counter unit, controls blanking and analog output
- vmmu.v - video memory managment unit, time-slots reads and writes, controls memory chip
- vga.v - top-level module

## User Constrained Files

- vga.demoboard.ucf - for quick demo on a breadboard, no memory installed
- vga.schematic.ucf - pin numbering according to the planned schematic
- vga.ucf - same as above, except for on change of one data pin location - 
   a wire had to be placed and a connection rerouted due to confusing Mimas 
   pin header schematics

## SPI commands

### Packed and unpacked pixel data

Video data can be sent in two formats through the interface (packed and unpacked).

- Packed format is native to the video unit in the form of 3 consecutive bytes ```[0brrggbbrr,0bggbbrrgg,0bbrrggbb]```, allowing for fast writes and higher throughput. However this format is unhandy to work with on an external device, requiring additional encoding on display endpoint.
- Unpacked data is sent with each byte being in form of ```0b00rrggbb```.

### Command reference

| Instruction | Format                   | Desciption                                                                 |
|-------------|--------------------------|----------------------------------------------------------------------------|
| NOOP        | 0x00                     | Do nothing                                                                 |
| BUFSWAP     | 0x01                     | Start reading next frame pixel data from the other buffer                  |
| SETNOINC    | 0x10                     | Don't increment block pointer after each write                             |
| SETHINC     | 0x11                     | Increment block pointer horizontally after each write                      |
| SET0        | 0x12                     | Reset block pointer to (0, 0)                                              |
| SETX        | 0x2X,0xXX                | Set column 'X' of destination block pointer (see block pointer remark)     |
| SETY        | 0x3Y,0xYY                | Set line 'Y' of destination block pointer                                  |
| WRITE1U     | 0x40,0xPP,0xPP,0xPP,0xPP | Write one unpacked pixel block                                             |
| WRITE1P     | 0x41,0xPP,0xPP,0xPP      | Write one packed pixel block                                               |
| WRITENU     | 0x42,0xNN,0xNN,0xPP,...  | Write N (< 65,536) unpacked pixel blocks                                   |
| WRITENP     | 0x43,0xNN,0xNN,0xPP,...  | Write N (< 65,536) packed pixel blocks                                     |