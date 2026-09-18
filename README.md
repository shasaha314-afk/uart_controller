# UART Transceiver Design on FPGA

Full-duplex UART (Universal Asynchronous Receiver/Transmitter) transceiver implemented in synthesisable Verilog, targeting a Xilinx Zynq-7000 FPGA (`xc7z010clg400-1`).

The design incorporates a baud rate generator, a transmitter FSM, and a receiver FSM with 16x oversampling, operating at **115,200 baud** from a **50 MHz** system clock. Verified via a loopback testbench achieving **100% data integrity across all 256 byte values** (0x00–0xFF).

> Author: Shashwat Saha

---

## Highlights

- ✅ Full-duplex UART @ **115,200 baud** from a 50 MHz clock
- 🧠 Transmitter and receiver implemented as independent **4-state FSMs**
- 🎯 **16x oversampled** receiver for robust start-bit detection and midpoint sampling
- 🧪 Loopback testbench: **256/256 PASS, 0 FAIL — 100% data integrity**
- 📦 Extremely lightweight: **49 LUTs (0.28%)**, **56 flip-flops (0.16%)** on the xc7z010clg400-1
- ⏱️ Timing: WNS **+15.471 ns**, max frequency **≈220 MHz** (well above the 50 MHz requirement)
- 🔋 **93 mW** total on-chip power

## System Architecture

| Module | Description |
|---|---|
| `uart.v` | Top-level integration module; routes data, clock enables, and control signals |
| `baudrate.v` | Divides the 50 MHz clock to produce Tx (115,200 Hz) and Rx (1,843,200 Hz) enables |
| `transmitter.v` | 4-state FSM (`IDLE → START → DATA → STOP`); serialises 8-bit data LSB-first |
| `receiver.v` | 4-state FSM (`IDLE → START → DATA → STOP`); deserialises with 16x oversampling |

### Baud Rate Generation

Two independent accumulators derive the Tx and Rx clock enables from the 50 MHz system clock:

| Parameter | Value |
|---|---|
| System Clock | 50 MHz |
| Baud Rate | 115,200 bps |
| `TX_ACC_MAX` | 434 cycles (`50,000,000 / 115,200`) |
| `RX_ACC_MAX` | 27 cycles (`50,000,000 / (115,200 × 16)`) |
| Oversampling Factor | 16x |
| Bit Period | 8,680 ns |

### FSM Summary

**Transmitter** — Moore FSM, transmits LSB-first, `Tx_busy` asserted whenever not `IDLE`:
`TX_IDLE → TX_START → TX_DATA (×8 bits) → TX_STOP → TX_IDLE`

**Receiver** — detects the start bit on a falling edge, confirms it at the midpoint (8 `Rxclk_en` pulses), then samples each data bit at its midpoint (16 `Rxclk_en` pulses per bit), and validates the stop bit before asserting `ready`:
`RX_IDLE → RX_START → RX_DATA (×8 bits) → RX_STOP → RX_IDLE`

> **Design note:** the receiver returns to an explicit `RX_IDLE` state (rather than looping back into `RX_START`) after each byte, so the sample counter is guaranteed to reset before the next start-bit search — this was validated by the 256-byte loopback test.


## Getting Started

### Prerequisites
- Xilinx Vivado Design Suite (design was synthesised/implemented with default strategies)
- A Verilog simulator (Vivado XSim was used for the reference results)

### Simulation
Run `uart_tb.v`, which instantiates `uart.v` in loopback (Tx wired directly to Rx) and sweeps all 256 byte values:

```
TOTAL: 256 PASS, 0 FAIL out of 256 bytes
Data integrity: 100%
```

A VCD dump (`uart.vcd`) is generated for waveform inspection of `clk`, `enable`, `Rx_en`, `Tx_busy`, `ready`, the loopback line, and `Rx_data`.

### Synthesis / Implementation
1. Add the source files and `uart_constraints.xdc` to a Vivado project targeting `xc7z010clg400-1`.
2. The constraints file defines a single 20 ns (50 MHz) clock on `clk_50m`:
   ```tcl
   create_clock -period 20.000 -name clk_50m [get_ports clk_50m]
   ```
   No I/O placement constraints are required, as the design was implemented without a physical board target.
3. Run Synthesis → Implementation and review the utilization/timing/power reports.

## Results Summary

### Resource Utilization

| Resource | Used | Available | Utilization |
|---|---|---|---|
| LUT | 49 | 17,600 | 0.28% |
| Flip-Flop (FF) | 56 | 35,200 | 0.16% |
| IO | 33 | 100 | 33.00% |
| BUFG | 1 | 32 | 3.13% |

### Timing

| Metric | Value |
|---|---|
| Clock period (constraint) | 20.000 ns (50 MHz) |
| Worst Negative Slack (WNS) | +15.471 ns |
| Total Negative Slack (TNS) | 0 ns |
| Failing endpoints | 0 |
| Maximum frequency (Fmax) | ≈220 MHz |

### Power

| Metric | Value |
|---|---|
| Total on-chip power | 93 mW |
| Junction temperature | 26.1 °C |
| Thermal margin | 58.9 °C (5.0 W) |

## Discussion

The receiver's 16x oversampling lets it tolerate up to ±6.25% baud-rate mismatch between transmitter and receiver before a sampling error could occur — though in this loopback setup both share the same baud generator, so the margin mainly guards against start-bit detection glitches. The large positive timing slack (Fmax ≈220 MHz against a 50 MHz requirement) confirms the UART logic is not the bottleneck on this FPGA family, leaving headroom for higher baud rates if the clock source were adjusted.

## References

1. Xilinx Inc., *Vivado Design Suite User Guide: Synthesis*, UG901.
2. Xilinx Inc., *7 Series FPGAs Data Sheet: Overview*, DS180.
3. IEEE Standard for Verilog Hardware Description Language, IEEE Std 1364-2005.
4. Xilinx Application Note XAPP223, *Spartan-3 FPGA UART Design Example*.

