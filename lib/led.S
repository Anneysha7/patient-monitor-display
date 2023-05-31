.syntax unified
@ Simple LED library
@ NOTE: This module depends on utils.S and symbols.S

@ --------------------- Module Interface --------------------
@ declare all labels corresponding to functions designed to be called from elsewhere
@ as global - this is the public API of the library
@ Function exports:
.global init_leds, write_row_pin, write_column_pin, write_led_pin, 
.global write_led, write_pins, write_row_pins, write_column_pins, write_row_pins_natural, write_column_pins_natural
.global read_led, read_pins, read_row, read_column,
 
@ --------------------- Implementation --------------------
.type init_leds, %function
@ REQUIRED for other functions in this library to work (call once)
@ Sets the GPIO pins used for the led matrix to OUTPUT mode 
@ --parameters--
@ none
init_leds:
  push {r4, lr}
  @ set the columns and rows default to off
  mov r0, 0b11111
  bl write_column_pins
  mov r0, 0b00000
  bl write_row_pins
  ldr r4, =0 @ r4 stores loop counter
init_loop_start:
  cmp r4, #10 @ 10 total columns and rows to initialize
  beq init_loop_end
  mov r0, r4 @ Index of pin in pins array
  ldr r1, =OFS_GPIO_DIR
  ldr r2, =1 @ Set direction to output
  bl write_led_pin
  add r4, #1
  b init_loop_start
init_loop_end:
  pop {r4, lr}
  bx lr
.size init_leds, .-init_leds

.type write_row_pin, %function
@ Controls the bit for a specified led GPIO row in the specified offset register
@ --parameters--
@ r0: row index (0-4 with 0 being the top row)
@ r1: offset register (usually OUT or DIR)
@ r2: led state (lsb)
write_row_pin:
  push {lr}
  bl write_led_pin
  pop {lr}
  bx lr
.size write_row_pin, .-write_row_pin

.type write_column_pin, %function
@ Controls the bit for a specified led GPIO column in the specified offset register
@ --parameters--
@ r0: column index (0-4 with 0 being the left most column)
@ r1: offset register (usually OUT or DIR)
@ r2: led state (lsb)
write_column_pin:
  push {lr}
  add r0, 5 @ convert to column index for write pin function
  bl write_led_pin
  pop {lr}
  bx lr
.size write_column_pin, .-write_column_pin

.type write_led_pin, %function
@ Controls the bit for a specified led GPIO pin in the specified offset register
@ --parameters--
@ r0: pin index (0-4 is rows, 5-9 is cols)
@ r1: offset register (usually OUT or DIR)
@ r2: led state (lsb)
write_led_pin:
  push {r4, lr}
  mov r4, r0
  cmp r0, #8 @ Necessary because one of the led pins in in port 1, the rest are in port 0 (srsly, why?)
  beq set_led_else_start
set_led_if_start:
  ldr r0, =ADR_P0
  b set_led_if_end
set_led_else_start:
  ldr r0, =ADR_P1
