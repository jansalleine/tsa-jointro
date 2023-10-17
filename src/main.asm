                    !cpu 6510
; ==============================================================================
ENABLE              = 0x20
ENABLE_JMP          = 0x4C
DISABLE             = 0x2C
; ==============================================================================
BLACK               = 0x00
WHITE               = 0x01
RED                 = 0x02
CYAN                = 0x03
PURPLE              = 0x04
GREEN               = 0x05
BLUE                = 0x06
YELLOW              = 0x07
ORANGE              = 0x08
BROWN               = 0x09
PINK                = 0x0A
DARK_GREY           = 0x0B
GREY                = 0x0C
LIGHT_GREEN         = 0x0D
LIGHT_BLUE          = 0x0E
LIGHT_GREY          = 0x0F
; ==============================================================================
MEMCFG              = 0x35
; ==============================================================================
; ------------------------------------------------------------------------------
;                   BADLINEs (0xD011 default)
;                   -------------------------
;                   00 : 0x33
;                   01 : 0x3B
;                   02 : 0x43
;                   03 : 0x4B
;                   04 : 0x53
;                   05 : 0x5B
;                   06 : 0x63
;                   07 : 0x6B
;                   08 : 0x73
;                   09 : 0x7B
;                   10 : 0x83
;                   11 : 0x8B
;                   12 : 0x93
;                   13 : 0x9B
;                   14 : 0xA3
;                   15 : 0xAB
;                   16 : 0xB3
;                   17 : 0xBB
;                   18 : 0xC3
;                   19 : 0xCB
;                   20 : 0xD3
;                   21 : 0xDB
;                   22 : 0xE3
;                   23 : 0xEB
;                   24 : 0xF3
; ------------------------------------------------------------------------------
IRQ_LINE0           = 0xFA
IRQ_LINE1           = 0x29
IRQ_LINE2           = 0x41
IRQ_LINE3           = 0x49
IRQ_LINE4           = 0x59
IRQ_LINE5           = 0x69
IRQ_LINE6           = 0x71
IRQ_LINE7           = 0x81
IRQ_LINE8           = 0x91
IRQ_LINE9           = 0x99
IRQ_LINE10          = 0xB1
; ==============================================================================
zp_start            = 0x02
flag_irq_ready      = zp_start
frame_ct_0          = flag_irq_ready+1
frame_ct_1          = frame_ct_0+1
frame_ct_2          = frame_ct_1+1
pt_charset          = frame_ct_2+1
pt_screenpos        = pt_charset+2
; ==============================================================================
;                   MEMORY MAP:
; ------------------------------------------------------------------------------
;                   0x0400 - 0x07E7       vidmem0
;                   0x07F0 - 0x07FF       sprite pointers
;                   0x0800 - 0x0FFF       charset
;                   0x1000 - 0x1C76       music
;                   0x2000 - 0x243F       sprite data
;                   0x24EF - 0x4496       code + data
; ==============================================================================
code_start          = 0x24EF           ; calculated so that irqs start at 0x2500
vicbank0            = 0x0000
charset0            = vicbank0+0x0800
vidmem0             = vicbank0+0x0400
music_start         = 0x1000
music_init          = music_start
music_play          = music_start+3
sprite_data         = vicbank0+0x2000
sprite_base         = <((sprite_data-vicbank0)/0x40)
dd00_val0           = <!(vicbank0/0x4000) & 3
d018_val0_hi        = <(((vidmem0-vicbank0)/0x400) << 4)
d018_val0_lo        = <(((charset0-vicbank0)/0x800) << 1)
d018_val0           = d018_val0_hi + d018_val0_lo
; ==============================================================================
                    !macro flag_set .flag {
                        lda #1
                        sta .flag
                    }
                    !macro flag_clear .flag {
                        lda #0
                        sta .flag
                    }
                    !macro flag_get .flag {
                        lda .flag
                    }
; ==============================================================================
                    *= music_start
                    !bin "sid/internationale.sid",,0x7E
; ==============================================================================
                    *= sprite_data
                    !fi 0x40,0
                    !bin "gfx/unicorn-sprites.bin"
                    !bin "gfx/anarchy-sprites.bin"
; ==============================================================================
                    *= code_start
                    lda #0x7F
                    sta 0xDC0D
                    lda #MEMCFG
                    sta 0x01
                    lda #0x1B
                    sta 0xD011
                    jmp init_code
; ==============================================================================
                    !zone IRQS
                    NUM_IRQS = 0x0B
irq:                sta .irq_savea+1
                    stx .irq_savex+1
                    sty .irq_savey+1
                    lda #<irq_stable              ; ( 02 / 21 )
                    sta 0xFFFE                    ; ( 04 / 25 )
                    lda #>irq_stable              ; ( 02 / 27 )
                    sta 0xFFFF                    ; ( 04 / 31 )
                    inc 0xD012                    ; ( 06 / 37 )
                    asl 0xD019                    ; ( 06 / 43 )
                    tsx                           ; ( 02 / 45 )
                    cli                           ; ( 02 / 47 )
                    !fi 14, 0xEA
irq_stable:         txs
                    ldx #0x08
-                   dex
                    bne -
                    bit 0xEA
                    nop
irq_line:           lda #IRQ_LINE0
                    cmp 0xD012
                    beq irq_next
irq_next:           jmp irq0
irq_end:            lda 0xD012
-                   cmp 0xD012
                    beq -
.irq_index:         ldx #0
                    lda irq_tab_lo,x
                    sta irq_next+1
                    lda irq_tab_hi,x
                    sta irq_next+2
                    lda irq_lines,x
                    sta irq_line+1
                    sec
                    sbc #1
                    sta 0xD012
                    inc .irq_index+1
                    lda .irq_index+1
                    cmp #NUM_IRQS
                    bne +
                    lda #0
                    sta .irq_index+1
+                   lda #<irq
                    sta 0xFFFE
                    lda #>irq
                    sta 0xFFFF
                    asl 0xD019
.irq_savea:         lda #0
.irq_savex:         ldx #0
.irq_savey:         ldy #0
                    rti
; ==============================================================================
irq0:               +flag_set flag_irq_ready
                    ldx #5
-                   dex
                    bpl -
                    lda #BLUE
                    sta 0xD020
                    ldx #10
-                   dex
                    bpl -
                    lda #LIGHT_BLUE
                    sta 0xD020
                    ldx #10
-                   dex
                    bpl -
highlight0:         lda #PURPLE
                    sta 0xD020
enable_rainbow:     bit switch_to_rainbow
                    jsr music_play
                    jsr anim_raute
                    jsr anim_ausr
                    jsr anim_dot
                    jsr anim_kringel
                    jsr anim_colon
                    jsr anim_minus
                    jsr anim_highlight
                    jsr anim_unicorn
                    jsr frame_counter
                    jsr flow_control
                    jsr sprites_anarchy
                    lda #0x08
                    sta 0xD016
                    lda #0
-                   cmp 0xD012
                    bne -
                    lda #BLACK
                    sta 0xD020
                    sta 0xD021
                    jmp irq_end
; ==============================================================================
irq1:               ldx #10
-                   dex
                    bpl -
                    lda #BLUE
                    sta 0xD020
                    ldx #9
-                   dex
                    bpl -
                    nop
                    bit 0xEA
                    lda #LIGHT_BLUE
                    sta 0xD020
                    ldx #10
-                   dex
                    bpl -
                    nop
highlight2:         lda #PURPLE
                    sta 0xD020
                    ldx #23
-                   dex
                    bpl -
                    lda #LIGHT_BLUE
                    sta 0xD020
                    ldx #10
-                   dex
                    bpl -
                    lda #BLUE
                    sta 0xD020
                    ldx #10
-                   dex
                    bpl -
                    lda #BLACK
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq2:               ldx #9
-                   dex
                    bpl -
                    nop
rb_col_0:           lda #BLACK ;RED
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq3:               ldx #9
-                   dex
                    bpl -
                    nop
rb_col_1:           lda #BLACK ;ORANGE
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq4:               ldx #6
-                   dex
                    bpl -
rb_col_2:           lda #BLACK ;YELLOW
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq5:               ldx #6
-                   dex
                    bpl -
                    nop
                    nop
rb_col_3:           lda #BLACK ;GREEN
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq6:               ldx #5
-                   dex
                    bpl -
                    nop
                    bit 0xEA
                    nop
rb_col_4:           lda #BLACK ;CYAN
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq7:               ldx #7
-                   dex
                    bpl -
rb_col_5:           lda #BLACK ;BLUE
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq8:               ldx #5
-                   dex
                    bpl -
                    nop
                    nop
rb_col_6:           lda #BLACK ;PURPLE
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq9:               ldx #9
-                   dex
                    bpl -
                    nop
                    lda #BLACK
                    sta 0xD020
                    jmp irq_end
; ==============================================================================
irq10:              ldx #26
-                   dex
                    bpl -
                    lda #BLUE
                    sta 0xD020
                    sta 0xD021
                    ldx #9
-                   dex
                    bpl -
                    nop
                    lda #LIGHT_BLUE
                    sta 0xD020
                    sta 0xD021
                    ldx #9
-                   dex
                    bpl -
                    nop
highlight1:         lda #PURPLE
                    sta 0xD020
                    sta 0xD021
                    ldx #22
-                   dex
                    bpl -
                    lda #LIGHT_BLUE
                    sta 0xD020
                    sta 0xD021
                    ldx #9
-                   dex
                    bpl -
                    nop
                    lda #BLUE
                    sta 0xD020
                    sta 0xD021
                    ldx #9
-                   dex
                    bpl -
                    nop
                    lda #BLACK
                    sta 0xD020
                    sta 0xD021
                    lda #0x00
d016_bits012:       ora #0x00
                    sta 0xD016
                    jsr sprites_unicorn
                    jmp irq_end
; ==============================================================================
irq_tab_lo:         !byte <irq0, <irq1, <irq2, <irq3
                    !byte <irq4, <irq5, <irq6, <irq7
                    !byte <irq8, <irq9, <irq10
irq_tab_hi:         !byte >irq0, >irq1, >irq2, >irq3
                    !byte >irq4, >irq5, >irq6, >irq7
                    !byte >irq8, >irq9, >irq10
irq_lines:          !byte IRQ_LINE0, IRQ_LINE1, IRQ_LINE2, IRQ_LINE3
                    !byte IRQ_LINE4, IRQ_LINE5, IRQ_LINE6, IRQ_LINE7
                    !byte IRQ_LINE8, IRQ_LINE9, IRQ_LINE10
; ==============================================================================
frame_counter:      clc
                    lda frame_ct_0
                    adc #1
                    sta frame_ct_0
                    lda frame_ct_1
                    adc #0
                    sta frame_ct_1
                    lda frame_ct_2
                    adc #0
                    sta frame_ct_2
                    rts
