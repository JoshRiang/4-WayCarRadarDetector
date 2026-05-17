const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

const PORT = 3001;
const SERIAL_PORT_PATH = 'COM9'; 
let port;
try {
  port = new SerialPort({ 
    path: SERIAL_PORT_PATH, 
    baudRate: 9600,
    autoOpen: true 
  });
  
  const parser = port.pipe(new ReadlineParser({ delimiter: '\n' }));

  // Debug: Cek apakah ada data mentah yang masuk dari Arduino
  port.on('data', (raw) => {
    console.log('Raw Data:', raw.toString());
  });

  parser.on('data', (data) => {
    console.log('Received:', data);
    const parsed = parseArduinoData(data);
    if (parsed) {
      io.emit('telemetry', parsed);
    }
  });

  port.on('error', (err) => {
    console.error('Serial Port Error:', err.message);
  });

  console.log(`Attempting to connect to Serial Port: ${SERIAL_PORT_PATH}`);
} catch (e) {
  console.log("Serial port error or not found, running in mock mode.");
}

function parseArduinoData(line) {
  // Format: 0:FF 1:FF 2:FF 3:FF | B:0 L:0000 | Int:FF
  const regex = /0:([0-9A-F]+)\s1:([0-9A-F]+)\s2:([0-9A-F]+)\s3:([0-9A-F]+)\s\|\sB:(\d)\sL:(\d+)\s\|\sInt:([0-9A-F]+)/;
  const match = line.match(regex);
  if (match) {
    return {
      sensors: {
        front: parseInt(match[1], 16),
        back: parseInt(match[2], 16),
        left: parseInt(match[3], 16),
        right: parseInt(match[4], 16),
      },
      buzzer: parseInt(match[5]),
      lights: match[6].split('').map(Number),
      intensity: parseInt(match[7], 16)
    };
  }
  return null;
}

/*
// Mock data generator using the requested string template
setInterval(() => {
  const toHex = (val) => val.toString(16).toUpperCase().padStart(2, '0');
  
  // Random sensor values (0-255)
  const s0 = toHex(Math.floor(Math.random() * 256));
  const s1 = toHex(Math.floor(Math.random() * 256));
  const s2 = toHex(Math.floor(Math.random() * 256));
  const s3 = toHex(Math.floor(Math.random() * 256));
  
  // Buzzer (0 or 1)
  const b = Math.random() > 0.8 ? 1 : 0;
  
  // Lights (4 digits, e.g. 0000)
  const l = [
    Math.random() > 0.5 ? 1 : 0,
    Math.random() > 0.5 ? 1 : 0,
    Math.random() > 0.5 ? 1 : 0,
    Math.random() > 0.5 ? 1 : 0
  ].join('');
  
  // Intensity (Closest distance)
  const intensity = toHex(Math.floor(Math.random() * 256));

  // Construct the template string
  const mockString = `0:${s0} 1:${s1} 2:${s2} 3:${s3} | B:${b} L:${l} | Int:${intensity}`;
  
  console.log('Mock Data Sent:', mockString);
  
  const parsed = parseArduinoData(mockString);
  if (parsed) {
    io.emit('telemetry', parsed);
  }
}, 1000);
*/

server.listen(PORT, () => {
  console.log(`Backend running on http://localhost:${PORT}`);
});
