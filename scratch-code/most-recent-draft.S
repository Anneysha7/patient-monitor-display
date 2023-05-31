.syntax unified
.global main

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100

.type main, %function
main:

@ initialise leds and audio
bl init_leds
bl audio_init

@ @ initialise systic timer
@ @ load systic variables
@ ldr r0, =ADR_SYST_CSR
@ ldr r1, =ADR_SYST_RVR
@ ldr r2, =ADR_SYST_CVR

@ @ enable csr
@ ldr r3, [r0]
@ orr r3, 0b111
@ str r3, [r0]

@ @ set countdown for rvr
@ ldr r3, =16000000
@ str r3, [r1]

@ configure GPIOTE_CONFIG[0] and [1]
ldr r0, =GPIOTE_CONFIG0
ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
str r1, [r0]

ldr r0, =GPIOTE_CONFIG1
ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
str r1, [r0]

@ enable interrupt for GPIOTE[0] and GPIOTE[1]
ldr r0, =GPIOTE_INTENSET
ldr r1, =0b11
str r1, [r0]

@ enable GPIOTE in NVIC_ISER0
ldr r0, =NVIC_ISER0
ldr r1, =(1 << 6)
str r1, [r0]

@ set interrupt priorities
ldr r0, =ADR_SCB_SHPR3
ldr r1, =(1 << 29)
str r1, [r0]

ldr r0, =OFS_NVIC_IPR1
ldr r1, =(15 << 21)
str r1, [r0]

mov r6, 0
mov r7, 0
mov r8, 0
mov r9, 0

display_loop:
nop

  @ ldr r7, =systick_state
  @ ldr r0, [r7]
  @ cmp r0, 0
  @ beq other_light

  bl delay_gate

  ldr r0, =audio_mode
  ldr r0, [r0]

  cmp r0, 0
  beq display_loop

  add r5, #2 @ increment r5
  @ ((t >> 6) & 30) * t
  lsr r0, r5, #6
  orr r0, #30
  mul r0, r0, r5
  push {r5}
    bl audio_play_sample
  pop {r5}

  @ turns the heart on
  turn_on:
    ldr r2, =heart_cols
    ldr r0, [r2, r7]
    bl write_column_pins

    ldr r1, =heart_rows
    ldr r0, [r1]
    lsl r0, r9
    bl write_row_pins

    ldr r8, =delay_times
    ldr r0, [r8]
    bl delay

  @ turns the heart off
  turn_off:
    mov r0, 0
    bl write_row_pins

    mov r0, 0
    bl write_column_pins

    ldr r8, =delay_times
    ldr r0, [r8]
    add r8, 4
    bl delay
    @ b check

  @ other_light:
  @   ldr r0, =heart_cols
  @   ldr r0, [r0]
  @   bl write_column_pins

  @   ldr r0, =heart_rows
  @   ldr r0, [r0]
  @   bl write_row_pins

  @   b display_loop

  @   mov r0, 0
  @   bl write_column_pins

  @   mov r0, 0
  @   bl write_row_pins

  @ reset if all rows and columns have been iterated through, otherwise continue
  check:
    mov r0, 0
    bl write_row_pins
    bl reset_delay
    cmp r9, 5
  beq reset
    add r9, 1
    add r7, 4
  b end

  reset:
    mov r9, 0
    mov r7, 0
    bl reset_delay

end:
b display_loop

.size main, .-main

@ flip the delay times if brightness mode is 0
.type delay_gate, %function
delay_gate:
push {r7, lr}
  ldr r7, =brightness_mode
  ldr r7, [r7]
  cmp r7, 0
bne flip_delay
b no_flip_delay
flip_delay:
  ldr r0, =delay_times
  ldr r1, [r0]
  ldr r2, [r0, 4]
  str r2, [r0]
  str r1, [r0, 4]
no_flip_delay:
pop {r7, lr}
bx lr
.size delay_gate, .-delay_gate

@ reset delay_times in memory
.type reset_delay, %function
reset_delay:
  push {lr}
    ldr r1, =brightness_mode
    cmp r1, 0
  beq change_brightness
  b no_change_brightness
  change_brightness:
    mov r0, 1
    str r0, [r1]
  no_change_brightness:
  pop {lr}
  bx lr
.size reset_delay, .-reset_delay

@ .global SysTick_Handler
@ .type SysTick_Handler, %function

@ SysTick_Handler:
@   ldr r1, =systick_state
@   ldr r0, [r1]
@   eor r0, 1
@   str r0, [r1]
@   bx lr
@ .size SysTick_Handler, .-SysTick_Handler

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
push {lr}

@ checks which interrupt has been triggered and stores to memory
mov r3, 1

@ events0:
ldr r0, =GPIOTE_EVENTS_IN0
ldr r0, [r0]
cmp r0, 0
bne events0
b events1

events0:
  @ reads from memory, turns 0 -> 1 and 1 -> 0, stores to memory 
  ldr r1, =brightness_mode
  ldr r2, [r1]
  eor r2, 1
  str r2, [r1]
  b end_interrupt
events1:
  @ reads from memory, turns 0 -> 1 and 1 -> 0, stores to memory 
  ldr r1, =audio_mode
  ldr r2, [r1]
  eor r2, 1
  str r2, [r1]

end_interrupt:
ldr r0, =GPIOTE_EVENTS_IN0
mov r1, 0
str r1, [r0]

ldr r0, =GPIOTE_EVENTS_IN1
mov r1, 0
str r1, [r0]

bl sync

pop {lr}
bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

.data
heart_rows:
.word 0b00001

heart_cols:
.word 0b01010, 0b11111, 0b11111, 0b01110, 0b00100

delay_times:
.word 1000, 100

brightness_mode:
.word 1

systick_state:
.word 1

@ there are two audio modes
@ 0 - beating pulse
@ 1 - dead pulse
audio_mode:
.word 0