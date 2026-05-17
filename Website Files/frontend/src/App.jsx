import React, { useState, useEffect } from 'react';
import io from 'socket.io-client';
import './App.css';

const socket = io('http://localhost:3001');

function App() {
  const [sensors, setSensors] = useState({ front: 255, back: 255, left: 255, right: 255 });

  useEffect(() => {
    socket.on('telemetry', (data) => {
      setSensors(data.sensors);
    });
    return () => socket.off('telemetry');
  }, []);

  const getTeslaColor = (val) => {
    if (val < 40) return '#e82127'; // Red
    if (val < 80) return '#ff7a00'; // Orange
    if (val < 130) return '#ffc700'; // Yellow
    return '#4d4d4d'; // Grey
  };

  // Map sensor value (0-255) to a physical offset from the car center
  // 0 is right against the car, 255 is far away
  const getOffset = (val) => {
    return Math.min(250, 100 + (val / 255) * 150);
  };

  const isStop = Object.values(sensors).some(v => v < 30);

  return (
    <div className="tesla-dashboard">
      <div className="car-viewer">
        <img src="/car_base.png" alt="Tesla Car" className="car-image" />
        
        {isStop && <div className="stop-label">STOP</div>}

        <svg className="sensor-layer" viewBox="0 0 600 600">
          {/* Front Arc */}
          <path 
            d={`M ${300 - 80} ${300 - getOffset(sensors.front)} Q 300 ${300 - getOffset(sensors.front) - 20} ${300 + 80} ${300 - getOffset(sensors.front)}`}
            className="arc-path"
            stroke={getTeslaColor(sensors.front)}
            opacity={sensors.front > 200 ? 0.2 : 1}
          />
          {sensors.front < 150 && (
            <text x="300" y={300 - getOffset(sensors.front) - 35} fill="white" textAnchor="middle" fontSize="12" fontWeight="bold">
              {sensors.front} cm
            </text>
          )}

          {/* Back Arc */}
          <path 
            d={`M ${300 - 80} ${300 + getOffset(sensors.back)} Q 300 ${300 + getOffset(sensors.back) + 20} ${300 + 80} ${300 + getOffset(sensors.back)}`}
            className="arc-path"
            stroke={getTeslaColor(sensors.back)}
            opacity={sensors.back > 200 ? 0.2 : 1}
          />
          {sensors.back < 150 && (
            <text x="300" y={300 + getOffset(sensors.back) + 45} fill="white" textAnchor="middle" fontSize="12" fontWeight="bold">
              {sensors.back} cm
            </text>
          )}

          {/* Left Arc */}
          <path 
            d={`M ${300 - getOffset(sensors.left)} ${300 - 60} Q ${300 - getOffset(sensors.left) - 20} 300 ${300 - getOffset(sensors.left)} ${300 + 60}`}
            className="arc-path"
            stroke={getTeslaColor(sensors.left)}
            opacity={sensors.left > 200 ? 0.2 : 1}
          />
          {sensors.left < 150 && (
            <text x={300 - getOffset(sensors.left) - 45} y="305" fill="white" textAnchor="middle" fontSize="12" fontWeight="bold">
              {sensors.left} cm
            </text>
          )}

          {/* Right Arc */}
          <path 
            d={`M ${300 + getOffset(sensors.right)} ${300 - 60} Q ${300 + getOffset(sensors.right) + 20} 300 ${300 + getOffset(sensors.right)} ${300 + 60}`}
            className="arc-path"
            stroke={getTeslaColor(sensors.right)}
            opacity={sensors.right > 200 ? 0.2 : 1}
          />
          {sensors.right < 150 && (
            <text x={300 + getOffset(sensors.right) + 45} y="305" fill="white" textAnchor="middle" fontSize="12" fontWeight="bold">
              {sensors.right} cm
            </text>
          )}
        </svg>
      </div>

      <div className="watermark">Tesla Vision System</div>
    </div>
  );
}

export default App;
