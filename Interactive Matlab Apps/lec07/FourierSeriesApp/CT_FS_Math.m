classdef CT_FS_Math < handle
    % CT_FS_MATH - Mathematical computations for Continuous-Time Fourier Series
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 2.0
    %
    % This class handles all mathematical computations related to Continuous-Time
    % Fourier Series including coefficient calculation, synthesis, harmonic generation,
    % orthogonality demonstrations, and advanced analysis features.
    
    properties (Access = private)
        % Internal state for caching and optimization
        last_signal = [];
        last_t = [];
        last_f0 = [];
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
        function obj = CT_FS_Math()
            % Constructor - initialize the CT Fourier Series math engine
            obj.performance_stats = struct();
            obj.performance_stats.calculation_times = [];
            obj.performance_stats.cache_hits = 0;
            obj.performance_stats.cache_misses = 0;
            obj.performance_stats.total_calculations = 0;
        end
        
        function cached = isCached(obj, signal, t, f0, N)
            % Check if the current parameters match cached values
            % 
            % Inputs:
            %   signal - Input signal
            %   t - Time vector
            %   f0 - Fundamental frequency
            %   N - Number of harmonics
            %
            % Output:
            %   cached - Boolean indicating if parameters match cache
            
            cached = false;
            
            try
                % Check if all cached values exist
                if isempty(obj.last_signal) || isempty(obj.last_t) || ...
                   isempty(obj.last_f0) || isempty(obj.last_N) || ...
                   isempty(obj.cached_coeffs) || isempty(obj.cached_freqs)
                    return;
                end
                
                % Check parameter matching with reasonable tolerance
                tolerance = 1e-10;  % More reasonable than eps for practical use
                if length(signal) ~= length(obj.last_signal) || ...
                   length(t) ~= length(obj.last_t) || ...
                   abs(f0 - obj.last_f0) > tolerance || ...
                   N ~= obj.last_N
                    return;
                end
                
                % Check signal and time vector matching with reasonable tolerance
                if max(abs(signal - obj.last_signal)) > tolerance || ...
                   max(abs(t - obj.last_t)) > tolerance
                    return;
                end
                
                cached = true;
                
            catch
                cached = false;
            end
        end
        
        function [coeffs, freqs, magnitude, phase] = calculateFourierCoefficients(obj, signal, t, N, f0)
            % Calculate Continuous-Time Fourier Series coefficients with enhanced accuracy
            %
            % Inputs:
            %   signal - Input periodic signal (continuous-time)
            %   t - Time vector (continuous)
            %   N - Number of harmonics
            %   f0 - Fundamental frequency (Hz)
            %
            % Outputs:
            %   coeffs - Complex coefficients for symmetric spectrum [-N to +N]
            %   freqs - Corresponding frequencies (symmetric: -nf0, ..., -f0, 0, f0, ..., nf0)
            %   magnitude - Magnitude spectrum (|coeffs|)
            %   phase - Phase spectrum (angle(coeffs))
            
            % Start performance monitoring
            start_time = tic;
            obj.performance_stats.total_calculations = obj.performance_stats.total_calculations + 1;
            
            % Enhanced input validation with configuration constants
            if isempty(signal) || isempty(t) || N <= 0 || f0 <= 0
                error('CT_FS_Math:InvalidInput', 'Invalid input parameters: signal, t, N, and f0 must be non-empty and positive');
            end
            
            if length(signal) ~= length(t)
                error('CT_FS_Math:DimensionMismatch', 'Signal and time vectors must have the same length');
            end
            
            % Use configuration constants for validation
            if N > 100
                warning('CT_FS_Math:HighHarmonics', 'High number of harmonics may cause computational issues');
            end
            
            % Additional validation
            if ~all(isfinite(signal)) || ~all(isfinite(t))
                error('CT_FS_Math:NonFiniteValues', 'Signal and time vectors must contain finite values');
            end
            
            if f0 > 1000
                warning('CT_FS_Math:HighFrequency', 'Very high frequency may cause numerical issues');
            end
            
            % Validate time vector spans at least one period
            T = 1/f0;
            if length(t) >= 2
                dt = t(2) - t(1);
                if t(end) < T - dt
                    error('CT_FS_Math:InsufficientTimeVector', 'The time vector must span at least one full period (T = %.4f s).', T);
                end
            end
            
            % Truncate to one period first for consistent caching
            T = 1/f0;  % Period
            if length(t) >= 2
                dt = t(2) - t(1);
            else
                error('CT_FS_Math:InvalidTime', 'Time vector must contain at least 2 samples');
            end
            
            % Ensure we have exactly one period for accurate calculation
            period_samples = max(1, round(T / dt));
            if length(signal) > period_samples
                signal = signal(1:period_samples);
                t = t(1:period_samples);
            end
            
            % Check for caching after truncation
            if obj.isCached(signal, t, f0, N)
                coeffs = obj.cached_coeffs;
                freqs = obj.cached_freqs;
                magnitude = obj.cached_magnitude;
                phase = obj.cached_phase;
                obj.performance_stats.cache_hits = obj.performance_stats.cache_hits + 1;
                return;
            end
            
            obj.performance_stats.cache_misses = obj.performance_stats.cache_misses + 1;
            
            % DC component (a0) - average value over one period
            % The DC component represents the average value of the signal over one period
            % This is calculated as: a0 = (1/T) * ∫[0 to T] x(t) dt
            % where T is the period and x(t) is the input signal
            a0 = (1/T) * trapz(t, signal);
            
            % Initialize coefficient arrays for symmetric spectrum (-N to +N)
            coeffs = zeros(1, 2*N+1);
            freqs = zeros(1, 2*N+1);
            magnitude = zeros(1, 2*N+1);
            phase = zeros(1, 2*N+1);
            
            % DC component (index N+1 for symmetric spectrum)
            coeffs(N+1) = a0;
            freqs(N+1) = 0;
            magnitude(N+1) = abs(a0);
            phase(N+1) = 0;  % DC has no phase
            
            % VECTORIZED HARMONIC CALCULATION for better performance
            % Calculate all harmonic coefficients simultaneously using vectorized operations
            if N > 0
                try
                    % Create harmonic indices vector
                    n = 1:N;
                    
                    % Vectorized angular frequencies
                    omega_n = obj.TWO_PI * n * f0;
                    
                    % Vectorized cosine and sine calculations
                    % This is much more efficient than the loop approach
                    cos_terms = signal .* cos(omega_n' * t);  % N x length(t) matrix
                    sin_terms = signal .* sin(omega_n' * t);  % N x length(t) matrix
                    
                    % Vectorized integration using trapz along the time dimension
                    an = (2/T) * trapz(t, cos_terms, 2);  % N x 1 vector
                    bn = (2/T) * trapz(t, sin_terms, 2);  % N x 1 vector
                    
                    % Check for numerical issues
                    finite_mask = isfinite(an) & isfinite(bn);
                    an(~finite_mask) = 0;
                    bn(~finite_mask) = 0;
                    
                    % Complex coefficients for positive frequencies
                    cn_pos = (an - 1j*bn) / 2;
                    coeffs(N+1+(1:N)) = cn_pos;
                    freqs(N+1+(1:N)) = n*f0;
                    magnitude(N+1+(1:N)) = abs(cn_pos);
                    phase(N+1+(1:N)) = angle(cn_pos);
                    
                    % Complex coefficients for negative frequencies
                    cn_neg = (an + 1j*bn) / 2;
                    coeffs(N+1-(1:N)) = cn_neg;
                    freqs(N+1-(1:N)) = -n*f0;
                    magnitude(N+1-(1:N)) = abs(cn_neg);
                    phase(N+1-(1:N)) = angle(cn_neg);
                    
                catch ME
                    fprintf('CT_FS_Math: Vectorized calculation failed, falling back to loop: %s\n', ME.message);
                    % Fallback to original loop-based calculation
                    for n = 1:N
                        try
                            omega_n = obj.TWO_PI * n * f0;
                            
                            cos_term = signal .* cos(omega_n * t);
                            an = (2/T) * trapz(t, cos_term);
                            
                            sin_term = signal .* sin(omega_n * t);
                            bn = (2/T) * trapz(t, sin_term);
                            
                            if ~isfinite(an) || ~isfinite(bn)
                                an = 0;
                                bn = 0;
                            end
                            
                            cn_pos = (an - 1j*bn) / 2;
                            coeffs(N+1+n) = cn_pos;
                            freqs(N+1+n) = n*f0;
                            magnitude(N+1+n) = abs(cn_pos);
                            phase(N+1+n) = angle(cn_pos);
                            
                            cn_neg = (an + 1j*bn) / 2;
                            coeffs(N+1-n) = cn_neg;
                            freqs(N+1-n) = -n*f0;
                            magnitude(N+1-n) = abs(cn_neg);
                            phase(N+1-n) = angle(cn_neg);
                        catch ME2
                            fprintf('CT_FS_Math: Error calculating harmonic %d: %s\n', n, ME2.message);
                            coeffs(N+1+n) = 0;
                            freqs(N+1+n) = n*f0;
                            magnitude(N+1+n) = 0;
                            phase(N+1+n) = 0;
                            coeffs(N+1-n) = 0;
                            freqs(N+1-n) = -n*f0;
                            magnitude(N+1-n) = 0;
                            phase(N+1-n) = 0;
                        end
                    end
                end
            end
            
            % Cache results for efficiency
            obj.last_signal = signal;
            obj.last_t = t;
            obj.last_f0 = f0;
            obj.last_N = N;
            obj.cached_coeffs = coeffs;
            obj.cached_freqs = freqs;
            obj.cached_magnitude = magnitude;
            obj.cached_phase = phase;
            
            % Record performance metrics
            calculation_time = toc(start_time);
            obj.performance_stats.calculation_times(end+1) = calculation_time;
            
            % Log performance for large calculations
            if calculation_time > 1.0  % More than 1 second
                fprintf('CT_FS_Math: Large calculation took %.2f seconds (N=%d, f0=%.2f)\n', ...
                    calculation_time, N, f0);
            end
        end
        
        function fourier_signal = synthesizeFourierSeries(obj, t, coeffs, freqs, N)
            % Synthesize Continuous-Time Fourier Series from coefficients
            %
            % Inputs:
            %   t - Time vector
            %   coeffs - Fourier coefficients
            %   freqs - Corresponding frequencies
            %   N - Number of harmonics to use
            %
            % Output:
            %   fourier_signal - Synthesized continuous-time signal
            
            if nargin < 5
                N = (length(coeffs) - 1) / 2;
            end
            
            % Bounds check N against coefficient length
            max_N = floor((numel(coeffs)-1)/2);
            N = min(N, max_N);
            
            % Validate time vector length
            if length(t) < 2
                error('CT_FS_Math:InvalidTime', 'Time vector must contain at least 2 samples');
            end
            
            % Assert spectrum structure for symmetric complex series
            assert(numel(coeffs) == numel(freqs), 'CT_FS_Math:DimensionMismatch', ...
                'Coefficients and frequencies must have same length');
            assert(mod(numel(coeffs), 2) == 1, 'CT_FS_Math:InvalidSpectrum', ...
                'Symmetric spectrum must have odd length (2N+1)');
            assert(N+1 <= numel(coeffs), 'CT_FS_Math:IndexOutOfBounds', ...
                'Harmonic index N+1 exceeds coefficient array length');
            
            fourier_signal = zeros(size(t));
            
            % DC component (index N+1 in symmetric spectrum)
            fourier_signal = fourier_signal + real(coeffs(N+1));
            
            % Harmonic components with enhanced precision
            for n = 1:N
                % Positive frequency component
                cn_pos = coeffs(N+1+n);
                omega_n = obj.TWO_PI * freqs(N+1+n);
                fourier_signal = fourier_signal + real(cn_pos * exp(1j*omega_n*t));
                
                % Negative frequency component
                cn_neg = coeffs(N+1-n);
                omega_neg = obj.TWO_PI * freqs(N+1-n);
                fourier_signal = fourier_signal + real(cn_neg * exp(1j*omega_neg*t));
            end
        end
        
        function harmonics = generateHarmonics(obj, t, coeffs, freqs, N)
            % Generate individual harmonic components for CT signals
            %
            % Inputs:
            %   t - Time vector
            %   coeffs - Fourier coefficients
            %   freqs - Corresponding frequencies
            %   N - Number of harmonics
            %
            % Output:
            %   harmonics - Matrix where each row is a harmonic component
            
            % Bounds check N against coefficient length
            max_N = floor((numel(coeffs)-1)/2);
            N = min(N, max_N);
            
            % Validate time vector length
            if length(t) < 2
                error('CT_FS_Math:InvalidTime', 'Time vector must contain at least 2 samples');
            end
            
            harmonics = zeros(N+1, length(t));
            
            % DC component (index N+1 in symmetric spectrum)
            harmonics(1,:) = real(coeffs(N+1));
            
            % Harmonic components
            for n = 1:N
                % Positive frequency component
                cn_pos = coeffs(N+1+n);
                omega_n = obj.TWO_PI * freqs(N+1+n);
                
                % Negative frequency component
                cn_neg = coeffs(N+1-n);
                omega_neg = obj.TWO_PI * freqs(N+1-n);
                
                % Combine positive and negative frequency components
                harmonics(n+1,:) = real(cn_pos * exp(1j*omega_n*t) + cn_neg * exp(1j*omega_neg*t));
            end
        end
        
        function [orthogonality_matrix, dot_products] = calculateOrthogonality(obj, t, f0, max_harmonic)
            % Calculate orthogonality relationships between CT harmonic functions
            %
            % Inputs:
            %   t - Time vector
            %   f0 - Fundamental frequency
            %   max_harmonic - Maximum harmonic number
            %
            % Outputs:
            %   orthogonality_matrix - Matrix of dot products
            %   dot_products - Individual dot product values
            
            T = 1/f0;
            dt = t(2) - t(1);
            
            % Create harmonic functions
            harmonics = zeros(max_harmonic, length(t));
            for n = 1:max_harmonic
                omega_n = obj.TWO_PI * n * f0;
                harmonics(n,:) = cos(omega_n * t);
            end
            
            % Calculate orthogonality matrix
            orthogonality_matrix = zeros(max_harmonic, max_harmonic);
            dot_products = [];
            
            for i = 1:max_harmonic
                for j = 1:max_harmonic
                    if i == j
                        % Same harmonic - should be non-zero
                        orthogonality_matrix(i,j) = trapz(t, harmonics(i,:).^2);
                    else
                        % Different harmonics - should be zero (orthogonal)
                        dot_product = trapz(t, harmonics(i,:) .* harmonics(j,:));
                        orthogonality_matrix(i,j) = dot_product;
                        dot_products(end+1) = dot_product;
                    end
                end
            end
        end
        
        function error_metrics = calculateErrorMetrics(obj, original, fourier, t)
            % Calculate comprehensive error metrics for CT Fourier series approximation
            %
            % Inputs:
            %   original - Original signal
            %   fourier - Fourier series approximation
            %   t - Time vector
            %
            % Output:
            %   error_metrics - Structure with various error measures
            
            % Enhanced input validation
            if isempty(original) || isempty(fourier)
                error('CT_FS_Math:EmptySignal', 'Original and Fourier signals cannot be empty');
            end
            
            if length(original) ~= length(fourier)
                error('CT_FS_Math:LengthMismatch', 'Original and Fourier signals must have the same length');
            end
            
            error_signal = original - fourier;
            
            error_metrics = struct();
            error_metrics.mse = mean(error_signal.^2);
            error_metrics.rmse = sqrt(error_metrics.mse);
            error_metrics.mae = mean(abs(error_signal));
            error_metrics.max_error = max(abs(error_signal));
            
            % Calculate SNR safely
            signal_power = mean(original.^2);
            if signal_power > 0 && error_metrics.mse > 0
                error_metrics.snr = 10*log10(signal_power / error_metrics.mse);
            else
                error_metrics.snr = Inf;
            end
            
            % Calculate relative error safely
            signal_range = max(original) - min(original);
            if signal_range > 0
                error_metrics.relative_error = error_metrics.rmse / signal_range;
            else
                error_metrics.relative_error = 0;
            end
            
            % Enhanced Gibbs phenomenon detection
            try
                [~, peaks] = findpeaks(abs(error_signal));
                if ~isempty(peaks)
                    error_metrics.gibbs_overshoot = max(abs(error_signal(peaks)));
                    error_metrics.gibbs_locations = t(peaks);
                    error_metrics.gibbs_count = length(peaks);
                else
                    error_metrics.gibbs_overshoot = 0;
                    error_metrics.gibbs_locations = [];
                    error_metrics.gibbs_count = 0;
                end
            catch
                error_metrics.gibbs_overshoot = 0;
                error_metrics.gibbs_locations = [];
                error_metrics.gibbs_count = 0;
            end
            
            % Additional CT-specific metrics
            error_metrics.energy_error = trapz(t, error_signal.^2);
            error_metrics.normalized_energy_error = error_metrics.energy_error / trapz(t, original.^2);
            
            % Calculate convergence percentage (inverse of relative error)
            if error_metrics.relative_error > 0
                error_metrics.convergence = max(0, min(1, 1 - error_metrics.relative_error));
            else
                error_metrics.convergence = 1; % Perfect convergence
            end
        end
        
        function [power_spectrum, total_power] = calculatePowerSpectrum(obj, coeffs, freqs)
            % Calculate power spectrum from CT Fourier coefficients
            %
            % Inputs:
            %   coeffs - Complex Fourier coefficients [c_-N, ..., c_0, ..., c_N]
            %   freqs - Corresponding frequencies
            %
            % Outputs:
            %   power_spectrum - Power at each frequency
            %   total_power - Total power of the signal
            
            % Calculate power spectrum from complex coefficients
            power_spectrum = abs(coeffs).^2;
            
            % For symmetric spectrum, we need to be careful about double counting
            % The power at each frequency is |c_n|^2
            % For the symmetric representation, we need to account for the fact
            % that c_n and c_-n are complex conjugates
            
            % Calculate total power (Parseval's theorem) - consistent for real signals
            N = (numel(coeffs)-1)/2;
            total_power = power_spectrum(N+1) + 2*sum(power_spectrum(N+2:end));
        end
        
        function convergence_data = analyzeConvergence(obj, signal, t, f0, max_N)
            % Analyze convergence behavior with increasing harmonics for CT signals
            %
            % Inputs:
            %   signal - Original signal
            %   t - Time vector
            %   f0 - Fundamental frequency
            %   max_N - Maximum number of harmonics to test
            %
            % Output:
            %   convergence_data - Structure with convergence analysis
            
            convergence_data = struct();
            convergence_data.N_values = 1:max_N;
            convergence_data.errors = zeros(1, max_N);
            convergence_data.snr_values = zeros(1, max_N);
            convergence_data.convergence_rate = zeros(1, max_N-1);
            
            for N = 1:max_N
                [coeffs, freqs] = obj.calculateFourierCoefficients(signal, t, N, f0);
                fourier_signal = obj.synthesizeFourierSeries(t, coeffs, freqs, N);
                error_metrics = obj.calculateErrorMetrics(signal, fourier_signal, t);
                
                convergence_data.errors(N) = error_metrics.rmse;
                convergence_data.snr_values(N) = error_metrics.snr;
                
                if N > 1
                    convergence_data.convergence_rate(N-1) = convergence_data.errors(N-1) - convergence_data.errors(N);
                end
            end
            
            % Enhanced convergence analysis
            convergence_data.is_converging = all(convergence_data.convergence_rate > 0);
            convergence_data.convergence_threshold = 1e-6;
            convergence_data.converged_at = find(convergence_data.errors < convergence_data.convergence_threshold, 1);
            if isempty(convergence_data.converged_at)
                convergence_data.converged_at = max_N;
            end
        end
        
        
        function clearCache(obj)
            % Clear cached results
            obj.last_signal = [];
            obj.last_t = [];
            obj.last_f0 = [];
            obj.last_N = [];
            obj.cached_coeffs = [];
            obj.cached_freqs = [];
            obj.cached_magnitude = [];
            obj.cached_phase = [];
        end
        
        function [magnitude_db, phase_deg] = convertToDecibels(obj, magnitude, phase)
            % Convert magnitude to decibels and phase to degrees
            magnitude_db = 20*log10(max(magnitude, 1e-10));
            phase_deg = rad2deg(phase);
        end
        
        function stats = getPerformanceStats(obj)
            % Get performance statistics
            stats = obj.performance_stats;
            if ~isempty(obj.performance_stats.calculation_times)
                stats.average_time = mean(obj.performance_stats.calculation_times);
                stats.max_time = max(obj.performance_stats.calculation_times);
                stats.min_time = min(obj.performance_stats.calculation_times);
            else
                stats.average_time = 0;
                stats.max_time = 0;
                stats.min_time = 0;
            end
            
            total_requests = obj.performance_stats.cache_hits + obj.performance_stats.cache_misses;
            if total_requests > 0
                stats.cache_hit_rate = obj.performance_stats.cache_hits / total_requests;
            else
                stats.cache_hit_rate = 0;
            end
        end
        
        function resetPerformanceStats(obj)
            % Reset performance statistics
            obj.performance_stats = struct();
            obj.performance_stats.calculation_times = [];
            obj.performance_stats.cache_hits = 0;
            obj.performance_stats.cache_misses = 0;
            obj.performance_stats.total_calculations = 0;
        end
        
        function reportPerformance(obj)
            % Print performance report
            stats = obj.getPerformanceStats();
            fprintf('\n=== CT_FS_Math Performance Report ===\n');
            fprintf('Total calculations: %d\n', obj.performance_stats.total_calculations);
            fprintf('Cache hit rate: %.1f%% (%d hits, %d misses)\n', ...
                stats.cache_hit_rate * 100, obj.performance_stats.cache_hits, obj.performance_stats.cache_misses);
            fprintf('Average calculation time: %.3f seconds\n', stats.average_time);
            fprintf('Max calculation time: %.3f seconds\n', stats.max_time);
            fprintf('Min calculation time: %.3f seconds\n', stats.min_time);
            fprintf('=====================================\n\n');
        end
        
    end
end
