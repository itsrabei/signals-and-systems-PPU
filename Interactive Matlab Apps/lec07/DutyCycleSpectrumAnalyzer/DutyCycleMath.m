function [coefficients, harmonics, sincEnvelope] = calculateFourierCoefficients(dutyCycle, numHarmonics, amplitude)
    % CALCULATE FOURIER COEFFICIENTS FOR RECTANGULAR PULSE TRAIN
    % 
    % Inputs:
    %   dutyCycle - Duty cycle (0 < D < 1)
    %   numHarmonics - Number of harmonics to calculate
    %   amplitude - Signal amplitude
    % 
    % Outputs:
    %   coefficients - Fourier series coefficients
    %   harmonics - Harmonic numbers
    %   sincEnvelope - Sinc envelope function
    
    % Harmonic numbers
    harmonics = 0:numHarmonics;
    
    % Initialize coefficients
    coefficients = zeros(size(harmonics));
    
    % DC component (k = 0)
    coefficients(1) = amplitude * dutyCycle;
    
    % AC components (k > 0)
    for k = 2:length(harmonics)
        if harmonics(k) ~= 0
            coefficients(k) = amplitude * dutyCycle * sinc(harmonics(k) * dutyCycle);
        end
    end
    
    % Sinc envelope
    sincEnvelope = amplitude * dutyCycle * abs(sinc(harmonics * dutyCycle));
end

function signal = generateRectangularPulseTrain(t, dutyCycle, period, amplitude)
    % GENERATE RECTANGULAR PULSE TRAIN
    % 
    % Inputs:
    %   t - Time vector
    %   dutyCycle - Duty cycle (0 < D < 1)
    %   period - Signal period
    %   amplitude - Signal amplitude
    % 
    % Output: signal - Generated pulse train
    
    % Initialize signal
    signal = zeros(size(t));
    
    % Generate pulse train
    for i = 1:length(t)
        % Normalize time to period
        t_norm = mod(t(i), period) / period;
        
        % Check if within pulse
        if t_norm <= dutyCycle
            signal(i) = amplitude;
        else
            signal(i) = 0;
        end
    end
end

function nullHarmonics = findHarmonicNulls(dutyCycle, numHarmonics, threshold)
    % FIND HARMONIC NULLS IN THE SPECTRUM
    % 
    % Inputs:
    %   dutyCycle - Duty cycle (0 < D < 1)
    %   numHarmonics - Number of harmonics to check
    %   threshold - Threshold for null detection
    % 
    % Output: nullHarmonics - Vector of harmonic numbers where nulls occur
    
    nullHarmonics = [];
    
    for k = 1:numHarmonics
        if abs(sinc(k * dutyCycle)) < threshold
            nullHarmonics = [nullHarmonics, k];
        end
    end
end

function [timeDomain, frequencyDomain] = analyzeSignal(dutyCycle, period, amplitude, numHarmonics, timeRange, sampleRate)
    % COMPREHENSIVE SIGNAL ANALYSIS
    % 
    % Inputs:
    %   dutyCycle - Duty cycle (0 < D < 1)
    %   period - Signal period
    %   amplitude - Signal amplitude
    %   numHarmonics - Number of harmonics
    %   timeRange - Time range for analysis
    %   sampleRate - Sampling rate
    % 
    % Outputs:
    %   timeDomain - Time domain analysis results
    %   frequencyDomain - Frequency domain analysis results
    
    % Generate time vector
    t = linspace(timeRange(1), timeRange(2), sampleRate * (timeRange(2) - timeRange(1)));
    
    % Generate time domain signal
    timeDomain.signal = generateRectangularPulseTrain(t, dutyCycle, period, amplitude);
    timeDomain.time = t;
    timeDomain.dutyCycle = dutyCycle;
    timeDomain.period = period;
    timeDomain.amplitude = amplitude;
    
    % Calculate frequency domain
    [coefficients, harmonics, sincEnvelope] = calculateFourierCoefficients(dutyCycle, numHarmonics, amplitude);
    
    frequencyDomain.coefficients = coefficients;
    frequencyDomain.harmonics = harmonics;
    frequencyDomain.sincEnvelope = sincEnvelope;
    frequencyDomain.magnitude = abs(coefficients);
    frequencyDomain.phase = angle(coefficients);
    
    % Find nulls
    frequencyDomain.nullHarmonics = findHarmonicNulls(dutyCycle, numHarmonics, 0.01);
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
    snr = 10 * log10(signalPower / noisePower);
end

function [bandwidth, centerFreq] = calculateSpectralProperties(coefficients, harmonics, fundamentalFreq)
    % CALCULATE SPECTRAL PROPERTIES
    % 
    % Inputs:
    %   coefficients - Fourier series coefficients
    %   harmonics - Harmonic numbers
    %   fundamentalFreq - Fundamental frequency
    % 
    % Outputs:
    %   bandwidth - Spectral bandwidth
    %   centerFreq - Center frequency
    
    % Calculate frequencies
    frequencies = harmonics * fundamentalFreq;
    
    % Find significant harmonics (above 10% of maximum)
    maxCoeff = max(abs(coefficients));
    threshold = 0.1 * maxCoeff;
    significantIndices = abs(coefficients) > threshold;
    
    if any(significantIndices)
        significantFreqs = frequencies(significantIndices);
        bandwidth = max(significantFreqs) - min(significantFreqs);
        centerFreq = mean(significantFreqs);
    else
        bandwidth = 0;
        centerFreq = 0;
    end
end

