// =====================================================================
// Module      : riscv_top
// Description : Top-level single-cycle RV32I processor. Instantiates
//               and connects: pc, decoder, control_unit, regfile,
//               alu, and memory. Supports R-type, I-type (ALU/load/
//               JALR), S-type (store), B-type (branch), U-type
//               (LUI/AUIPC) and J-type (JAL) instructions.
// =====================================================================
module riscv_top (
    input wire clk,
    input wire rst
);

    // ---------------- Program Counter ----------------
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire        pc_src;

    pc pc_inst (
        .clk     (clk),
        .rst     (rst),
        .stall   (1'b0),
        .pc_next (pc_next),
        .pc_out  (pc_current)
    );

    assign pc_plus4 = pc_current + 32'd4;

    // ---------------- Fetch ----------------
    wire [31:0] instr;

    // ---------------- Decode ----------------
    wire [6:0]  opcode;
    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] imm;

    decoder dec_inst (
        .instr  (instr),
        .opcode (opcode),
        .rd     (rd),
        .funct3 (funct3),
        .rs1    (rs1),
        .rs2    (rs2),
        .funct7 (funct7),
        .imm    (imm)
    );

    // ---------------- Control ----------------
    wire        reg_write, mem_read, mem_write, branch, jump, jalr;
    wire [1:0]  alu_src_a, result_src;
    wire        alu_src_b;
    wire [3:0]  alu_ctrl;

    control_unit ctrl_inst (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .jalr       (jalr),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .result_src (result_src),
        .alu_ctrl   (alu_ctrl)
    );

    // ---------------- Register File ----------------
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] rd_data;

    regfile rf_inst (
        .clk      (clk),
        .rst      (rst),
        .we       (reg_write),
        .rs1_addr (rs1),
        .rs2_addr (rs2),
        .rd_addr  (rd),
        .rd_data  (rd_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    // ---------------- ALU operand muxes ----------------
    reg  [31:0] alu_op_a;
    wire [31:0] alu_op_b;
    wire [31:0] alu_result;
    wire        alu_zero, alu_lt, alu_ltu;

    always @(*) begin
        case (alu_src_a)
            2'b00:   alu_op_a = rs1_data;    // R/I/S/B-type
            2'b01:   alu_op_a = pc_current;  // AUIPC
            2'b10:   alu_op_a = 32'd0;       // LUI
            default: alu_op_a = rs1_data;
        endcase
    end

    assign alu_op_b = alu_src_b ? imm : rs2_data;

    alu alu_inst (
        .a        (alu_op_a),
        .b        (alu_op_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (alu_zero),
        .lt       (alu_lt),
        .ltu      (alu_ltu)
    );

    // ---------------- Memory ----------------
    wire [31:0] dmem_rdata;

    memory mem_inst (
        .clk        (clk),
        .imem_addr  (pc_current),
        .imem_rdata (instr),
        .dmem_addr  (alu_result),
        .dmem_wdata (rs2_data),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .funct3     (funct3),
        .dmem_rdata (dmem_rdata)
    );

    // ---------------- Branch resolution ----------------
    reg branch_taken;
    always @(*) begin
        case (funct3)
            3'b000:  branch_taken = alu_zero;   // BEQ
            3'b001:  branch_taken = ~alu_zero;  // BNE
            3'b100:  branch_taken = alu_lt;     // BLT
            3'b101:  branch_taken = ~alu_lt;    // BGE
            3'b110:  branch_taken = alu_ltu;    // BLTU
            3'b111:  branch_taken = ~alu_ltu;   // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    wire [31:0] branch_target = pc_current + imm;
    wire [31:0] jalr_target   = (alu_result & ~32'd1); // clear LSB per spec

    assign pc_src  = (branch & branch_taken) | jump;
    assign pc_next = jalr ? jalr_target :
                      pc_src ? branch_target :
                               pc_plus4;

    // ---------------- Writeback mux ----------------
    reg [31:0] wb_data;
    always @(*) begin
        case (result_src)
            2'b00:   wb_data = alu_result;  // R/I-type ALU, LUI, AUIPC
            2'b01:   wb_data = dmem_rdata;  // Loads
            2'b10:   wb_data = pc_plus4;    // JAL/JALR link address
            default: wb_data = alu_result;
        endcase
    end
    assign rd_data = wb_data;

endmodule
