# UART in SystemVerilog

UART (Universal Asynchronous Receiver-Transmitter) implementation in SystemVerilog using finite state machines. Configured for **9600 baud** at a **50 MHz** clock (8N1: 8 data bits, no parity, 1 stop bit).

## Project Structure

```
UART/
├── UartTX.sv      - Transmitter module
├── UartRX.sv      - Receiver module
└── tbModUart.sv   - Integration testbench (TX + RX)
```

## Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| Clock     | 50 MHz | System clock frequency |
| Baud Rate | 9600  | UART baud rate |
| CLKS      | 5208  | Clock cycles per bit (50,000,000 / 9,600) |
| Format    | 8N1   | 8 data bits, no parity, 1 stop bit |

To change baud rate or clock frequency, update `CLKS` in both modules:
```
CLKS = clk_frequency / baud_rate
```

## Modules

### TX — Transmitter (`UartTX.sv`)

Serializes a byte and transmits it over the `tx` line, LSB first.

**Ports**

| Port  | Direction | Width | Description |
|-------|-----------|-------|-------------|
| clk   | input  | 1 | System clock |
| reset | input  | 1 | Synchronous reset (active high) |
| start | input  | 1 | Assert high for 1 cycle to begin transmission |
| data  | input  | 8 | Byte to transmit |
| tx    | output | 1 | Serial output line |
| busy  | output | 1 | High while transmitting |

**State Machine**

```
IDLE → START → DATA (x8) → STOP → IDLE
```

- `IDLE`: Waits for `start = 1`, loads data into shift register
- `START`: Drives `tx = 0` for CLKS cycles (start bit)
- `DATA`: Shifts out 8 bits LSB first, each lasting CLKS cycles
- `STOP`: Drives `tx = 1` for CLKS cycles (stop bit), then clears `busy`

---

### RX — Receiver (`UartRX.sv`)

Detects an incoming UART frame on the `rx` line and reconstructs the byte.

**Ports**

| Port  | Direction | Width | Description |
|-------|-----------|-------|-------------|
| clk   | input  | 1 | System clock |
| reset | input  | 1 | Synchronous reset (active high) |
| rx    | input  | 1 | Serial input line |
| data  | output | 8 | Received byte |
| ready | output | 1 | Pulses high for 1 cycle when a byte is ready |

**State Machine**

```
IDLE → START → DATA (x8) → STOP → IDLE
```

- `IDLE`: Monitors `rx`; transitions to START when `rx = 0` (start bit detected)
- `START`: Waits CLKS/2 cycles to align sampling to the center of each bit; returns to IDLE if `rx` is not still 0 (noise rejection)
- `DATA`: Samples `rx` every CLKS cycles, storing each bit at `data[bit_count]`
- `STOP`: Waits CLKS cycles, then asserts `ready = 1` for one clock cycle

---

## Simulation

### Requirements

```bash
brew install icarus-verilog
brew install --cask gtkwave
```

### Run integration testbench

```bash
iverilog -g2012 -o UartSIM UartTX.sv UartRX.sv tbModUart.sv
./UartSIM
gtkwave Uart.vcd
```

Expected output:
```
TX sent: a5 | RX received: a5
```

## Verification with Synopsys VCS

In addition to Icarus Verilog, the integration testbench was verified using **Synopsys VCS (X-2025.06)** on a university EDA server.

```bash
vcs -full64 -sverilog UartTX.sv UartRX.sv tbModUart.sv -o simv
./simv
```

Result confirms full TX → RX data integrity:

```
TX sent: a5 | RX received: a5
```

## Logic Synthesis with Synopsys Design Compiler

The transmitter was synthesized using **Synopsys Design Compiler (X-2025.06-SP1)** targeting the **SAED 32nm** educational standard cell library (HVT, 0.75 V, 125 °C corner) at a 50 MHz clock target.

```bash
dc_shell -f synth_uart.tcl
```

### Area

| Metric | Value |
|--------|-------|
| Total cells | 111 |
| Combinational cells | 82 |
| Sequential cells | 28 |
| Nets | 162 |
| Buffers / inverters | 10 |

### Timing

| Metric | Value |
|--------|-------|
| Clock target | 50 MHz (20 ns period) |
| Data arrival time | 15.49 ns |
| Data required time | 18.44 ns |
| **Slack** | **+2.95 ns (MET)** |
| Estimated max frequency | ~58 MHz |

The critical path runs through the baud rate counter (`baud_count_reg`), as expected for a wide incrementer chain.

### Power (0.75 V, 125 °C)

| Component | Power | Share |
|-----------|-------|-------|
| Clock network | 4.11 µW | 66.4% |
| Registers | 1.58 µW | 25.5% |
| Combinational | 0.50 µW | 8.1% |
| **Total dynamic** | **4.31 µW** | — |
| **Cell leakage** | **1.87 µW** | — |
| **Total** | **6.18 µW** | — |

The clock network dominates power consumption, which is typical for sequential designs and a candidate for clock gating optimization.

## UART Frame Format

```
Idle  Start   D0  D1  D2  D3  D4  D5  D6  D7   Stop  Idle
  1     0      .   .   .   .   .   .   .   .     1     1
        |<------------- 10 bits total ---------->|
```

Each bit lasts 5208 clock cycles (104,160 ns at 50 MHz).