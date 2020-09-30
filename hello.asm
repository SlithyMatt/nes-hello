.include "ppu.inc"
.include "apu.inc"

.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

hello_str: .asciiz "Hello, World!"

START_X        = 7
START_Y        = 2
START_NT_ADDR  = $2000 + 32*START_Y + START_X

.macro WAIT_VBLANK
:  bit PPUSTATUS
   bpl :-
.endmacro

start:
   sei
   cld
   ldx #$40
   stx APU_FRAMECTR ; disable IRQ
   ldx #$FF
   txs ; init stack pointer
   inx ; reset X to zero to initialize PPU and APU registers
   stx PPUCTRL
   stx PPUMASK
   stx APU_MODCTRL

   WAIT_VBLANK

   ; while waiting for two frames for PPU to stabilize, reset RAM
   txa   ; still zero!
@clr_ram:
   sta $000,x
   sta $100,x
   sta $200,x
   sta $300,x
   sta $400,x
   sta $500,x
   sta $600,x
   sta $700,x
   inx
   bne @clr_ram

   WAIT_VBLANK

   ; set scroll position to 0,0
   sta PPUSCROLL ; x = 0
   sta PPUSCROLL ; y = 0
   ; start writing to palette, starting with background color
   lda #>BG_COLOR
   sta PPUADDR
   lda #<BG_COLOR
   sta PPUADDR
   lda #BLACK
   sta PPUDATA ; black backround color
   sta PPUDATA ; palette 0, color 0 = black
   lda #(RED | DARK)
   sta PPUDATA ; color 1 = dark red
   lda #(RED | NEUTRAL)
   sta PPUDATA ; color 2 = neutral red
   lda #(RED | LIGHT)
   sta PPUDATA ; color 3 = light red

   lda #>START_NT_ADDR
   sta PPUADDR
   lda #<START_NT_ADDR
   sta PPUADDR
   ldx #0
@string_loop:
   lda hello_str,x
   beq @game_loop
   sta PPUDATA
   inx
   jmp @string_loop

@game_loop:
   WAIT_VBLANK
   ; do something
   jmp @game_loop
