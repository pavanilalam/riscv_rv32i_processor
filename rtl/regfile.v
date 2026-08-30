// =====================================================================
// Module      : regfile
// Description : RV32I integer register file. 32 x 32-bit registers.
//               x0 is hardwired to zero. Two asynchronous read ports,
//               one synchronous write port (write-before-read on same
//               cycle is not required for a single-cycle datapath).
// =====================================================================
module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,         // register write enable
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    reg [31:0] regs [0:31];
    integer i;

    // Asynchronous (combinational) reads, x0 always reads 0
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

endmodule
