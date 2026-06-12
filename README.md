# UART in Verilog

UART (Universal Asynchronous Receiver-Transmitter) implementation in Verilog using finite state machines. Configured for **9600 baud** at a **50 MHz** clock (8N1: 8 data bits, no parity, 1 stop bit).

## Project Structure

```
UART/
├── UartTX.v       - Transmitter module
├── UartRX.v       - Receiver module
├── tbUartTX.v     - TX testbench
├── tbUartRX.v     - RX testbench
└── tbModUart.v    - Integration testbench (TX + RX)
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

### TX — Transmitter (`UartTX.v`)

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

### RX — Receiver (`UartRX.v`)

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

### Run TX testbench

```bash
iverilog -o TXSIM UartTX.v tbUartTX.v
./TXSIM
gtkwave UartTX.vcd
```

### Run RX testbench

```bash
iverilog -o RXSIM UartRX.v tbUartRX.v
./RXSIM
gtkwave UartRX.vcd
```

### Run integration testbench

```bash
iverilog -o UartSIM UartTX.v UartRX.v tbModUart.v
./UartSIM
gtkwave Uart.vcd
```

Expected output:
```
TX sent: a5 | RX received: a5
```

## UART Frame Format

```
Idle  Start   D0  D1  D2  D3  D4  D5  D6  D7   Stop  Idle
  1     0      .   .   .   .   .   .   .   .     1     1
        |<------------- 10 bits total ---------->|
```

Each bit lasts 5208 clock cycles (104,160 ns at 50 MHz).