; ==============================================================================
flow_control:       lda frame_ct_2
                    cmp #0
                    bne +
                    lda frame_ct_1
                    cmp #6
                    bne +
                    lda frame_ct_0
                    cmp #1
                    bne +
                    lda #ENABLE
                    sta enable_rainbow
+                   lda frame_ct_2
                    cmp #0
                    bne +
                    lda frame_ct_1
                    cmp #6
                    bne +
                    lda frame_ct_0
                    cmp #0x85
                    bne +
                    lda #0
                    sta sprites_unicorn+1
+                   lda frame_ct_2
                    cmp #0
                    bne +
                    lda frame_ct_1
                    cmp #0x06
                    bne +
                    lda frame_ct_0
                    cmp #0xF5
                    bne +
                    lda #0
                    sta sprites_anarchy+1
+                   rts
; ==============================================================================
init_code:          jsr init_nmi
                    jsr init_zp
                    lda #0
                    jsr music_init
                    jsr init_charset
                    lda #BLUE
                    sta 0xD021
                    jsr basic_fade
                    jsr init_vic
                    jsr init_irq
                    jmp mainloop
; ==============================================================================
init_irq:           lda irq_lines
                    sec
                    sbc #1
                    sta 0xD012
                    lda #<irq
                    sta 0xFFFE
                    lda #>irq
                    sta 0xFFFF
                    lda 0xD011
                    and #%01101111
                    ora #%00010000
                    sta 0xD011
                    lda #0x01
                    sta 0xD019
                    sta 0xD01A
                    rts
; ==============================================================================
init_nmi:           lda #<nmi
                    sta 0x0318
                    !if MEMCFG = 0x35 {
                        sta 0xFFFA
                    }
                    lda #>nmi
                    sta 0x0319
                    !if MEMCFG = 0x35 {
                        sta 0xFFFB
                    }
                    rts
; ==============================================================================
init_vic:           lda #dd00_val0
                    sta 0xDD00
                    lda #d018_val0
                    sta 0xD018

                    lda #BLACK
                    sta 0xD020
                    sta 0xD021
                    rts
; ==============================================================================
init_zp:            ldx #zp_start
                    lda #0
-                   sta 0x00,x
                    inx
                    bne -
                    rts
; ==============================================================================
init_charset:       lda #0x33
                    sta 0x01
                    ldx #0
-                   lda 0xD000+0x000,x
                    sta charset0+0x000,x
                    lda 0xD000+0x100,x
                    sta charset0+0x100,x
                    lda 0xD000+0x200,x
                    sta charset0+0x200,x
                    lda 0xD000+0x300,x
                    sta charset0+0x300,x
                    lda 0xD000+0x400,x
                    sta charset0+0x400,x
                    lda 0xD000+0x500,x
                    sta charset0+0x500,x
                    lda 0xD000+0x600,x
                    sta charset0+0x600,x
                    lda 0xD000+0x700,x
                    sta charset0+0x700,x
                    inx
                    bne -
                    lda #MEMCFG
                    sta 0x01
                    rts
; ==============================================================================
                    !zone MAINLOOP
mainloop:           jsr wait_irq
                    jsr scroller
                    jmp mainloop
; ==============================================================================
                    !zone NMI
nmi:                lda #0x37               ; restore 0x01 standard value
                    sta 0x01
                    lda #0                  ; if AR/RR present
                    sta 0xDE00              ; reset will lead to menu
                    jmp 0xFCE2              ; reset
; ==============================================================================
                    !zone WAIT
wait_irq:           +flag_clear flag_irq_ready
.wait_irq:          +flag_get flag_irq_ready
                    beq .wait_irq
                    rts
; ==============================================================================
                    !zone ANIMATION
                    ANIM_RAUTE_SPEED = 3
anim_raute:         lda #ANIM_RAUTE_SPEED
                    beq +
                    dec anim_raute+1
                    rts
+                   lda #ANIM_RAUTE_SPEED
                    sta anim_raute+1
                    ldx anim_raute_pt
                    cpx #8
                    bne +
                    ldx #0
                    stx anim_raute_pt
+                   lda anim_tab_raute_lo,x
                    sta .arsrc+1
                    lda anim_tab_raute_hi,x
                    sta .arsrc+2
                    ldx #7
.arsrc:             lda 0x0000,x
.ardst:             sta charset0+(35*8),x
                    dex
                    bpl .arsrc
                    inc anim_raute_pt
                    rts
anim_raute_pt:      !byte 0
; ==============================================================================
                    ANIM_AUSR_SPEED = 1
anim_ausr:          lda #ANIM_AUSR_SPEED
                    beq +
                    dec anim_ausr+1
                    rts
+                   lda #ANIM_AUSR_SPEED
                    sta anim_ausr+1
                    ldx anim_ausr_pt
                    cpx #8
                    bne +
                    ldx #0
                    stx anim_ausr_pt
+                   lda anim_tab_ausr_lo,x
                    sta .aasrc+1
                    lda anim_tab_ausr_hi,x
                    sta .aasrc+2
                    ldx #7
.aasrc:             lda 0x0000,x
.aadst:             sta charset0+(33*8),x
                    dex
                    bpl .aasrc
                    inc anim_ausr_pt
                    rts
anim_ausr_pt:       !byte 0
; ==============================================================================
                    ANIM_DOT_SPEED = 3
anim_dot:           lda #ANIM_DOT_SPEED
                    beq +
                    dec anim_dot+1
                    rts
+                   lda #ANIM_DOT_SPEED
                    sta anim_dot+1
                    ldx anim_dot_pt
                    cpx #10
                    bne +
                    ldx #0
                    stx anim_dot_pt
+                   lda anim_tab_dot_lo,x
                    sta .adsrc+1
                    lda anim_tab_dot_hi,x
                    sta .adsrc+2
                    ldx #7
.adsrc:             lda 0x0000,x
.addst:             sta charset0+(46*8),x
                    dex
                    bpl .adsrc
                    inc anim_dot_pt
                    rts
anim_dot_pt:       !byte 0
; ==============================================================================
                    ANIM_KRINGEL_SPEED = 1
anim_kringel:       lda #ANIM_KRINGEL_SPEED
                    beq +
                    dec anim_kringel+1
                    rts
+                   lda #ANIM_KRINGEL_SPEED
                    sta anim_kringel+1
                    ldx anim_kringel_pt
                    cpx #4
                    bne +
                    ldx #0
                    stx anim_kringel_pt
+                   lda anim_tab_kringel_lo,x
                    sta .aksrc+1
                    lda anim_tab_kringel_hi,x
                    sta .aksrc+2
                    ldx #7
.aksrc:             lda 0x0000,x
.akdst:             sta charset0+(104*8),x
                    dex
                    bpl .aksrc
                    inc anim_kringel_pt
                    rts
anim_kringel_pt:    !byte 0
; ==============================================================================
                    ANIM_COLON_SPEED = 6
anim_colon:         lda #ANIM_COLON_SPEED
                    beq +
                    dec anim_colon+1
                    rts
+                   lda #ANIM_COLON_SPEED
                    sta anim_colon+1
                    ldx anim_colon_pt
                    cpx #25
                    bne +
                    ldx #0
                    stx anim_colon_pt
+                   lda anim_tab_colon_lo,x
                    sta .acsrc+1
                    lda anim_tab_colon_hi,x
                    sta .acsrc+2
                    ldx #7
.acsrc:             lda 0x0000,x
.acdst:             sta charset0+(58*8),x
                    dex
                    bpl .acsrc
                    inc anim_colon_pt
                    rts
anim_colon_pt:      !byte 0
; ==============================================================================
                    ANIM_MINUS_SPEED = 2
anim_minus:         lda #ANIM_MINUS_SPEED
                    beq +
                    dec anim_minus+1
                    rts
+                   lda #ANIM_MINUS_SPEED
                    sta anim_minus+1
                    ldx anim_minus_pt
                    cpx #8
                    bne +
                    ldx #0
                    stx anim_minus_pt
+                   lda anim_tab_minus_lo,x
                    sta .amsrc+1
                    lda anim_tab_minus_hi,x
                    sta .amsrc+2
                    ldx #7
.amsrc:             lda 0x0000,x
.amdst:             sta charset0+(45*8),x
                    dex
                    bpl .amsrc
                    inc anim_minus_pt
                    rts
anim_minus_pt:      !byte 0
; ==============================================================================
                    ANIM_HIGHLIGHT_COUNT = 0xCF
                    ANIM_HIGHLIGHT_SPEED = 0x03
anim_highlight:     lda #ANIM_HIGHLIGHT_COUNT
                    beq .check_speed_hl
                    dec anim_highlight+1
                    rts
.check_speed_hl:    lda #ANIM_HIGHLIGHT_SPEED
                    beq .change_highlight
                    dec .check_speed_hl+1
                    rts
.change_highlight:  lda #ANIM_HIGHLIGHT_SPEED
                    sta .check_speed_hl+1
                    ldx .fade_pt_hl
                    lda .fade_tab,x
                    bmi +
                    sta highlight0+1
                    sta highlight1+1
                    sta highlight2+1
                    inc .fade_pt_hl
                    rts
+                   lda #ANIM_HIGHLIGHT_COUNT
                    sta anim_highlight+1
                    lda #0
                    sta .fade_pt_hl
                    rts
.fade_pt_hl:        !byte 0x00
.fade_tab:          !byte 0x0C, 0x03, 0x0D, 0x01
                    !byte 0x01, 0x0D, 0x03, 0x0C
                    !byte 0x04, 0xFF
; ==============================================================================
                    ANIM_UNICORN_COUNT = 0xFF
                    ANIM_UNICORN_SPEED = 0x05
anim_unicorn:       lda #ANIM_UNICORN_COUNT
                    beq .check_speed_uc
                    dec anim_unicorn+1
                    rts
.check_speed_uc:    lda #ANIM_UNICORN_SPEED
                    beq .change_unicorn
                    dec .check_speed_uc+1
                    rts
.change_unicorn:    lda #ANIM_UNICORN_SPEED
                    sta .check_speed_uc+1
                    ldx .fade_pt_uc
                    lda .fade_tab,x
                    bmi +
                    sta unicorn_color+1
                    inc .fade_pt_uc
                    rts
+                   lda #ANIM_UNICORN_COUNT
                    sta anim_unicorn+1
                    lda #0
                    sta .fade_pt_uc
                    rts
.fade_pt_uc:        !byte 0x00
; ==============================================================================
                    !zone SWITCH
                    SWITCH_TO_RAINBOW_SPEED = 8
                    NUM_RAINBOW_LINES = 11
switch_to_rainbow:  lda #SWITCH_TO_RAINBOW_SPEED
                    beq +
                    dec switch_to_rainbow+1
                    rts
+                   lda #SWITCH_TO_RAINBOW_SPEED
                    sta switch_to_rainbow+1
                    ldx #0x27
