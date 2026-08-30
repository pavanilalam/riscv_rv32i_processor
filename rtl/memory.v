// =====================================================================
// Module      : memory
// Description : Combined instruction + data memory interface.
//                 - Instruction memory : 1024 x 32-bit words (4 KB),
//                   word-addressed, loaded from program.hex.
//                 - Data memory        : 4096 x 8-bit bytes (4 KB),
//                   byte-addressable, supports LB/LH/LW/LBU/LHU and
//                   SB/SH/SW with correct sign/zero extension.
// =====================================================================
module memory (
    input  wire        clk,

    // ---- Instruction fetch port (combinational read) ----
    input  wire [31:0] imem_addr,
    output wire [31:0] imem_rdata,

    // ---- Data memory port ----
    input  wire [31:0] dmem_addr,
    input  wire [31:0] dmem_wdata,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  funct3,
    output reg  [31:0] dmem_rdata
);

    reg [31:0] imem [0:1023];   // 4 KB instruction memory
    reg [7:0]  dmem [0:4095];   // 4 KB data memory (byte addressable)

    initial begin
        $readmemh("program.hex", imem);
    end

    // Instruction fetch: word-aligned, combinational
    assign imem_rdata = imem[imem_addr[11:2]];

    // Data memory read: combinational with sign/zero extension
    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: dmem_rdata = {{24{dmem[dmem_addr][7]}}, dmem[dmem_addr]};                    // LB
                3'b001: dmem_rdata = {{16{dmem[dmem_addr+1][7]}}, dmem[dmem_addr+1], dmem[dmem_addr]}; // LH
                3'b010: dmem_rdata = {dmem[dmem_addr+3], dmem[dmem_addr+2],
                                       dmem[dmem_addr+1], dmem[dmem_addr]};                            // LW
                3'b100: dmem_rdata = {24'b0, dmem[dmem_addr]};                                         // LBU
                3'b101: dmem_rdata = {16'b0, dmem[dmem_addr+1], dmem[dmem_addr]};                      // LHU
                default: dmem_rdata = 32'd0;
            endcase
        end else begin
            dmem_rdata = 32'd0;
        end
    end

    // Data memory write: synchronous
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin                                    // SB
                    dmem[dmem_addr] <= dmem_wdata[7:0];
                end
                3'b001: begin                                    // SH
                    dmem[dmem_addr]   <= dmem_wdata[7:0];
                    dmem[dmem_addr+1] <= dmem_wdata[15:8];
                end
                3'b010: begin                                    // SW
                    dmem[dmem_addr]   <= dmem_wdata[7:0];
                    dmem[dmem_addr+1] <= dmem_wdata[15:8];
                    dmem[dmem_addr+2] <= dmem_wdata[23:16];
                    dmem[dmem_addr+3] <= dmem_wdata[31:24];
                end
                default: ;
            endcase
        end
    end

endmodule
