# Discrete-Time Fourier Series App

Interactive MATLAB application for visualizing and analyzing discrete-time Fourier series (DTFS) synthesis and decomposition.

## Overview

This application demonstrates how periodic discrete-time signals can be represented using discrete-time Fourier series. It provides comprehensive tools for analyzing DTFS coefficients, synthesizing signals from harmonics, and visualizing the relationship between time and frequency domains.

## Features

- Interactive discrete-time signal generation
- Real-time DTFS coefficient calculation
- Animated harmonic convergence visualization
- Magnitude and phase spectrum display
- Synthesis vs. original signal comparison
- Comprehensive error analysis
- Professional visualization with multiple plot views
- Export capabilities

## Files

- `DT_Fourier_Series_App.m` - Main application function and GUI
- `launch_dtfs_app.m` - Application launcher with error checking
- `DT_FS_Math.m` - DTFS mathematical computations
- `DT_FS_PlotManager.m` - Plotting and visualization management
- `DT_FS_AnimationController.m` - Animation control and harmonic synthesis
- `DT_FS_Config.m` - Configuration and preset management
- `quick_test.m` - Quick functionality test
- `test_dtfs_app.m` - Comprehensive test suite

## Usage

### Launching the Application

**Recommended method (with error checking):**
```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec07/DTFourierSeriesApp'

% Launch using the launcher
launch_dtfs_app();
```

**Direct launch:**
```matlab
% Navigate to the directory
cd 'Interactive Matlab Apps/lec07/DTFourierSeriesApp'

% Launch directly
DT_Fourier_Series_App();
```

### Testing

Before using the application, you can run tests to verify functionality:

```matlab
% Quick test
quick_test();

% Comprehensive test suite
test_dtfs_app();
```

### Signal Input

The application supports various discrete-time periodic signals:
- Square wave sequences
- Triangular wave sequences
- Sinusoidal sequences
- Custom periodic sequences

### Controls

- **Signal Input**: Enter discrete-time sequence values
- **Period Setting**: Specify fundamental period N
- **Harmonic Controls**: Set number of harmonics for synthesis
- **Visualization Panels**: Multiple views including time domain, frequency domain, and synthesis
- **Animation Controls**: Step through harmonic convergence
- **Analysis Tools**: Error metrics and coefficient analysis

## Educational Applications

1. **DTFS Fundamentals**: Understand discrete-time periodic signal representation
2. **Coefficient Analysis**: Study magnitude and phase of DTFS coefficients
3. **Synthesis Process**: Visualize signal reconstruction from harmonics
4. **Periodicity**: Explore relationship between signal period and frequency domain
5. **Convergence**: Observe how synthesis accuracy improves with more harmonics

## Requirements

- MATLAB R2023b or later
- Signal Processing Toolbox (recommended)

## Troubleshooting

### Common Issues

1. **Launch fails**: 
   - Ensure you're in the correct directory
   - Check that all required files are present
   - Run `quick_test()` to identify specific issues

2. **Missing files error**:
   - Verify all files listed in "Files" section are present
   - Check file permissions

3. **MATLAB version compatibility**:
   - Requires MATLAB R2023b or later for uifigure support
   - Update MATLAB if using older version

4. **Performance issues**:
   - Reduce number of harmonics
   - Decrease sequence length
   - Close other MATLAB applications

### Getting Help

- Click the "Help" button in the application GUI
- Review MATLAB file headers for detailed documentation
- Run test functions to verify installation

## Examples

### Example 1: Square Wave DTFS

1. Enter a square wave sequence (e.g., [1, 1, -1, -1] for period 4)
2. Set period to match sequence length
3. Observe DTFS coefficients showing odd harmonics
4. Synthesize using increasing number of harmonics

### Example 2: Sinusoidal Sequence

1. Generate a sinusoidal sequence with known period
2. Calculate DTFS coefficients
3. Verify that coefficients match expected values
4. Compare synthesis with original signal

## Author

Ahmed Rabei - TEFO, 2025

