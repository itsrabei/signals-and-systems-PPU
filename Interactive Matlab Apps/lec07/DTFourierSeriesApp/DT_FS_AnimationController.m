classdef DT_FS_AnimationController < handle
    % DT_FS_ANIMATION_CONTROLLER - Handles all animation functionality for DT Fourier Series
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 1.0
    %
    % This class manages animation of Discrete-Time Fourier series convergence,
    % harmonic synthesis, and other dynamic visualizations with enhanced features.
    
    properties (Access = private)
        % Animation state
        is_animating = false;
        animation_timer = [];
        current_harmonic = -1;
        animation_speed = 1.0;
        % animation_direction removed - animation only goes forward now
        
        % Callback functions
        update_callback = [];
        completion_callback = [];
        progress_callback = [];
        
        % Animation data
        original_signal = [];
        sample_indices = [];
        fourier_math = [];
        max_harmonics = 10;
        period_N = 10;
        
        % Precomputed data for efficiency
        precomputed_coeffs = [];
        precomputed_freqs = [];
        coefficients_precomputed = false;
        
        % Animation settings
        frame_rate = 10;  % FPS
        smooth_transition = true;
        pause_between_harmonics = false;
        sample_duration = 0.5;  % Duration each sample is displayed (seconds)
    end
    
    methods (Access = public)
        function obj = DT_FS_AnimationController(fourier_math)
            % Constructor
            % Input: fourier_math - DT_FS_Math object for calculations
            obj.fourier_math = fourier_math;
        end
        
        function setUpdateCallback(obj, callback)
            % Set callback function for animation updates
            obj.update_callback = callback;
        end
        
        function setCompletionCallback(obj, callback)
            % Set callback function for animation completion
            obj.completion_callback = callback;
        end
        
        function setProgressCallback(obj, callback)
            % Set callback function for progress updates
            obj.progress_callback = callback;
        end
        
        function startAnimation(obj, original_signal, sample_indices, max_harmonics, period_N)
            % Start Discrete-Time Fourier series convergence animation
            %
            % Inputs:
            %   original_signal - Original discrete signal to approximate
            %   sample_indices - Sample indices vector
            %   max_harmonics - Maximum number of harmonics
            %   period_N - Period of the signal
            
            try
                % Enhanced input validation
                if isempty(original_signal) || isempty(sample_indices) || max_harmonics <= 0 || period_N <= 0
                    fprintf('DT_FS_AnimationController: Invalid input parameters\n');
                    return;
                end
                
                if obj.is_animating
                    obj.stopAnimation();
                end
                
                obj.original_signal = original_signal;
                obj.sample_indices = sample_indices;
                % Interpret max_harmonics as the maximum number of harmonic PAIRS to include
                % (progressive addition: DC, then ±1, then ±2, ...)
                obj.period_N = max(1, min(period_N, 100)); % Clamp period
                available_pairs = max(0, floor((obj.period_N - 1) / 2));
                obj.max_harmonics = max(0, min(max_harmonics, min(available_pairs, 50))); % Clamp pairs
                obj.current_harmonic = -1;  % Start at -1 so first increment goes to 0
                
                % Pre-calculate all coefficients for maximum efficiency
                try
                    [obj.precomputed_coeffs, obj.precomputed_freqs] = obj.fourier_math.calculateFourierCoefficients(...
                        original_signal, sample_indices, length(original_signal));
                    obj.coefficients_precomputed = true;
                catch ME
                    fprintf('DT_FS_AnimationController: Pre-calculation failed: %s\n', ME.message);
                    obj.coefficients_precomputed = false;
                end
                
                obj.is_animating = true;
                
                % Create and start animation timer with N-proportional timing
                try
                    % Calculate period based on number of PAIRS and desired sample duration
                    total_animation_time = max(1, obj.max_harmonics) * obj.sample_duration / obj.animation_speed;
                    period = max(0.2, total_animation_time / max(1, obj.max_harmonics));
                    
                    obj.animation_timer = timer('TimerFcn', @(~,~) obj.animateStep, ...
                                             'Period', period, ...
                                             'ExecutionMode', 'fixedRate', ...
                                             'BusyMode', 'drop', ...
                                             'ErrorFcn', @(~,~) obj.handleTimerError);
                    start(obj.animation_timer);
                    fprintf('DT_FS_AnimationController: Animation started with %d harmonic pairs\n', obj.max_harmonics);
                catch ME
                    fprintf('DT_FS_AnimationController: Timer creation failed: %s\n', ME.message);
                    obj.is_animating = false;
                    obj.animation_timer = [];
                end
                
            catch ME
                fprintf('DT_FS_AnimationController: Animation start error: %s\n', ME.message);
                obj.is_animating = false;
            end
        end
        
        function stopAnimation(obj)
            % Stop the current animation
            try
                if obj.is_animating
                    obj.is_animating = false;
                    
                    % Stop and delete timer
                    if ~isempty(obj.animation_timer) && isvalid(obj.animation_timer)
                        stop(obj.animation_timer);
                        delete(obj.animation_timer);
                    end
                    obj.animation_timer = [];
                    
                    % Call completion callback
                    if ~isempty(obj.completion_callback)
                        try
                            obj.completion_callback();
                        catch ME
                            fprintf('DT_FS_AnimationController: Completion callback error: %s\n', ME.message);
                        end
                    end
                    
                    fprintf('DT_FS_AnimationController: Animation stopped\n');
                end
            catch ME
                fprintf('DT_FS_AnimationController: Animation stop error: %s\n', ME.message);
                % Force reset state
                obj.is_animating = false;
                obj.animation_timer = [];
            end
        end
        
        % reverseAnimation function removed as reverse button was removed
        
        function setSpeed(obj, speed)
            % Set animation speed
            try
                % Clamp speed to reasonable range
                obj.animation_speed = max(0.1, min(speed, 5.0));
                
                % Update timer period if animation is running (fix race condition)
                if obj.is_animating && ~isempty(obj.animation_timer) && isvalid(obj.animation_timer)
                    % Stop timer, update period, then restart to avoid race condition
                    stop(obj.animation_timer);
                    % Calculate period based on number of PAIRS and desired sample duration
                    total_animation_time = max(1, obj.max_harmonics) * obj.sample_duration / obj.animation_speed;
                    period = max(0.2, total_animation_time / max(1, obj.max_harmonics));
                    obj.animation_timer.Period = period;
                    start(obj.animation_timer);
                end
                
                fprintf('DT_FS_AnimationController: Animation speed set to %.1fx\n', obj.animation_speed);
            catch ME
                fprintf('DT_FS_AnimationController: Speed setting error: %s\n', ME.message);
            end
        end
        
        function setFrameRate(obj, frame_rate)
            % Set animation frame rate
            try
                % Clamp frame rate to reasonable range
                obj.frame_rate = max(1, min(frame_rate, 30));
                
                % Update timer period if animation is running
                if obj.is_animating && ~isempty(obj.animation_timer) && isvalid(obj.animation_timer)
                    % Calculate period based on number of PAIRS and desired sample duration
                    total_animation_time = max(1, obj.max_harmonics) * obj.sample_duration / obj.animation_speed;
                    period = max(0.2, total_animation_time / max(1, obj.max_harmonics));
                    obj.animation_timer.Period = period;
                end
                
                fprintf('DT_FS_AnimationController: Frame rate set to %d FPS\n', obj.frame_rate);
            catch ME
                fprintf('DT_FS_AnimationController: Frame rate setting error: %s\n', ME.message);
            end
        end
        
        function setSampleDuration(obj, duration)
            % Set sample duration for animation
            try
                % Clamp duration to reasonable range (0.1 to 2.0 seconds)
                obj.sample_duration = max(0.1, min(duration, 2.0));
                
                % Update timer period if animation is running
                if obj.is_animating && ~isempty(obj.animation_timer) && isvalid(obj.animation_timer)
                    total_animation_time = max(1, obj.max_harmonics) * obj.sample_duration / obj.animation_speed;
                    period = max(0.2, total_animation_time / max(1, obj.max_harmonics));
                    obj.animation_timer.Period = period;
                end
                
                fprintf('DT_FS_AnimationController: Sample duration set to %.1f seconds\n', obj.sample_duration);
            catch ME
                fprintf('DT_FS_AnimationController: Sample duration setting error: %s\n', ME.message);
            end
        end
        
        % toggleDirection function removed as reverse functionality was removed
        
        function current_harmonic = getCurrentHarmonic(obj)
            % Get current harmonic number
            current_harmonic = obj.current_harmonic;
        end
        
        function is_animating = getAnimationStatus(obj)
            % Get animation status
            is_animating = obj.is_animating;
        end
        
        function speed = getAnimationSpeed(obj)
            % Get current animation speed
            speed = obj.animation_speed;
        end
        
        % getAnimationDirection function removed as reverse functionality was removed
        
        function progress = getAnimationProgress(obj)
            % Get animation progress (0 to 1)
            % current_harmonic ranges from -1 to max_harmonics
            % Progress should be 0 at -1 and 1 at max_harmonics
            if obj.max_harmonics > 0
                progress = (obj.current_harmonic + 1) / (obj.max_harmonics + 1);
                progress = max(0, min(1, progress));
            else
                progress = 0;
            end
        end
        
        function resetAnimation(obj)
            % Reset animation to initial state
            try
                obj.stopAnimation();
                obj.current_harmonic = -1;
                obj.animation_speed = 1.0;
                obj.coefficients_precomputed = false;
                obj.precomputed_coeffs = [];
                obj.precomputed_freqs = [];
                fprintf('DT_FS_AnimationController: Animation reset\n');
            catch ME
                fprintf('DT_FS_AnimationController: Animation reset error: %s\n', ME.message);
            end
        end
        
        function cleanup(obj)
            % Clean up resources
            try
                obj.stopAnimation();
                obj.update_callback = [];
                obj.completion_callback = [];
                obj.progress_callback = [];
                obj.fourier_math = [];
                fprintf('DT_FS_AnimationController: Cleanup completed\n');
            catch ME
                fprintf('DT_FS_AnimationController: Cleanup error: %s\n', ME.message);
            end
        end
    end
    
    methods (Access = private)
        function animateStep(obj)
            % Perform one animation step
            try
                if ~obj.is_animating
                    return;
                end
                
                % Update current harmonic (forward only)
                obj.current_harmonic = obj.current_harmonic + 1;
                
                % Check bounds - stop at max pairs
                if obj.current_harmonic > obj.max_harmonics
                    obj.current_harmonic = obj.max_harmonics;
                    obj.stopAnimation(); % Stop animation when reaching max harmonics
                    return;
                end
                
                % Call update callback with current harmonic
                if ~isempty(obj.update_callback)
                    try
                        % Prepare animation data
                        animation_data = obj.prepareAnimationData();
                        obj.update_callback(animation_data);
                    catch ME
                        fprintf('DT_FS_AnimationController: Update callback error: %s\n', ME.message);
                    end
                end
                
                % Call progress callback
                if ~isempty(obj.progress_callback)
                    try
                        progress = obj.getAnimationProgress();
                        obj.progress_callback(progress, obj.current_harmonic, obj.max_harmonics);
                    catch ME
                        fprintf('DT_FS_AnimationController: Progress callback error: %s\n', ME.message);
                    end
                end
                
            catch ME
                fprintf('DT_FS_AnimationController: Animation step error: %s\n', ME.message);
                obj.handleAnimationError();
            end
        end
        
        function animation_data = prepareAnimationData(obj)
            % Prepare data for animation update
            try
                animation_data = struct();
                animation_data.current_harmonic = obj.current_harmonic;
                animation_data.max_harmonics = obj.max_harmonics;
                animation_data.original_signal = obj.original_signal;
                animation_data.sample_indices = obj.sample_indices;
                animation_data.period_N = obj.period_N;
                
                % Calculate Fourier series with current number of harmonics
                if obj.coefficients_precomputed && ~isempty(obj.precomputed_coeffs)
                    % Use precomputed coefficients
                    coeffs = obj.precomputed_coeffs;
                    freqs = obj.precomputed_freqs;
                else
                    % Calculate coefficients on the fly
                    [coeffs, freqs] = obj.fourier_math.calculateFourierCoefficients(...
                        obj.original_signal, obj.sample_indices, length(obj.original_signal));
                end
                
                % Synthesize signal with current number of PAIRS
                % current_harmonic is 0-based pair index; 0 => DC only
                pair_count = max(0, obj.current_harmonic);
                [fourier_signal, ~] = obj.fourier_math.synthesizeFourierSeries(...
                    coeffs, freqs, obj.sample_indices, pair_count);
                
                % Generate progressive components for visualization (DC + ±k pairs)
                harmonics = obj.fourier_math.generateHarmonics(coeffs, freqs, obj.sample_indices, pair_count);
                
                animation_data.fourier_signal = fourier_signal;
                animation_data.coefficients = coeffs;
                animation_data.frequencies = freqs;
                animation_data.harmonics = harmonics;
                
                % Calculate error metrics
                error_metrics = obj.fourier_math.calculateErrorMetrics(obj.original_signal, fourier_signal);
                animation_data.error_metrics = error_metrics;
                
            catch ME
                fprintf('DT_FS_AnimationController: Animation data preparation error: %s\n', ME.message);
                % Return empty animation data
                animation_data = struct();
                animation_data.current_harmonic = obj.current_harmonic;
                animation_data.max_harmonics = obj.max_harmonics;
                animation_data.original_signal = [];
                animation_data.sample_indices = [];
                animation_data.fourier_signal = [];
                animation_data.coefficients = [];
                animation_data.frequencies = [];
                animation_data.harmonics = [];
                animation_data.error_metrics = [];
            end
        end
        
        function handleTimerError(obj, varargin)
            % Handle timer errors gracefully
            try
                fprintf('DT_FS_AnimationController: Timer error occurred, attempting recovery\n');
                
                % Stop the current timer safely
                if ~isempty(obj.animation_timer) && isvalid(obj.animation_timer)
                    stop(obj.animation_timer);
                    delete(obj.animation_timer);
                end
                
                % Reset animation state
                obj.is_animating = false;
                obj.animation_timer = [];
                
                % Notify completion callback with error handling
                if ~isempty(obj.completion_callback)
                    try
                        obj.completion_callback();
                    catch ME
                        fprintf('DT_FS_AnimationController: Completion callback error: %s\n', ME.message);
                    end
                end
                
            catch ME
                fprintf('DT_FS_AnimationController: Error during timer error handling: %s\n', ME.message);
                % Force reset state
                obj.is_animating = false;
                obj.animation_timer = [];
            end
        end
        
        function handleAnimationError(obj)
            % Handle general animation errors
            try
                fprintf('DT_FS_AnimationController: Animation error occurred, stopping animation\n');
                obj.stopAnimation();
            catch ME
                fprintf('DT_FS_AnimationController: Error during animation error handling: %s\n', ME.message);
                % Force reset state
                obj.is_animating = false;
                obj.animation_timer = [];
            end
        end
    end
    
    methods (Access = protected)
        function delete(obj)
            % Destructor - ensure proper cleanup
            try
                obj.cleanup();
            catch ME
                fprintf('DT_FS_AnimationController: Destructor error: %s\n', ME.message);
            end
        end
    end
end
