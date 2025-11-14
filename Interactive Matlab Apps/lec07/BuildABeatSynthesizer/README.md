# Build-A-Beat Synthesizer

Interactive Fourier series synthesizer for creating musical tones and beats through additive synthesis.

## Overview

This application demonstrates how complex musical timbres can be created by combining harmonically related sine waves using Fourier series principles. Students can explore the relationship between harmonic content and musical sound quality.

## Features

- Real-time harmonic amplitude control
- Musical note selection (C4, D4, E4, F4, G4, A4, B4, C5)
- Waveform visualization in time and frequency domains
- Audio playback with pause/resume controls
- WAV file export capability
- Educational challenges and presets
- Creative sound design tools
- Harmonic analysis and visualization

## Files

- `BuildABeatSynthesizer.m` - Main application function
- `SynthesizerMath.m` - Fourier series and synthesis calculations
- `simple_test.m` - Basic functionality test
- `test_synthesizer.m` - Comprehensive test suite

## Usage

### Basic Usage

```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec07/BuildABeatSynthesizer'

% Launch the synthesizer
BuildABeatSynthesizer();
```

### Testing

```matlab
% Run simple test
simple_test();

% Run comprehensive tests
test_synthesizer();
```

### Creating Sounds

1. **Select a Musical Note**: Choose from the note dropdown (C4, D4, etc.)
2. **Adjust Harmonics**: Use sliders to control amplitude of each harmonic
3. **Play Sound**: Click play to hear the synthesized tone
4. **Visualize**: View time domain waveform and frequency spectrum
5. **Export**: Save as WAV file for use in other applications

### Harmonic Controls

- **Fundamental (1st harmonic)**: Base frequency of the note
- **2nd-10th harmonics**: Overtones that create timbre
- **Amplitude sliders**: Control strength of each harmonic
- **Preset buttons**: Load predefined harmonic configurations

## Educational Applications

1. **Additive Synthesis**: Understand how complex sounds are built from simple components
2. **Harmonic Series**: Explore relationship between harmonics and musical timbre
3. **Fourier Series Application**: See practical use of Fourier series in music
4. **Sound Design**: Experiment with creating different instrument sounds
5. **Frequency Analysis**: Visualize harmonic content of synthesized sounds

## Musical Concepts

- **Fundamental Frequency**: Determines the pitch of the note
- **Harmonics**: Create the characteristic timbre of different instruments
- **Amplitude Envelope**: Controls how the sound evolves over time
- **Waveform Shape**: Affected by harmonic content

## Requirements

- MATLAB R2023b or later
- Audio System Toolbox (for audio playback and export)

## Examples

### Creating a Pure Tone

1. Select any note (e.g., A4 = 440 Hz)
2. Set 1st harmonic amplitude to 1.0
3. Set all other harmonics to 0.0
4. Play to hear a pure sine wave tone

### Creating a Rich Tone

1. Select a note
2. Set 1st harmonic to 1.0
3. Add 2nd harmonic at 0.5
4. Add 3rd harmonic at 0.3
5. Add decreasing amounts of higher harmonics
6. Play to hear a richer, more complex tone

### Using Presets

1. Click on preset buttons to load predefined configurations
2. Experiment with different presets to hear various timbres
3. Modify presets to create your own sounds

## Troubleshooting

1. **No audio output**: 
   - Check system audio settings
   - Verify Audio System Toolbox is installed
   - Ensure volume is not muted

2. **Export fails**:
   - Check file permissions in target directory
   - Verify sufficient disk space

3. **Performance issues**:
   - Reduce number of active harmonics
   - Close other audio applications

## Author

Ahmed Rabei - TEFO, 2025

