# UART Transceiver Design on FPGA

## Overview
This project implements a full-duplex UART (Universal Asynchronous Receiver/Transmitter) transceiver in synthesizable Verilog, targeting the Xilinx Zynq-7000 FPGA[cite: 2]. The design operates at 115,200 baud with a 50 MHz system clock and features a 16x oversampled receiver for robust start-bit detection and timing skew reduction[cite: 2].

## Architecture
The system consists of four primary modules[cite: 2]:
* **`uart.v`**: Top-level integration module that routes data and control signals[cite: 2].
* **`baudrate.v`**: Divides the 50 MHz clock to generate Tx (115,200 Hz) and Rx (1,843,200 Hz) enables[cite: 2].
* **`transmitter.v`**: 4-state Moore FSM serializing 8-bit data LSB-first[cite: 2].
* **`receiver.v`**: 4-state FSM deserializing data using 16x oversampling[cite: 2].

## Performance & Implementation Results
* **Data Integrity**: Verified via loopback testbench in Vivado XSim, achieving 100% data integrity across all 256 possible byte values (0x00 to 0xFF)[cite: 2].
* **Resource Utilization (Zynq-7000)**: Highly lightweight, utilizing 49 LUTs (0.28%) and 56 Flip-Flops (0.16%)[cite: 2].
* **Timing**: Maximum operating frequency (Fmax) of 220 MHz with a Worst Negative Slack (WNS) of +15.471 ns[cite: 2].
* **Power**: Total on-chip power consumption of 0.093 W[cite: 2].
