# P41 Terminal output (UART) - dossier

## U1 Digital logic

The important control equation is:

- `ready = 1` when the 3-bit busy counter is zero.
- `accept = write AND ready AND NOT reset`.

When a write is accepted, the counter loads binary `100` (decimal 4). While it is non-zero, it counts down by one on each rising clock edge. A write during this busy interval is ignored. The counter therefore needs flip-flops and next-state logic; gates implement the zero-detect and accept conditions.

| reset | write | ready before edge | accept |
|---:|---:|---:|---:|
| 1 | X | 1 after reset | 0 |
| 0 | 0 | 0 or 1 | 0 |
| 0 | 1 | 0 | 0 |
| 0 | 1 | 1 | 1 |

## U2 Digital components

The Digital task uses a 3-bit down-counter made from D flip-flops. Combinational gate logic detects the zero state, selects either the constant value 4 (when a write is accepted), or the decremented counter value (while busy). `ready` is the zero-detect output and `accept` is the write-and-ready condition. The full Verilog device adds the memory-mapped register interface and the transmitted character output.

## U3 Data representation

Three representative values:

1. Package ID 41 is decimal `41`, hexadecimal `0x29`, binary `0010 1001`. Register 15 returns this value so software can identify the device.
2. A transmitted ASCII capital `A` is decimal `65`, hexadecimal `0x41`, binary `0100 0001`. The low byte of `TXDATA` carries this character.
3. The busy reload value 4 is decimal `4`, hexadecimal `0x4`, binary `100` in the 3-bit counter.

The UART transmits only `wdata[7:0]`; using the full 32-bit value as a character would be incorrect. The counter is unsigned, so it must not be sign-extended.

## U4 Computer organisation

The UART is used during the memory stage of ordinary load/store instructions. The CPU calculates an I/O address, the address decoder selects device slot 0, and the I/O bus passes the read or write to this block. A store to `UART_TXDATA` sends a character; a load from `UART_TXSTATUS` checks whether the transmitter is ready. The instruction itself still follows the normal fetch, decode, execute, memory and write-back cycle.

## U5 Processors

RC-V is a load-store RISC-V processor, so the program controls the UART using ordinary `lw` and `sw` instructions and a small polling routine. A CISC design might provide a special output instruction, while a stack machine could pass the character on its operand stack. A GPU is designed for many parallel data operations and would normally be an unnecessarily complicated choice for a single terminal character.

## U6 Memory and I/O

P41 is a memory-mapped I/O device in slot 0, beginning at address `0x00020000`. Register 0 (`TXDATA`) accepts a character; register 1 (`TXSTATUS`) has ready in bit 0; register 15 returns package number 41. The CPU writes a character only after polling ready. This is programmed I/O: the CPU waits for the device rather than using a DMA transfer.

## E1 Instruction trace: a DMA-stolen cycle

This is an illustrative one-word DMA transfer trace (the exact addresses and data depend on the simulator run). Assume DMA is copying one word from RAM address `0x00001000` to `0x00001100`.

1. The DMA controller (P48) has been programmed with source, destination and length. Its control register starts the transfer and its status reports busy.
2. The bus arbiter (P34) sees the DMA request and grants the bus to DMA for a stolen cycle; the processor does not use that memory-bus slot for its own load/store.
3. In the DMA read phase, the source address `0x00001000` is presented to the address decoder (P31). The RAM (P29) returns the source word through the read-data path (P32).
4. In the DMA write phase, the destination address `0x00001100` and the saved word are sent to the memory write path. The RAM stores the word at the destination.
5. P48 advances its source/destination and length state. When the transfer finishes, its done status is set; if interrupt enable was requested, it can raise an interrupt through P47.

For the submitted simulator trace, replace the illustrative addresses with the values shown by your own `--trace` run and include the actual word value and bus-control signals.

## E2 Neighbour review

Review partners for this package are P48 (DMA controller) and P42 (Keyboard input). Add the two real GitHub pull-request review-comment links here after completing those reviews:

- P48 review: pending
- P42 review: pending

## E3 Where my block sits

P41 belongs to the I/O layer of the computer and is connected to the memory-mapped I/O bus through the address decoder and I/O interface. The CPU writes characters to TXDATA and reads TXSTATUS; the terminal output logic exposes accepted characters through `tx_valid` and `tx_char`.

## E4 Syllabus map

Topics touched by this package:

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
