// =====================================================================
// Module      : decoder
// Description : Splits a 32-bit RV32I instruction into its fields and
//               generates the correctly sign-extended immediate for
//               every instruction format (I, S, B, U, J). R-type
//               instructions produce imm = 0 (unused).
// =====================================================================
module decoder (
    input  wire [31:0] instr,
    output wire [6:0]  opcode,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [6:0]  funct7,
    output reg  [31:0] imm
);

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    always @(*) begin
        case (opcode)
            7'b0110011: imm = 32'd0;                                             // R-type
            7'b0010011,                                                          // I-type ALU
            7'b0000011,                                                          // Load
            7'b1100111:                                                          // JALR
                imm = {{20{instr[31]}}, instr[31:20]};
            7'b0100011:                                                          // S-type (store)
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011:                                                          // B-type (branch)
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b0110111,                                                          // LUI
            7'b0010111:                                                          // AUIPC
                imm = {instr[31:12], 12'b0};
            7'b1101111:                                                          // JAL
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default:
                imm = 32'd0;
        endcase
    end

endmodule
