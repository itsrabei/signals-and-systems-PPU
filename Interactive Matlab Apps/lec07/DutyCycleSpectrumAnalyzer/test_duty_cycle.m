function test_duty_cycle()
    % TEST DUTY CYCLE AND SPECTRUM ANALYZER
    % 
    % This function tests the Duty Cycle and Spectrum Analyzer application
    % by running various test cases and verifying the mathematical calculations
    
    fprintf('Testing Duty Cycle and Spectrum Analyzer...\n');
    
    % Test 1: Basic Fourier coefficient calculation
    fprintf('\nTest 1: Basic Fourier coefficient calculation\n');
    testFourierCoefficients();
    
    % Test 2: Duty cycle effects
    fprintf('\nTest 2: Duty cycle effects\n');
    testDutyCycleEffects();
    
    % Test 3: Harmonic nulling
    fprintf('\nTest 3: Harmonic nulling\n');
    testHarmonicNulling();
    
    % Test 4: Signal generation
    fprintf('\nTest 4: Signal generation\n');
    testSignalGeneration();
    
    % Test 5: Spectral analysis
    fprintf('\nTest 5: Spectral analysis\n');
    testSpectralAnalysis();
    
    fprintf('\nAll tests completed successfully!\n');
end

function testFourierCoefficients()
    % Test Fourier coefficient calculation
    
    % Test case 1: 50% duty cycle
    dutyCycle = 0.5;
    numHarmonics = 10;
    amplitude = 1;
    
    [coefficients, harmonics, sincEnvelope] = calculateFourierCoefficients(dutyCycle, numHarmonics, amplitude);
    
    % Verify DC component
    expectedDC = amplitude * dutyCycle;
    assert(abs(coefficients(1) - expectedDC) < 1e-10, 'DC component incorrect');
    
    % Verify sinc envelope
    expectedSinc = amplitude * dutyCycle * abs(sinc(harmonics * dutyCycle));
    assert(all(abs(sincEnvelope - expectedSinc) < 1e-10), 'Sinc envelope incorrect');
    
    fprintf('  ✓ Fourier coefficient calculation passed');
end

function testDutyCycleEffects()
    % Test duty cycle effects on spectrum
    
    % Test narrow pulse (10% duty cycle)
    dutyCycle1 = 0.1;
    [coeffs1, ~, ~] = calculateFourierCoefficients(dutyCycle1, 20, 1);
    
    % Test wide pulse (90% duty cycle)
    dutyCycle2 = 0.9;
    [coeffs2, ~, ~] = calculateFourierCoefficients(dutyCycle2, 20, 1);
    
    % Narrow pulse should have wider spectrum (more harmonics)
    % Wide pulse should have narrower spectrum (fewer harmonics)
    assert(sum(abs(coeffs1) > 0.1) > sum(abs(coeffs2) > 0.1), 'Duty cycle effects incorrect');
    
    fprintf('  ✓ Duty cycle effects verified');
end

function testHarmonicNulling()
    % Test harmonic nulling detection
    
    % Test 50% duty cycle (should null even harmonics)
    dutyCycle = 0.5;
    numHarmonics = 20;
    threshold = 0.01;
    
    nullHarmonics = findHarmonicNulls(dutyCycle, numHarmonics, threshold);
    
    % For 50% duty cycle, even harmonics should be nulled
    expectedNulls = 2:2:numHarmonics;
    assert(all(ismember(nullHarmonics, expectedNulls)), 'Harmonic nulling incorrect');
    
    fprintf('  ✓ Harmonic nulling detection verified');
end

function testSignalGeneration()
    % Test signal generation
    
    % Generate test signal
    t = linspace(0, 2, 1000);
    dutyCycle = 0.3;
    period = 1;
    amplitude = 2;
    
    signal = generateRectangularPulseTrain(t, dutyCycle, period, amplitude);
    
    % Verify signal properties
    assert(max(signal) == amplitude, 'Maximum amplitude incorrect');
    assert(min(signal) == 0, 'Minimum amplitude incorrect');
    
    % Verify duty cycle
    pulseWidth = sum(signal > 0) / length(signal);
    assert(abs(pulseWidth - dutyCycle) < 0.01, 'Duty cycle incorrect');
    
    fprintf('  ✓ Signal generation verified');
end

function testSpectralAnalysis()
    % Test spectral analysis
    
    % Perform analysis
    dutyCycle = 0.4;
    period = 1;
    amplitude = 1;
    numHarmonics = 15;
    timeRange = [0, 2];
    sampleRate = 1000;
    
    [timeDomain, frequencyDomain] = analyzeSignal(dutyCycle, period, amplitude, numHarmonics, timeRange, sampleRate);
    
    % Verify time domain
    assert(isfield(timeDomain, 'signal'), 'Time domain signal missing');
    assert(isfield(timeDomain, 'time'), 'Time domain time vector missing');
    assert(timeDomain.dutyCycle == dutyCycle, 'Duty cycle not stored correctly');
    
    % Verify frequency domain
    assert(isfield(frequencyDomain, 'coefficients'), 'Frequency domain coefficients missing');
    assert(isfield(frequencyDomain, 'harmonics'), 'Frequency domain harmonics missing');
    assert(isfield(frequencyDomain, 'sincEnvelope'), 'Frequency domain sinc envelope missing');
    
    fprintf('  ✓ Spectral analysis verified');
end
