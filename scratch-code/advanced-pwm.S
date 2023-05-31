.syntax unified
.global main

.type main, %function
main:
bl init_leds
d_loop:
mov r0, 0b00001
bl write_column_pins
bl write_row_pins
ldr r8, =delay_times
ldr r0, [r8]
add r8, 4
bl delay
mov r0, 0
bl write_column_pins
ldr r0, [r8]
bl delay

mov r0, 0b00010
bl write_column_pins
bl write_row_pins
bl toggle_brightness
ldr r0, =100000
bl delay
b d_loop
.size main, .-main

@ toggle brightness
.type toggle_brightness, %function
toggle_brightness:
push {r7, lr}
ldr r7, =delay_times
ldr r0, [r7]
ldr r1, [r7, 4]
str r1, [r7]
str r0, [r7, 4]
pop {r7, lr}
bx lr
.size toggle_brightness, .-toggle_brightness