.srcrainbow:        lda colram_rainbow,x
.dstrainbow:        sta 0xD800+(2*40),x
                    dex
                    bpl .srcrainbow
                    lda .num_rb_lines+1
                    cmp #11
                    bne +
                    lda #RED
                    sta rb_col_0+1
                    jmp .num_rb_lines
+                   cmp #10
                    bne +
                    lda #ORANGE
                    sta rb_col_1+1
                    jmp .num_rb_lines
+                   cmp #8
                    bne +
                    lda #YELLOW
                    sta rb_col_2+1
                    jmp .num_rb_lines
+                   cmp #6
                    bne +
                    lda #GREEN
                    sta rb_col_3+1
                    jmp .num_rb_lines
+                   cmp #5
                    bne +
                    lda #CYAN
                    sta rb_col_4+1
                    jmp .num_rb_lines
+                   cmp #3
                    bne +
                    lda #BLUE
                    sta rb_col_5+1
                    jmp .num_rb_lines
+                   cmp #1
                    bne .num_rb_lines
                    lda #PURPLE
                    sta rb_col_6+1
.num_rb_lines:      lda #NUM_RAINBOW_LINES
                    beq +
                    dec .num_rb_lines+1
                    clc
                    lda .srcrainbow+1
                    adc #40
                    sta .srcrainbow+1
                    lda .srcrainbow+2
                    adc #0
                    sta .srcrainbow+2
                    clc
                    lda .dstrainbow+1
                    adc #40
                    sta .dstrainbow+1
                    lda .dstrainbow+2
                    adc #0
                    sta .dstrainbow+2
                    rts
+                   lda #NUM_RAINBOW_LINES
                    sta .num_rb_lines+1
                    lda #<(colram_rainbow)
                    sta .srcrainbow+1
                    lda #>(colram_rainbow)
                    sta .srcrainbow+2
                    lda #<(0xD800+(2*40))
                    sta .dstrainbow+1
                    lda #>(0xD800+(2*40))
                    sta .dstrainbow+2
                    lda #DISABLE
                    sta enable_rainbow
                    rts
; ==============================================================================
                    !zone SPRITES
                    COLOR_UNICORNS = PURPLE
                    POS_Y_UNICORN0 = 0xD1
                    POS_X_UNICORN0 = 0x1F
                    POS_Y_UNICORN1 = 0xD1
                    POS_X_UNICORN1 = 0x20
sprites_unicorn:    lda #1
                    beq +
                    ldx #sprite_base
                    stx vidmem0+0x3F8
                    stx vidmem0+0x3F9
                    stx vidmem0+0x3FA
                    stx vidmem0+0x3FB
                    stx vidmem0+0x3FC
                    stx vidmem0+0x3FD
                    stx vidmem0+0x3FE
                    stx vidmem0+0x3FF
                    jmp ++
+                   ldx #sprite_base+1
                    stx vidmem0+0x3F8
                    inx
                    stx vidmem0+0x3F9
                    inx
                    stx vidmem0+0x3FA
                    inx
                    stx vidmem0+0x3FB
                    inx
                    stx vidmem0+0x3FC
                    inx
                    stx vidmem0+0x3FD
                    inx
                    stx vidmem0+0x3FE
                    inx
                    stx vidmem0+0x3FF
++                  lda #POS_Y_UNICORN0
                    sta 0xD001
                    sta 0xD003
                    sta 0xD009
                    sta 0xD00B
                    lda #POS_Y_UNICORN0+21
                    sta 0xD005
                    sta 0xD007
                    sta 0xD00D
                    sta 0xD00F
                    lda #POS_X_UNICORN0
                    sta 0xD000
                    sta 0xD004
                    lda #POS_X_UNICORN0+24
                    sta 0xD002
                    sta 0xD006
                    lda #POS_X_UNICORN1
                    sta 0xD008
                    sta 0xD00C
                    lda #POS_X_UNICORN1+24
                    sta 0xD00A
                    sta 0xD00E
                    lda #0
                    sta 0xD017
                    sta 0xD01B
                    sta 0xD01C
                    sta 0xD01D
unicorn_color:      lda #COLOR_UNICORNS
                    sta 0xD027
                    sta 0xD027+1
                    sta 0xD027+2
                    sta 0xD027+3
                    sta 0xD027+4
                    sta 0xD027+5
                    sta 0xD027+6
                    sta 0xD027+7
                    lda #%11110000
                    sta 0xD010
                    lda #%11111111
                    sta 0xD015
                    rts
; ==============================================================================
                    POS_Y_ANARCHY = 0x58
                    POS_X_ANARCHY = 0x1F
                    H_ANARCHY = 21
                    W_ANARCHY = 24
sprites_anarchy:    lda #1
                    beq +
                    ldx #sprite_base
                    stx vidmem0+0x3F8
                    stx vidmem0+0x3F9
                    stx vidmem0+0x3FA
                    stx vidmem0+0x3FB
                    stx vidmem0+0x3FC
                    stx vidmem0+0x3FD
                    stx vidmem0+0x3FE
                    stx vidmem0+0x3FF
                    jmp ++
+                   ldx #sprite_base+9
                    stx vidmem0+0x3F8
                    inx
                    stx vidmem0+0x3F9
                    inx
                    stx vidmem0+0x3FA
                    inx
                    stx vidmem0+0x3FB
                    inx
                    stx vidmem0+0x3FC
                    inx
                    stx vidmem0+0x3FD
                    inx
                    stx vidmem0+0x3FE
                    inx
                    stx vidmem0+0x3FF
++                  lda #POS_Y_ANARCHY+(0*H_ANARCHY)
                    sta 0xD001
                    sta 0xD003
                    lda #POS_Y_ANARCHY+(1*H_ANARCHY)
                    sta 0xD005
                    sta 0xD007
                    sta 0xD009
                    lda #POS_Y_ANARCHY+(2*H_ANARCHY)
                    sta 0xD00B
                    sta 0xD00D
                    sta 0xD00F
                    lda #POS_X_ANARCHY+(0*W_ANARCHY)
                    sta 0xD000
                    sta 0xD004
                    sta 0xD00A
                    lda #POS_X_ANARCHY+(1*W_ANARCHY)
                    sta 0xD002
                    sta 0xD006
                    sta 0xD00C
                    lda #<POS_X_ANARCHY+(2*W_ANARCHY)
                    sta 0xD008
                    sta 0xD00E
                    lda #0
                    sta 0xD01B
                    sta 0xD01C
                    sta 0xD017
                    sta 0xD01D
                    lda #RED
                    sta 0xD027
                    sta 0xD027+1
                    sta 0xD027+2
                    sta 0xD027+3
                    sta 0xD027+4
                    sta 0xD027+5
                    sta 0xD027+6
                    sta 0xD027+7
                    lda #%00000000
                    sta 0xD010
                    lda #%11111111
                    sta 0xD015
                    rts
; ==============================================================================
                    !zone SCROLLER
                    SCROLLER_LINE = vidmem0 + (17*40)
scroller:           lda #0
                    cmp #8
                    bne .scroll
                    lda #0
                    sta scroller+1
                    jsr .pt_scrolltext
                    jsr .new_char
.scroll:            lda #0x07
                    sec
                    sbc #0x04
                    bcs +
                    jsr .hardscroll
                    lda #0x07
+                   sta .scroll+1
                    sta d016_bits012+1
                    rts
.pt_scrolltext:     lda scrolltext
                    cmp #0xff
                    beq .text_reset
                    tay
                    clc
                    lda .pt_scrolltext+1
                    adc #0x01
                    sta .pt_scrolltext+1
                    lda .pt_scrolltext+2
                    adc #0x00
                    sta .pt_scrolltext+2
                    tya
                    rts
.text_reset:        lda #<scrolltext
                    sta .pt_scrolltext+1
                    lda #>scrolltext
                    sta .pt_scrolltext+2
                    lda #' '
                    rts
.new_char:          tay
                    lda #0x00
                    sta pt_charset
                    lda #0xD8
                    sta pt_charset+1
                    lda #0
                    sta .char_hi+1
                    tya
                    asl
                    rol .char_hi+1
                    asl
                    rol .char_hi+1
                    asl
                    rol .char_hi+1
                    clc
                    adc pt_charset
                    sta pt_charset
.char_hi:           lda #0
                    adc pt_charset+1
                    sta pt_charset+1
                    lda #0x33
                    sta 0x01
                    ldy #0x07
-                   lda (pt_charset),y
                    sta .charbuffer,y
                    dey
                    bpl -
                    lda #0x35
                    sta 0x01
                    rts
.hardscroll:        lda #<SCROLLER_LINE
                    sta pt_screenpos
                    lda #>SCROLLER_LINE
                    sta pt_screenpos+1
                    ldx #0x00
-                   ldy #'.'
                    asl .charbuffer,x
                    bcc +
.pt_char:           ldy #248
+                   tya
                    ldy #0x27
                    sta (pt_screenpos),y
                    clc
                    lda pt_screenpos
                    adc #0x28
                    sta pt_screenpos
                    bcc +
                    inc pt_screenpos+1
+                   lda .pt_char+1
                    eor #(247 XOR 248)
                    sta .pt_char+1
                    inx
                    cpx #0x08
                    bne -
                    ldx #0
-                   !for i, 0, 7 {
                        lda SCROLLER_LINE+(i*40)+1,x
                        sta SCROLLER_LINE+(i*40),x
                    }
                    inx
                    cpx #0x27
                    bne -
                    lda .pt_char+1
                    eor #(247 XOR 248)
                    sta .pt_char+1
                    inc scroller+1
                    rts
.charbuffer:        !byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; ==============================================================================
                    !zone BASIC_FADE
basic_fade:         jsr .wait_bottom
.load_hi:           lda rand_tab_hi
                    sta .hi
.load_lo:           lda rand_tab_lo
                    sta .lo
                    lda .hi
                    bpl ++
                    ldx #0
--                  ldy #3
-                   jsr .wait_top
                    dey
                    bne -
                    lda .fade_tab,x
                    bmi +
                    sta 0xD021
                    inx
                    jmp --
+                   rts
++                  clc
                    lda .src_v+1
                    adc .lo
                    sta .src_v+1
                    lda .src_v+2
                    adc .hi
                    sta .src_v+2
                    clc
                    lda .dst_v+1
                    adc .lo
                    sta .dst_v+1
                    lda .dst_v+2
                    adc .hi
                    sta .dst_v+2
                    clc
                    lda .src_c+1
                    adc .lo
                    sta .src_c+1
                    lda .src_c+2
                    adc .hi
                    sta .src_c+2
                    clc
                    lda .dst_c+1
                    adc .lo
                    sta .dst_c+1
                    lda .dst_c+2
                    adc .hi
                    sta .dst_c+2
