# UART Transmitter — Synthesis Report

**Design:** UART Transmitter (8N1)
**Language:** Verilog RTL
**Synthesis Tool:** Synopsys Design Compiler X-2025.06-SP1
**Technology:** SAED 32nm (HVT standard cells)
**Operating Conditions:** 0.75 V, 125 °C (ss corner — worst case)
**Clock Target:** 50 MHz (20 ns period)

---

## 1. Area

| Metric | Value |
|--------|-------|
| Total cells | 111 |
| Combinational cells | 82 |
| Sequential cells (flip-flops) | 28 |
| Buffers / inverters | 10 |
| Number of nets | 162 |
| Number of ports | 39 |

The 28 sequential cells correspond to the FSM state register, the baud rate
counter, the bit counter, and the data shift register.

---

## 2. Performance (Timing)

| Metric | Value |
|--------|-------|
| Clock period (target) | 20.00 ns (50 MHz) |
| Data arrival time | 15.49 ns |
| Data required time | 18.44 ns |
| Library setup time | 1.56 ns |
| **Slack** | **+2.95 ns (MET)** |
| Estimated max frequency | ~58 MHz |

**Critical path:** runs from `baud_count_reg[1]` through the baud rate counter's
incrementer chain (Half Adder cells) to `baud_count_reg[12]`. This is expected,
as the wide counter's carry chain is the slowest combinational path in the design.

---

## 3. Power (0.75 V, 125 °C)

| Power Group | Internal | Switching | Leakage | Total | Share |
|-------------|----------|-----------|---------|-------|-------|
| Clock network | 4.11 µW | 0.00 | 0.00 | 4.11 µW | 66.4% |
| Registers | — | 25.8 nW | 1.59 mW* | 1.58 µW | 25.5% |
| Combinational | 0.15 µW | 66.7 nW | 0.28 mW* | 0.50 µW | 8.1% |

| Summary | Value |
|---------|-------|
| Cell internal power | 4.22 µW (98%) |
| Net switching power | 92.4 nW (2%) |
| **Total dynamic power** | **4.31 µW** |
| **Cell leakage power** | **1.87 µW** |
| **Total power** | **6.18 µW** |

\* Leakage values in pW as reported by the tool.

**Observation:** The clock network dominates total power consumption at 66.4%,
which is typical for sequential designs where the clock toggles continuously
across all flip-flops. This makes clock gating the primary optimization target
for reducing power, since the transmitter is idle most of the time.

---

