// =====================================================================
// Module      : pc
// Description : Program Counter register. Holds the address of the
//               instruction currently being fetched and updates on
//               every clock edge unless reset or stalled.
// =====================================================================
module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,     // freeze PC (not used in single-cycle core, kept for extensibility)
    input  wire [31:0] pc_next,   // next PC value (computed in top-level)
    output reg  [31:0] pc_out     // current PC value
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'h0000_0000;
        else if (!stall)
            pc_out <= pc_next;
    end

endmodule
