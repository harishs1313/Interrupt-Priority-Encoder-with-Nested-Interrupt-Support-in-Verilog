`timescale 1ns/1ps

module tb_ipe_advanced;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset_n = 0;
    reg [7:0] interrupts = 0;
    reg [7:0] mask_reg = 0;
    reg [1:0] priority_mode = 0;
    reg [2:0] current_isr_priority = 3'b111;
    reg cpu_ack = 0;

    wire nested_int_pending;
    wire int_valid;
    wire [2:0] irq_id;
    wire [7:0] irq_ack;
    wire [31:0] vector_addr;

    ipe_advanced dut (
        .clk(clk),
        .reset_n(reset_n),
        .interrupts(interrupts),
        .mask_reg(mask_reg),
        .priority_mode(priority_mode),
        .current_isr_priority(current_isr_priority),
        .nested_int_pending(nested_int_pending),
        .cpu_ack(cpu_ack),
        .int_valid(int_valid),
        .irq_id(irq_id),
        .irq_ack(irq_ack),
        .vector_addr(vector_addr)
    );

    initial begin
        $dumpfile("ipe_advanced.vcd");
        $dumpvars(0, tb_ipe_advanced);
    end

    initial begin
        #10 reset_n = 1;

        $display("[TEST 1] IRQ0 (basic)");
        interrupts = 8'b00000001; // IRQ0
        #20 interrupts = 0;
        cpu_ack = 1;
        #10 cpu_ack = 0;
        #10;

        $display("[TEST 2] Nested IRQ1 while IRQ3 active");
        current_isr_priority = 3'd3;
        interrupts = 8'b00000010; // IRQ1
        #20;
        cpu_ack = 1;
        #10 cpu_ack = 0;

        $display("[TEST 3] Lower priority IRQ5 during IRQ3");
        interrupts = 8'b00100000;
        #20;
        if (nested_int_pending)
            $error("False nested interrupt detected!");

        $display("All tests completed.");
        #100 $finish;
    end

endmodule
