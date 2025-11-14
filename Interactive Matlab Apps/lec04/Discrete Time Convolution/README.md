# Discrete-Time Convolution Visualizer

A comprehensive MATLAB application for visualizing discrete-time convolution with step-by-step animation, real-time MATLAB comparison, and theory compliance verification.

## Overview

This application provides an interactive GUI for understanding discrete-time convolution through visual demonstration. It shows how two signals are convolved step-by-step, with the ability to compare results with MATLAB's built-in `conv()` function.

## Features

- Interactive GUI with signal input and controls
- Real-time convolution visualization
- Step-by-step animation with forward/backward navigation
- MATLAB `conv()` function comparison
- Theory compliance verification
- Support for various signal types (u[n], delta[n], sin[n], tri[n], etc.)
- Preset examples for educational use
- Export capabilities for results and visualizations

## Files

- `DT_main.m` - Main application class and GUI
- `DT_convolution_engine.m` - Core convolution computation engine
- `DT_signal_parser.m` - Signal parsing and generation utilities
- `DT_animation_controller.m` - Animation and step control logic
- `DT_plot_manager.m` - Plotting and visualization management
- `DT_preset_manager.m` - Preset signal configurations
- `DT_tests.m` - Test suite for validation

## Usage

### Basic Usage

```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec04/Discrete Time Convolution'

% Launch the application
app = DT_main();
```

### Input Format

Signals can be entered in several formats:

1. **Array format**: `[1, 2, 3, 4, 5]`
2. **Signal notation**: `u[n]`, `delta[n]`, `sin[n]`, `tri[n]`
3. **Mathematical expressions**: `n*exp(-n)`, `sin(2*pi*n/10)`

Time vectors can be specified separately or automatically generated.

### Controls

- **Signal Input Fields**: Enter x[n] and h[n] signals
- **Time Vector Fields**: Specify time indices (optional)
- **Run/Pause Button**: Start or pause animation
- **Step Buttons**: Navigate step-by-step through convolution
- **Speed Slider**: Adjust animation speed
- **Presets Dropdown**: Load predefined examples
- **Help Button**: Access usage instructions

## Examples

### Example 1: Unit Step Convolution

```
x[n]: u[n]
h[n]: u[n]
Time Vector: -5:5
```

### Example 2: Impulse Response

```
x[n]: [1, 2, 3, 2, 1]
h[n]: delta[n-2]
Time Vector: 0:4
```

## Theory Compliance

The application verifies that the computed convolution matches theoretical expectations and provides detailed analysis including:
- Convolution length verification
- Energy calculations
- Symmetry properties
- MATLAB comparison results

## Requirements

- MATLAB R2023b or later
- Signal Processing Toolbox (for some signal types)

## Troubleshooting

1. **Signal parsing errors**: Ensure signal notation follows supported formats
2. **Time vector mismatch**: Verify time vectors match signal lengths
3. **Animation not starting**: Check that both signals are properly entered

## Author

Ahmed Rabei - TEFO, 2025

