// =====================================================================
// Module      : alu
// Description : 32-bit Arithmetic Logic Unit for RV32I. Performs all
//               arithmetic/logic operations needed by R-type and
//               I-type instructions, and exposes zero/lt/ltu flags
//               used by the branch resolution logic.
//
// alu_ctrl encoding:
//   0000 ADD    0001 SUB    0010 SLL    0011 SLT (signed)
//   0100 SLTU   0101 XOR    0110 SRL    0111 SRA
//   1000 OR     1001 AND
// =====================================================================
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero,   // result == 0  (used for BEQ/BNE)
    output wire        lt,     // signed   a < b (used for BLT/BGE)
    output wire        ltu     // unsigned a < b (used for BLTU/BGEU)
);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                                   // ADD / ADDI
            4'b0001: result = a - b;                                   // SUB
            4'b0010: result = a << b[4:0];                             // SLL / SLLI
            4'b0011: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT / SLTI
            4'b0100: result = (a < b) ? 32'd1 : 32'd0;                 // SLTU / SLTIU
            4'b0101: result = a ^ b;                                   // XOR / XORI
            4'b0110: result = a >> b[4:0];                             // SRL / SRLI
            4'b0111: result = $signed(a) >>> b[4:0];                   // SRA / SRAI
            4'b1000: result = a | b;                                   // OR / ORI
            4'b1001: result = a & b;                                   // AND / ANDI
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);
    assign lt   = ($signed(a) < $signed(b));
    assign ltu  = (a < b);

endmodule