.src_v:             lda vidmem_data
.dst_v:             sta vidmem0
.src_c:             lda colram_data
.dst_c:             sta 0xD800
                    lda #<vidmem_data
                    sta .src_v+1
                    lda #>vidmem_data
                    sta .src_v+2
                    lda #<vidmem0
                    sta .dst_v+1
                    lda #>vidmem0
                    sta .dst_v+2
                    lda #<colram_data
                    sta .src_c+1
                    lda #>colram_data
                    sta .src_c+2
                    lda #<0xD800
                    sta .dst_c+1
                    lda #>0xD800
                    sta .dst_c+2
                    clc
                    lda .load_hi+1
                    adc #1
                    sta .load_hi+1
                    lda .load_hi+2
                    adc #0
                    sta .load_hi+2
                    clc
                    lda .load_lo+1
                    adc #1
                    sta .load_lo+1
                    lda .load_lo+2
                    adc #0
                    sta .load_lo+2
                    jmp basic_fade
.wait_bottom:       lda #0xFF
                    cmp 0xD012
                    bne *-3
                    rts
.wait_top:          bit $d011
                    bpl *-3
                    bit $d011
                    bmi *-3
                    rts
.hi:                !byte 0x00
.lo:                !byte 0x00
.fade_tab:          !byte 0x0B, 0x04, 0x0C, 0x03
                    !byte 0x03, 0x0D, 0x01, 0x01
                    !byte 0x0D, 0x03, 0x0C, 0x04
                    !byte 0x0B, 0x06, 0x00, 0xFF
; ==============================================================================
                    !zone DATA
vidmem_data:        !byte 0xE9, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0xDF
                    !byte 0x23, 0x23, 0x7E, 0x63, 0x63, 0x63, 0x63, 0x63
                    !byte 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63
                    !byte 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63
                    !byte 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63
                    !byte 0x63, 0x63, 0x63, 0x63, 0x63, 0x7C, 0x23, 0x23
                    !byte 0x23, 0x7E, 0x2D, 0x3A, 0x5F, 0xE0, 0xE0, 0xE0
                    !byte 0xE0, 0xE0, 0xE0, 0xE6, 0xE0, 0xE0, 0xE0, 0x74
                    !byte 0xE9, 0xE0, 0xCA, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0
                    !byte 0xE0, 0x74, 0xE9, 0xE0, 0xBA, 0xE0, 0xE0, 0xE0
                    !byte 0xE0, 0xE0, 0xDF, 0x2D, 0x3A, 0x2D, 0x7C, 0x23
                    !byte 0x21, 0x2D, 0x3A, 0x2D, 0x2E, 0xE0, 0xE0, 0xCA
                    !byte 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xC9, 0x74
                    !byte 0xE0, 0xE0, 0xE0, 0xAE, 0xE0, 0xE0, 0xE0, 0xC9
                    !byte 0x69, 0x60, 0xE0, 0xE0, 0xE0, 0xAE, 0xE0, 0xE0
                    !byte 0xE0, 0xC9, 0xE0, 0x2D, 0x2E, 0x3A, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x2D, 0x2E, 0x2E, 0x77, 0x77, 0x77
                    !byte 0x77, 0xDB, 0xE0, 0x4F, 0x77, 0x77, 0x77, 0x60
                    !byte 0xE0, 0xE6, 0xE0, 0x4F, 0x77, 0x77, 0x77, 0x77
                    !byte 0x2D, 0x2D, 0xE0, 0xE0, 0x4F, 0x77, 0x77, 0x77
                    !byte 0x77, 0xE0, 0xE0, 0x74, 0x2E, 0x2D, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0xE0, 0xAE, 0x74, 0x2E, 0x2E, 0x2E, 0x60
                    !byte 0xE0, 0xE0, 0xAE, 0x74, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0xE0, 0xE0, 0x74, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0xE0, 0xAE, 0x74, 0x2E, 0x2E, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x20, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0xE0, 0xE0, 0x74, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x5F, 0xE0, 0xE0, 0xE0, 0xE0, 0xAE, 0xE0, 0xE0
                    !byte 0xDF, 0x60, 0xCA, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0
                    !byte 0xE0, 0xE6, 0xE0, 0x74, 0x2E, 0x2D, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D
                    !byte 0x2D, 0xE0, 0xC9, 0x74, 0x2D, 0x2D, 0x2D, 0x2D
                    !byte 0x2D, 0x5F, 0xE0, 0xCA, 0xE0, 0xE0, 0xE0, 0xDB
                    !byte 0xE0, 0x74, 0xE0, 0xE0, 0x4F, 0x77, 0x77, 0x77
                    !byte 0x77, 0xE0, 0xE0, 0x74, 0x2D, 0x2D, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x6F, 0x68, 0x6F, 0x68, 0x68, 0x68
                    !byte 0x6F, 0xE0, 0xE0, 0x74, 0x6F, 0x68, 0x6F, 0x68
                    !byte 0x68, 0x68, 0x68, 0x68, 0x68, 0x68, 0x5F, 0xE0
                    !byte 0xE0, 0x74, 0xE0, 0xC9, 0x74, 0x6F, 0x68, 0x68
                    !byte 0x6F, 0xE0, 0xE0, 0x68, 0x68, 0x68, 0x6F, 0x21
                    !byte 0x21, 0xE9, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF
                    !byte 0xEF, 0xEA, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF
                    !byte 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEA
                    !byte 0xEF, 0xEF, 0xEA, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF
                    !byte 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0x69, 0x21
                    !byte 0x21, 0x77, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D, 0x2E
                    !byte 0x2E, 0xE0, 0xAE, 0x74, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0xE9, 0xE0
                    !byte 0xE0, 0x74, 0xE0, 0xE0, 0x74, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x93, 0x8A, 0x74, 0x2D, 0x2D, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x3A, 0x3A, 0x3A, 0x3A, 0x3A, 0x3A
                    !byte 0x3A, 0xE6, 0xE0, 0x74, 0x3A, 0x3A, 0x3A, 0xE9
                    !byte 0xCA, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xBA
                    !byte 0xE0, 0x74, 0xE0, 0xAE, 0x74, 0x3A, 0x3A, 0x3A
                    !byte 0x3A, 0xE0, 0xBA, 0x74, 0x3A, 0x3A, 0x2D, 0x21
                    !byte 0x21, 0x2D, 0x2D, 0x3A, 0x3A, 0x3A, 0x3A, 0x3A
                    !byte 0x3A, 0xE0, 0xE0, 0x74, 0x3A, 0x3A, 0x3A, 0xE0
                    !byte 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xC9, 0xE0
                    !byte 0x69, 0x3A, 0xE0, 0xE0, 0x74, 0x3A, 0x3A, 0x3A
                    !byte 0x3A, 0xE0, 0xE0, 0x74, 0x3A, 0x2D, 0x2D, 0x21
                    !byte 0x23, 0x7B, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D
                    !byte 0x2D, 0x2D, 0x77, 0x2D, 0x2D, 0x2D, 0x2D, 0x2D
                    !byte 0x2D, 0x2D, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77
                    !byte 0x20, 0x2D, 0x2D, 0x77, 0x20, 0x2D, 0x2D, 0x2D
                    !byte 0x2D, 0x77, 0x2D, 0x2D, 0x2D, 0x2D, 0x6C, 0x23
                    !byte 0x23, 0x23, 0x7B, 0x52, 0x52, 0x52, 0x52, 0x52
                    !byte 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52
                    !byte 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52
                    !byte 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52
                    !byte 0x52, 0x52, 0x52, 0x52, 0x52, 0x6C, 0x23, 0x23
                    !byte 0x5F, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23
                    !byte 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x69
                    !byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
                    !byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
                    !byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
                    !byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
                    !byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
                    !byte 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E
colram_data:        !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0B, 0x0B
                    !byte 0x0B, 0x04, 0x00, 0x0B, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x0D, 0x0D, 0x00, 0x0B, 0x00, 0x04, 0x0B
                    !byte 0x0B, 0x00, 0x0B, 0x00, 0x0C, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x0D
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x0B, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x00, 0x0C, 0x0B, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x00, 0x0C, 0x0C, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x07, 0x07, 0x0D, 0x0D, 0x0D, 0x0D, 0x00
                    !byte 0x07, 0x07, 0x07, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x00, 0x00, 0x07, 0x07, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x07, 0x07, 0x0D, 0x0C, 0x00, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C
                    !byte 0x0C, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x0C, 0x00
                    !byte 0x07, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x0C, 0x0C
                    !byte 0x0C, 0x0C, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x0C
                    !byte 0x0C, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x00, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C
                    !byte 0x0C, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x0C, 0x0C
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x00, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x0D, 0x0C, 0x00, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x07, 0x07, 0x0D, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x0D, 0x07, 0x07, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x0D, 0x07, 0x07, 0x0D, 0x00, 0x00, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
                    !byte 0x02, 0x07, 0x07, 0x0D, 0x02, 0x02, 0x02, 0x02
                    !byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x07, 0x07
                    !byte 0x07, 0x0D, 0x07, 0x07, 0x0D, 0x02, 0x02, 0x02
                    !byte 0x02, 0x07, 0x07, 0x02, 0x02, 0x02, 0x02, 0x0B
                    !byte 0x0B, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
                    !byte 0x0A, 0x07, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
                    !byte 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x07
                    !byte 0x0A, 0x0A, 0x07, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
                    !byte 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0B
                    !byte 0x0B, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C
                    !byte 0x0C, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x0C, 0x0C
                    !byte 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x07, 0x07
                    !byte 0x07, 0x0D, 0x07, 0x07, 0x0D, 0x0C, 0x0C, 0x0C
                    !byte 0x0C, 0x07, 0x07, 0x0D, 0x00, 0x00, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x07, 0x07, 0x0D, 0x0B, 0x0B, 0x0B, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x0D, 0x07, 0x07, 0x0D, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x07, 0x07, 0x0D, 0x0B, 0x0B, 0x00, 0x0B
                    !byte 0x0B, 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x05, 0x05, 0x0D, 0x0B, 0x0B, 0x0B, 0x05
                    !byte 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05
                    !byte 0x05, 0x0B, 0x05, 0x05, 0x0D, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x05, 0x05, 0x0D, 0x0B, 0x00, 0x00, 0x0B
                    !byte 0x0B, 0x04, 0x00, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x0D, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D
                    !byte 0x00, 0x06, 0x06, 0x0D, 0x00, 0x06, 0x06, 0x06
                    !byte 0x06, 0x0D, 0x06, 0x06, 0x06, 0x00, 0x04, 0x0B
                    !byte 0x0B, 0x0B, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B
                    !byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0C
                    !byte 0x0C, 0x0F, 0x0F, 0x0F, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x0F, 0x0F, 0x0F, 0x0C, 0x0C
                    !byte 0x0B, 0x0B, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C
                    !byte 0x0F, 0x0F, 0x0F, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x0F, 0x03, 0x0F, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x0F, 0x0F, 0x0F, 0x0C
                    !byte 0x0C, 0x0B, 0x0B, 0x0B, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0F
                    !byte 0x0F, 0x0F, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x0F, 0x03, 0x07, 0x03, 0x0F, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x0F, 0x0F, 0x0F
                    !byte 0x0C, 0x0C, 0x0B, 0x0B, 0x0B, 0x00, 0x00, 0x00
                    !byte 0x00, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0F, 0x0F
                    !byte 0x0F, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x0F, 0x03, 0x07, 0x07, 0x07, 0x03, 0x0F, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x0F, 0x0F
                    !byte 0x0F, 0x0C, 0x0C, 0x0B, 0x0B, 0x0B, 0x00, 0x00
                    !byte 0x00, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0F, 0x0F
                    !byte 0x0F, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x0F, 0x03, 0x07, 0x07, 0x07, 0x03, 0x0F, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x0F, 0x0F
                    !byte 0x0F, 0x0C, 0x0C, 0x0B, 0x0B, 0x0B, 0x00, 0x00
                    !byte 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0F
                    !byte 0x0F, 0x0F, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x0F, 0x03, 0x07, 0x03, 0x0F, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x0F, 0x0F, 0x0F
                    !byte 0x0C, 0x0C, 0x0B, 0x0B, 0x0B, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C
                    !byte 0x0F, 0x0F, 0x0F, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x0F, 0x03, 0x0F, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x0F, 0x0F, 0x0F, 0x0C
                    !byte 0x0C, 0x0B, 0x0B, 0x0B, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x00, 0x00, 0x00, 0x0B, 0x0B, 0x0B, 0x0C
                    !byte 0x0C, 0x0F, 0x0F, 0x0F, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x01, 0x01, 0x01, 0x0F, 0x0F, 0x0F, 0x0C, 0x0C
                    !byte 0x0B, 0x0B, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00
