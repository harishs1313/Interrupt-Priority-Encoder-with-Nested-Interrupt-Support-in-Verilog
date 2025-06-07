`timescale 1ns/1ps

module ipe_advanced (
    input wire clk,
    input wire reset_n,

    input wire [7:0] interrupts,
    input wire [7:0] mask_reg,
    input wire [1:0] priority_mode,
    input wire [2:0] current_isr_priority,
    output wire nested_int_pending,

    input wire cpu_ack,
    output reg int_valid,
    output reg [2:0] irq_id,
    output reg [7:0] irq_ack,
    output wire [31:0] vector_addr
);

    reg [7:0] prev_irq;
    wire [7:0] active_irqs = interrupts & ~mask_reg;
    wire [7:0] edge_irqs = active_irqs & ~prev_irq;

    reg [2:0] irq_priority [0:7];
    initial begin
        irq_priority[0] = 3'd0;
        irq_priority[1] = 3'd1;
        irq_priority[2] = 3'd2;
        irq_priority[3] = 3'd3;
        irq_priority[4] = 3'd4;
        irq_priority[5] = 3'd5;
        irq_priority[6] = 3'd6;
        irq_priority[7] = 3'd7;
    end

    reg [2:0] rr_counter;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            prev_irq <= 8'b0;
            irq_id <= 3'b000;
            int_valid <= 1'b0;
            rr_counter <= 3'b0;
        end else begin
            prev_irq <= active_irqs;
            int_valid <= 1'b0;

            case (priority_mode)
                2'b00: begin
                    casex (edge_irqs)
                        8'b00000001: begin irq_id <= 3'd0; int_valid <= 1'b1; end
                        8'b0000001x: begin irq_id <= 3'd1; int_valid <= 1'b1; end
                        8'b000001xx: begin irq_id <= 3'd2; int_valid <= 1'b1; end
                        8'b00001xxx: begin irq_id <= 3'd3; int_valid <= 1'b1; end
                        8'b0001xxxx: begin irq_id <= 3'd4; int_valid <= 1'b1; end
                        8'b001xxxxx: begin irq_id <= 3'd5; int_valid <= 1'b1; end
                        8'b01xxxxxx: begin irq_id <= 3'd6; int_valid <= 1'b1; end
                        8'b1xxxxxxx: begin irq_id <= 3'd7; int_valid <= 1'b1; end
                    endcase
                end
                2'b01: begin
                    casex (edge_irqs)
                        8'b1xxxxxxx: begin irq_id <= 3'd7; int_valid <= 1'b1; end
                        8'b01xxxxxx: begin irq_id <= 3'd6; int_valid <= 1'b1; end
                        8'b001xxxxx: begin irq_id <= 3'd5; int_valid <= 1'b1; end
                        8'b0001xxxx: begin irq_id <= 3'd4; int_valid <= 1'b1; end
                        8'b00001xxx: begin irq_id <= 3'd3; int_valid <= 1'b1; end
                        8'b000001xx: begin irq_id <= 3'd2; int_valid <= 1'b1; end
                        8'b0000001x: begin irq_id <= 3'd1; int_valid <= 1'b1; end
                        8'b00000001: begin irq_id <= 3'd0; int_valid <= 1'b1; end
                    endcase
                end
                2'b10: begin
                    int_valid <= 1'b0;
                    if (edge_irqs[rr_counter]) begin irq_id <= rr_counter; int_valid <= 1'b1; rr_counter <= rr_counter + 1; end
                    else if (edge_irqs[(rr_counter + 1) % 8]) begin irq_id <= (rr_counter + 1) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 2) % 8; end
                    else if (edge_irqs[(rr_counter + 2) % 8]) begin irq_id <= (rr_counter + 2) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 3) % 8; end
                    else if (edge_irqs[(rr_counter + 3) % 8]) begin irq_id <= (rr_counter + 3) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 4) % 8; end
                    else if (edge_irqs[(rr_counter + 4) % 8]) begin irq_id <= (rr_counter + 4) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 5) % 8; end
                    else if (edge_irqs[(rr_counter + 5) % 8]) begin irq_id <= (rr_counter + 5) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 6) % 8; end
                    else if (edge_irqs[(rr_counter + 6) % 8]) begin irq_id <= (rr_counter + 6) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 7) % 8; end
                    else if (edge_irqs[(rr_counter + 7) % 8]) begin irq_id <= (rr_counter + 7) % 8; int_valid <= 1'b1; rr_counter <= (rr_counter + 0) % 8; end
                end
            endcase
        end
    end

    assign nested_int_pending = int_valid && 
                                 (irq_priority[irq_id] < current_isr_priority);

    assign vector_addr = 32'h00001000 + (irq_id * 4);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            irq_ack <= 8'b0;
        else if (cpu_ack && int_valid)
            irq_ack <= (1 << irq_id);
        else
            irq_ack <= 8'b0;
    end

endmodule
