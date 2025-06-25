# 🎓 SystemVerilog Projects – FPGA Designs from University

This repository contains a series of hardware design projects written in **SystemVerilog**, developed during my time as a student at the **Department of Electrical and Computer Engineering, Democritus University of Thrace**.

These projects were tested primarily on the **Nexys A7-100T FPGA board** and cover a wide range of digital design concepts including FSMs, VGA controllers, combinational logic, AI logic, Hamming encoding, and security-aware circuits.

---

##  Rock-Paper-Scissors on FPGA

A simple combinational logic game based on the classic **Rock, Paper, Scissors**. Designed for FPGA using SystemVerilog.

### Features:
- 2 players (A and B) using 3-bit one-hot encoded inputs:
  - `001`: Scissors
  - `010`: Rock
  - `100`: Paper
- Invalid moves are detected (e.g., multiple inputs).
- Output: win, lose, tie, or invalid.

### 📁 Files:
- `winnerA.sv`, `winnerB.sv`, `checkTie.sv`, `validIO.sv`
- Testbenches for all modules
- Nexys A7 `.xdc` constraint file

---

##  VGA-Based Projects

### 1. **VGA 4-Square Display**

A basic VGA controller that displays 4 colored squares on screen.

- Resolution: **800x600 @ 72Hz**
- Custom VGA timing (HSYNC/VSYNC)
- Displays Red, Green, Blue, White squares

📁 Files:
- `PanelDisplay.sv`, `PanelDisplay_tb.sv`
- `vga_pins.xdc`

---

### 2. **VGA Tic-Tac-Toe (2-Player)**

An interactive 2-player Tic-Tac-Toe game with button control.

- VGA grid rendering using 800x600 resolution
- ROM-based symbols for X and O
- Button control for cursor and placement
- Win/Tie detection

📁 Files:
- `top.sv`, `X_ROM.sv`, `O_ROM.sv`
- `edge_detector.sv`, `fpga_pins.xdc`

---

### 3. **VGA Tic-Tac-Toe with AI**

Adds **AI opponent** for Player O using the `MoveGen.sv` module.

####  AI Strategy:
1. Win if possible  
2. Block the player  
3. Pick first available cell  

📁 Files:
- `top.sv` (with AI logic)
- `MoveGen.sv`, `edge_detector.sv`
- Symbol ROMs, constraints

---

##  Small SystemVerilog Projects

### i) FSM Server Controller

- Controls up to 3 users accessing a server
- FSM with 4 states (S0–S3)
- Inputs: connect/disconnect
- Output: 1 if allowed, 0 otherwise

---

### ii) Hamming (15,11) Encoder

- Serial input of 11 data bits
- Calculates 4 parity bits
- Outputs 15-bit Hamming code
- Fully self-checking testbench

---

### iii) Network Switch with Arbitration

- 4-port data switch using request signals
- Routes data from active requests
- Combinational arbitration logic

---

### iv) Odd-Even Merge Sorter

- Sorts four 8-bit numbers
- Built with comparator network
- Pipelined architecture with registers
- Outputs: max, second_max, second_min, min

---

### v) Hardware Trojan Simulation

- Simulates a Trojan interrupting communication between elastic registers
- Trojan blocks data when `flush=1`
- Demonstrates secure data flow validation

---

## 🧠 Skills & Concepts Practiced

- Combinational & Sequential Logic  
- VGA Controller Design  
- FSM Design and Transitions  
- Symbol ROMs and Memory Mapping  
- Hardware Game Logic  
- Hamming Encoding  
- Arbitration & Resource Management  
- Security-aware Design  
- Pipelined Sorting Networks  
- Testbench Development in SystemVerilog  

---

##  Hardware Used

- 🧿 **Nexys A7-100T FPGA Board**
- 💾 Vivado Design Suite (for synthesis, simulation, and constraint management)


---

## 👨‍💻 Author

**Vaggelis Papaioannou**  
Department of Electrical & Computer Engineering  
Democritus University of Thrace

