.syntax unified
.global main

.type main, %function
main:

@ Glowy
@    Consecutive dim and bright lights??? Since we need to stay in the
@    respective dim/ bright loop for it to keep glowing

@ 1. How to make a bright to dim transition and vice-versa?
@ 2. Why does the entire row light up using write_led
bl init_leds

  dim_loop:
  mov r0, 4
  mov r1, 4
  mov r2, 1
  bl write_led

  mov r0, 1000
  bl delay

  mov r0, 4
  mov r1, 4
  mov r2, 0
  bl write_led

  ldr r0, =100000
  bl delay

  bright_loop:
  mov r0, 0
  mov r1, 0
  mov r2, 1
  bl write_led

  ldr r0, =10000
  bl delay

  mov r0, 0
  mov r1, 0
  mov r2, 0
  bl write_led

  mov r0, 100
  bl delay

  b dim_loop
  
.data
hello:
.word 0x424242