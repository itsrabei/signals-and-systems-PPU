# Interactive MATLAB Applications

This directory contains interactive MATLAB applications designed to complement the Signals and Systems lecture series. Each application provides hands-on visualization and experimentation tools for key concepts covered in the course.

## Overview

The applications are organized by lecture number, with each subdirectory containing MATLAB scripts and applications relevant to that lecture's topics. Applications range from simple interactive demonstrations to comprehensive visualization tools with graphical user interfaces.

## Directory Structure

```
Interactive Matlab Apps/
├── lec01/                    # Signal fundamentals and basic operations
├── lec02/                    # Signal properties and transformations
├── lec03/                    # System interconnections
├── lec04/                    # Discrete-time convolution
│   └── Discrete Time Convolution/  # Comprehensive DT convolution visualizer
├── lec05/                    # Continuous-time convolution
│   └── Continuous Time Convolution/  # Comprehensive CT convolution visualizer
└── lec07/                    # Fourier series and spectral analysis
    ├── FourierSeriesApp/            # Continuous-time Fourier series analyzer
    ├── DTFourierSeriesApp/          # Discrete-time Fourier series analyzer
    ├── BuildABeatSynthesizer/      # Musical synthesis using Fourier series
    └── DutyCycleSpectrumAnalyzer/  # Duty cycle and spectrum analysis
```

## Requirements

- MATLAB R2023b or later
- Signal Processing Toolbox (for some applications)
- Audio System Toolbox (for audio-related applications)

## Usage

### Running Applications

Most applications can be run directly by executing the main script file in MATLAB:

```matlab
% Navigate to the application directory
cd 'Interactive Matlab Apps/lec01'

% Run the application
interactive_pure_tone_generator
```

For applications with multiple files, see the README in each subdirectory for specific instructions.

### Application Types

1. **Interactive Scripts**: Simple MATLAB scripts with GUI interfaces
   - Run directly from MATLAB command window
   - Provide real-time parameter adjustment
   - Include visualization and audio playback

2. **Class-Based Applications**: Object-oriented MATLAB applications
   - Comprehensive GUI with multiple panels
   - Step-by-step animation controls
   - Export and analysis capabilities

3. **Simulink Models**: System-level simulations
   - Open in Simulink
   - Configure parameters through model interface

## Applications by Lecture

### Lecture 1: Signal Fundamentals
- `interactive_pure_tone_generator.m` - Generate and analyze pure sinusoidal tones
- `interactive_audio_manipulation.m` - Audio signal manipulation and transformation
- `Time_transformation_examples.m` - Time domain transformations (shift, scale, reverse)

### Lecture 2: Signal Properties
- `interactive_audio_even_odd_components.m` - Even/odd signal decomposition
- `interactive_decaying_pure_tone.m` - Exponential decay and oscillations
- `interactive_discrete_cosine_oscillator.m` - Discrete-time cosine signal generation
- `interactive_euler_phasor_animator.m` - Complex exponential visualization
- `interactive_multi_sine_wave_generator.m` - Multiple frequency component synthesis

### Lecture 3: System Interconnections
- `SystemInterconnectionsSimulator.slx` - Simulink model for system interconnection analysis

### Lecture 4: Discrete-Time Convolution
- `Discrete Time Convolution/` - Comprehensive DT convolution visualizer with step-by-step animation
- `interactive_audio_echo_reverb.m` - Audio echo and reverb effects using convolution
- `interactive_moving_average_smoothing.m` - Moving average filter demonstration

### Lecture 5: Continuous-Time Convolution
- `Continuous Time Convolution/` - Comprehensive CT convolution visualizer with step-by-step animation

### Lecture 7: Fourier Series and Spectral Analysis
- `FourierSeriesApp/` - Continuous-time Fourier series synthesis and analysis
- `DTFourierSeriesApp/` - Discrete-time Fourier series visualization
- `BuildABeatSynthesizer/` - Musical tone synthesis using Fourier series harmonics
- `DutyCycleSpectrumAnalyzer/` - Rectangular pulse train spectrum analysis
- `interactive_fourier_transform_analyzer.m` - Fourier transform visualization
- `interactive_spectral_analysis_tool.m` - General-purpose spectral analysis

## Getting Help

For detailed information about specific applications:
- Check the README file in each subdirectory
- Review the header comments in each MATLAB file
- Use the Help button within each application's GUI

## Troubleshooting

### Common Issues

1. **Path Errors**: Ensure you are in the correct directory or add the application directory to your MATLAB path
2. **Missing Toolboxes**: Some applications require specific toolboxes. Check the application's README for requirements
3. **GUI Not Displaying**: Ensure you're using MATLAB R2023b or later for uifigure-based applications

### Getting Support

If you encounter issues:
1. Check the application's specific README for troubleshooting tips
2. Review MATLAB file headers for usage instructions
3. Verify all required files are present in the application directory

## Authors

- **Ahmed Rabei** - TEFO, 2025

## Related Resources

- [Lectures/README.md](../Lectures/README.md) - Lecture notes documentation
- [Solved Examples/README.md](../Solved%20Examples/README.md) - Worked examples documentation

