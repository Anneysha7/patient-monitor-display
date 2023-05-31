@ Utility functions and symbols
.syntax unified
@ --------------------- Module Interface --------------------

@ Function exports:
.global set_bit, clear_bit, toggle_bit, write_bit, read_bit, copy_bits, read_bits
.global delay, reverse, sync

@ --------------------- Implementation --------------------

@ bit fiddling utility functions
.type set_bit, %function
@ --parameters--
@ r0: base address
@ r1: offset
@ r2: bit index
set_bit:
  @ calculate address (base + offset), store in r0
  add r0, r1
  @ load current register value, store in r1
  ldr r1, [r0]
  @ align the "1" bit into the correct slot in r3
  mov r3, 1
  lsl r3, r2
  @ set the desired bit
  orr r1, r3
  @ write the data back
  str r1, [r0]
  bx lr
.size set_bit, .-set_bit

.type clear_bit, %function
@ --parameters--
@ r0: base address
@ r1: offset
@ r2: bit index
clear_bit:
  @ calculate address (base + offset), store in r0
  add r0, r1
  @ load current register value, store in r1
  ldr r1, [r0]
  @ align the "1" bit into the correct slot in r3
  mov r3, 1
  lsl r3, r2
  @ clear the desired bit
  bic r1, r3
  @ write the data back
  str r1, [r0]
  bx lr
.size clear_bit, .-clear_bit

.type toggle_bit, %function
@ --parameters--
@ r0: base address
@ r1: offset
@ r2: bit index
toggle_bit:
  @ calculate address (base + offset), store in r0
  add r0, r1
  @ load current register value, store in r1
  ldr r1, [r0]
  @ align the "1" bit into the correct slot in r3
  mov r3, 1
  lsl r3, r2
  @ toggle the desired bit
  eor r1, r3
  @ write the data back
  str r1, [r0]
  bx lr
.size toggle_bit, .-toggle_bit

.type write_bit, %function
@ --parameters--
@ r0: base address
@ r1: offset
@ r2: bit index
@ r3: data (LSB)
write_bit:
  add r0, r1
  push {r0} @ save base address + offset to stack
  ldr r1, [r0]
  @ first, clear the bit we're going to replace
  mov r0, 1
  lsl r0, r2
  bic r1, r0
  @ move the data bit into place and orr to "write" it
  and r3, 1   @ clear all but LSB
  lsl r3, r2
  orr r1, r3  @ then orr to set 0/1
  pop {r0}    @ restore base address + offset
  str r1, [r0]
  bx lr
.size write_bit, .-write_bit

.type read_bit, %function
@ --parameters--
@ r0: base address
@ r1: offset
@ r2: bit index
@ --return--
@ r0: bit<0> contains read bit
@ flags set
read_bit:
  add r1, r0
  ldr r0, [r1]
  lsr r0, r2
  ands r0, 1
  bx lr
.size read_bit, .-read_bit

.type copy_bits, %function
@ --parameters--
@ r0: address (base + offset)
@ r1: bits to copy
@ r2: least significant bit index
@ r3: width
copy_bits:
  push {r4}
  orn r4, 0
  lsl r4, r3
  orr r3, r4, r1  @ r3 = 0xff..f:bits
  rsb r2, 32
  ror r3, r2      @ r3 = 0xf..f:bits:f..f
  ror r1, r2      @ r1 = 0x0..0:bits:0..0
  ldr r4, [r0]
  orr r4, r1
  and r4, r3
  str r4, [r0]
  pop {r4}
  bx lr
.size copy_bits, .-copy_bits

.type read_bits, %function
@ --parameters--
@ r0: base address
@ r1: offset
@ r2: least significant bit index to start reading
@ r3: width of bits to read
@ --return--
@ r0: contains read bits shifted to start at the least significant bit (bit<0>)
read_bits:
  add r1, r0
  ldr r0, [r1]
  mov r1, 32
  sub r1, r2
  sub r1, r3
  lsl r0, r1
  mov r1, 32
  sub r1, r3
  lsr r0, r1
  bx lr
.size read_bits, .-read_bits

.type delay, %function
@ --parameters--
@ r0: delay amount
delay:
  subs r0, 1
  bmi delay_return
  b delay
delay_return:
  bx lr
.size delay, .-delay

.type reverse, %function
@ Reverses the bit order of (part of) a register.
@ Eg: bit 31 becomes bit 0 and vice versa, bit 30 becomes bit 1 and vice versa and so on
@ --parameters--
@ r0: value to reverse
@ r1: start bit index
@ r2: number of bits to reverse (end index = start bit index + number of bits)
reverse:
  push {r4}
  push {r1, r2}
  add r2, r1
  mov r3, 0 @ Accumulator
  mov r4, 0 @ Bit selector
reverse_loop:
  lsl r3, 1
  mov r4, 1
  lsl r4, r1
  and r4, r0
  lsr r4, r1
  orr r3, r4
  add r1, 1
  cmp r1, r2
  blt reverse_loop
  pop {r1, r2}
  lsl r3, r1
  @ Create the bit mask
  mvn r4, 0
  lsr r4, r1
  lsl r4, r1
  add r2, r1
  rsb r1, r2, 32
  lsl r4, r1
  lsr r4, r1
  bic r0, r4
  orr r0, r3
  pop {r4}
  bx lr
.size reverse, .-reverse

.type sync, %function
@ Just delays for a bit to let memory update
sync:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  bx lr
.size sync, .-sync