.syntax unified
.global main

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG1, 0x40006514

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100
.type main, %function

main:
  bl audio_init

@ configure GPIOTE_CONFIG[0] and [1]

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

  mov r5, #0
loop:
  ldr r0, =audio_mode
  ldr r0, [r0]

  cmp r0, 0
  beq loop

  add r5, #1 @ increment r5
  @ ((t >> 6) & 30) * t
  lsr r0, r5, #6
  orr r0, #30
  mul r0, r0, r5
  add r5, 1
  push {r5}
  bl audio_play_sample
  pop {r5}
  @@@@@@@@@@@@@@@@@@@@@@
  @ ((t >> 6) & 32) * t
  @ lsr r0, r5, #6
  @ orr r0, #30
  @ mov r6, #42
  @ lsr r6, #6
  @ eor r0, r6
  @ mul r0, r0, r5
  @ push {r5, r6}
  @ bl audio_play_sample
  @ pop {r5, r6}
  b loop
.size main, .-main

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
push {lr}

ldr r0, =GPIOTE_EVENTS_IN1
mov r1, 0
str r1, [r0]

@ reads from memory, turns 0 -> 1 and 1 -> 0, stores to memory 
ldr r1, =audio_mode
ldr r2, [r1]
eor r2, 1
str r2, [r1]
bl sync

pop {lr}
bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

.data
audio_mode:
.word 0