colram_rainbow:     !byte 0x0B, 0x04, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
                    !byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
                    !byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
                    !byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
                    !byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x04, 0x0B
                    !byte 0x0B, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0B
                    !byte 0x0B, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
                    !byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0B
                    !byte 0x0B, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x0B
                    !byte 0x0B, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07
                    !byte 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x0B
                    !byte 0x0B, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05
                    !byte 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05
                    !byte 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05
                    !byte 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05
                    !byte 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x0B
                    !byte 0x0B, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x0B
                    !byte 0x0B, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
                    !byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x0B
                    !byte 0x0B, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x0B
                    !byte 0x0B, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06
                    !byte 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x0B
                    !byte 0x0B, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0B
                    !byte 0x0B, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
                    !byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0B
; ==============================================================================
charset_anims:
chr_raute_00:       !byte %.##..##.
                    !byte %.##..##.
                    !byte %########
                    !byte %.##..##.
                    !byte %########
                    !byte %.##..##.
                    !byte %.##..##.
                    !byte %........
chr_raute_01:       !byte %##..##..
                    !byte %########
                    !byte %##..##..
                    !byte %########
                    !byte %##..##..
                    !byte %##..##..
                    !byte %........
                    !byte %##..##..
chr_raute_02:       !byte %########
                    !byte %#..##..#
                    !byte %########
                    !byte %#..##..#
                    !byte %#..##..#
                    !byte %........
                    !byte %#..##..#
                    !byte %#..##..#
chr_raute_03:       !byte %..##..##
                    !byte %########
                    !byte %..##..##
                    !byte %..##..##
                    !byte %........
                    !byte %..##..##
                    !byte %..##..##
                    !byte %########
chr_raute_04:       !byte %########
                    !byte %.##..##.
                    !byte %.##..##.
                    !byte %........
                    !byte %.##..##.
                    !byte %.##..##.
                    !byte %########
                    !byte %.##..##.
chr_raute_05:       !byte %##..##..
                    !byte %##..##..
                    !byte %........
                    !byte %##..##..
                    !byte %##..##..
                    !byte %########
                    !byte %##..##..
                    !byte %########
chr_raute_06:       !byte %#..##..#
                    !byte %........
                    !byte %#..##..#
                    !byte %#..##..#
                    !byte %########
                    !byte %#..##..#
                    !byte %########
                    !byte %#..##..#
chr_raute_07:       !byte %........
                    !byte %..##..##
                    !byte %..##..##
                    !byte %########
                    !byte %..##..##
                    !byte %########
                    !byte %..##..##
                    !byte %..##..##
anim_tab_raute_lo:  !byte <chr_raute_00
                    !byte <chr_raute_01
                    !byte <chr_raute_02
                    !byte <chr_raute_03
                    !byte <chr_raute_04
                    !byte <chr_raute_05
                    !byte <chr_raute_06
                    !byte <chr_raute_07
anim_tab_raute_hi:  !byte >chr_raute_00
                    !byte >chr_raute_01
                    !byte >chr_raute_02
                    !byte >chr_raute_03
                    !byte >chr_raute_04
                    !byte >chr_raute_05
                    !byte >chr_raute_06
                    !byte >chr_raute_07
; ==============================================================================
chr_ausr_00:        !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
chr_ausr_01:        !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##...
chr_ausr_02:        !byte %...##...
                    !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %........
                    !byte %........
chr_ausr_03:        !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %........
chr_ausr_04:        !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
chr_ausr_05:        !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %...##...
chr_ausr_06:        !byte %...##...
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %...##...
                    !byte %...##...
chr_ausr_07:        !byte %...##...
                    !byte %...##...
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %...##...
anim_tab_ausr_lo:   !byte <chr_ausr_00
                    !byte <chr_ausr_01
                    !byte <chr_ausr_02
                    !byte <chr_ausr_03
                    !byte <chr_ausr_04
                    !byte <chr_ausr_05
                    !byte <chr_ausr_06
                    !byte <chr_ausr_07
anim_tab_ausr_hi:   !byte >chr_ausr_00
                    !byte >chr_ausr_01
                    !byte >chr_ausr_02
                    !byte >chr_ausr_03
                    !byte >chr_ausr_04
                    !byte >chr_ausr_05
                    !byte >chr_ausr_06
                    !byte >chr_ausr_07
; ==============================================================================
chr_dot_00:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %........
chr_dot_01:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %....##..
                    !byte %....##..
                    !byte %........
chr_dot_02:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %.....##.
                    !byte %.....##.
                    !byte %........
chr_dot_03:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %.....##.
                    !byte %.....##.
                    !byte %........
                    !byte %........
chr_dot_04:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %.....##.
                    !byte %.....##.
                    !byte %........
                    !byte %........
                    !byte %........
chr_dot_05:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %....##..
                    !byte %....##..
                    !byte %........
                    !byte %........
                    !byte %........
chr_dot_06:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %........
chr_dot_07:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %..##....
                    !byte %..##....
                    !byte %........
                    !byte %........
                    !byte %........
chr_dot_08:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %..##....
                    !byte %..##....
                    !byte %........
                    !byte %........
chr_dot_09:         !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %..##....
                    !byte %..##....
                    !byte %........
anim_tab_dot_lo:    !byte <chr_dot_00
                    !byte <chr_dot_01
                    !byte <chr_dot_02
                    !byte <chr_dot_03
                    !byte <chr_dot_04
                    !byte <chr_dot_05
                    !byte <chr_dot_06
                    !byte <chr_dot_07
                    !byte <chr_dot_08
                    !byte <chr_dot_09
anim_tab_dot_hi:    !byte >chr_dot_00
                    !byte >chr_dot_01
                    !byte >chr_dot_02
                    !byte >chr_dot_03
                    !byte >chr_dot_04
                    !byte >chr_dot_05
                    !byte >chr_dot_06
                    !byte >chr_dot_07
                    !byte >chr_dot_08
                    !byte >chr_dot_09
; ==============================================================================
chr_kringel_00:     !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %##..##..
                    !byte %##..##..
                    !byte %..##..##
                    !byte %..##..##
chr_kringel_01:     !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %.##..##.
                    !byte %.##..##.
                    !byte %#..##..#
                    !byte %#..##..#
chr_kringel_02:     !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %..##..##
                    !byte %..##..##
                    !byte %##..##..
                    !byte %##..##..
chr_kringel_03:     !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %#..##..#
                    !byte %#..##..#
                    !byte %.##..##.
                    !byte %.##..##.
anim_tab_kringel_lo:!byte <chr_kringel_00
                    !byte <chr_kringel_01
                    !byte <chr_kringel_02
                    !byte <chr_kringel_03
anim_tab_kringel_hi:!byte >chr_kringel_00
                    !byte >chr_kringel_01
                    !byte >chr_kringel_02
                    !byte >chr_kringel_03
; ==============================================================================
chr_colon_00:       !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %........
chr_colon_01:       !byte %........
                    !byte %........
                    !byte %...##...
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_02:       !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_03:       !byte %......#.
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_04:       !byte %....#.#.
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_05:       !byte %...##.#.
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_06:       !byte %.#.##.#.
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_07:       !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
                    !byte %...##.#.
                    !byte %........
                    !byte %........
chr_colon_08:       !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
chr_colon_09:       !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %.#......
chr_colon_10:       !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %.#.#....
chr_colon_11:       !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##...
chr_colon_12:       !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %........
                    !byte %.#.##.#.
                    !byte %........
                    !byte %.#.##.#.
anim_tab_colon_lo:  !byte <chr_colon_00
                    !byte <chr_colon_01
                    !byte <chr_colon_02
                    !byte <chr_colon_03
                    !byte <chr_colon_04
                    !byte <chr_colon_05
                    !byte <chr_colon_06
                    !byte <chr_colon_07
                    !byte <chr_colon_08
                    !byte <chr_colon_09
                    !byte <chr_colon_10
                    !byte <chr_colon_11
                    !byte <chr_colon_12
                    !byte <chr_colon_11
                    !byte <chr_colon_10
                    !byte <chr_colon_09
                    !byte <chr_colon_08
                    !byte <chr_colon_07
                    !byte <chr_colon_06
                    !byte <chr_colon_05
                    !byte <chr_colon_04
                    !byte <chr_colon_03
                    !byte <chr_colon_02
                    !byte <chr_colon_01
                    !byte <chr_colon_00
anim_tab_colon_hi:  !byte >chr_colon_00
                    !byte >chr_colon_01
                    !byte >chr_colon_02
                    !byte >chr_colon_03
                    !byte >chr_colon_04
                    !byte >chr_colon_05
                    !byte >chr_colon_06
                    !byte >chr_colon_07
                    !byte >chr_colon_08
                    !byte >chr_colon_09
                    !byte >chr_colon_10
                    !byte >chr_colon_11
                    !byte >chr_colon_12
                    !byte >chr_colon_11
                    !byte >chr_colon_10
                    !byte >chr_colon_09
                    !byte >chr_colon_08
                    !byte >chr_colon_07
                    !byte >chr_colon_06
                    !byte >chr_colon_05
                    !byte >chr_colon_04
                    !byte >chr_colon_03
                    !byte >chr_colon_02
                    !byte >chr_colon_01
                    !byte >chr_colon_00
