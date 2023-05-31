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
bl init_leds

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

  ldr r8, =led_state

  display_loop:
  nop

  ldr r0, [r8]
  cmp r0, 1
  beq turn_off

  @ turns the heart on
  turn_on:

  ldr r1, =heart_rows
  ldr r2, =heart_cols
  ldr r0, [r2, r7]
  bl write_column_pins

  ldr r1, =heart_rows
  ldr r2, =heart_cols
  ldr r0, [r1]
  lsl r0, r9
  bl write_row_pins

  ldr r0, =10000
  bl delay
  b check

  @ turns the heart off
  turn_off:
  mov r0, 0
  bl write_row_pins

  mov r0, 0
  bl write_column_pins

  ldr r0, =1000
  bl delay

  @ check
  check:
  mov r0, 0
  bl write_row_pins
  cmp r9, 5
  beq reset
  add r9, 1
  add r7, 4
  b end
  reset:
  mov r9, 0
  mov r7, 0

  end:
  b display_loop

.size main, .-main

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
@ clear event
ldr r0, =GPIOTE_EVENTS_IN0
mov r1, 0
str r1, [r0]
ldr r0, =GPIOTE_EVENTS_IN1
mov r1, 0
str r1, [r0]

@ reads from memory, turns 0 -> 1 and 1 -> 0, stores to memory 
ldr r1, =led_state
ldr r2, [r1]
eor r2, 1
str r2, [r1]

bx lr        
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

.data
heart_rows:
.word 0b00001

heart_cols:
.word 0b01010, 0b11111, 0b11111, 0b01110, 0b00100

delay_times:
.word 10000000, 1000

led_state:
.word 0