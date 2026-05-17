# Four Way Car Radar Detector

This repository contains the implementation of a **Four Way Car Radar Detector**, an advanced parking assist system designed to monitor obstacles from four different sides (Front, Back, Left, Right) simultaneously. The project leverages low-level **AVR Assembly** for high-precision hardware control and a **Python Bridge** for real-time data monitoring.

## 1. Introduction to the Problem and the Solution

### The Problem
When maneuvering vehicles in tight spaces or performing parking tasks, drivers often face significant "blind spots." Estimating the distance to obstacles manually can be unreliable, leading to minor collisions or vehicle damage. Most standard consumer solutions are either limited in coverage or rely on high-level software abstractions that may introduce latencies or timing inaccuracies.

### The Solution
The **Four Way Car Radar Detector** provides a comprehensive 360-degree spatial awareness solution. By using four HC-SR04 ultrasonic sensors controlled via pure Assembly code, the system ensures microsecond-level precision in distance measurement. The solution provides multi-layered feedback:
- **Visual Indication:** Independent LEDs for each side.
- **Audio Feedback:** A dynamic buzzer that changes frequency based on proximity.
- **Character Navigation:** A 7-segment display showing the nearest obstacle's direction (F, b, L, r).
- **Remote Monitoring:** A Python-based interface to track exact distances on a computer screen.

---

## 2. Hardware Design and Implementation Details

The system is built around the **ATMega328P** (Arduino Uno) architecture. To optimize the limited I/O resources, the design incorporates a Shift Register and shared trigger lines.

### Key Components
- **Microcontroller:** Arduino Uno (ATMega328P).
- **Sensors:** 4x HC-SR04 Ultrasonic Sensors.
- **Expansion:** IC 74HC595 (8-bit Shift Register) to drive the 7-segment display.
- **Indicators:** 4x LEDs and 1x Passive Buzzer (Sounder).
- **Display:** Common Cathode 7-Segment.

### Pin Mapping
- **PORTC:** PC4 (Shared Trigger), PC0-PC3 (Echo Front, Back, Left, Right).
- **PORTB:** PB0-PB3 (LEDs), PB4 (Buzzer Output).
- **PORTD:** PD2 (Data), PD3 (Clock), PD4 (Latch) for the Shift Register.

### Hardware Features
- **Shared Trigger Logic:** All four sensors are triggered by a single pulse on A4 to reduce pin usage.
- **1kHz Tone Generation:** The buzzer is driven by a 1kHz square wave generated via Timer0 interrupts, ensuring compatibility with passive sounders.
- **Bit-Banging 74HC595:** A serial data transfer protocol implemented in Assembly to send 8-bit character masks to the Shift Register.

---

## 3. Software Implementation Details

The software architecture is split into two layers: the high-performance firmware and the high-level monitoring bridge.

### AVR Assembly Firmware (The Core)
The firmware is written in pure Assembly to ensure deterministic execution and precise timing:
- **Timer0 Interrupt (500μs):** Handles the buzzer's audio frequency and uses a tick-divider (1:20) to manage LED blinking intervals every 10ms.
- **Timer1 (16-bit):** Used for measuring the duration of the Echo pulse.
- **Atomic Read Protocol:** Implements a strict `TCNT1L` followed by `TCNT1H` read sequence to prevent data corruption during 16-bit register access.
- **Shadow Variables:** Employs temporary registers (`temp_min_dist`) to store intermediate sensor data during the 4-way scanning cycle, preventing the buzzer from "choking" or stuttering during updates.

### Python Bridge (The Interface)
A Python script serves as the bridge between the hardware and the user:
- **UART Communication:** Operates at 9600 baud rate.
- **Real-Time Parsing:** Receives binary distance data and translates it into a readable dashboard format.
- **Diagnostic Output:** Displays distances for all sensors, current active buzzer status, and the calculated blink interval.

---

## 4. Test Results and Performance Evaluation

The system was tested in both simulated environments (Proteus/Wokwi) and physical prototypes.

### Zonal Alert Performance
| Zone | Distance | LED/Buzzer Response | 7-Segment | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Safe** | > 40 cm | OFF | Blank | Pass |
| **Warning** | 10 cm - 40 cm | Dynamic Blinking (Fast to Slow) | Nearest ID (F, b, L, r) | Pass |
| **Critical** | < 10 cm | Solid ON (Continuous Beep) | Nearest ID | Pass |

### Performance Evaluation
- **Timing Accuracy:** The use of Assembly eliminated the jitter commonly found in high-level IDE abstractions.
- **Reliability:** The implementation of a 35ms cooldown between sensor polls successfully mitigated echo collisions.
- **Precision:** Distances are accurate within ±1 cm throughout the 2-200 cm range.

---

## 5. Conclusion and Future Work

### Conclusion
The **Four Way Car Radar Detector** successfully demonstrates the power of low-level programming in managing time-critical hardware tasks. By integrating AVR Assembly with a Python monitoring system, the project achieves a high degree of responsiveness and accuracy, providing a reliable safety tool for vehicle navigation.

### Future Work
- **Wireless Integration:** Replacing the serial cable with a Bluetooth (HC-05) or Wi-Fi (ESP8266) module for untethered monitoring.
- **GUI Development:** Enhancing the Python script with a graphical dashboard using Tkinter or PyQt to visualize object positions.
- **Blind Spot Expansion:** Adding more sensors at 45-degree angles to achieve true 360-degree coverage.

---

**Developed by:**
JOSHUA RICHARDO RIANGKAMANG - 2406361946 
REYHAN BATARA - 2406348950
HAIKAL GIFARI INZAGHI - 2406432261  
IRGY RABBANI SAKTI - 2406438290 