; ==============================================================================
chr_minus_00:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %.######.
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_01:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %######..
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_02:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %#####..#
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_03:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %####..##
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_04:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %###..###
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_05:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %##..####
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_06:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %#..#####
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
chr_minus_07:       !byte %........
                    !byte %........
                    !byte %........
                    !byte %..######
                    !byte %........
                    !byte %........
                    !byte %........
                    !byte %........
anim_tab_minus_lo:  !byte <chr_minus_00
                    !byte <chr_minus_01
                    !byte <chr_minus_02
                    !byte <chr_minus_03
                    !byte <chr_minus_04
                    !byte <chr_minus_05
                    !byte <chr_minus_06
                    !byte <chr_minus_07
anim_tab_minus_hi:  !byte >chr_minus_00
                    !byte >chr_minus_01
                    !byte >chr_minus_02
                    !byte >chr_minus_03
                    !byte >chr_minus_04
                    !byte >chr_minus_05
                    !byte >chr_minus_06
                    !byte >chr_minus_07
; ==============================================================================
scrolltext:         !scr "       Hello Evoke! Here's one ugly piece of Coder GF"
                    !scr "X to welcome myself in The Solaris Agency. HAR HAR HA"
                    !scr "R! Links versiffter Anarchist joins the dirty old men"
                    !scr " bringing RAINBOW FLAGS and UNICORNS to the rescue! ;"
                    !scr ") Viva la Revolution! Sing along like Wader did. Love"
                    !scr " & Peace! Yours spider. <3     Greetings go out to ou"
                    !scr "r C64 scene fellows in: "
                    !scr "Abyss Connection, "
                    !scr "Arise, "
                    !scr "Artline Designs, "
                    !scr "Atlantis, "
                    !scr "AttentionWhore, "
                    !scr "Bonzai, "
                    !scr "Booze Design, "
                    !scr "Censor Design, "
                    !scr "Cosine, "
                    !scr "Creators, "
                    !scr "Dekadence, "
                    !scr "Delysid, "
                    !scr "Desire, "
                    !scr "Elysium, "
                    !scr "Excess, "
                    !scr "Extend, "
                    !scr "Fairlight, "
                    !scr "Fantastic 4 Cracking Group, "
                    !scr "Finnish Gold, "
                    !scr "Fossil, "
                    !scr "Genesis Project, "
                    !scr "Hack n'Trade, "
                    !scr "Hoaxers, "
                    !scr "Hokuto Force, "
                    !scr "K2, "
                    !scr "Laxity, "
                    !scr "Lepsi De, "
                    !scr "Lethargy, "
                    !scr "Mayday!, "
                    !scr "MultiStyle Labs, "
                    !scr "Offence, "
                    !scr "Onslaught, "
                    !scr "Padua, "
                    !scr "Performers, "
                    !scr "Plush, "
                    !scr "Pretzel Logic, "
                    !scr "Prosonix, "
                    !scr "PVM, "
                    !scr "Rabenauge, "
                    !scr "Reflex, "
                    !scr "Resource, "
                    !scr "ROLE, "
                    !scr "Samar, "
                    !scr "SHAPE, "
                    !scr "Singular, "
                    !scr "Sitzgruppe, "
                    !scr "svenonacid, "
                    !scr "The Dreams, "
                    !scr "The Solution, "
                    !scr "Triad, "
                    !scr "TRSi, "
                    !scr "Vision, "
                    !scr "Wrath Designs, "
                    !scr "Xenon and Everyone I may have forgotten here.        "
                    !scr "In diesem Sinne: Wer das liest ist doof! ;)       - w"
                    !scr "rap -        "
                    !byte 0xFF
