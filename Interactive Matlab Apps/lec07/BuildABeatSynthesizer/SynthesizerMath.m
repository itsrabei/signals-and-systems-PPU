function waveform = synthesizeWaveform(t, fundamentalFreq, harmonicAmplitudes, amplitude)
    % SYNTHESIZE WAVEFORM USING FOURIER SERIES
    % 
    % Inputs:
    %   t - Time vector
    %   fundamentalFreq - Fundamental frequency (Hz)
    %   harmonicAmplitudes - Vector of harmonic amplitudes
    %   amplitude - Master amplitude
    % 
    % Output: waveform - Synthesized waveform
    
    % Initialize waveform
    waveform = zeros(size(t));
    
    % Add each harmonic
    for k = 1:length(harmonicAmplitudes)
        if harmonicAmplitudes(k) > 0
            harmonic = harmonicAmplitudes(k) * sin(2 * pi * k * fundamentalFreq * t);
            waveform = waveform + harmonic;
        end
    end
    
    % Apply master amplitude
    waveform = amplitude * waveform;
end

function [frequencies, magnitudes, phases] = calculateSpectrum(fundamentalFreq, harmonicAmplitudes, amplitude)
    % CALCULATE FREQUENCY SPECTRUM
    % 
    % Inputs:
    %   fundamentalFreq - Fundamental frequency (Hz)
    %   harmonicAmplitudes - Vector of harmonic amplitudes
    %   amplitude - Master amplitude
    % 
    % Outputs:
    %   frequencies - Frequency vector (Hz)
    %   magnitudes - Magnitude spectrum
    %   phases - Phase spectrum
    
    % Calculate frequencies
    frequencies = fundamentalFreq * (1:length(harmonicAmplitudes));
    
    % Calculate magnitudes
    magnitudes = amplitude * harmonicAmplitudes;
    
    % Calculate phases (all harmonics are sine waves, so phase = 0)
    phases = zeros(size(harmonicAmplitudes));
end

function harmonicAmplitudes = getSquareWaveHarmonics(numHarmonics)
    % GET HARMONIC AMPLITUDES FOR SQUARE WAVE
    % 
    % Input: numHarmonics - Number of harmonics
    % Output: harmonicAmplitudes - Harmonic amplitudes for square wave
    
    harmonicAmplitudes = zeros(1, numHarmonics);
    
    for k = 1:numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            harmonicAmplitudes(k) = 1 / k;
        else  % Even harmonics
            harmonicAmplitudes(k) = 0;
        end
    end
end

function harmonicAmplitudes = getSawtoothWaveHarmonics(numHarmonics)
    % GET HARMONIC AMPLITUDES FOR SAWTOOTH WAVE
    % 
    % Input: numHarmonics - Number of harmonics
    % Output: harmonicAmplitudes - Harmonic amplitudes for sawtooth wave
    
    harmonicAmplitudes = zeros(1, numHarmonics);
    
    for k = 1:numHarmonics
        harmonicAmplitudes(k) = 1 / k;
    end
end

function harmonicAmplitudes = getTriangleWaveHarmonics(numHarmonics)
    % GET HARMONIC AMPLITUDES FOR TRIANGLE WAVE
    % 
    % Input: numHarmonics - Number of harmonics
    % Output: harmonicAmplitudes - Harmonic amplitudes for triangle wave
    
    harmonicAmplitudes = zeros(1, numHarmonics);
    
    for k = 1:numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            harmonicAmplitudes(k) = 1 / (k^2);
        else  % Even harmonics
            harmonicAmplitudes(k) = 0;
        end
    end
end

function harmonicAmplitudes = getSineWaveHarmonics(numHarmonics)
    % GET HARMONIC AMPLITUDES FOR PURE SINE WAVE
    % 
    % Input: numHarmonics - Number of harmonics
    % Output: harmonicAmplitudes - Harmonic amplitudes for sine wave
    
    harmonicAmplitudes = zeros(1, numHarmonics);
    harmonicAmplitudes(1) = 1;  % Only fundamental
end

