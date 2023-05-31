.syntax unified
.global main

.type main, %function
main:
bl init_leds

  display_loop:

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
  add r8, 4

  @ turns the heart off
  turn_off:
  mov r0, 0
  bl write_row_pins

  mov r0, 0
  bl write_column_pins

  ldr r0, [r8]
  bl delay

  mov r8, 0

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


.data
heart_rows:
.word 0b00001

heart_cols:
.word 0b01010, 0b11111, 0b11111, 0b01110, 0b00100

delay_times:
.word 10000, 1000

led_state:
.word 1

brightness_mode:
.word 1