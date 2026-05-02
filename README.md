# 4-Way Car Radar Detector

An Arduino-based IoT assembly project that provides **360-degree proximity detection** around a vehicle using four HC-SR04 ultrasonic sensors (front, rear, left, right), an LCD display, directional LEDs, and a buzzer — all working together to alert the driver of nearby obstacles in real time.

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Hardware Components](#hardware-components)
4. [Circuit & Pin Assignments](#circuit--pin-assignments)
5. [Assembly Instructions](#assembly-instructions)
6. [How It Works](#how-it-works)
7. [Getting Started](#getting-started)
8. [Project Structure](#project-structure)
9. [Future Improvements](#future-improvements)
10. [Contributing](#contributing)
11. [License](#license)

---

## Overview

The **4-Way Car Radar Detector** is a low-cost proximity warning system designed to be mounted on a vehicle or model car. Four ultrasonic sensors continuously measure the distance to obstacles in every cardinal direction. The measured distances are shown on a 16×2 LCD screen, while four directional LEDs (one per sensor) and a buzzer provide intuitive visual and audio alerts as an obstacle gets closer.

```
          [FRONT SENSOR]
               ↑
[LEFT]  ← [ARDUINO] →  [RIGHT]
               ↓
          [REAR SENSOR]
```

---

## Features

- **4-direction coverage** — simultaneous distance measurement from front, rear, left, and right
- **Real-time LCD display** — shows the distance (in centimeters) for each direction
- **Directional LED indicators** — each LED corresponds to one sensor; brightness/blink rate increases as an obstacle approaches
- **Buzzer alerts** — beep frequency increases as the closest detected obstacle gets nearer
- **Configurable distance thresholds** — warning and critical zones can be adjusted in the source code
- **Low cost & open-source** — built entirely on off-the-shelf Arduino-compatible hardware

---

## Hardware Components

| # | Component | Quantity | Notes |
|---|-----------|----------|-------|
| 1 | Arduino Uno (or Nano / Mega) | 1 | Brain of the system |
| 2 | HC-SR04 Ultrasonic Sensor | 4 | One per direction (front, rear, left, right) |
| 3 | 16×2 I²C LCD Display | 1 | Shows live distance readings |
| 4 | LED (red recommended) | 4 | One per direction |
| 5 | Active Buzzer | 1 | Audio proximity alert |
| 6 | 220 Ω Resistor | 4 | Current limiting for LEDs |
| 7 | Breadboard | 1 | Prototyping |
| 8 | Jumper Wires (M-M / M-F) | ~40 | As needed |
| 9 | USB-A to USB-B cable | 1 | Programming & power |
| 10 | 9V battery or DC barrel jack | 1 | Optional standalone power |

---

## Circuit & Pin Assignments

### HC-SR04 Ultrasonic Sensors

Each sensor has four pins: **VCC**, **GND**, **Trig**, and **Echo**.

| Direction | Trig Pin | Echo Pin |
|-----------|----------|----------|
| Front     | D2       | D3       |
| Rear      | D4       | D5       |
| Left      | D6       | D7       |
| Right     | D8       | A0       |

- **VCC** → Arduino **5V**
- **GND** → Arduino **GND**

### LEDs

| Direction | Arduino Pin | Resistor |
|-----------|-------------|----------|
| Front LED | D10         | 220 Ω to GND |
| Rear LED  | D11         | 220 Ω to GND |
| Left LED  | D12         | 220 Ω to GND |
| Right LED | D13         | 220 Ω to GND |

### Buzzer

| Component | Arduino Pin |
|-----------|-------------|
| Buzzer (+) | D~9 (PWM)  |
| Buzzer (−) | GND        |

> **Note:** The Right sensor's Echo uses analog pin A0 in digital mode, freeing D9 (PWM) exclusively for the buzzer. If you need to reassign the buzzer, any other PWM-capable pin (D3, D5, D6, D10, D11) will work — update the `BUZZER_PIN` constant in the sketch accordingly.

### 16×2 I²C LCD Display

| LCD Pin | Arduino Pin |
|---------|-------------|
| VCC     | 5V          |
| GND     | GND         |
| SDA     | A4          |
| SCL     | A5          |

> The I²C address is typically `0x27` or `0x3F`. Check your module's datasheet and update `LCD_ADDRESS` in the sketch if needed.

---

## Assembly Instructions

1. **Place the Arduino** on the breadboard (or use it standalone with jumper wires).

2. **Wire the ultrasonic sensors**  
   - Connect all four sensor VCC pins to the Arduino 5V rail.  
   - Connect all four sensor GND pins to the Arduino GND rail.  
   - Connect each sensor's Trig and Echo pins according to the table above.

3. **Wire the LEDs**  
   - Insert each LED into the breadboard with the longer leg (anode) facing the Arduino pin.  
   - Add a 220 Ω resistor between the cathode (short leg) and GND.  
   - Connect the anode to the appropriate Arduino digital pin.

4. **Wire the buzzer**  
   - Connect the positive lead to Arduino pin D9 (PWM).  
   - Connect the negative lead to GND.

5. **Wire the LCD display**  
   - Connect VCC → 5V, GND → GND, SDA → A4, SCL → A5.

6. **Double-check all connections** before powering on.

7. **Power the Arduino** via USB or a 9V barrel jack adapter.

---

## How It Works

```
┌─────────────────────────────────────────────────────┐
│                    Arduino Loop                      │
│                                                      │
│  1. Trigger each HC-SR04 sensor (10 µs pulse)        │
│  2. Measure echo pulse duration                      │
│  3. Convert duration → distance (cm)                 │
│     distance = (duration / 2) / 29.1                 │
│                                                      │
│  4. Display all four distances on LCD                │
│                                                      │
│  5. For each direction:                              │
│     • distance > WARNING_DIST  → LED off, no beep   │
│     • distance ≤ WARNING_DIST  → LED blinks slowly  │
│     • distance ≤ CRITICAL_DIST → LED solid ON       │
│                                                      │
│  6. Buzzer beep rate ∝ 1 / (closest distance)       │
└─────────────────────────────────────────────────────┘
```

### Distance Thresholds (default, adjustable in sketch)

| Zone     | Distance  | Behaviour                            |
|----------|-----------|--------------------------------------|
| Safe     | > 50 cm   | No alert                             |
| Warning  | 20–50 cm  | LED blinks, slow beep                |
| Critical | ≤ 20 cm   | LED solid ON, rapid continuous beep  |

---

## Getting Started

### Prerequisites

- [Arduino IDE](https://www.arduino.cc/en/software) (v1.8+ or v2.x)
- **LiquidCrystal_I2C** library  
  Install via Arduino IDE → *Sketch → Include Library → Manage Libraries* → search **LiquidCrystal I2C** by Frank de Brabander → Install

### Upload the Sketch

1. Clone or download this repository:
   ```bash
   git clone https://github.com/JoshRiang/4-WayCarRadarDetector.git
   ```
2. Open `4-WayCarRadarDetector.ino` in the Arduino IDE.
3. Select your board under *Tools → Board* (e.g., **Arduino Uno**).
4. Select the correct COM port under *Tools → Port*.
5. Click **Upload** (→).

### Adjusting Thresholds

Open `4-WayCarRadarDetector.ino` and edit the constants at the top of the file:

```cpp
#define WARNING_DIST   50   // cm — start blinking LEDs
#define CRITICAL_DIST  20   // cm — solid LED + rapid beep
#define LCD_ADDRESS  0x27   // I²C address of your LCD module
```

---

## Project Structure

```
4-WayCarRadarDetector/
├── 4-WayCarRadarDetector.ino   # Main Arduino sketch
├── README.md                   # Project documentation
└── docs/
    └── wiring-diagram.png      # (optional) fritzing / circuit diagram
```

---

## Future Improvements

- [ ] Replace single-colour LEDs with RGB LEDs for colour-coded proximity feedback (green → yellow → red)
- [ ] Add a 7-segment display or OLED for a more compact UI
- [ ] Integrate a Bluetooth or Wi-Fi module (ESP8266/ESP32) to send proximity data to a smartphone app
- [ ] Use an interrupt-driven echo measurement for more accurate readings at close range
- [ ] Add a mute button to silence the buzzer while keeping visual alerts active
- [ ] 3D-print a sensor mount/enclosure for clean vehicle installation
- [ ] Log distance data to an SD card for later analysis

---

## Contributing

Contributions, bug reports, and feature requests are welcome!  
Please open an issue or submit a pull request following the standard GitHub workflow:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Commit your changes (`git commit -m "Add your-feature-name"`)
4. Push to the branch (`git push origin feature/your-feature-name`)
5. Open a Pull Request

---

## License

This project is released under the [MIT License](LICENSE).  
Feel free to use, modify, and distribute it for personal or educational purposes.
