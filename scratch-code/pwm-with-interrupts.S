.syntax unified
.global main

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100

.type main, %function
main:
bl init_leds
bl audio_init

@ configure GPIOTE_CONFIG[0]
ldr r0, =GPIOTE_CONFIG0
ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
str r1, [r0]

@ enable interrupt for GPIOTE[0]
ldr r0, =GPIOTE_INTENSET
ldr r1, =0b11
str r1, [r0]

@ enable GPIOTE in NVIC_ISER0
ldr r0, =NVIC_ISER0
ldr r1, =(1 << 6)
str r1, [r0]

mov r6, 0
mov r7, 0
mov r8, 0
mov r9, 0

display_loop:
  bl delay_gate

  @ add r5, #1 @ increment r5
  @ mov r0, r5
  @ push {r5}
  @ bl audio_play_sample
  @ pop {r5}

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

  @ check
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

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
push {lr}

ldr r0, =GPIOTE_EVENTS_IN0
mov r1, 0
str r1, [r0]

@ reads from memory, turns 0 -> 1 and 1 -> 0, stores to memory 
ldr r1, =brightness_mode
ldr r2, [r1]
eor r2, 1
str r2, [r1]
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

@ there are three audio modes
@ 1, 2,
audio_mode:
.word 1