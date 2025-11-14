# Duty Cycle and Spectrum Analyzer

Interactive exploration tool for rectangular pulse trains and their frequency spectra, demonstrating the relationship between duty cycle and Fourier series coefficients.

## Overview

This application visualizes how the duty cycle of a rectangular pulse train affects its frequency spectrum. Students can observe how the sinc envelope shapes the harmonic content and understand harmonic nulling effects.

## Features

- Real-time duty cycle adjustment (0% to 100%)
- Time domain visualization of rectangular pulses
- Frequency domain analysis with Fourier series coefficients
- Sinc envelope overlay on spectrum
- Harmonic nulling visualization
- Educational presets and challenges
- Export capabilities for plots and data

## Files

- `DutyCycleSpectrumAnalyzer.m` - Main application function
- `DutyCycleMath.m` - Mathematical calculations for duty cycle analysis
- `simple_test.m` - Basic functionality test
- `test_duty_cycle.m` - Comprehensive test suite

## Usage

### Basic Usage

```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec07/DutyCycleSpectrumAnalyzer'

% Launch the analyzer
DutyCycleSpectrumAnalyzer();
```

### Testing

```matlab
% Run simple test
simple_test();

% Run comprehensive tests
test_duty_cycle.m();
```

### Analyzing Pulse Trains

1. **Set Fundamental Parameters**:
   - Period: Fundamental period of the pulse train
   - Amplitude: Peak amplitude of pulses

2. **Adjust Duty Cycle**:
   - Use slider to change duty cycle from 0% to 100%
   - Observe changes in time domain waveform
   - Watch frequency spectrum update in real-time

3. **Analyze Spectrum**:
   - View Fourier series coefficients
   - Observe sinc envelope shape
   - Identify harmonic nulling points

4. **Use Presets**:
   - Load predefined configurations
   - Explore different duty cycle scenarios

## Educational Applications

1. **Duty Cycle Effects**: Understand how pulse width affects frequency content
2. **Sinc Envelope**: Visualize how sinc function shapes the spectrum
3. **Harmonic Nulling**: Observe where harmonics disappear based on duty cycle
4. **Fourier Series**: See practical application of Fourier series analysis
5. **Pulse Modulation**: Foundation for understanding pulse width modulation (PWM)

## Key Concepts

### Duty Cycle

Duty cycle = (Pulse Width) / (Period) × 100%

- **0%**: No signal (DC only)
- **50%**: Square wave (equal on/off time)
- **100%**: Constant DC signal

### Sinc Envelope

The spectrum envelope follows a sinc function:
- First null occurs when: k = Period / Pulse Width
- Envelope shape depends on duty cycle
- Higher duty cycles → narrower main lobe

### Harmonic Nulling

Harmonics disappear when:
- k × (Pulse Width) = integer multiple of period
- Creates nulls in the frequency spectrum

## Requirements

- MATLAB R2023b or later
- Signal Processing Toolbox (recommended)

## Examples

### Example 1: Square Wave (50% Duty Cycle)

1. Set duty cycle to 50%
2. Observe symmetric rectangular pulses
3. Note odd harmonics only in spectrum
4. See sinc envelope with first null at k = 2

### Example 2: Narrow Pulses (10% Duty Cycle)

1. Set duty cycle to 10%
2. Observe narrow pulses with long gaps
3. See wide sinc envelope in spectrum
4. Many harmonics present before first null

### Example 3: Wide Pulses (90% Duty Cycle)

1. Set duty cycle to 90%
2. Observe wide pulses with short gaps
3. See narrow sinc envelope in spectrum
4. Few harmonics before first null

## Troubleshooting

1. **Spectrum not updating**: 
   - Ensure all parameters are within valid ranges
   - Check that period > 0

2. **Display issues**:
   - Verify MATLAB graphics are properly configured
   - Try resizing the window

3. **Calculation errors**:
   - Ensure duty cycle is between 0 and 100%
   - Verify period is positive

## Author

Ahmed Rabei - TEFO, 2025

