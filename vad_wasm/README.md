# Voice Activity Detection (VAD) WebAssembly Module

This project implements a Voice Activity Detection algorithm in Rust and compiles it to WebAssembly for use in web applications.

## Features

- Real-time voice activity detection
- Configurable thresholds for energy, frequency, and SFM
- Efficient FFT-based processing
- WebAssembly compatible

## Building

1. Install Rust and wasm-pack:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install wasm-pack
```

2. Build the WebAssembly module:
```bash
wasm-pack build --target web
```

## Usage in JavaScript

```javascript
import init, { VAD } from './vad_wasm.js';

async function initVAD() {
    await init();
    
    // Create VAD instance with default parameters
    const vad = new VAD(16000, 0.30, 316.76, 0.60);
    
    // Process audio data
    const audioData = new Float32Array(/* your audio data */);
    const decisions = vad.detect_voice(audioData);
    
    // decisions is an array of booleans indicating voice activity
    console.log(decisions);
}
```

## Parameters

- `sample_rate`: Audio sample rate (default: 16000 Hz)
- `energy_thresh`: Energy threshold (default: 0.30)
- `f_thresh`: Frequency threshold (default: 316.76)
- `sfm_thresh`: Spectral Flatness Measure threshold (default: 0.60)

## Algorithm Details

The VAD algorithm uses three features to detect voice activity:
1. Energy level
2. Dominant frequency
3. Spectral Flatness Measure (SFM)

A frame is considered to contain voice if at least two of these features exceed their respective thresholds.

## License

MIT 