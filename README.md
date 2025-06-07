# Interrupt Priority Encoder (IPE) — Advanced Design

This repository contains a Verilog implementation of an **Interrupt Priority Encoder (IPE)** with nested interrupt support and configurable priority modes, along with a testbench and instructions for simulation and waveform inspection.

---

## Project Overview

The **IPE module** is a hardware interrupt controller designed to:

- Monitor multiple interrupt inputs (`interrupts`).
- Mask interrupts (`mask_reg`).
- Select the highest priority interrupt based on configurable priority schemes.
- Support nested interrupts by comparing the priority of incoming interrupts to the current ISR (Interrupt Service Routine).
- Generate an interrupt vector address for CPU servicing.
- Provide an acknowledgment interface for CPU handshake.

---

## Design Details

### Top Module: `ipe_advanced.v`

**Key Inputs:**

- `clk` — System clock.
- `reset_n` — Active-low reset.
- `interrupts` — 8-bit interrupt request lines.
- `mask_reg` — 8-bit interrupt mask (1 = mask/disable IRQ).
- `priority_mode` — 2-bit control for priority scheme:
  - `00`: Default priority (IRQ0 highest).
  - `01`: Reverse priority.
  - `10`: Round-robin.
- `current_isr_priority` — Priority level of current CPU ISR, for nested interrupt comparison.
- `cpu_ack` — CPU acknowledgment for servicing an interrupt.

**Key Outputs:**

- `nested_int_pending` — Flag indicating if a higher-priority interrupt is pending (nested interrupt condition).
- `int_valid` — Indicates if any interrupt is currently valid.
- `irq_id` — 3-bit ID of the interrupt to service.
- `irq_ack` — One-hot acknowledge signal to the interrupt line.
- `vector_addr` — Address vector to jump to the ISR.

---

### Internal Logic Breakdown

1. **Interrupt Detection & Masking**  
   Active interrupts are computed as `interrupts & ~mask_reg`.

2. **Edge Detection**  
   Detect rising edges on interrupts compared to the previous clock cycle.

3. **Priority Encoding**  
   Based on the `priority_mode`, select the interrupt with highest priority:
   - Default mode: IRQ0 has highest priority.
   - Reverse mode: IRQ7 has highest priority.
   - Round-robin mode: Interrupts served in a rotating order.

4. **Nested Interrupt Support**  
   Compares new interrupt priority with `current_isr_priority`.  
   If new interrupt is higher priority, `nested_int_pending` is asserted for CPU preemption.

5. **Vector Address Calculation**  
   Vector = base address + (IRQ ID * 4), standard for interrupt vector tables.

6. **CPU Acknowledge Interface**  
   Generates one-hot acknowledgment when CPU acknowledges the interrupt.

---

## Testbench: `tb_ipe_advanced.v`

### Purpose

- Verify basic and nested interrupt behavior.
- Test interrupt masking and priority modes.
- Stimulate interrupt signals and CPU acknowledgments.
- Monitor signals and print simulation messages.

### Features

- Clock generation with a 10ns period.
- Active-low reset held for 10ns at the start.
- Three test cases:
  1. Basic interrupt triggering.
  2. Nested interrupt detection.
  3. Lower priority interrupt does not trigger nesting.
- `$monitor` statement for real-time simulation output.
- Waveform dump setup to generate `.vcd` file for GTKWave.

---

## Simulation & Waveform Viewing

### Running the Simulation

Use the following commands to compile and simulate:

```bash
iverilog -o ipe_sim ipe_advanced.v tb_ipe_advanced.v
vvp ipe_sim
