# RISC-V RV32I Single-Cycle Processor (Verilog HDL)

A fully functional, single-cycle RISC-V **RV32I** processor implemented in Verilog HDL, verified in **Xilinx Vivado** with a self-checking testbench.

---

## ✨ Highlights
- Designed and implemented a complete RV32I processor spanning 6 core modules:
  - Program Counter, Register File, ALU, Instruction Decoder, Control Unit, Memory Interface
- Verified correct instruction execution across multiple test programs using testbenches and waveform analysis in Vivado.
- Demonstrated branch/jump redirection, arithmetic operations, and memory access with self-checking verification.

---

## 🏗️ Architecture Overview

This is a **single-cycle** implementation of the RV32I base integer instruction set. One instruction completes every clock cycle.

### Supported Instructions
| Category | Instructions |
|----------|--------------|
| R-type   | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I-type   | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| Loads    | LB, LH, LW, LBU, LHU |
| Stores   | SB, SH, SW |
| Branches | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jumps    | JAL, JALR |
| Upper Immediate | LUI, AUIPC |

### Datapath Block Diagram
+---------+
+------->|   PC    |----+--------------------------> imem_addr
|        +---------+    |
|             |         |
|         pc_current    |
|             |         v
|             |   +------------+        +------------------+
|             +-->| decoder    |<-------| memory (imem+dmem)|
|                 | imm gen    | instr  +------------------+
|                 +------------+                  ^   ^
|                    |    |                        |   |
|                    v    v                dmem_addr   dmem_wdata
|               +----------+                (=alu_result) (=rs2_data)
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

Code

---

## 📂 Module List
| # | File | Module | Responsibility |
|---|------|--------|----------------|
| 1 | `rtl/pc.v` | `pc` | Program counter update |
| 2 | `rtl/regfile.v` | `regfile` | 32×32 register file (x0 = 0) |
| 3 | `rtl/alu.v` | `alu` | Arithmetic/logic ops + flags |
| 4 | `rtl/decoder.v` | `decoder` | Instruction field split + immediate generation |
| 5 | `rtl/control_unit.v` | `control_unit` | Opcode/funct decoding → control signals |
| 6 | `rtl/memory.v` | `memory` | Instruction + data memory |
| — | `rtl/riscv_top.v` | `riscv_top` | Top-level integration |

---

## ⚙️ Instruction Execution Flow
1. **Fetch** – PC addresses instruction memory.
2. **Decode** – Instruction fields + immediate generation.
3. **Register Read** – `rs1_data`, `rs2_data` fetched.
4. **Execute** – ALU computes result / branch comparison.
5. **Memory** – Load/store via data memory.
6. **Write-back** – Result written to destination register.
7. **Next PC** – PC+4, branch target, or JALR target.

---

### Expected Register State (after program execution)
| Reg | Value | Meaning |
|-----|-------|---------|
| x1  | 5     | ADDI |
| x2  | 10    | ADDI |
| x3  | 15    | ADD (x1+x2) |
| x4  | 5     | SUB (x2-x1) |
| x5  | 15    | LW from mem[0] |
| x6  | 0     | Skipped by BEQ |
| x7  | 36    | JAL return address |
| x8  | 0     | Skipped by JAL |
| x9  | 1     | ADDI after JAL |

---

## ▶️ Running Simulation in Vivado
1. Create RTL project.
2. Add design sources (`rtl/*.v`).
3. Add simulation sources (`tb/riscv_tb.v`).
4. Add memory image (`sim/program.hex`).
5. Set `riscv_tb` as simulation top.
6. Run behavioral simulation (`run 500 ns`).
7. Check console for PASS/FAIL and waveform for signal correctness.

---

## 📁 Repository Layout
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
├── program.asm
└── program.hex

Code

---


## 📌 Suggested Topics
`riscv`, `verilog`, `rv32i`, `computer-architecture`, `fpga`, `vivado`, `hdl`

---