; ==============================================================================
rand_tab_lo:        !byte 0xC8, 0x13, 0x48, 0xF1, 0x81, 0x85, 0x8E, 0x75
                    !byte 0xF5, 0x89, 0x94, 0xB3, 0x68, 0x11, 0x8A, 0x3D
                    !byte 0xAB, 0x5F, 0x60, 0xE3, 0xE9, 0x4C, 0xD0, 0xEC
                    !byte 0x9F, 0xC5, 0x5F, 0x33, 0x09, 0xDC, 0x82, 0xE3
                    !byte 0xA9, 0xC1, 0x2D, 0x8E, 0xB2, 0x44, 0x78, 0xF3
                    !byte 0x22, 0x5E, 0xD5, 0xCE, 0xD2, 0xCD, 0x9F, 0xCC
                    !byte 0x34, 0x7F, 0x12, 0x63, 0x7D, 0x46, 0x79, 0xAC
                    !byte 0x00, 0xA4, 0xC5, 0x2E, 0x56, 0xF4, 0x6E, 0xF3
                    !byte 0x2A, 0x7B, 0xA8, 0xB2, 0x50, 0x6D, 0xCD, 0x4A
                    !byte 0xE8, 0x53, 0xAD, 0x8F, 0xD5, 0x54, 0xF5, 0xB4
                    !byte 0x35, 0xE0, 0xDA, 0x05, 0x7E, 0xCC, 0x56, 0xE7
                    !byte 0x3A, 0x36, 0x65, 0x6A, 0xD9, 0x30, 0x2C, 0xB5
                    !byte 0x46, 0x59, 0x5D, 0x14, 0xC3, 0x4E, 0xD4, 0x14
                    !byte 0x6D, 0x20, 0x54, 0x0B, 0x65, 0xE2, 0xC6, 0x2F
                    !byte 0x99, 0x78, 0x46, 0xA4, 0xFC, 0xC0, 0x79, 0x17
                    !byte 0xA7, 0x97, 0xC8, 0x06, 0xEA, 0xFC, 0xD6, 0xA2
                    !byte 0x3C, 0x3A, 0x8B, 0x98, 0xAD, 0x2F, 0x99, 0x5B
                    !byte 0xD1, 0xEB, 0x2F, 0x29, 0x4D, 0xD9, 0x14, 0x25
                    !byte 0x6B, 0xA1, 0x71, 0x31, 0x7B, 0xCD, 0x05, 0xE4
                    !byte 0x69, 0x51, 0x3E, 0xCB, 0xE4, 0xD1, 0xCA, 0xC6
                    !byte 0xF5, 0xA0, 0x7A, 0x57, 0x62, 0xD0, 0x90, 0x9F
                    !byte 0x16, 0x3C, 0x69, 0x52, 0x2C, 0x71, 0xD8, 0x94
                    !byte 0x11, 0xC2, 0x81, 0x10, 0x0C, 0x83, 0x2B, 0x3B
                    !byte 0x42, 0x96, 0x4F, 0x0B, 0xA1, 0xB3, 0x9A, 0xB9
                    !byte 0x89, 0xA3, 0x16, 0x55, 0x5E, 0xCC, 0x1E, 0xDC
                    !byte 0x85, 0x8D, 0x43, 0x64, 0xDB, 0x5D, 0xC9, 0x30
                    !byte 0x49, 0x0E, 0x16, 0xCA, 0x71, 0x3C, 0x1A, 0x4A
                    !byte 0xE6, 0x30, 0x9C, 0xE4, 0xAF, 0x99, 0x76, 0x3C
                    !byte 0xC5, 0x3A, 0x55, 0xC3, 0x1C, 0x91, 0xE6, 0x3E
                    !byte 0xCB, 0x28, 0x27, 0xE0, 0x8A, 0x5F, 0x73, 0xA6
                    !byte 0x36, 0xD7, 0x27, 0x91, 0xDE, 0xA8, 0x33, 0x73
                    !byte 0x4D, 0xC8, 0x86, 0x2D, 0xAA, 0x0F, 0x92, 0xD7
                    !byte 0xE5, 0x38, 0xA5, 0xDD, 0x56, 0xC3, 0x08, 0xE0
                    !byte 0x8C, 0x5C, 0x9B, 0x6F, 0x95, 0xE8, 0x18, 0xA9
                    !byte 0xEF, 0x83, 0x12, 0x72, 0x72, 0x1F, 0xBC, 0xDA
                    !byte 0xEE, 0x51, 0xD9, 0x21, 0x23, 0x2B, 0xD2, 0xBE
                    !byte 0xAB, 0xFE, 0xB5, 0x60, 0x37, 0xFF, 0x15, 0x75
                    !byte 0x3F, 0xED, 0x7D, 0x5C, 0x95, 0x5B, 0x6C, 0x3B
                    !byte 0xA3, 0x0D, 0x7A, 0x4B, 0x0B, 0xDF, 0x1C, 0xA1
                    !byte 0x14, 0x8C, 0xD2, 0xFC, 0xB1, 0x5D, 0xA1, 0x1E
                    !byte 0x1B, 0xDE, 0xDD, 0x07, 0x13, 0x58, 0xAD, 0xD4
                    !byte 0x0E, 0xE1, 0x6B, 0x79, 0xF3, 0xBE, 0xFE, 0x84
                    !byte 0xA0, 0xC4, 0xD0, 0xBD, 0xDF, 0xDB, 0xDB, 0x73
                    !byte 0xD3, 0x10, 0xA0, 0x89, 0x24, 0x71, 0x41, 0x20
                    !byte 0xF7, 0x23, 0xE8, 0x7C, 0x56, 0x39, 0x9E, 0xE1
                    !byte 0xF4, 0x17, 0xC7, 0xDA, 0x15, 0x04, 0xEC, 0x9D
                    !byte 0x87, 0x1A, 0xC0, 0x47, 0x77, 0x03, 0xB8, 0xD6
                    !byte 0x39, 0x40, 0xB0, 0x25, 0x74, 0x66, 0x7F, 0xD1
                    !byte 0xBB, 0xF6, 0x65, 0x3B, 0xE7, 0x20, 0x3E, 0x3D
                    !byte 0x19, 0xE1, 0x21, 0x26, 0x4B, 0x50, 0xA2, 0x1B
                    !byte 0xC7, 0x8E, 0xBC, 0xE1, 0x39, 0xDC, 0xF2, 0x3E
                    !byte 0xBF, 0x9F, 0x92, 0x8F, 0x27, 0x07, 0xC3, 0x70
                    !byte 0x58, 0xBE, 0x04, 0x5B, 0x4D, 0x8B, 0x5F, 0x2B
                    !byte 0x45, 0xFF, 0xF2, 0x6B, 0xB0, 0x69, 0xA3, 0xED
                    !byte 0xEC, 0x37, 0xA8, 0x76, 0xB6, 0x21, 0x9B, 0x1F
                    !byte 0xA2, 0xFA, 0xE4, 0x9D, 0xB0, 0xB7, 0xF7, 0x03
                    !byte 0xAE, 0x6F, 0xEE, 0xB7, 0x0C, 0x08, 0x98, 0x63
                    !byte 0xEB, 0x67, 0xFA, 0xD6, 0x96, 0x65, 0xC7, 0x9C
                    !byte 0x72, 0x22, 0xAC, 0x54, 0xDF, 0xFD, 0x4E, 0x00
                    !byte 0x42, 0x4F, 0xD5, 0x68, 0x36, 0x01, 0x98, 0x98
                    !byte 0x01, 0x78, 0x3D, 0xCD, 0x4F, 0x93, 0xDD, 0x1E
                    !byte 0x82, 0x66, 0xBC, 0x64, 0x2E, 0xCF, 0x42, 0x6C
                    !byte 0xD7, 0x05, 0x1D, 0x90, 0x7C, 0xA8, 0x6F, 0xFD
                    !byte 0xC2, 0xC1, 0x54, 0xDE, 0xC9, 0xB2, 0x02, 0xCF
                    !byte 0x57, 0x34, 0xF8, 0x26, 0xF7, 0xE6, 0x7A, 0x44
                    !byte 0x46, 0x2A, 0xF6, 0x7B, 0x74, 0x1A, 0x60, 0x8D
                    !byte 0xAA, 0x08, 0xA5, 0xC6, 0x41, 0x2A, 0x6A, 0x28
                    !byte 0xF9, 0x9C, 0x96, 0xBF, 0x25, 0xAD, 0x05, 0x8D
                    !byte 0x40, 0x18, 0x34, 0x81, 0x4E, 0x62, 0xEA, 0xE7
                    !byte 0xB5, 0xD3, 0xFE, 0x11, 0x35, 0x0C, 0x34, 0xC6
                    !byte 0xA9, 0xBD, 0xC9, 0x90, 0x76, 0x0D, 0x02, 0x6E
                    !byte 0xAA, 0xF0, 0xD0, 0x11, 0xD3, 0x59, 0x06, 0x13
                    !byte 0x10, 0xFA, 0x74, 0xB9, 0xEE, 0x67, 0x40, 0x06
                    !byte 0xB4, 0x6C, 0x91, 0xEA, 0x0D, 0xCA, 0x87, 0x7C
                    !byte 0x9D, 0x66, 0x6A, 0xF8, 0x13, 0xA6, 0x7D, 0xF0
                    !byte 0xF9, 0xF4, 0x2E, 0x24, 0x8C, 0x0E, 0x64, 0x74
                    !byte 0x1C, 0xB9, 0x15, 0xAC, 0xA3, 0x6E, 0x9D, 0xCE
                    !byte 0xF8, 0xAE, 0x7E, 0xE9, 0x88, 0x77, 0x68, 0xE2
                    !byte 0xA5, 0x1C, 0x47, 0x1B, 0x48, 0x0F, 0xBD, 0x64
                    !byte 0xD4, 0xBF, 0x53, 0x48, 0xAE, 0x97, 0x55, 0x4E
                    !byte 0x0B, 0x9A, 0x21, 0xBB, 0x86, 0xB3, 0xEF, 0x3F
                    !byte 0x9A, 0xDA, 0x45, 0x57, 0x50, 0x6E, 0x07, 0x49
                    !byte 0x03, 0x70, 0x15, 0x1D, 0x41, 0x3F, 0x33, 0x89
                    !byte 0x68, 0x10, 0x8A, 0xC1, 0xC7, 0x4A, 0x8A, 0xC5
                    !byte 0xC4, 0xFB, 0x22, 0x27, 0x28, 0xF0, 0x29, 0x87
                    !byte 0x61, 0x0C, 0xFF, 0xB3, 0x38, 0xCE, 0x61, 0x82
                    !byte 0x78, 0x25, 0x26, 0x53, 0x92, 0xE6, 0x84, 0xA2
                    !byte 0x32, 0xC8, 0xAB, 0xD5, 0x08, 0x61, 0x5E, 0x33
                    !byte 0x1D, 0xD9, 0x17, 0x70, 0x96, 0xC0, 0xD8, 0x7D
                    !byte 0x83, 0x8C, 0x48, 0x6F, 0xB1, 0xCF, 0x38, 0x09
                    !byte 0x59, 0x37, 0x86, 0x4B, 0x9B, 0xC2, 0x47, 0x81
                    !byte 0x9E, 0x4F, 0xB4, 0x0A, 0xBE, 0x39, 0xB4, 0x01
                    !byte 0xAB, 0x1A, 0xB5, 0x85, 0xAF, 0x51, 0xDE, 0x45
                    !byte 0xE5, 0x95, 0x12, 0xB8, 0x40, 0xB8, 0x79, 0x18
                    !byte 0x24, 0x31, 0x5A, 0xA7, 0x37, 0x1B, 0xA7, 0x5D
                    !byte 0x07, 0x7F, 0x20, 0x85, 0x5A, 0x49, 0x70, 0x00
                    !byte 0x09, 0x28, 0x7E, 0xAF, 0x32, 0xDD, 0x2C, 0x8B
                    !byte 0x0A, 0x9A, 0x9B, 0x92, 0x0A, 0xAA, 0xBC, 0x84
                    !byte 0x23, 0x02, 0x19, 0x7C, 0x62, 0xAC, 0x8E, 0xA9
                    !byte 0x04, 0x6A, 0x60, 0x50, 0x4C, 0xA7, 0x84, 0x8F
                    !byte 0xC4, 0x57, 0x45, 0x52, 0x47, 0x16, 0x51, 0x06
                    !byte 0xB1, 0xD6, 0x0E, 0xB7, 0xE7, 0x4C, 0xB0, 0x19
                    !byte 0xB6, 0x8D, 0xC1, 0x97, 0x5A, 0x7F, 0x3F, 0x7B
                    !byte 0xBA, 0xB6, 0xC2, 0x22, 0x5A, 0x77, 0x53, 0x43
                    !byte 0x9E, 0x59, 0x52, 0x6D, 0x12, 0xE0, 0x1F, 0x52
                    !byte 0x8F, 0x4C, 0x55, 0xF6, 0xDB, 0xE2, 0x86, 0xFB
                    !byte 0x87, 0xCB, 0x91, 0xC0, 0x3A, 0x2B, 0x7A, 0x00
                    !byte 0x26, 0x18, 0x42, 0x3B, 0x8B, 0x2D, 0xF1, 0xC4
                    !byte 0x58, 0xFD, 0x93, 0xFB, 0xCB, 0xF9, 0x23, 0x4B
                    !byte 0xDC, 0x6B, 0x02, 0x80, 0x66, 0x0F, 0x3D, 0x82
                    !byte 0x73, 0x88, 0x0F, 0x01, 0x5B, 0xBA, 0x32, 0xD7
                    !byte 0xCE, 0xD3, 0x2A, 0xBA, 0x80, 0xB1, 0x94, 0x63
                    !byte 0x88, 0x4A, 0x03, 0x77, 0xC9, 0x61, 0xB7, 0x43
                    !byte 0x5C, 0x29, 0xBB, 0x36, 0x88, 0x95, 0x7E, 0x04
                    !byte 0xE9, 0x24, 0x38, 0x31, 0xED, 0x5E, 0xD4, 0x32
                    !byte 0xA5, 0xA4, 0x67, 0x75, 0x9C, 0x2D, 0x35, 0x69
                    !byte 0x5C, 0x41, 0x99, 0x1E, 0xF1, 0x93, 0x1F, 0xD2
                    !byte 0x75, 0x49, 0xEB, 0xB6, 0x17, 0x93, 0x31, 0x0D
                    !byte 0x44, 0x63, 0xAF, 0xEF, 0x80, 0xE5, 0xB8, 0xA6
                    !byte 0x2E, 0x44, 0xAE, 0xD1, 0x83, 0xB2, 0x2C, 0x90
                    !byte 0xCA, 0xE3, 0xDF, 0x6C, 0x6D, 0x29, 0xBA, 0x2F
                    !byte 0xBD, 0xF2, 0x94, 0x80, 0x30, 0x43, 0x67, 0xBF
                    !byte 0xBB, 0xD8, 0x35, 0x9E, 0x97, 0x1D, 0x09, 0x72
                    !byte 0xA4, 0xE5, 0xE3, 0xD8, 0x0A, 0xCC, 0xCF, 0xA0
                    !byte 0x76, 0xB9, 0x62, 0x58, 0xE2, 0x19, 0xA6, 0x4D
