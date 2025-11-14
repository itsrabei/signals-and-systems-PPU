# Continuous-Time Fourier Series App

Interactive MATLAB application for visualizing and analyzing continuous-time Fourier series synthesis and decomposition.

## Overview

This application demonstrates how periodic continuous-time signals can be represented as sums of harmonically related complex exponentials. It provides real-time visualization of Fourier series synthesis, coefficient analysis, and harmonic convergence.

## Features

- Interactive signal generation and parameter control
- Real-time Fourier series coefficient calculation
- Animated harmonic convergence visualization
- Magnitude and phase spectrum display
- Synthesis vs. original signal comparison
- Error analysis and convergence metrics
- Export capabilities for signals and spectra

## Files

- `CT_Fourier_Series_App.m` - Main application function and GUI
- `CT_FS_Math.m` - Fourier series mathematical computations
- `CT_FS_PlotManager.m` - Plotting and visualization management
- `CT_FS_AnimationController.m` - Animation control and harmonic synthesis
- `CT_FS_Config.m` - Configuration and preset management

## Usage

### Basic Usage

```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec07/FourierSeriesApp'

% Launch the application
CT_Fourier_Series_App();
```

### Signal Types

The application supports various periodic signal types:
- Square wave
- Triangular wave
- Sawtooth wave
- Rectangular pulse train
- Custom periodic functions

### Controls

- **Signal Type Selection**: Choose from predefined signal types
- **Period/Frequency Controls**: Adjust fundamental period and frequency
- **Harmonic Controls**: Set number of harmonics and synthesis parameters
- **Visualization Options**: Toggle between time domain, frequency domain, and synthesis views
- **Animation Controls**: Play/pause harmonic convergence animation

## Educational Applications

1. **Understanding Fourier Series**: Visualize how periodic signals decompose into harmonics
2. **Gibbs Phenomenon**: Observe overshoot at discontinuities
3. **Convergence Analysis**: Study how synthesis improves with more harmonics
4. **Spectrum Analysis**: Examine magnitude and phase relationships

## Requirements

- MATLAB R2023b or later
- Signal Processing Toolbox (recommended)

## Examples

### Square Wave Analysis

1. Select "Square Wave" signal type
2. Set fundamental frequency (e.g., 1 Hz)
3. Adjust number of harmonics (start with 5, increase to see convergence)
4. Observe magnitude spectrum showing odd harmonics only

### Triangular Wave Synthesis

1. Select "Triangular Wave" signal type
2. Set period and amplitude
3. Increase harmonics gradually to see synthesis improve
4. Compare synthesized signal with original

## Troubleshooting

1. **Slow performance**: Reduce number of harmonics or time resolution
2. **Display issues**: Ensure MATLAB graphics are properly configured
3. **Calculation errors**: Verify signal parameters are within valid ranges

## Author

Ahmed Rabei - TEFO, 2025

