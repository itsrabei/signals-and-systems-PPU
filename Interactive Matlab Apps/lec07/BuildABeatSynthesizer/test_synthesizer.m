function test_synthesizer()
    % TEST BUILD-A-BEAT SYNTHESIZER
    % 
    % This function tests the Build-A-Beat Synthesizer application
    % by running various test cases and verifying the mathematical calculations
    
    fprintf('Testing Build-A-Beat Synthesizer...\n');
    
    % Test 1: Basic waveform synthesis
    fprintf('\nTest 1: Basic waveform synthesis\n');
    testWaveformSynthesis();
    
    % Test 2: Harmonic amplitude calculations
    fprintf('\nTest 2: Harmonic amplitude calculations\n');
    testHarmonicAmplitudes();
    
    % Test 3: Timbre analysis
    fprintf('\nTest 3: Timbre analysis\n');
    testTimbreAnalysis();
    
    % Test 4: Audio signal generation
    fprintf('\nTest 4: Audio signal generation\n');
    testAudioSignalGeneration();
    
    % Test 5: Spectral features
    fprintf('\nTest 5: Spectral features\n');
    testSpectralFeatures();
    
    fprintf('\nAll tests completed successfully!\n');
end

function testWaveformSynthesis()
    % Test waveform synthesis
    
    % Test parameters
    t = linspace(0, 1, 1000);
    fundamentalFreq = 440;  % A4
    harmonicAmplitudes = [1, 0.5, 0.33, 0.25, 0.2];
    amplitude = 0.5;
    
    % Generate waveform
    waveform = synthesizeWaveform(t, fundamentalFreq, harmonicAmplitudes, amplitude);
    
    % Verify waveform properties
    assert(length(waveform) == length(t), 'Waveform length incorrect');
    assert(max(abs(waveform)) <= amplitude, 'Waveform amplitude exceeds limit');
    
    % Verify periodicity (should be periodic with fundamental frequency)
    period = 1 / fundamentalFreq;
    samplesPerPeriod = round(period * 1000);  % 1000 samples per second
    if samplesPerPeriod < length(waveform)
        period1 = waveform(1:samplesPerPeriod);
        period2 = waveform(samplesPerPeriod+1:2*samplesPerPeriod);
        assert(all(abs(period1 - period2) < 0.1), 'Waveform not periodic');
    end
    
    fprintf('  ✓ Waveform synthesis verified');
end

function testHarmonicAmplitudes()
    % Test harmonic amplitude calculations for different waveforms
    
    % Test square wave harmonics
    numHarmonics = 10;
    squareHarmonics = getSquareWaveHarmonics(numHarmonics);
    
    % Verify odd harmonics are non-zero, even harmonics are zero
    for k = 1:numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            assert(squareHarmonics(k) > 0, 'Odd harmonic should be non-zero');
            assert(abs(squareHarmonics(k) - 1/k) < 1e-10, 'Odd harmonic amplitude incorrect');
        else  % Even harmonics
            assert(squareHarmonics(k) == 0, 'Even harmonic should be zero');
        end
    end
    
    % Test sawtooth wave harmonics
    sawtoothHarmonics = getSawtoothWaveHarmonics(numHarmonics);
    
    % Verify all harmonics are non-zero and decay as 1/k
    for k = 1:numHarmonics
        assert(sawtoothHarmonics(k) > 0, 'Sawtooth harmonic should be non-zero');
        assert(abs(sawtoothHarmonics(k) - 1/k) < 1e-10, 'Sawtooth harmonic amplitude incorrect');
    end
    
    % Test triangle wave harmonics
    triangleHarmonics = getTriangleWaveHarmonics(numHarmonics);
    
    % Verify odd harmonics decay as 1/k^2, even harmonics are zero
    for k = 1:numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            assert(triangleHarmonics(k) > 0, 'Odd harmonic should be non-zero');
            assert(abs(triangleHarmonics(k) - 1/(k^2)) < 1e-10, 'Odd harmonic amplitude incorrect');
        else  % Even harmonics
            assert(triangleHarmonics(k) == 0, 'Even harmonic should be zero');
        end
    end
    
    % Test sine wave harmonics
    sineHarmonics = getSineWaveHarmonics(numHarmonics);
    
    % Verify only fundamental is non-zero
    assert(sineHarmonics(1) == 1, 'Fundamental harmonic should be 1');
    for k = 2:numHarmonics
        assert(sineHarmonics(k) == 0, 'Higher harmonic should be zero');
    end
    
    fprintf('  ✓ Harmonic amplitude calculations verified');
