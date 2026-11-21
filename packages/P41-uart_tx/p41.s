# P41 - Framed terminal output using the UART transmitter.
# Reads at most 40 characters, then prints:
# +----------+
# | message  |
# +----------+
#
# Only rcv_read_line is used from the shared library.
# All output goes through our own p41_putc routine.

        .text
p41_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        # Read a line into a 41-byte buffer (40 chars + NUL).
        la      a0, p41_buffer
        li      a1, 41
        call    rcv_read_line
        mv      s0, a0              # s0 = text length
        la      s1, p41_buffer      # s1 = current text pointer

        # First border: '+' + (length + 2) hyphens + '+' + newline.
        li      a0, '+'
        call    p41_putc
        addi    s2, s0, 2
p41_top_dashes:
        beqz    s2, p41_top_end
        li      a0, '-'
        call    p41_putc
        addi    s2, s2, -1
        j       p41_top_dashes
p41_top_end:
        li      a0, '+'
        call    p41_putc
        li      a0, 10
        call    p41_putc

        # Middle line: '| ' + text + ' |' + newline.
        li      a0, '|'
        call    p41_putc
        li      a0, ' '
        call    p41_putc

p41_text_loop:
        beqz    s0, p41_text_end
        lbu     a0, 0(s1)
        call    p41_putc
        addi    s1, s1, 1
        addi    s0, s0, -1
        j       p41_text_loop

p41_text_end:
        li      a0, ' '
        call    p41_putc
        li      a0, '|'
        call    p41_putc
        li      a0, 10
        call    p41_putc

        # Bottom border.
        li      a0, '+'
        call    p41_putc
        # Re-read length from the buffer's terminating position:
        # s2 is reused as a counter; the original length was saved in
        # the stack-free s0? It was consumed above, so count the string.
        la      s1, p41_buffer
        li      s2, 0
p41_count_text:
        lbu     t0, 0(s1)
        beqz    t0, p41_count_done
        addi    s2, s2, 1
        addi    s1, s1, 1
        j       p41_count_text
p41_count_done:
        addi    s2, s2, 2
p41_bottom_dashes:
        beqz    s2, p41_bottom_end
        li      a0, '-'
        call    p41_putc
        addi    s2, s2, -1
        j       p41_bottom_dashes
p41_bottom_end:
        li      a0, '+'
        call    p41_putc
        li      a0, 10
        call    p41_putc

        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

# p41_putc(a0 = character)
# Wait until TXSTATUS bit 0 is set, then write the byte to TXDATA.
# Uses only caller-saved temporary registers.
p41_putc:
        li      t0, UART_TXSTATUS
p41_putc_wait:
        lw      t1, 0(t0)
        andi    t1, t1, 1
        beqz    t1, p41_putc_wait
        li      t0, UART_TXDATA
        sw      a0, 0(t0)
        ret

        .data
        .align  2
p41_buffer:
        .space  41