set_led_if_end:
  mov r3, r2
  ldr r2, =pin_data
  ldr r2, [r2, r4, lsl #2] @ read data from pin array
  bl write_bit
  pop {r4, lr}
  bx lr
.size write_led_pin, .-write_led_pin

.type write_led, %function
@ Controls the column and row pins for a given led. Turns the column low and row high. 
@ Makes no checks for any existing state with other leds and the side effects this could cause.
@ --parameters--
@ r0: row index (0-4 with 0 being the top row)
@ r1: column index (0-4 with 0 being the left most column)
@ r2: led state (lsb)
write_led:
  push {lr}
  push {r0 - r2}
  ldr r1, =OFS_GPIO_OUT
  @ rows are used to control the leds, so this can just be called as is to turn the row OUT high or low
  bl write_led_pin
  pop {r0 - r2}
  @ turn the corresponding column low regardless
  mov r0, r1
  add r0, 5
  ldr r1, =OFS_GPIO_OUT
  mov r2, 0
  bl write_led_pin
  pop {lr}
  bx lr
.size write_led, .-write_led

.type write_pins, %function
@ Controls the led column or row current outputs based on a given structure. 
@ Makes no checks for any existing state with other leds and the side effects this could cause.
@ Bit index = led row / column index - 1 (top most row is row 1, bottom most row is row 5, 
@                                         left most column is col 1, right most column is col 5)
@ For example of led states:
@ r0 = 0b...01011 -> Row/Col 1: high, Row/Col 2: high, Row/Col 3: low, Row/Col 4: high, Row/Col 5: low
@ Remember that:
@   - to turn an led on, the row must be high and the column low
@   - to turn an led off, the row can be low and/or the column high
@ --parameters--
@ r0: led states, least significant 5 bits where a 1 means pin high, 0 means pin low (bit<0> == row/col 1, bit<4> == row/col 5)
@ r1: row or column control (0 == Row, 1 == Column)
write_pins:
  push {r4 - r6, lr}
  mov r4, 5
  mul r6, r4, r1
  mov r5, r0
write_pins_loop:
  subs r4, 1
  bmi write_pins_loop_end
  lsr r2, r5, r4
  and r2, 0b1
  mov r0, r4
  add r0, r6
  ldr r1, =OFS_GPIO_OUT
  bl write_led_pin
  b write_pins_loop
write_pins_loop_end:
  pop {r4 - r6, lr}
  bx lr
.size write_pins, .-write_pins

.type write_row_pins, %function
@ Controls the led rows current output based on a given structure. 
@ Makes no checks for any existing state with other leds and the side effects this could cause.
@ Bit index = led row index - 1 (top most row is row 1, bottom most row is row 5)
@ For example of led states:
@ r0 = 0b...01011 -> Row 1: high, Row 2: high, Row 3: low, Row 4: high, Row 5: low
@ --parameters--
@ r0: led states, least significant 5 bits where a 1 means led on, 0 means led off (bit<0> == row 1 (top), bit<4> == row 5 (bottom))
write_row_pins:
  push {lr}
  mov r1, 0
  bl write_pins
  pop {lr}
  bx lr
.size write_row_pins, .-write_row_pins

.type write_column_pins, %function
@ Controls the led columns current output based on a given structure. (Inverts the input so that 
@ a 1 turns the column on and 0 turns the column off because of the way the LED circuits are wired).
@ Makes no checks for any existing state with other leds and the side effects this could cause.
@ Bit index = led column index - 1 (left most column is column 1, right most column is column 5)
@ For example of led states:
@ r0 = 0b...01011 -> Col 1: low, Col 2: low, Col 3: high, Col 4: low, Col 5: high
@ Remember that:
@   - to turn an led on, the row must be high and the column low
@   - to turn an led off, the row can be low and/or the column high
@ --parameters--
@ r0: led states, least significant 5 bits where a 1 means led on, 0 means led off (bit<0> == col 1 (left), bit<4> == col 5 (right))
write_column_pins:
  push {lr}
  mvn r0, r0
  and r0, 0b11111
  mov r1, 1
  bl write_pins
  pop {lr}
  bx lr
.size write_column_pins, .-write_column_pins

.type write_row_pins_natural, %function
@ The same as write_row_pins but with the bit order reversed so that the binary string matches 
@ the led order.
@ --parameters--
@ r0: led states, least significant 5 bits where a 1 means led on, 0 means led off (bit<0> == row 5 (bottom), bit<4> == row 1 (top))
write_row_pins_natural:
  push {lr}
  mov r1, 0
  mov r2, 5
  bl reverse
  mov r1, 0
  bl write_pins
  pop {lr}
  bx lr
.size write_row_pins_natural, .-write_row_pins_natural

.type write_column_pins_natural, %function
@ The same as write_column_pins but with the bit order reversed so that the binary string matches 
@ the led order.
@ --parameters--
@ r0: led states, least significant 5 bits where a 1 means led on, 0 means led off (bit<0> == col 5 (right), bit<4> == col 1 (left))
write_column_pins_natural:
  push {lr}
  mvn r0, r0
  and r0, 0b11111
  mov r1, 0
  mov r2, 5
  bl reverse
  mov r1, 1
  bl write_pins
  pop {lr}
  bx lr
.size write_column_pins_natural, .-write_column_pins_natural

.type read_led, %function
@ Reads the led current output state based on a given row and column index. 
@ --parameters--
@ r0: row index (0-4 with 0 being the top row)
@ r1: column index (0-4 with 0 being the left most column)
@ --return--
@ r0: bit<0> contains led state (1 == On, 0 == Off)
@ flags set
read_led:
  push {r4, r5, lr}
  mov r4, r0
  mov r5, r1
  bl read_row
  lsr r0, r4
  and r4, r0, 0b1
  bl read_column
  lsr r0, r5
  and r5, r0, 0b1
  @ To make a circuit, the row has to be high and the column low (and not)
  bics r0, r4, r5
  pop {r4, r5, lr}
  bx lr
.size read_led, .-read_led

.type read_pins, %function
@ Reads the row or column pins current output state. 
@ --parameters--
@ r0: read row or column (0 == Row, 1 == Column)
@ --return--
@ r0: bit<0-4> contains output state, bit index == row / column index (1 == High, 0 == Low)
read_pins:
  push {r4 - r6, lr}
  mov r6, 20
  mul r6, r0
  mov r4, 0
  mov r5, 5
read_pins_loop:
  subs r5, 1
  bmi read_pins_loop_end
  lsl r4, 1
  @ column 3 is on port 2
  cmp r6, 0
  beq read_pins_if_start
  @ if we're here, then we are reading columns
  cmp r5, 3
  beq read_pins_else_start
read_pins_if_start:
  ldr r0, =ADR_P0
  b read_pins_if_end
read_pins_else_start:
  ldr r0, =ADR_P1
read_pins_if_end:
  ldr r1, =OFS_GPIO_OUT
  ldr r2, =pin_data
  mov r3, 4
  mul r3, r5
  add r3, r6
  ldr r2, [r2, r3]
  bl read_bit
  orr r4, r0
  b read_pins_loop
read_pins_loop_end:
  mov r0, r4
  pop {r4 - r6, lr}
  bx lr
.size read_pins, .-read_pins

.type read_row, %function
@ Reads the row pins current output state. 
@ --parameters--
@ none
@ --return--
@ r0: bit<0-4> contains row output state, bit index == row index (1 == High, 0 == Low)
read_row:
  push {lr}
  mov r0, 0
  bl read_pins
  pop {lr}
  bx lr
.size read_row, .-read_row

.type read_column, %function
@ Reads the column pins current output state. 
@ --parameters--
@ none
@ --return--
@ r0: bit<0-4> contains column output state, bit index == column index (1 == High, 0 == Low)
read_column:
  push {lr}
  mov r0, 1
  bl read_pins
  pop {lr}
  bx lr
.size read_column, .-read_column

.data
pin_data:
@ row_pins:
@     0   1   2   3   4
.word 21, 22, 15, 24, 19
@ col_pins:
@     0   1   2   3   4
.word 28, 11, 31, 05, 30