function [timbre, brightness, richness] = analyzeTimbre(harmonicAmplitudes)
    % ANALYZE TIMBRE CHARACTERISTICS
    % 
    % Input: harmonicAmplitudes - Vector of harmonic amplitudes
    % Outputs:
    %   timbre - Overall timbre description
    %   brightness - Spectral brightness (0-1)
    %   richness - Harmonic richness (0-1)
    
    % Calculate brightness (weighted by harmonic number)
    totalAmplitude = sum(harmonicAmplitudes);
    if totalAmplitude > 0
        weightedSum = sum((1:length(harmonicAmplitudes)) .* harmonicAmplitudes);
        brightness = weightedSum / (length(harmonicAmplitudes) * totalAmplitude);
    else
        brightness = 0;
    end
    
    % Calculate richness (number of significant harmonics)
    threshold = 0.1 * max(harmonicAmplitudes);
    significantHarmonics = sum(harmonicAmplitudes > threshold);
    richness = significantHarmonics / length(harmonicAmplitudes);
    
    % Determine timbre description
    if richness < 0.2
        timbre = 'Pure';
    elseif brightness < 0.3
        timbre = 'Dark';
    elseif brightness > 0.7
        timbre = 'Bright';
    else
        timbre = 'Balanced';
    end
end

function [mse, snr] = calculateReconstructionError(originalSignal, reconstructedSignal)
    % CALCULATE RECONSTRUCTION ERROR METRICS
    % 
    % Inputs:
    %   originalSignal - Original signal
    %   reconstructedSignal - Reconstructed signal
    % 
    % Outputs:
    %   mse - Mean squared error
    %   snr - Signal-to-noise ratio (dB)
    
    % Calculate MSE
    mse = mean((originalSignal - reconstructedSignal).^2);
    
    % Calculate SNR
    signalPower = mean(originalSignal.^2);
    noisePower = mse;
    if noisePower > 0
        snr = 10 * log10(signalPower / noisePower);
    else
        snr = Inf;
    end
end

function [fundamentalFreq, noteName] = getNoteFrequency(noteIndex)
    % GET NOTE FREQUENCY AND NAME
    % 
    % Input: noteIndex - Note index (1-8)
    % Outputs:
    %   fundamentalFreq - Frequency in Hz
    %   noteName - Note name string
    
    % Note frequencies (Hz)
    noteFreqs = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25];
    noteNames = {'C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'};
    
    if noteIndex >= 1 && noteIndex <= length(noteFreqs)
        fundamentalFreq = noteFreqs(noteIndex);
        noteName = noteNames{noteIndex};
    else
        fundamentalFreq = 261.63;  % Default to C4
        noteName = 'C4';
    end
end

function audioSignal = generateAudioSignal(t, fundamentalFreq, harmonicAmplitudes, amplitude, sampleRate)
    % GENERATE AUDIO SIGNAL FOR PLAYBACK
    % 
    % Inputs:
    %   t - Time vector
    %   fundamentalFreq - Fundamental frequency (Hz)
    %   harmonicAmplitudes - Vector of harmonic amplitudes
    %   amplitude - Master amplitude
    %   sampleRate - Sampling rate (Hz)
    % 
    % Output: audioSignal - Audio signal for playback
    
    % Generate waveform
    audioSignal = synthesizeWaveform(t, fundamentalFreq, harmonicAmplitudes, amplitude);
    
    % Normalize to prevent clipping
    maxVal = max(abs(audioSignal));
    if maxVal > 0
        audioSignal = audioSignal / maxVal * 0.8;  % Leave some headroom
    end
end

function [spectralCentroid, spectralRolloff] = calculateSpectralFeatures(harmonicAmplitudes, fundamentalFreq)
    % CALCULATE SPECTRAL FEATURES
    % 
    % Inputs:
    %   harmonicAmplitudes - Vector of harmonic amplitudes
    %   fundamentalFreq - Fundamental frequency (Hz)
    % 
    % Outputs:
    %   spectralCentroid - Spectral centroid (Hz)
    %   spectralRolloff - Spectral rolloff frequency (Hz)
    
    % Calculate frequencies
    frequencies = fundamentalFreq * (1:length(harmonicAmplitudes));
    
    % Calculate spectral centroid
    totalAmplitude = sum(harmonicAmplitudes);
    if totalAmplitude > 0
        spectralCentroid = sum(frequencies .* harmonicAmplitudes) / totalAmplitude;
    else
        spectralCentroid = 0;
    end
    
    % Calculate spectral rolloff (95% of energy)
    cumulativeEnergy = cumsum(harmonicAmplitudes.^2);
    totalEnergy = cumulativeEnergy(end);
    rolloffThreshold = 0.95 * totalEnergy;
    
    rolloffIndex = find(cumulativeEnergy >= rolloffThreshold, 1);
    if ~isempty(rolloffIndex)
        spectralRolloff = frequencies(rolloffIndex);
    else
        spectralRolloff = frequencies(end);
    end
end

