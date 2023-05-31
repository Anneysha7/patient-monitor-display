.syntax unified
.global main

.type main, %function
main:

  bl init_leds
  ldr r0, =ADR_SYST_CSR
  ldr r1, =ADR_SYST_RVR
  ldr r2, =ADR_SYST_CVR

  ldr r3, [r0]
  orr r3, 0b111
  str r3, [r0]


  ldr r3, =16000000
  str r3, [r1]

  mov r5, 8
  ldr r7, =systick_state

  inf_loop:

    ldr r0, [r7]
    cmp r0, 0
    beq other_light

    turn_on:

    ldr r0, =lights_columns
    ldr r0, [r0]
    bl write_column_pins

    ldr r0, =lights_rows
    ldr r0, [r0]
    bl write_row_pins

    b inf_loop

    turn_off:

    mov r0, 1
    bl write_column_pins

    mov r0, 0
    bl write_row_pins

    other_light:

    ldr r0, =lights_columns
    ldr r0, [r0, 4]
    bl write_column_pins

    ldr r0, =lights_rows
    ldr r0, [r0, 4]
    bl write_row_pins

    b inf_loop

    mov r0, 0
    bl write_column_pins

    mov r0, 0
    bl write_row_pins

    b inf_loop
  
.size main, .-main

.global SysTick_Handler
.type SysTick_Handler, %function

SysTick_Handler:
  ldr r1, =systick_state
  ldr r0, [r1]
  eor r0, 1
  str r0, [r1]
  bx lr
.size SysTick_Handler, .-SysTick_Handler
.data
hello:
.word 0x424242

systick_state:
.word 0

lights_rows:
.word 0b10001, 0b01110, 0b01010, 0b01110, 0b10001

lights_columns:
.word 0b00001, 0b00010, 0b00100, 0b01000, 0b10000