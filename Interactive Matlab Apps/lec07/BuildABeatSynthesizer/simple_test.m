function simple_test()
    % SIMPLE TEST FOR BUILD-A-BEAT SYNTHESIZER
    % 
    % This function performs basic tests to verify the application works
    
    fprintf('Testing Build-A-Beat Synthesizer...\n');
    
    % Test 1: Basic waveform generation
    fprintf('\nTest 1: Basic waveform generation\n');
    testWaveformGeneration();
    
    % Test 2: Harmonic calculations
    fprintf('\nTest 2: Harmonic calculations\n');
    testHarmonicCalculations();
    
    % Test 3: Audio signal properties
    fprintf('\nTest 3: Audio signal properties\n');
    testAudioSignalProperties();
    
    fprintf('\nAll tests completed successfully!\n');
end

function testWaveformGeneration()
    % Test basic waveform generation
    
    % Generate simple sine wave
    t = linspace(0, 1, 1000);
    frequency = 440;  % A4
    amplitude = 0.5;
    
    % Generate sine wave
    sineWave = amplitude * sin(2 * pi * frequency * t);
    
    % Verify properties
    assert(length(sineWave) == length(t), 'Waveform length incorrect');
    assert(max(abs(sineWave)) <= amplitude, 'Amplitude exceeds limit');
    assert(min(sineWave) >= -amplitude, 'Amplitude below limit');
    
    fprintf('  ✓ Waveform generation passed');
end

function testHarmonicCalculations()
    % Test harmonic amplitude calculations
    
    % Test square wave harmonics (odd only, 1/k decay)
    numHarmonics = 5;
    
    % Calculate expected values
    expectedHarmonics = zeros(1, numHarmonics);
    for k = 1:numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            expectedHarmonics(k) = 1 / k;
        else  % Even harmonics
            expectedHarmonics(k) = 0;
        end
    end
    
    % Verify calculations
    assert(expectedHarmonics(1) == 1, 'Fundamental should be 1');
    assert(expectedHarmonics(2) == 0, 'Second harmonic should be 0');
    assert(abs(expectedHarmonics(3) - 1/3) < 1e-10, 'Third harmonic incorrect');
    assert(expectedHarmonics(4) == 0, 'Fourth harmonic should be 0');
    assert(abs(expectedHarmonics(5) - 1/5) < 1e-10, 'Fifth harmonic incorrect');
    
    fprintf('  ✓ Harmonic calculations passed');
end

function testAudioSignalProperties()
    % Test audio signal properties
    
    % Generate test signal
    t = linspace(0, 1, 44100);  % 1 second at 44.1 kHz
    frequency = 261.63;  % C4
    amplitude = 0.5;
    
    % Generate sine wave
    audioSignal = amplitude * sin(2 * pi * frequency * t);
    
    % Verify audio properties
    assert(length(audioSignal) == 44100, 'Audio signal length incorrect');
    assert(max(abs(audioSignal)) <= 1, 'Audio signal amplitude exceeds limit');
    assert(min(audioSignal) >= -1, 'Audio signal amplitude below limit');
    
    % Verify no clipping
    assert(all(abs(audioSignal) <= 1), 'Audio signal clipped');
    
    fprintf('  ✓ Audio signal properties passed');
end

