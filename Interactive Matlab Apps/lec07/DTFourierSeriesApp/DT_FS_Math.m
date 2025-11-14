classdef DT_FS_Math < handle
    % DT_FS_MATH - Mathematical computations for Discrete-Time Fourier Series
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 1.0
    %
    % This class handles all mathematical computations related to Discrete-Time
    % Fourier Series including coefficient calculation, synthesis, harmonic generation,
    % orthogonality demonstrations, and advanced analysis features.
    
    properties (Access = private)
        % Internal state for caching and optimization
        last_signal = [];
        last_n = [];
        last_N = [];
        cached_coeffs = [];
        cached_freqs = [];
        cached_magnitude = [];
        cached_phase = [];
        
        % Mathematical constants
        PI = pi;
        TWO_PI = 2*pi;
        
        % Performance monitoring
        performance_stats = [];
    end
    
    methods (Access = public)
        function obj = DT_FS_Math()
            % Constructor - initialize the DT Fourier Series math engine
            obj.performance_stats = struct();
            obj.performance_stats.calculation_times = [];
            obj.performance_stats.cache_hits = 0;
            obj.performance_stats.cache_misses = 0;
            obj.performance_stats.total_calculations = 0;
        end
        
        function cached = isCached(obj, signal, n, N)
            % Check if the current parameters match cached values
            % 
            % Inputs:
            %   signal - Input discrete signal
            %   n - Sample indices vector
            %   N - Period of the signal
            %
            % Output:
            %   cached - Boolean indicating if parameters match cache
            
            cached = false;
            
            try
                % Check if all cached values exist
                if isempty(obj.last_signal) || isempty(obj.last_n) || ...
                   isempty(obj.last_N) || isempty(obj.cached_coeffs) || ...
                   isempty(obj.cached_freqs)
                    return;
                end
                
                % Check parameter matching with reasonable tolerance
                tolerance = 1e-10;
                if length(signal) ~= length(obj.last_signal) || ...
                   length(n) ~= length(obj.last_n) || ...
                   N ~= obj.last_N
                    return;
                end
                
                % Check signal and index vector matching with reasonable tolerance
                if max(abs(signal - obj.last_signal)) > tolerance || ...
                   max(abs(n - obj.last_n)) > tolerance
                    return;
                end
                
                cached = true;
                
            catch
                cached = false;
            end
        end
        
        function [coeffs, freqs, magnitude, phase] = calculateFourierCoefficients(obj, signal, n, N)
            % Calculate Discrete-Time Fourier Series coefficients
            %
            % Inputs:
            %   signal - Input periodic discrete signal
            %   n - Sample indices vector (0 to N-1)
            %   N - Period of the signal
            %
            % Outputs:
            %   coeffs - Complex coefficients for symmetric spectrum [-N/2 to N/2-1]
            %   freqs - Corresponding discrete frequencies (k/N)
            %   magnitude - Magnitude spectrum (|coeffs|)
            %   phase - Phase spectrum (angle(coeffs))
            
            % Start performance monitoring
            start_time = tic;
            
            % Enhanced input validation
            if isempty(signal) || isempty(n) || N <= 0
                error('DT_FS_Math:InvalidInput', 'Invalid input parameters: signal, n, and N must be non-empty and positive');
            end
            
            if ~all(isfinite(signal)) || ~all(isfinite(n))
                error('DT_FS_Math:NonFiniteValues', 'Signal and index vectors must contain finite values');
            end
            
            % Check if we can use cached results
            if obj.isCached(signal, n, N)
                obj.performance_stats.cache_hits = obj.performance_stats.cache_hits + 1;
                coeffs = obj.cached_coeffs;
                freqs = obj.cached_freqs;
                magnitude = obj.cached_magnitude;
                phase = obj.cached_phase;
                return;
            end
            
            obj.performance_stats.cache_misses = obj.performance_stats.cache_misses + 1;
            
            try
                % Ensure signal is periodic with period N
                if length(signal) > N
                    signal = signal(1:N);
                elseif length(signal) < N
                    % Pad with zeros if necessary
                    signal = [signal; zeros(N - length(signal), 1)];
                end
                
                % Calculate DTFS coefficients using the formula:
                % X[k] = (1/N) * sum(x[n] * exp(-j*2*pi*k*n/N)) for n=0 to N-1
                
                % Initialize coefficient arrays
                coeffs = zeros(N, 1);
                freqs = zeros(N, 1);
                
                % Calculate DTFS coefficients using FFT (much more efficient)
                coeffs = fft(signal) / N;
                freqs = (0:N-1)';  % Integer frequency indices
                
                % Calculate magnitude and phase
                magnitude = abs(coeffs);
                phase = angle(coeffs);
                
                % Cache the results
                obj.last_signal = signal;
                obj.last_n = n;
                obj.last_N = N;
                obj.cached_coeffs = coeffs;
                obj.cached_freqs = freqs;
                obj.cached_magnitude = magnitude;
                obj.cached_phase = phase;
                
                % Update performance statistics
                calc_time = toc(start_time);
                obj.performance_stats.calculation_times = [obj.performance_stats.calculation_times, calc_time];
                obj.performance_stats.total_calculations = obj.performance_stats.total_calculations + 1;
                
            catch ME
                fprintf('DT_FS_Math: Coefficient calculation error: %s\n', ME.message);
                % Return default values on error to prevent cascading failures
                N = length(signal);
                coeffs = zeros(N, 1);
                freqs = (0:N-1)';
                magnitude = zeros(N, 1);
                phase = zeros(N, 1);
            end
        end
        
        function [synthesized_signal, harmonics] = synthesizeFourierSeries(obj, coeffs, freqs, n, N)
            % Synthesize discrete signal from DTFS coefficients
            %
            % Inputs:
            %   coeffs - DTFS coefficients
            %   freqs - Corresponding frequencies
            %   n - Sample indices vector
            %   N - Number of harmonic PAIRS to use (0 => DC only, 1 => DC+±1, ...)
            %
            % Outputs:
            %   synthesized_signal - Reconstructed discrete signal
            %   harmonics - Individual harmonic components
            
            try
                % Input validation
                if isempty(coeffs) || isempty(freqs) || N < 0
                    error('DT_FS_Math:InvalidInput', 'Invalid input parameters for synthesis');
                end
                
                % Handle N=0 case (no harmonics, all zeros)
                % Here, N represents number of harmonic PAIRS; the coefficient array length
                % determines the maximum available pairs as floor((num_coeffs-1)/2)
                pair_count = max(0, min(N, floor((length(coeffs) - 1) / 2)));
                
                % Initialize output
                synthesized_signal = zeros(size(n));
                harmonics = zeros(length(n), max(1, pair_count + 1));
                
                % Use only the first N coefficients for synthesis with proper conjugate symmetry
                coeffs_to_use = zeros(size(coeffs));
                num_coeffs = length(coeffs);
                
                % Always include the DC component (k=0)
                coeffs_to_use(1) = coeffs(1);
                
                % Add harmonic pairs (±k) up to pair_count to maintain conjugate symmetry
                for k = 1:pair_count
                    % Positive frequency component (k)
                    if (k + 1) <= num_coeffs
                        coeffs_to_use(k + 1) = coeffs(k + 1);
                    end
                    % Negative frequency component (N-k)
                    neg_idx = num_coeffs - k + 1;
                    if neg_idx >= 1 && neg_idx <= num_coeffs
                        coeffs_to_use(neg_idx) = coeffs(neg_idx);
                    end
                end
                
                % Perform inverse FFT for efficient synthesis
                % Use real() to ensure real output for real input signals
                % Note: coeffs_to_use already contains the correct scaling from FFT/N
                synthesized_signal = real(ifft(coeffs_to_use) * length(coeffs));
                
                % Individual harmonics are generated separately by generateHarmonics method
                % to avoid redundant computation during animation
                harmonics = [];
                
            catch ME
                fprintf('DT_FS_Math: Synthesis error: %s\n', ME.message);
                % Return default values on error to prevent cascading failures
                synthesized_signal = zeros(size(n));
                harmonics = zeros(length(n), min(max(1, N + 1), 10)); % DC + pairs limited
            end
        end
        
        function harmonics = generateHarmonics(obj, coeffs, freqs, n, N)
            % Generate progressive harmonic components (DC + ±k pairs) for visualization
            %
            % Inputs:
            %   coeffs - DTFS coefficients
            %   freqs - Corresponding frequencies
            %   n - Sample indices vector
            %   N - Number of harmonic PAIRS to generate (0 => DC only)
            %
            % Output:
            %   harmonics - Matrix of components (samples x (1 + pairs));
            %               column 1 is DC, each subsequent column is the combined ±k pair
            
            try
                % Input validation
                if isempty(coeffs) || isempty(freqs) || N < 0
                    error('DT_FS_Math:InvalidInput', 'Invalid input parameters for harmonic generation');
                end
                
                num_coeffs = length(coeffs);
                pair_count = max(0, min(N, floor((num_coeffs - 1) / 2)));
                
                % Initialize output: DC + each ±k pair
                harmonics = zeros(length(n), max(1, pair_count + 1));
                fundamental_period = num_coeffs;
                
                % DC component as first column
                dc_component = coeffs(1) * ones(length(n), 1);
                harmonics(:, 1) = real(dc_component);
                
                % Each subsequent column is the combined real contribution of ±k pair
                for k = 1:pair_count
                    pos = coeffs(k+1) * exp(1j * obj.TWO_PI * k * n / fundamental_period);
                    neg_idx = num_coeffs - k + 1;
                    neg = 0;
                    if neg_idx >= 1 && neg_idx <= num_coeffs
                        % Negative frequency component uses positive exponent with negative k
                        neg = coeffs(neg_idx) * exp(1j * obj.TWO_PI * (-k) * n / fundamental_period);
                    end
                    pair_component = pos + neg;
                    harmonics(:, k + 1) = real(pair_component);
                end
                
            catch ME
                fprintf('DT_FS_Math: Harmonic generation error: %s\n', ME.message);
                harmonics = zeros(length(n), max(1, N + 1));
            end
        end
        
        function error_metrics = calculateErrorMetrics(obj, original_signal, synthesized_signal)
            % Calculate error metrics between original and synthesized signals
            %
            % Inputs:
            %   original_signal - Original discrete signal
            %   synthesized_signal - Synthesized signal from DTFS
            %
            % Output:
            %   error_metrics - Structure containing various error measures
            
            try
                % Ensure signals have the same length
                min_length = min(length(original_signal), length(synthesized_signal));
                original_signal = original_signal(1:min_length);
                synthesized_signal = synthesized_signal(1:min_length);
                
                % Calculate error signal
                error_signal = original_signal - synthesized_signal;
                
                % Calculate various error metrics
                mse = mean(error_signal.^2);
                rmse = sqrt(mse);
                mae = mean(abs(error_signal));
                
                % Calculate signal-to-noise ratio
                signal_power = mean(original_signal.^2);
                noise_power = mean(error_signal.^2);
                if noise_power > 0
                    snr_db = 10 * log10(signal_power / noise_power);
                else
                    snr_db = Inf;
                end
                
                % Calculate relative error
                if signal_power > 0
                    relative_error = noise_power / signal_power;
                else
                    relative_error = 0;
                end
                
                % Calculate convergence percentage
                if relative_error > 0
                    convergence = max(0, min(1, 1 - relative_error));
                else
                    convergence = 1; % Perfect convergence
                end
                
                % Create error metrics structure
                error_metrics = struct();
                error_metrics.mse = mse;
                error_metrics.rmse = rmse;
                error_metrics.mae = mae;
                error_metrics.snr_db = snr_db;
                error_metrics.relative_error = relative_error;
                error_metrics.convergence = convergence;
                error_metrics.error_signal = error_signal;
                
            catch ME
                fprintf('DT_FS_Math: Error metrics calculation error: %s\n', ME.message);
                % Return default error metrics
                error_metrics = struct();
                error_metrics.mse = 0;
                error_metrics.rmse = 0;
                error_metrics.mae = 0;
                error_metrics.snr_db = Inf;
                error_metrics.relative_error = 0;
                error_metrics.convergence = 1;
                error_metrics.error_signal = [];
            end
        end
        
        function power_spectrum = calculatePowerSpectrum(obj, coeffs)
            % Calculate power spectrum from DTFS coefficients
            %
            % Input:
            %   coeffs - DTFS coefficients
            %
            % Output:
            %   power_spectrum - Power spectrum (|coeffs|^2)
            
            try
                if isempty(coeffs)
                    power_spectrum = [];
                    return;
                end
                
                % Power spectrum is the squared magnitude of coefficients
                power_spectrum = abs(coeffs).^2;
                
            catch ME
                fprintf('DT_FS_Math: Power spectrum calculation error: %s\n', ME.message);
                power_spectrum = [];
            end
        end
        
        function frequency_response = calculateFrequencyResponse(obj, coeffs, freqs)
            % Calculate frequency response from DTFS coefficients
            %
            % Inputs:
            %   coeffs - DTFS coefficients
            %   freqs - Corresponding frequencies
            %
            % Output:
            %   frequency_response - Structure containing magnitude and phase response
            
            try
                if isempty(coeffs) || isempty(freqs)
                    frequency_response = struct();
                    frequency_response.magnitude = [];
                    frequency_response.phase = [];
                    frequency_response.frequencies = [];
                    return;
                end
                
                % Calculate magnitude and phase response
                magnitude_response = abs(coeffs);
                phase_response = angle(coeffs);
                
                % Create frequency response structure
                frequency_response = struct();
                frequency_response.magnitude = magnitude_response;
                frequency_response.phase = phase_response;
                frequency_response.frequencies = freqs;
                
            catch ME
                fprintf('DT_FS_Math: Frequency response calculation error: %s\n', ME.message);
                frequency_response = struct();
                frequency_response.magnitude = [];
                frequency_response.phase = [];
                frequency_response.frequencies = [];
            end
        end
        
        function orthogonality_demo = demonstrateOrthogonality(obj, N)
            % Demonstrate orthogonality of discrete complex exponentials
            %
            % Input:
            %   N - Period of the signal
            %
            % Output:
            %   orthogonality_demo - Structure containing orthogonality demonstration
            
            try
                % Create two different frequency components
                n = (0:N-1)';
                k1 = 1;  % First frequency
                k2 = 2;  % Second frequency
                
                % Create the two complex exponentials
                exp1 = exp(1j * obj.TWO_PI * k1 * n / N);
                exp2 = exp(1j * obj.TWO_PI * k2 * n / N);
                
                % Calculate their inner product
                inner_product = sum(exp1 .* conj(exp2)) / N;
                
                % Create demonstration structure
                orthogonality_demo = struct();
                orthogonality_demo.n = n;
                orthogonality_demo.exp1 = exp1;
                orthogonality_demo.exp2 = exp2;
                orthogonality_demo.inner_product = inner_product;
                orthogonality_demo.k1 = k1;
                orthogonality_demo.k2 = k2;
                orthogonality_demo.is_orthogonal = abs(inner_product) < 1e-10;
                
            catch ME
                fprintf('DT_FS_Math: Orthogonality demonstration error: %s\n', ME.message);
                orthogonality_demo = struct();
                orthogonality_demo.n = [];
                orthogonality_demo.exp1 = [];
                orthogonality_demo.exp2 = [];
                orthogonality_demo.inner_product = [];
                orthogonality_demo.k1 = [];
                orthogonality_demo.k2 = [];
                orthogonality_demo.is_orthogonal = false;
            end
        end
        
        function convergence_analysis = analyzeConvergence(obj, signal, n, N, max_harmonics)
            % Analyze convergence of DTFS as number of harmonics increases
            %
            % Inputs:
            %   signal - Original discrete signal
            %   n - Sample indices vector
            %   N - Period of the signal
            %   max_harmonics - Maximum number of harmonics to analyze
            %
            % Output:
            %   convergence_analysis - Structure containing convergence data
            
            try
                % Input validation
                if isempty(signal) || max_harmonics <= 0
                    error('DT_FS_Math:InvalidInput', 'Invalid input parameters for convergence analysis');
                end
                
                % Initialize convergence data
                harmonic_counts = 1:max_harmonics;
                mse_values = zeros(size(harmonic_counts));
                
                % Calculate DTFS coefficients once
                [coeffs, freqs] = obj.calculateFourierCoefficients(signal, n, length(signal));
                
                % Analyze convergence for different numbers of harmonics
                for i = 1:length(harmonic_counts)
                    num_harmonics = harmonic_counts(i);
                    
                    % Synthesize signal with current number of harmonics
                    [synthesized, ~] = obj.synthesizeFourierSeries(coeffs, freqs, n, num_harmonics);
                    
                    % Calculate error metrics
                    error_metrics = obj.calculateErrorMetrics(signal, synthesized);
                    mse_values(i) = error_metrics.mse;
                end
                
                % Create convergence analysis structure
                convergence_analysis = struct();
                convergence_analysis.harmonic_counts = harmonic_counts;
                convergence_analysis.mse_values = mse_values;
                convergence_analysis.coeffs = coeffs;
                convergence_analysis.freqs = freqs;
                
            catch ME
                fprintf('DT_FS_Math: Convergence analysis error: %s\n', ME.message);
                convergence_analysis = struct();
                convergence_analysis.harmonic_counts = [];
                convergence_analysis.mse_values = [];
                convergence_analysis.coeffs = [];
                convergence_analysis.freqs = [];
            end
        end
        
        function stats = getPerformanceStats(obj)
            % Get performance statistics
            %
            % Output:
            %   stats - Structure containing performance statistics
            
            stats = obj.performance_stats;
            if ~isempty(obj.performance_stats.calculation_times)
                stats.average_calculation_time = mean(obj.performance_stats.calculation_times);
                stats.max_calculation_time = max(obj.performance_stats.calculation_times);
                stats.min_calculation_time = min(obj.performance_stats.calculation_times);
            else
                stats.average_calculation_time = 0;
                stats.max_calculation_time = 0;
                stats.min_calculation_time = 0;
            end
        end
        
        function resetCache(obj)
            % Reset the cache to free memory
            obj.last_signal = [];
            obj.last_n = [];
            obj.last_N = [];
            obj.cached_coeffs = [];
            obj.cached_freqs = [];
            obj.cached_magnitude = [];
            obj.cached_phase = [];
        end
    end
end
