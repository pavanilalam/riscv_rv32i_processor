# =====================================================================
# Test program for the RV32I single-cycle processor.
# Assembled by hand into program.hex (one 32-bit hex word per line).
# Exercises: ADDI, ADD, SUB, SW, LW, BEQ (taken), JAL, and verifies
# that instructions skipped by control flow are never executed.
# =====================================================================

        addi x1, x0, 5        # 0x00 : x1 = 5
        addi x2, x0, 10       # 0x04 : x2 = 10
        add  x3, x1, x2       # 0x08 : x3 = x1 + x2 = 15
        sub  x4, x2, x1       # 0x0C : x4 = x2 - x1 = 5
        sw   x3, 0(x0)        # 0x10 : mem[0] = 15
        lw   x5, 0(x0)        # 0x14 : x5 = mem[0] = 15
        beq  x1, x4, skip1    # 0x18 : x1 == x4 (5 == 5) -> branch taken
        addi x6, x0, 99       # 0x1C : SKIPPED (proves branch worked)
skip1:
        jal  x7, skip2        # 0x20 : x7 = 0x24 (return addr), jump to skip2
        addi x8, x0, 111      # 0x24 : SKIPPED (proves jump worked)
skip2:
        addi x9, x0, 1        # 0x28 : x9 = 1  (landing point)
halt:
        beq  x0, x0, halt     # 0x2C : infinite loop, halts the program

# Expected final register file contents:
#   x1=5  x2=10  x3=15  x4=5  x5=15
#   x6=0 (never executed)   x7=36 (0x24, jal link address)
#   x8=0 (never executed)   x9=1
