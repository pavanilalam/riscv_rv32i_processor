`timescale 1ns / 1ps
// =====================================================================
// Testbench   : riscv_tb
// Description : Instantiates the RV32I processor, applies reset,
//               runs the test program (see sim/program.hex /
//               sim/program.asm), then checks the final register
//               file contents against expected values and reports
//               PASS/FAIL. Also dumps a VCD waveform for viewing in
//               Vivado's waveform viewer or GTKWave.
// =====================================================================
module riscv_tb;

    reg clk;
    reg rst;

    riscv_top dut (
        .clk (clk),
        .rst (rst)
    );

    // 100 MHz clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        #12;
        rst = 0;

        // Run long enough for the program (through the infinite loop) to finish
        #500;

        $display("---------------------------------------------------");
        $display(" RV32I Single-Cycle Processor - Verification Report");
        $display("---------------------------------------------------");
        $display("x1 (expect 5)            = %0d", dut.rf_inst.regs[1]);
        $display("x2 (expect 10)           = %0d", dut.rf_inst.regs[2]);
        $display("x3 (expect 15)           = %0d", dut.rf_inst.regs[3]);
        $display("x4 (expect 5)            = %0d", dut.rf_inst.regs[4]);
        $display("x5 (expect 15, from LW)  = %0d", dut.rf_inst.regs[5]);
        $display("x6 (expect 0, skipped)   = %0d", dut.rf_inst.regs[6]);
        $display("x7 (expect 36, JAL link) = %0d", dut.rf_inst.regs[7]);
        $display("x8 (expect 0, skipped)   = %0d", dut.rf_inst.regs[8]);
        $display("x9 (expect 1)            = %0d", dut.rf_inst.regs[9]);

        if (dut.rf_inst.regs[1] == 32'd5  && dut.rf_inst.regs[2] == 32'd10 &&
            dut.rf_inst.regs[3] == 32'd15 && dut.rf_inst.regs[4] == 32'd5  &&
            dut.rf_inst.regs[5] == 32'd15 && dut.rf_inst.regs[6] == 32'd0  &&
            dut.rf_inst.regs[7] == 32'd36 && dut.rf_inst.regs[8] == 32'd0  &&
            dut.rf_inst.regs[9] == 32'd1)
            $display(">>> TEST PASSED: all instructions executed correctly <<<");
        else
            $display(">>> TEST FAILED: inspect the waveform for mismatches <<<");

        $display("---------------------------------------------------");
        $finish;
    end

    // Waveform dump (viewable in Vivado's waveform window or GTKWave)
    initial begin
        $dumpfile("riscv_tb.vcd");
        $dumpvars(0, riscv_tb);
    end

endmodule
