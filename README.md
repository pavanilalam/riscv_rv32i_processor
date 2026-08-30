# RISC-V RV32I Single-Cycle Processor (Verilog HDL)

A fully functional, single-cycle RISC-V **RV32I** processor implemented in
Verilog HDL, verified in **Xilinx Vivado** with a self-checking testbench.

---

## 1. Architecture Overview

This is a **single-cycle** (one instruction completes every clock cycle)
implementation of the RV32I base integer instruction set. It supports:

| Category | Instructions |
|---|---|
| R-type (register-register) | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I-type (register-immediate) | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| Loads | LB, LH, LW, LBU, LHU |
| Stores | SB, SH, SW |
| Branches | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jumps | JAL, JALR |
| Upper immediate | LUI, AUIPC |

### Block diagram (single-cycle datapath)

```
                 +---------+
        +------->|   PC    |----+--------------------------> imem_addr
        |        +---------+    |
        |             |         |
        |         pc_current    |
        |             |         v
        |             |   +------------+        +------------------+
        |             +-->| decoder    |         |  memory (imem +  |
        |                 | (fields +  |<--------|  dmem)           |
        |                 |  imm gen)  | instr    +------------------+
        |                 +------------+                  ^   ^
        |                    |    |                        |   |
        |                    v    v                dmem_addr   dmem_wdata
        |               +----------+                (=alu_result)  (=rs2_data)
        |               | control  |
        |               |  unit    |
        |               +----------+
        |                 |  |  |
        |                 v  v  v
        |   +---------+  regfile <-----+  rd_data (writeback mux)
        |   | regfile |  (rs1,rs2,rd)  |
        |   +---------+                |
        |        |   |                 |
        |        v   v                 |
        |     +-----------+            |
        +-----| ALU       |----> alu_result --> dmem_addr, branch cmp
              | (a,b,ctrl)|
              +-----------+
                    |
             branch/jump target calc --> pc_next
```

### Module list (matches the 6 core modules)

| # | File | Module | Responsibility |
|---|------|--------|-----------------|
| 1 | `rtl/pc.v` | `pc` | Holds/updates the program counter each clock edge |
| 2 | `rtl/regfile.v` | `regfile` | 32 x 32-bit register file (x0 hardwired to 0) |
| 3 | `rtl/alu.v` | `alu` | Arithmetic/logic ops + zero/lt/ltu flags for branches |
| 4 | `rtl/decoder.v` | `decoder` | Splits instruction into fields, generates sign-extended immediates for all 5 formats (I/S/B/U/J) |
| 5 | `rtl/control_unit.v` | `control_unit` | Decodes opcode/funct3/funct7 into datapath control signals |
| 6 | `rtl/memory.v` | `memory` | Instruction memory (loaded from `program.hex`) + byte-addressable data memory with LB/LH/LW/LBU/LHU and SB/SH/SW support |
| — | `rtl/riscv_top.v` | `riscv_top` | Top-level module that instantiates and wires all 6 modules together |

---

## 2. How instruction execution works (single cycle)

1. **Fetch** – `pc_current` addresses `memory.imem`, returning `instr`.
2. **Decode** – `decoder` extracts `opcode/rd/funct3/rs1/rs2/funct7` and
   generates the correct immediate; `control_unit` turns the opcode into
   control signals (`reg_write`, `mem_read`, `mem_write`, `branch`, `jump`,
   `jalr`, ALU operand selects, `alu_ctrl`, `result_src`).
3. **Register read** – `regfile` supplies `rs1_data`/`rs2_data`
   combinationally.
4. **Execute** – `alu` computes the result (or memory address, or branch
   comparison) from the muxed operands.
5. **Memory** – for loads/stores, `memory` reads/writes `dmem` at
   `alu_result`.
6. **Write-back** – a mux selects ALU result / memory data / PC+4 (for
   JAL/JALR link) and writes it into `rd` on the next clock edge.
7. **Next PC** – computed combinationally: `PC+4` normally, `PC+imm` for
   taken branches/JAL, or `(rs1+imm) & ~1` for JALR.

---

## 3. Verification

`tb/riscv_tb.v` is a self-checking testbench that:

- Instantiates `riscv_top`, generates a 100 MHz clock, applies reset.
- Runs `sim/program.hex` (assembly source documented in `sim/program.asm`),
  a hand-written test program that exercises `ADDI`, `ADD`, `SUB`, `SW`,
  `LW`, a **taken** `BEQ`, and `JAL` — including two instructions that must
  be *skipped* by control flow, which proves branch/jump redirection works.
- Dumps a `.vcd` waveform for inspection in Vivado's waveform viewer (or
  GTKWave).
- Prints expected vs. actual register values and a final `PASS`/`FAIL`
  verdict using `$display`.

Expected final register state:

| Reg | Value | Meaning |
|---|---|---|
| x1 | 5 | ADDI |
| x2 | 10 | ADDI |
| x3 | 15 | ADD (x1+x2) |
| x4 | 5 | SUB (x2-x1) |
| x5 | 15 | LW from mem[0], written by SW |
| x6 | 0 | must stay 0 — instruction skipped by taken BEQ |
| x7 | 36 (0x24) | JAL return-address link |
| x8 | 0 | must stay 0 — instruction skipped by JAL |
| x9 | 1 | ADDI, landing point after JAL |

---

## 4. Running the simulation in Xilinx Vivado

1. **Create project**: `File → Project → New...` → RTL Project (do *not*
   specify sources yet) → default part is fine for simulation-only use.
2. **Add design sources**: right-click *Design Sources* → *Add Sources* →
   add all files in `rtl/` (`pc.v`, `regfile.v`, `alu.v`, `decoder.v`,
   `control_unit.v`, `memory.v`, `riscv_top.v`).
3. **Add simulation sources**: right-click *Simulation Sources* → *Add
   Sources* → add `tb/riscv_tb.v`.
4. **Add the memory image**: right-click *Simulation Sources* → *Add
   Sources* → *Add or create simulation sources* → add `sim/program.hex`
   as a simulation-only file (or simply copy `program.hex` into the
   Vivado working directory referenced by `$readmemh`, typically
   `<project>.sim/sim_1/behav/xsim/`).
5. Set `riscv_tb` as the top module for simulation (Vivado usually
   auto-detects it since it has no ports).
6. Run `Flow Navigator → SIMULATION → Run Simulation → Run Behavioral
   Simulation`.
7. In the Tcl console, extend the run if needed: `run 500 ns`.
8. Check the **Tcl console** for the `PASS`/`FAIL` report, and add
   `dut/rf_inst/regs`, `dut/pc_inst/pc_out`, `dut/instr` etc. to the
   **Waveform** window to visually confirm each instruction's effects.

---

## 5. Repository layout

```
riscv_rv32i_processor/
├── README.md
├── .gitignore
├── rtl/
│   ├── pc.v
│   ├── regfile.v
│   ├── alu.v
│   ├── decoder.v
│   ├── control_unit.v
│   ├── memory.v
│   └── riscv_top.v
├── tb/
│   └── riscv_tb.v
└── sim/
    ├── program.asm      # human-readable source for the test program
    └── program.hex      # assembled machine code, loaded via $readmemh
```

---