end

function testTimbreAnalysis()
    % Test timbre analysis
    
    % Test bright timbre (many high harmonics)
    brightHarmonics = [1, 0.8, 0.6, 0.4, 0.2, 0.1, 0.05, 0.02];
    [timbre1, brightness1, richness1] = analyzeTimbre(brightHarmonics);
    
    assert(brightness1 > 0.5, 'Bright timbre should have high brightness');
    assert(richness1 > 0.5, 'Bright timbre should have high richness');
    assert(strcmp(timbre1, 'Bright'), 'Timbre classification incorrect');
    
    % Test dark timbre (few low harmonics)
    darkHarmonics = [1, 0.3, 0.1, 0, 0, 0, 0, 0];
    [timbre2, brightness2, richness2] = analyzeTimbre(darkHarmonics);
    
    assert(brightness2 < 0.5, 'Dark timbre should have low brightness');
    assert(richness2 < 0.5, 'Dark timbre should have low richness');
    assert(strcmp(timbre2, 'Dark'), 'Timbre classification incorrect');
    
    % Test pure timbre (only fundamental)
    pureHarmonics = [1, 0, 0, 0, 0, 0, 0, 0];
    [timbre3, brightness3, richness3] = analyzeTimbre(pureHarmonics);
    
    assert(richness3 < 0.2, 'Pure timbre should have very low richness');
    assert(strcmp(timbre3, 'Pure'), 'Timbre classification incorrect');
    
    fprintf('  ✓ Timbre analysis verified');
end

function testAudioSignalGeneration()
    % Test audio signal generation
    
    % Test parameters
    t = linspace(0, 1, 44100);  % 1 second at 44.1 kHz
    fundamentalFreq = 261.63;  % C4
    harmonicAmplitudes = [1, 0.5, 0.33, 0.25, 0.2];
    amplitude = 0.5;
    sampleRate = 44100;
    
    % Generate audio signal
    audioSignal = generateAudioSignal(t, fundamentalFreq, harmonicAmplitudes, amplitude, sampleRate);
    
    % Verify audio signal properties
    assert(length(audioSignal) == length(t), 'Audio signal length incorrect');
    assert(max(abs(audioSignal)) <= 0.8, 'Audio signal amplitude exceeds safe limit');
    assert(min(audioSignal) >= -0.8, 'Audio signal amplitude below safe limit');
    
    % Verify no clipping
    assert(all(abs(audioSignal) <= 1), 'Audio signal clipped');
    
    fprintf('  ✓ Audio signal generation verified');
end

function testSpectralFeatures()
    % Test spectral feature calculations
    
    % Test parameters
    harmonicAmplitudes = [1, 0.8, 0.6, 0.4, 0.2, 0.1, 0.05, 0.02];
    fundamentalFreq = 440;
    
    % Calculate spectral features
    [spectralCentroid, spectralRolloff] = calculateSpectralFeatures(harmonicAmplitudes, fundamentalFreq);
    
    % Verify spectral centroid
    assert(spectralCentroid > fundamentalFreq, 'Spectral centroid should be above fundamental');
    assert(spectralCentroid < fundamentalFreq * length(harmonicAmplitudes), 'Spectral centroid too high');
    
    % Verify spectral rolloff
    assert(spectralRolloff > fundamentalFreq, 'Spectral rolloff should be above fundamental');
    assert(spectralRolloff <= fundamentalFreq * length(harmonicAmplitudes), 'Spectral rolloff too high');
    
    % Verify rolloff is higher than centroid
    assert(spectralRolloff >= spectralCentroid, 'Spectral rolloff should be >= centroid');
    
    fprintf('  ✓ Spectral features verified');
end