rand_tab_hi:        !byte 0x02, 0x03, 0x03, 0x00, 0x02, 0x02, 0x00, 0x01
                    !byte 0x00, 0x00, 0x01, 0x03, 0x01, 0x03, 0x00, 0x02
                    !byte 0x03, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x01
                    !byte 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x03
                    !byte 0x01, 0x00, 0x02, 0x01, 0x03, 0x02, 0x02, 0x01
                    !byte 0x01, 0x00, 0x02, 0x00, 0x02, 0x00, 0x03, 0x02
                    !byte 0x00, 0x00, 0x00, 0x02, 0x03, 0x02, 0x03, 0x02
                    !byte 0x03, 0x02, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00
                    !byte 0x03, 0x00, 0x03, 0x00, 0x01, 0x02, 0x02, 0x01
                    !byte 0x02, 0x00, 0x01, 0x03, 0x03, 0x02, 0x01, 0x00
                    !byte 0x03, 0x00, 0x01, 0x03, 0x02, 0x03, 0x00, 0x02
                    !byte 0x03, 0x03, 0x03, 0x03, 0x02, 0x03, 0x02, 0x03
                    !byte 0x03, 0x02, 0x02, 0x02, 0x02, 0x02, 0x03, 0x01
                    !byte 0x03, 0x02, 0x00, 0x03, 0x01, 0x02, 0x00, 0x00
                    !byte 0x03, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x02
                    !byte 0x01, 0x00, 0x00, 0x03, 0x00, 0x01, 0x03, 0x03
                    !byte 0x03, 0x01, 0x01, 0x02, 0x00, 0x03, 0x01, 0x02
                    !byte 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00
                    !byte 0x00, 0x02, 0x02, 0x01, 0x02, 0x01, 0x01, 0x03
                    !byte 0x02, 0x01, 0x01, 0x03, 0x02, 0x03, 0x03, 0x01
                    !byte 0x02, 0x03, 0x02, 0x00, 0x03, 0x00, 0x02, 0x00
                    !byte 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0x03, 0x02
                    !byte 0x02, 0x01, 0x01, 0x02, 0x03, 0x00, 0x03, 0x03
                    !byte 0x02, 0x01, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00
                    !byte 0x02, 0x03, 0x02, 0x01, 0x03, 0x01, 0x00, 0x00
                    !byte 0x03, 0x02, 0x03, 0x00, 0x01, 0x03, 0x03, 0x01
                    !byte 0x01, 0x03, 0x03, 0x01, 0x01, 0x00, 0x03, 0x00
                    !byte 0x03, 0x02, 0x01, 0x00, 0x02, 0x02, 0x00, 0x01
                    !byte 0x02, 0x02, 0x02, 0x03, 0x01, 0x02, 0x02, 0x02
                    !byte 0x02, 0x00, 0x01, 0x01, 0x02, 0x03, 0x01, 0x02
                    !byte 0x00, 0x02, 0x02, 0x01, 0x03, 0x00, 0x01, 0x02
                    !byte 0x01, 0x01, 0x02, 0x03, 0x01, 0x03, 0x02, 0x01
                    !byte 0x00, 0x03, 0x01, 0x03, 0x02, 0x01, 0x00, 0x02
                    !byte 0x00, 0x01, 0x02, 0x01, 0x00, 0x01, 0x00, 0x02
                    !byte 0x02, 0x03, 0x03, 0x03, 0x00, 0x02, 0x02, 0x02
                    !byte 0x01, 0x00, 0x01, 0x02, 0x00, 0x02, 0x00, 0x00
                    !byte 0x00, 0x02, 0x02, 0x02, 0x00, 0x00, 0x01, 0x03
                    !byte 0x02, 0x00, 0x01, 0x00, 0x02, 0x01, 0x03, 0x01
                    !byte 0x00, 0x01, 0x03, 0x01, 0x00, 0x03, 0x02, 0x03
                    !byte 0x03, 0x03, 0x03, 0x02, 0x01, 0x01, 0x01, 0x03
                    !byte 0x03, 0x00, 0x02, 0x01, 0x00, 0x03, 0x02, 0x01
                    !byte 0x02, 0x03, 0x03, 0x02, 0x02, 0x02, 0x00, 0x00
                    !byte 0x01, 0x00, 0x01, 0x03, 0x00, 0x02, 0x00, 0x00
                    !byte 0x01, 0x03, 0x00, 0x01, 0x00, 0x03, 0x03, 0x03
                    !byte 0x01, 0x01, 0x00, 0x02, 0x03, 0x03, 0x03, 0x01
                    !byte 0x02, 0x01, 0x02, 0x03, 0x03, 0x03, 0x00, 0x01
                    !byte 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01
                    !byte 0x01, 0x00, 0x02, 0x03, 0x03, 0x01, 0x02, 0x02
                    !byte 0x01, 0x01, 0x02, 0x02, 0x00, 0x00, 0x00, 0x01
                    !byte 0x01, 0x02, 0x01, 0x02, 0x02, 0x03, 0x01, 0x01
                    !byte 0x00, 0x02, 0x03, 0x00, 0x02, 0x03, 0x01, 0x03
                    !byte 0x01, 0x02, 0x00, 0x02, 0x03, 0x00, 0x00, 0x02
                    !byte 0x01, 0x01, 0x02, 0x00, 0x03, 0x03, 0x02, 0x00
                    !byte 0x00, 0x02, 0x02, 0x02, 0x01, 0x03, 0x02, 0x02
                    !byte 0x02, 0x03, 0x02, 0x02, 0x03, 0x03, 0x00, 0x01
                    !byte 0x02, 0x02, 0x01, 0x00, 0x03, 0x02, 0x02, 0x02
                    !byte 0x00, 0x02, 0x00, 0x03, 0x00, 0x03, 0x03, 0x03
                    !byte 0x02, 0x03, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00
                    !byte 0x01, 0x02, 0x01, 0x03, 0x02, 0x01, 0x03, 0x02
                    !byte 0x00, 0x01, 0x01, 0x03, 0x01, 0x02, 0x01, 0x00
                    !byte 0x00, 0x03, 0x00, 0x03, 0x03, 0x00, 0x00, 0x02
                    !byte 0x01, 0x00, 0x01, 0x02, 0x02, 0x02, 0x03, 0x02
                    !byte 0x03, 0x00, 0x00, 0x03, 0x01, 0x01, 0x03, 0x02
                    !byte 0x00, 0x03, 0x01, 0x01, 0x01, 0x02, 0x01, 0x00
                    !byte 0x02, 0x03, 0x01, 0x01, 0x00, 0x00, 0x01, 0x01
                    !byte 0x01, 0x02, 0x02, 0x01, 0x02, 0x01, 0x01, 0x01
                    !byte 0x02, 0x01, 0x02, 0x03, 0x02, 0x00, 0x00, 0x03
                    !byte 0x02, 0x02, 0x03, 0x03, 0x02, 0x03, 0x02, 0x00
                    !byte 0x01, 0x02, 0x01, 0x00, 0x01, 0x02, 0x02, 0x03
                    !byte 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x02
                    !byte 0x00, 0x02, 0x02, 0x00, 0x01, 0x02, 0x03, 0x00
                    !byte 0x00, 0x02, 0x03, 0x01, 0x02, 0x00, 0x01, 0x01
                    !byte 0x01, 0x00, 0x00, 0x01, 0x02, 0x00, 0x02, 0x00
                    !byte 0x02, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0x03
                    !byte 0x03, 0x03, 0x01, 0x00, 0x02, 0x00, 0x00, 0x01
                    !byte 0x00, 0x00, 0x03, 0x02, 0x02, 0x00, 0x03, 0x01
                    !byte 0x00, 0x03, 0x00, 0x00, 0x01, 0x02, 0x02, 0x03
                    !byte 0x02, 0x01, 0x03, 0x02, 0x01, 0x02, 0x00, 0x03
                    !byte 0x00, 0x03, 0x03, 0x00, 0x00, 0x02, 0x00, 0x01
                    !byte 0x00, 0x02, 0x01, 0x01, 0x02, 0x01, 0x00, 0x00
                    !byte 0x01, 0x01, 0x00, 0x03, 0x01, 0x02, 0x00, 0x01
                    !byte 0x03, 0x00, 0x01, 0x03, 0x02, 0x03, 0x02, 0x00
                    !byte 0x01, 0x01, 0x02, 0x01, 0x00, 0x03, 0x02, 0x03
                    !byte 0x02, 0x00, 0x01, 0x02, 0x01, 0x02, 0x03, 0x03
                    !byte 0x01, 0x01, 0x03, 0x00, 0x02, 0x00, 0x02, 0x03
                    !byte 0x02, 0x01, 0x01, 0x01, 0x02, 0x02, 0x01, 0x03
                    !byte 0x00, 0x01, 0x03, 0x02, 0x01, 0x01, 0x01, 0x00
                    !byte 0x02, 0x03, 0x02, 0x00, 0x02, 0x00, 0x02, 0x03
                    !byte 0x02, 0x03, 0x03, 0x03, 0x00, 0x01, 0x02, 0x02
                    !byte 0x02, 0x01, 0x02, 0x00, 0x03, 0x03, 0x01, 0x02
                    !byte 0x03, 0x02, 0x03, 0x00, 0x03, 0x03, 0x01, 0x03
                    !byte 0x02, 0x00, 0x01, 0x02, 0x03, 0x00, 0x03, 0x01
                    !byte 0x01, 0x02, 0x00, 0x00, 0x01, 0x03, 0x02, 0x02
                    !byte 0x01, 0x01, 0x01, 0x01, 0x03, 0x02, 0x01, 0x01
                    !byte 0x03, 0x00, 0x03, 0x02, 0x01, 0x02, 0x03, 0x00
                    !byte 0x03, 0x03, 0x01, 0x01, 0x00, 0x02, 0x00, 0x01
                    !byte 0x01, 0x01, 0x01, 0x03, 0x00, 0x01, 0x03, 0x02
                    !byte 0x00, 0x02, 0x01, 0x03, 0x03, 0x03, 0x00, 0x02
                    !byte 0x03, 0x02, 0x00, 0x00, 0x01, 0x03, 0x03, 0x03
                    !byte 0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x03, 0x00
                    !byte 0x02, 0x01, 0x03, 0x02, 0x00, 0x01, 0x02, 0x02
                    !byte 0x00, 0x02, 0x01, 0x01, 0x01, 0x03, 0x00, 0x02
                    !byte 0x01, 0x03, 0x01, 0x02, 0x02, 0x01, 0x00, 0x03
                    !byte 0x02, 0x00, 0x02, 0x00, 0x01, 0x01, 0x03, 0x01
                    !byte 0x01, 0x01, 0x01, 0x00, 0x02, 0x03, 0x03, 0x00
                    !byte 0x01, 0x02, 0x03, 0x00, 0x03, 0x01, 0x00, 0x00
                    !byte 0x02, 0x00, 0x03, 0x03, 0x00, 0x01, 0x00, 0x00
                    !byte 0x00, 0x03, 0x01, 0x00, 0x00, 0x01, 0x01, 0x03
                    !byte 0x02, 0x00, 0x01, 0x02, 0x01, 0x01, 0x02, 0x03
                    !byte 0x01, 0x01, 0x00, 0x03, 0x02, 0x01, 0x03, 0x00
                    !byte 0x03, 0x02, 0x00, 0x03, 0x03, 0x01, 0x01, 0x00
                    !byte 0x01, 0x03, 0x01, 0x00, 0x00, 0x02, 0x00, 0x01
                    !byte 0x00, 0x03, 0x03, 0x03, 0x00, 0x03, 0x00, 0x00
                    !byte 0x02, 0x01, 0x00, 0x02, 0x03, 0x03, 0x00, 0x00
                    !byte 0x01, 0x01, 0x00, 0x02, 0x01, 0x01, 0x02, 0x03
                    !byte 0x03, 0x03, 0x01, 0x02, 0x03, 0x00, 0x02, 0x01
                    !byte 0x03, 0x01, 0x00, 0x01, 0x02, 0x03, 0x00, 0x01
                    !byte 0x00, 0x03, 0x00, 0x02, 0x00, 0x02, 0x03, 0x00
                    !byte 0x03, 0x00, 0x00, 0x01, 0x02, 0x02, 0x03, 0x03
                    !byte 0x00, 0x00, 0x03, 0x01, 0x01, 0x01, 0x01, 0x01
                    !byte 0x02, 0x02, 0x01, 0x01, 0x01, 0x03, 0x03, 0x02
                    !byte 0x01, 0x00, 0x03, 0x01, 0x00, 0x02, 0x02, 0x00
                    !byte 0x02, 0x01, 0x01, 0x00, 0x03, 0x03, 0x03, 0x02
                    !byte 0x01, 0x03, 0x01, 0x00, 0x01, 0x00, 0x01, 0x02
                    !byte 0x03, 0x02, 0x00, 0x00, 0x00, 0x03, 0x01, 0x02
                    !byte 0xFF
