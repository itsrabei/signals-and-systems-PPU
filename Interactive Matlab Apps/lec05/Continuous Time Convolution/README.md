# Continuous-Time Convolution Visualizer

A comprehensive MATLAB application for visualizing continuous-time convolution with step-by-step animation, real-time MATLAB comparison, and theory compliance verification.

## Overview

This application provides an interactive GUI for understanding continuous-time convolution through visual demonstration. It shows how two continuous signals are convolved step-by-step, with the ability to compare results with MATLAB's built-in `conv()` function.

## Features

- Interactive GUI with signal input and controls
- Real-time convolution visualization
- Step-by-step animation with forward/backward navigation
- MATLAB `conv()` function comparison
- Theory compliance verification
- Support for various signal types (rect, tri, gauss, saw, chirp, etc.)
- Preset examples for educational use
- Custom time range controls for each signal
- Export capabilities for results and visualizations

## Files

- `CT_main.m` - Main application class and GUI
- `CT_convolution_engine.m` - Core convolution computation engine
- `CT_signal_parser.m` - Signal parsing and generation utilities
- `CT_animation_controller.m` - Animation and step control logic
- `CT_plot_manager.m` - Plotting and visualization management
- `CT_preset_manager.m` - Preset signal configurations
- `CT_tests.m` - Test suite for validation

## Usage

### Basic Usage

```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec05/Continuous Time Convolution'

% Launch the application
app = CT_main();
```

### Input Format

Signals can be entered in several formats:

1. **Signal notation**: `rect(t)`, `tri(t)`, `gauss(t)`, `saw(t)`, `chirp(t)`
2. **Mathematical expressions**: `exp(-t)`, `sin(2*pi*t)`, `t*exp(-t)`
3. **Piecewise functions**: Define signals with multiple segments

Time parameters:
- **Time Start/End**: Overall time range for visualization
- **Time Step**: Sampling resolution (smaller = smoother but slower)
- **Custom Ranges**: Separate time ranges for x(t) and h(t)

### Controls

- **Signal Input Fields**: Enter x(t) and h(t) signals
- **Time Range Fields**: Specify time domain parameters
- **Run/Pause Button**: Start or pause animation
- **Step Buttons**: Navigate step-by-step through convolution
- **Speed Slider**: Adjust animation speed
- **Presets Dropdown**: Load predefined examples
- **Dynamic Y-limits**: Auto-adjust plot limits
- **Help Button**: Access usage instructions

## Examples

### Example 1: Rectangular Pulse Convolution

```
x(t): rect(t)
h(t): rect(t)
Time Range: -2 to 2
Time Step: 0.01
```

### Example 2: Exponential Decay

```
x(t): exp(-t)*u(t)
h(t): exp(-2*t)*u(t)
Time Range: 0 to 5
Time Step: 0.05
```

## Theory Compliance

The application verifies that the computed convolution matches theoretical expectations and provides detailed analysis including:
- Convolution length verification
- Energy calculations
- Symmetry properties
- MATLAB comparison results
- Impulse response scaling

## Requirements

- MATLAB R2023b or later
- Signal Processing Toolbox (for some signal types)

## Troubleshooting

1. **Signal parsing errors**: Ensure signal notation follows supported formats
2. **Time step too small**: May cause slow performance; increase time step
3. **Animation not starting**: Check that both signals are properly entered and time ranges are valid

## Author

Ahmed Rabei - TEFO, 2025

