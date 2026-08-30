// =====================================================================
// Module      : control_unit
// Description : Generates all datapath control signals from the
//               instruction opcode/funct3/funct7 fields.
//
//   alu_src_a : 00 = rs1   01 = PC    10 = zero (used by LUI/AUIPC)
//   alu_src_b : 0  = rs2   1  = immediate
//   result_src: 00 = ALU result   01 = data memory   10 = PC+4 (link)
// =====================================================================
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        jump,
    output reg        jalr,
    output reg  [1:0] alu_src_a,
    output reg        alu_src_b,
    output reg  [1:0] result_src,
    output reg  [3:0] alu_ctrl
);

    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    always @(*) begin
        // ---- safe defaults (NOP-like behaviour for unsupported opcodes) ----
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_src_a  = 2'b00;
        alu_src_b  = 1'b0;
        result_src = 2'b00;
        alu_ctrl   = 4'b0000;

        case (opcode)

            OP_RTYPE: begin
                reg_write = 1'b1;
                alu_src_a = 2'b00;
                alu_src_b = 1'b0;
                case ({funct7, funct3})
                    10'b0000000_000: alu_ctrl = 4'b0000; // ADD
                    10'b0100000_000: alu_ctrl = 4'b0001; // SUB
                    10'b0000000_001: alu_ctrl = 4'b0010; // SLL
                    10'b0000000_010: alu_ctrl = 4'b0011; // SLT
                    10'b0000000_011: alu_ctrl = 4'b0100; // SLTU
                    10'b0000000_100: alu_ctrl = 4'b0101; // XOR
                    10'b0000000_101: alu_ctrl = 4'b0110; // SRL
                    10'b0100000_101: alu_ctrl = 4'b0111; // SRA
                    10'b0000000_110: alu_ctrl = 4'b1000; // OR
                    10'b0000000_111: alu_ctrl = 4'b1001; // AND
                    default:         alu_ctrl = 4'b0000;
                endcase
            end

            OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src_a = 2'b00;
                alu_src_b = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000;                          // ADDI
                    3'b010: alu_ctrl = 4'b0011;                          // SLTI
                    3'b011: alu_ctrl = 4'b0100;                          // SLTIU
                    3'b100: alu_ctrl = 4'b0101;                          // XORI
                    3'b110: alu_ctrl = 4'b1000;                          // ORI
                    3'b111: alu_ctrl = 4'b1001;                          // ANDI
                    3'b001: alu_ctrl = 4'b0010;                          // SLLI
                    3'b101: alu_ctrl = funct7[5] ? 4'b0111 : 4'b0110;    // SRAI/SRLI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            OP_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src_a  = 2'b00;
                alu_src_b  = 1'b1;
                alu_ctrl   = 4'b0000;   // address = rs1 + imm
                result_src = 2'b01;
            end

            OP_STORE: begin
                mem_write = 1'b1;
                alu_src_a = 2'b00;
                alu_src_b = 1'b1;
                alu_ctrl  = 4'b0000;    // address = rs1 + imm
            end

            OP_BRANCH: begin
                branch    = 1'b1;
                alu_src_a = 2'b00;
                alu_src_b = 1'b0;
                alu_ctrl  = 4'b0001;    // SUB -> zero flag feeds BEQ/BNE
            end

            OP_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10;     // rd = PC + 4
            end

            OP_JALR: begin
                reg_write  = 1'b1;
                jalr       = 1'b1;
                alu_src_a  = 2'b00;
                alu_src_b  = 1'b1;
                alu_ctrl   = 4'b0000;   // target = rs1 + imm
                result_src = 2'b10;     // rd = PC + 4
            end

            OP_LUI: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b10;     // 0
                alu_src_b  = 1'b1;      // + imm
                alu_ctrl   = 4'b0000;
                result_src = 2'b00;
            end

            OP_AUIPC: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b01;     // PC
                alu_src_b  = 1'b1;      // + imm
                alu_ctrl   = 4'b0000;
                result_src = 2'b00;
            end

            default: ; // unsupported opcode -> behaves as NOP
        endcase
    end

endmodule
