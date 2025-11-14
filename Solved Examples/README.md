# Solved Examples

This directory contains worked examples and practice problems organized by lecture number. Each example file provides detailed solutions with step-by-step explanations and accompanying figures.

## Overview

The solved examples complement the lecture notes by providing additional practice problems with complete solutions. Examples are written in LaTeX and include high-quality TikZ/PGFPlots figures for visualization.

## Directory Structure

```
Solved Examples/
├── lec01_examples.tex         # Examples for Lecture 1
├── lec02_examples.tex         # Examples for Lecture 2
├── lec03_examples.tex         # Examples for Lecture 3
├── lec04_examples.tex         # Examples for Lecture 4
├── lec05_examples.tex         # Examples for Lecture 5
├── lec06_examples.tex         # Examples for Lecture 6
├── lec07_examples.tex         # Examples for Lecture 7
├── lec08_examples.tex         # Examples for Lecture 8
├── lec09_examples.tex         # Examples for Lecture 9
└── figures/                   # Figure source files organized by lecture
    ├── lec01_examples/
    ├── lec02_examples/
    └── ...
```

## Compiling Examples

### Prerequisites

- LaTeX distribution (TeX Live or MiKTeX)
- Same packages as required for lectures (see [Lectures/README.md](../Lectures/README.md))

### Compile a Single Example

```bash
cd "Solved Examples"
pdflatex lec01_examples.tex
pdflatex lec01_examples.tex  # Run twice for cross-references
```

### Compile All Examples

**On Windows (PowerShell):**
```powershell
cd "Solved Examples"
Get-ChildItem -Filter "lec*_examples.tex" | ForEach-Object {
    pdflatex $_.Name
    pdflatex $_.Name
}
```

**On Linux/macOS:**
```bash
cd "Solved Examples"
for file in lec*_examples.tex; do
    pdflatex "$file"
    pdflatex "$file"
done
```

## Content by Lecture

### Lecture 1 Examples
- Signal definitions and classifications
- Time domain transformations
- Signal operations

### Lecture 2 Examples
- Elementary signals (impulse, step, exponentials)
- Signal properties (even/odd decomposition)
- Periodic signal analysis

### Lecture 3 Examples
- System properties
- System classification
- Memory and causality

### Lecture 4 Examples
- Discrete-time convolution
- Impulse response
- Convolution properties

### Lecture 5 Examples
- Continuous-time convolution
- Convolution examples
- System response analysis

### Lecture 6 Examples
- System implementation
- Correlation functions
- LTI system properties

### Lecture 7 Examples
- Fourier series analysis
- Coefficient calculation
- Synthesis examples

### Lecture 8 Examples
- Advanced Fourier series
- Applications and properties

### Lecture 9 Examples
- Fourier series applications
- Additional practice problems

## Figure Organization

Figures are organized in subdirectories matching the example file names:
- `figures/lec01_examples/` - Figures for Lecture 1 examples
- `figures/lec02_examples/` - Figures for Lecture 2 examples
- And so on...

Each figure file uses descriptive names with the `fig_` prefix for easy identification.

## Style and Formatting

Examples follow the same style conventions as the main lectures:
- Consistent mathematical notation
- Clear step-by-step solutions
- High-quality figures with TikZ/PGFPlots
- Cross-references to relevant lecture material

## Related Resources

- [Lectures/README.md](../Lectures/README.md) - Main lecture notes
- [Interactive Matlab Apps/README.md](../Interactive Matlab Apps/README.md) - Interactive applications

## Authors

- **Dr. Ghandi Manasra**
- **Ahmed Rabei**

