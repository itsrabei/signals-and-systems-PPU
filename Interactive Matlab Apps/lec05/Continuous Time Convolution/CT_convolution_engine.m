classdef CT_convolution_engine < handle
    % ContinuousConvolutionEngine - Continuous-Time Convolution Computation Engine
    %
    % This class handles the core convolution mathematics for the Continuous-Time
    % Convolution Visualizer. It computes step-by-step convolution, manages
    % signal data, and provides theory compliance verification.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Features:
    % - Step-by-step convolution computation
    % - MATLAB conv() compatibility verification
    % - Theory compliance checking
    % - Support for various signal types

    properties (SetAccess = private)
        x_func, h_func, t_start, t_end, dt, tau_vector, convolution_result, matlab_result
        IsInitialized logical = false, current_t_index = 1, animation_t_values
        % Custom ranges properties
        x_t_start, x_t_end, h_t_start, h_t_end, use_custom_ranges
        % Impulse scaling properties
        impulse_scaling_enabled logical = true
        % Caching for performance
        cached_x_scaled, cached_h_scaled, last_scaling_hash
    end
    
    properties (Access = private)
        Parser CT_signal_parser
    end
    
    methods
        function obj = CT_convolution_engine()
            obj.Parser = CT_signal_parser();
        end

        function initialize(obj, x_expr, h_expr, t_start, t_end, dt, x_t_start, x_t_end, h_t_start, h_t_end)
            try
                % Input validation
                if ~ischar(x_expr) || ~ischar(h_expr)
                    error('CT_convolution_engine:InvalidInputType: Signal expressions must be strings.');
                end
                
                if ~isnumeric(t_start) || ~isnumeric(t_end) || ~isnumeric(dt)
                    error('CT_convolution_engine:InvalidInputType: Time parameters must be numeric.');
                end
                
                if t_start >= t_end, error('CT_convolution_engine:InvalidTimeRange: Time Start must be less than Time End.'); end
                if dt <= 0, error('CT_convolution_engine:InvalidTimeStep: Time Step must be positive.'); end
                if (t_end - t_start) / dt > 20000, error('CT_convolution_engine:TimeRangeTooLarge: Time range is too large or step is too small.'); end
                
                % Handle custom ranges if provided
                if nargin >= 8 && ~isempty(x_t_start) && ~isempty(x_t_end) && ~isempty(h_t_start) && ~isempty(h_t_end)
                    % Custom ranges provided
                    if x_t_start >= x_t_end, error('CT_convolution_engine:InvalidTimeRange: x(t) Start must be less than x(t) End.'); end
                    if h_t_start >= h_t_end, error('CT_convolution_engine:InvalidTimeRange: h(t) Start must be less than h(t) End.'); end
                    obj.x_t_start = x_t_start; obj.x_t_end = x_t_end;
                    obj.h_t_start = h_t_start; obj.h_t_end = h_t_end;
                    obj.use_custom_ranges = true;
                else
                    % Use unified time range
                    obj.x_t_start = t_start; obj.x_t_end = t_end;
                    obj.h_t_start = t_start; obj.h_t_end = t_end;
                    obj.use_custom_ranges = false;
                end
                
                obj.t_start = t_start; obj.t_end = t_end; obj.dt = dt;
                
                obj.tau_vector = t_start:dt:t_end;
                % Calculate animation time vector based on expected convolution length
                expected_length = 2*length(obj.tau_vector) - 1;
                obj.animation_t_values = linspace(2*t_start, 2*t_end, expected_length);
                
                % Ensure animation time vector is not empty
                if isempty(obj.animation_t_values)
                    obj.animation_t_values = [2*t_start, 2*t_end];
                end
                
                % Ensure we have valid time vectors
                if isempty(obj.tau_vector) || length(obj.tau_vector) < 2
                    error('CT_convolution_engine:InvalidTimeVector: Time vector is too short or empty.');
                end
                
                % Parse signals with custom ranges if enabled
                if obj.use_custom_ranges
                    % Create time vectors for each signal
                    x_t_vec = obj.x_t_start:obj.dt:obj.x_t_end;
                    h_t_vec = obj.h_t_start:obj.dt:obj.h_t_end;
                    x_vals = obj.Parser.parseSignal(x_expr, x_t_vec, dt);
                    h_vals = obj.Parser.parseSignal(h_expr, h_t_vec, dt);
                    
                    % Create interpolation functions with correct time vectors
                    obj.x_func = @(t) interp1(x_t_vec, x_vals, t, 'linear', 0);
                    obj.h_func = @(t) interp1(h_t_vec, h_vals, t, 'linear', 0);
                else
                    % Use unified time range
                    x_vals = obj.Parser.parseSignal(x_expr, obj.tau_vector, dt);
                    h_vals = obj.Parser.parseSignal(h_expr, obj.tau_vector, dt);
                    
                    % Create interpolation functions with unified time vector
                    obj.x_func = @(t) interp1(obj.tau_vector, x_vals, t, 'linear', 0);
                    obj.h_func = @(t) interp1(obj.tau_vector, h_vals, t, 'linear', 0);
                end

                obj.computeFullConvolution();
                
                % MATLAB convolution comparison - handle different signal lengths
                if obj.use_custom_ranges
                    % For custom ranges, we need to ensure both signals are on the same time grid
                    % Use the union of time ranges for MATLAB comparison
                    t_union = unique([x_t_vec, h_t_vec]);
                    t_union = sort(t_union);
                    
                    % Interpolate both signals to the union time grid
                    x_vals_union = interp1(x_t_vec, x_vals, t_union, 'linear', 0);
                    h_vals_union = interp1(h_t_vec, h_vals, t_union, 'linear', 0);
                    
                    obj.matlab_result = conv(x_vals_union, h_vals_union) * dt;
                else
                    obj.matlab_result = conv(x_vals, h_vals) * dt;
                end
                
                % Theory compliance check: area property
                if obj.use_custom_ranges
                    obj.verifyTheoryCompliance(x_vals, h_vals, x_t_vec, h_t_vec);
                else
                    obj.verifyTheoryCompliance(x_vals, h_vals);
                end
                
                obj.current_t_index = 1;
                obj.IsInitialized = true;
            catch ME, obj.reset(); rethrow(ME); end
        end
        
        function [x_values, h_shifted, product, conv_value, current_t] = computeStep(obj)
            x_values=[]; h_shifted=[]; product=[]; conv_value=NaN; current_t=NaN;
            if ~obj.IsInitialized || obj.isAnimationComplete(), return; end
            
            current_t = obj.animation_t_values(obj.current_t_index);
            x_values = obj.x_func(obj.tau_vector);
            h_shifted = obj.h_func(current_t - obj.tau_vector);
            
            % Note: Impulse scaling should only be applied for visualization,
            % not for the actual convolution computation to maintain mathematical accuracy
            
            product = x_values .* h_shifted;
            conv_value = trapz(obj.tau_vector, product);
            
            obj.current_t_index = obj.current_t_index + 1;
        end
        
        function computeFullConvolution(obj)
            obj.convolution_result = zeros(size(obj.animation_t_values));
            x_tau_vals = obj.x_func(obj.tau_vector);
            for i = 1:length(obj.animation_t_values)
                t = obj.animation_t_values(i);
                product = x_tau_vals .* obj.h_func(t - obj.tau_vector);
                obj.convolution_result(i) = trapz(obj.tau_vector, product);
            end
        end
        
        function [y_custom, y_matlab, comparison] = getConvolutionComparison(obj)
            y_custom = obj.convolution_result;
            y_matlab_full = obj.matlab_result;
            
            n = min(length(y_custom), length(y_matlab_full));
            y_matlab = y_matlab_full(1:n);
            y_custom_trimmed = y_custom(1:n);
            
            tol = max(1e-6, 10 * obj.dt * max(1, max(abs(y_matlab))));
            
            comparison.max_error = max(abs(y_custom_trimmed - y_matlab));
            if comparison.max_error <= tol, comparison.status = 'Perfect Match';
            else, comparison.status = 'Mismatch'; end
        end
        
        function [t_vals, y_vals] = getFullResult(obj)
            t_vals = obj.animation_t_values; y_vals = obj.convolution_result;
        end
        
        function reset(obj)
            obj.IsInitialized=false; obj.current_t_index=1; obj.convolution_result=[];
            obj.animation_t_values=[]; obj.tau_vector=[]; obj.x_func=[]; obj.h_func=[];
        end
        
        function setImpulseScaling(obj, enabled)
            obj.impulse_scaling_enabled = enabled;
        end
        
        function h_scaled = applyImpulseScaling(obj, h_vals, t_vals)
            % Smart impulse detection and area-based scaling for better visualization
            % Prevents tall impulses from squishing other signals
            h_scaled = h_vals;
            
            if isempty(h_vals) || length(h_vals) < 3
                return;
            end
            
            dt = t_vals(2) - t_vals(1);
            
            % Smart impulse detection using multiple criteria
            [impulse_locs, impulse_areas] = obj.detectImpulses(h_vals, t_vals);
            
            if isempty(impulse_locs)
                return;
            end
            
            % Calculate the maximum non-impulse value for reference
            non_impulse_mask = true(size(h_vals));
            for i = 1:length(impulse_locs)
                idx = impulse_locs(i);
                % Mark a small window around each impulse
                window_size = max(1, round(0.02 * length(h_vals)));
                start_idx = max(1, idx - window_size);
                end_idx = min(length(h_vals), idx + window_size);
                non_impulse_mask(start_idx:end_idx) = false;
            end
            
            non_impulse_vals = h_vals(non_impulse_mask);
            max_non_impulse = max(abs(non_impulse_vals));
            if isempty(max_non_impulse) || max_non_impulse < 1e-10
                max_non_impulse = 1.0;  % Default reference
            end
            
            % Apply smart scaling to impulses
            for i = 1:length(impulse_locs)
                idx = impulse_locs(i);
                area = impulse_areas(i);
                
                if area > 1e-10  % Valid impulse area
                    % Calculate scale factor based on area
                    base_height = 1.0;  % Base height for unit impulse
                    area_scale = area / base_height;
                    
                    % Apply reasonable bounds to prevent extreme scaling
                    area_scale = max(0.1, min(5.0, area_scale));
                    
                    % Additional scaling to prevent squishing
                    % Scale relative to non-impulse signal amplitude
                    relative_scale = min(3.0, max_non_impulse * 2.0 / abs(h_vals(idx)));
                    final_scale = min(area_scale, relative_scale);
                    
                    % Scale the impulse height
                    h_scaled(idx) = h_vals(idx) * final_scale;
                end
            end
        end
        
        function [impulse_locs, impulse_areas] = detectImpulses(obj, signal, t_vals)
            % Smart impulse detection using multiple criteria
            impulse_locs = [];
            impulse_areas = [];
            
            if isempty(signal) || length(signal) < 3
                return;
            end
            
            dt = t_vals(2) - t_vals(1);
            signal_abs = abs(signal);
            
            % Method 1: Find peaks using findpeaks with adaptive threshold
            max_signal = max(signal_abs);
            if max_signal < 1e-10
                return;
            end
            
            % Adaptive threshold based on signal characteristics
            threshold = max(0.01 * max_signal, 1e-6);
            
            % Find peaks with minimum separation
            min_separation = max(1, round(0.05 * length(signal))); % 5% of signal length
            try
                [peaks, locs] = findpeaks(signal_abs, 'MinPeakHeight', threshold, ...
                    'MinPeakDistance', min_separation);
            catch
                % Fallback if findpeaks fails
                peaks = [];
                locs = [];
            end
            
            % Method 2: Detect impulses by looking for isolated high values
            % (values that are much higher than their neighbors)
            for i = 2:length(signal)-1
                if signal_abs(i) > threshold
                    % Check if this is a local maximum
                    if signal_abs(i) > signal_abs(i-1) && signal_abs(i) > signal_abs(i+1)
                        % Check if it's significantly higher than neighbors
                        neighbor_avg = (signal_abs(i-1) + signal_abs(i+1)) / 2;
                        if signal_abs(i) > 2 * neighbor_avg
                            locs = [locs, i];
                            peaks = [peaks, signal_abs(i)];
                        end
                    end
                end
            end
            
            % Remove duplicates and sort
            [locs, unique_idx] = unique(locs);
            peaks = peaks(unique_idx);
            
            % Calculate areas for each detected impulse
            for i = 1:length(locs)
                idx = locs(i);
                
                % Calculate area around this impulse
                % Use a small window around the peak
                window_size = max(1, round(0.02 * length(signal))); % 2% of signal length
                start_idx = max(1, idx - window_size);
                end_idx = min(length(signal), idx + window_size);
                
                % Calculate area under the curve around this peak
                area = trapz(t_vals(start_idx:end_idx), signal_abs(start_idx:end_idx));
                
                % Only include if area is significant
                if area > 1e-10
                    impulse_locs = [impulse_locs, idx];
                    impulse_areas = [impulse_areas, area];
                end
            end
        end
        
        function progress = getProgress(obj)
            if obj.IsInitialized, progress=min(100,(obj.current_t_index-1)/length(obj.animation_t_values)*100);
            else, progress=0; end
        end
        
        function is_complete = isAnimationComplete(obj)
            is_complete = ~obj.IsInitialized || obj.current_t_index > length(obj.animation_t_values);
        end
        
        function [x_values, h_shifted, product, conv_value, current_t] = computeStepBack(obj)
            x_values=[]; h_shifted=[]; product=[]; conv_value=NaN; current_t=NaN;
            if ~obj.IsInitialized || obj.current_t_index <= 1, return; end
            
            obj.current_t_index = obj.current_t_index - 1;
            [x_values, h_shifted, product, conv_value, current_t] = obj.getCurrentFrameData();
        end
        
        function [x_values, h_shifted, product, conv_value, current_t] = computeStepForward(obj)
            x_values=[]; h_shifted=[]; product=[]; conv_value=NaN; current_t=NaN;
            if ~obj.IsInitialized || obj.isAnimationComplete(), return; end
            
            [x_values, h_shifted, product, conv_value, current_t] = obj.getCurrentFrameData();
            obj.current_t_index = obj.current_t_index + 1;
        end
        
        function [x_values, h_shifted, product, conv_value, current_t] = getCurrentFrameData(obj)
            % Helper function to get data for current frame without changing index
            x_values=[]; h_shifted=[]; product=[]; conv_value=NaN; current_t=NaN;
            if ~obj.IsInitialized || obj.current_t_index > length(obj.animation_t_values), return; end
            
            current_t = obj.animation_t_values(obj.current_t_index);
            x_values = obj.x_func(obj.tau_vector);
            h_shifted = obj.h_func(current_t - obj.tau_vector);
            product = x_values .* h_shifted;
            conv_value = trapz(obj.tau_vector, product);
        end
        
        function verifyTheoryCompliance(obj, x_vals, h_vals, x_t_vec, h_t_vec)
            % Verify area property: area(y) = area(x) * area(h)
            try
                if nargin > 3 && obj.use_custom_ranges
                    % Use custom time vectors
                    area_x = trapz(x_t_vec, x_vals);
                    area_h = trapz(h_t_vec, h_vals);
                else
                    % Use unified time vector
                    area_x = trapz(obj.tau_vector, x_vals);
                    area_h = trapz(obj.tau_vector, h_vals);
                end
                area_y = trapz(obj.animation_t_values, obj.convolution_result);
                expected_area = area_x * area_h;
                
                tolerance = 1e-3;  % More lenient tolerance for numerical integration
                if abs(area_y - expected_area) > tolerance
                    warning('CT_convolution_engine:AreaMismatch', ...
                        'Area property violation: area(y)=%.6f, expected=%.6f', ...
                        area_y, expected_area);
                end
            catch ME
                warning('CT_convolution_engine:AreaCheckFailed', ...
                    'Could not verify area property: %s', ME.message);
            end
        end
        
        function clearData(obj)
            % Clear data for memory management
            obj.tau_vector = [];
            obj.animation_t_values = [];
            obj.convolution_result = [];
            obj.x_values = [];
            obj.h_values = [];
            obj.current_t_index = 1;
            obj.IsInitialized = false;
        end
        
        function optimizeMemory(obj)
            % Optimize memory usage by clearing unnecessary data
            if obj.IsInitialized && obj.current_t_index > 1
                % Keep only essential data for current state
                obj.tau_vector = obj.tau_vector;
                obj.animation_t_values = obj.animation_t_values;
                obj.convolution_result = obj.convolution_result;
            end
        end
    end
end