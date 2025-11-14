classdef CT_FS_AnimationController < handle
    % CT_FS_ANIMATION_CONTROLLER - Handles all animation functionality for CT Fourier Series
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 2.0
    %
    % This class manages animation of Continuous-Time Fourier series convergence,
    % harmonic synthesis, and other dynamic visualizations with enhanced features.
    
    properties (Access = private)
        % Animation state
        is_animating = false;
        animation_timer = [];
        current_harmonic = 1;
        animation_speed = 1.0;
        animation_direction = 1;  % 1 for forward, -1 for backward
        
        % Callback functions
        update_callback = [];
        completion_callback = [];
        progress_callback = [];
        
        % Animation data
        original_signal = [];
        time_vector = [];
        fourier_math = [];
        max_harmonics = 10;
        fundamental_freq = 1;
        
        % Precomputed data for efficiency
        precomputed_coeffs = [];
        precomputed_freqs = [];
        coefficients_precomputed = false;
        
        % Animation settings
        frame_rate = 10;  % FPS
        smooth_transition = true;
        pause_between_harmonics = false;
    end
    
    methods (Access = public)
        function obj = CT_FS_AnimationController(fourier_math)
            % Constructor
            % Input: fourier_math - CT_FS_Math object for calculations
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
        
        function startAnimation(obj, original_signal, t, max_N, f0)
            % Start Continuous-Time Fourier series convergence animation
            %
            % Inputs:
            %   original_signal - Original signal to approximate
            %   t - Time vector
            %   max_N - Maximum number of harmonics
            %   f0 - Fundamental frequency
            
            try
                % Enhanced input validation
                if isempty(original_signal) || isempty(t) || max_N <= 0 || f0 <= 0
                    fprintf('AnimationController: Invalid input parameters\n');
                    return;
                end
                
                if obj.is_animating
                    obj.stopAnimation();
                end
                
                obj.original_signal = original_signal;
                obj.time_vector = t;
                obj.max_harmonics = max(1, min(max_N, 100)); % Clamp harmonics
                obj.fundamental_freq = max(0.1, min(f0, 10)); % Clamp frequency
                obj.current_harmonic = 1;
                obj.animation_direction = 1;
                
                % Pre-calculate all coefficients for maximum efficiency
                try
                    [obj.precomputed_coeffs, obj.precomputed_freqs] = obj.fourier_math.calculateFourierCoefficients(...
                        original_signal, t, obj.max_harmonics, obj.fundamental_freq);
                    obj.coefficients_precomputed = true;
                catch ME
                    fprintf('AnimationController: Pre-calculation failed: %s\n', ME.message);
                    obj.coefficients_precomputed = false;
                end
                
                obj.is_animating = true;
                
                % Use a more robust animation approach to prevent stuck animation
                try
                    % Calculate a safe period that won't cause system overload
                    % Use a much more conservative minimum period to ensure stability
                    % For speeds > 1.0x, use a fixed period to prevent stuck animation
                    if obj.animation_speed <= 1.0
                        period = max(0.1, 1/obj.frame_rate / obj.animation_speed);  % Minimum 100ms for normal speeds
                    else
                        period = 0.15;  % Fixed 150ms period for all speeds > 1.0x
                    end
                    
                    % Suppress ALL timer-related warnings during creation
                    old_warnings = warning('off', 'all');
                    
                    % Create timer with conservative settings
                    obj.animation_timer = timer('TimerFcn', @(~,~) obj.animateStep, ...
                                             'Period', period, ...
                                             'ExecutionMode', 'fixedRate', ...
                                             'BusyMode', 'queue', ...  % Queue instead of drop for better reliability
                                             'ErrorFcn', @(~,~) obj.handleTimerError);
                    
                    % Restore all warnings
                    warning(old_warnings);
                    
                    start(obj.animation_timer);
                    fprintf('AnimationController: Timer started with period %.3f seconds (speed %.2f, step_size will be %d)\n', period, obj.animation_speed, obj.getStepSizeForSpeed(obj.animation_speed));
                catch ME
                    % Restore warning state in case of error
                    warning(old_warnings);
                    fprintf('AnimationController: Timer creation failed: %s\n', ME.message);
                    obj.is_animating = false;
                    obj.animation_timer = [];
                end
            catch ME
                fprintf('AnimationController: Start animation error: %s\n', ME.message);
                obj.is_animating = false;
            end
        end
        
        function startReverseAnimation(obj, original_signal, t, max_N, f0)
            % Start reverse animation (from max harmonics to 1)
            obj.startAnimation(original_signal, t, max_N, f0);
            obj.animation_direction = -1;
            obj.current_harmonic = obj.max_harmonics;  % Use clamped value
        end
        
        function animateStep(obj)
            % Execute one animation step with enhanced features and correct harmonic accumulation
            try
                if ~obj.is_animating
                    return;
                end
                
                % Simple animation step without complex monitoring
                
                % Check bounds
                if obj.animation_direction > 0 && obj.current_harmonic > obj.max_harmonics
                    obj.stopAnimation();
                    return;
                elseif obj.animation_direction < 0 && obj.current_harmonic < 1
                    obj.stopAnimation();
                    return;
                end
                
                % Smart step sizing based on animation speed
                % For higher speeds, use larger step sizes to prevent stuck animation
                if obj.animation_speed <= 1.0
                    step_size = 1;  % Normal step size for speeds <= 1.0x
                elseif obj.animation_speed <= 2.0
                    step_size = 2;  % Skip every other harmonic for speeds 1.5x-2.0x
                else
                    step_size = 3;  % Skip 2 harmonics for speeds > 2.0x
                end
                
                % CRITICAL FIX: Always calculate coefficients for the current harmonic count
                % This ensures the animation shows the progressive addition of harmonics
                try
                    % Calculate coefficients for the current number of harmonics
                    % This is essential for correct animation - we want to show how the
                    % Fourier series improves as we add more harmonics
                        [coeffs, freqs] = obj.fourier_math.calculateFourierCoefficients(...
                            obj.original_signal, obj.time_vector, obj.current_harmonic, obj.fundamental_freq);
                catch ME
                    fprintf('AnimationController: Coefficient calculation error: %s\n', ME.message);
                    obj.stopAnimation();
                    return;
                end
                
                % CRITICAL FIX: Synthesize using only the current number of harmonics
                % This ensures the animation shows the progressive approximation
                try
                    fourier_signal = obj.fourier_math.synthesizeFourierSeries(...
                        obj.time_vector, coeffs, freqs, obj.current_harmonic);
                catch ME
                    fprintf('AnimationController: Fourier synthesis error: %s\n', ME.message);
                    obj.stopAnimation();
                    return;
                end
                
                % Calculate error metrics with error handling
                try
                    error_metrics = obj.fourier_math.calculateErrorMetrics(...
                        obj.original_signal, fourier_signal, obj.time_vector);
                catch ME
                    fprintf('AnimationController: Error metrics calculation error: %s\n', ME.message);
                    error_metrics = struct('mse', 0, 'snr', Inf, 'convergence', 1);
                end
                
                % Generate individual harmonics for visualization
                try
                    harmonics = obj.fourier_math.generateHarmonics(...
                        obj.time_vector, coeffs, freqs, obj.current_harmonic);
                catch ME
                    fprintf('AnimationController: Harmonics generation error: %s\n', ME.message);
                    harmonics = [];
                end
                
                % Create enhanced animation data structure with all necessary information
                animation_data = struct();
                animation_data.harmonic_number = obj.current_harmonic;
                animation_data.max_harmonics = obj.max_harmonics;
                animation_data.fourier_signal = fourier_signal;
                animation_data.coefficients = coeffs;
                animation_data.frequencies = freqs;
                animation_data.harmonics = harmonics;
                animation_data.error_metrics = error_metrics;
                animation_data.progress = (obj.current_harmonic - 1) / max(1, (obj.max_harmonics - 1));
                animation_data.direction = obj.animation_direction;
                animation_data.is_complete = (obj.current_harmonic == obj.max_harmonics && obj.animation_direction > 0) || ...
                                           (obj.current_harmonic == 1 && obj.animation_direction < 0);
                
                % Add convergence information
                animation_data.convergence_info = struct();
                animation_data.convergence_info.mse = error_metrics.mse;
                animation_data.convergence_info.snr = error_metrics.snr;
                animation_data.convergence_info.convergence = error_metrics.convergence;
                
                % Call update callback with error handling
                if ~isempty(obj.update_callback)
                    try
                        obj.update_callback(animation_data);
                    catch ME
                        fprintf('AnimationController: Update callback error: %s\n', ME.message);
                    end
                end
                
                % Call progress callback with error handling
                if ~isempty(obj.progress_callback)
                    try
                        obj.progress_callback(animation_data);
                    catch ME
                        fprintf('AnimationController: Progress callback error: %s\n', ME.message);
                    end
                end
                
                % Update harmonic number with smart step sizing
                obj.current_harmonic = obj.current_harmonic + (obj.animation_direction * step_size);
                
                % Debug information for higher speeds
                if obj.animation_speed > 1.0
                    fprintf('AnimationController: Speed %.1fx, Harmonic %d->%d (step_size=%d)\n', ...
                        obj.animation_speed, obj.current_harmonic - (obj.animation_direction * step_size), obj.current_harmonic, step_size);
                end
            catch ME
                fprintf('AnimationController: Animation step error: %s\n', ME.message);
                obj.stopAnimation();
            end
        end
        
        function stopAnimation(obj)
            % Stop the animation with enhanced cleanup and error handling
            try
                obj.is_animating = false;
                
                % Safely stop and delete timer
                if ~isempty(obj.animation_timer)
                    try
                        if isvalid(obj.animation_timer)
                            stop(obj.animation_timer);
                        end
                    catch ME
                        fprintf('AnimationController: Error stopping timer: %s\n', ME.message);
                    end
                    
                    try
                        delete(obj.animation_timer);
                    catch ME
                        fprintf('AnimationController: Error deleting timer: %s\n', ME.message);
                    end
                    
                    obj.animation_timer = [];
                end
                
                % Call completion callback with error handling
                if ~isempty(obj.completion_callback)
                    try
                        obj.completion_callback();
                    catch ME
                        fprintf('AnimationController: Completion callback error: %s\n', ME.message);
                    end
                end
                
            catch ME
                fprintf('AnimationController: Stop animation error: %s\n', ME.message);
                % Force reset state
                obj.is_animating = false;
                obj.animation_timer = [];
            end
        end
        
        function pauseAnimation(obj)
            % Pause the animation
            if ~isempty(obj.animation_timer) && obj.is_animating
                stop(obj.animation_timer);
            end
        end
        
        function resetAnimation(obj)
            % Reset animation to a safe state - useful when animation gets stuck
            try
                fprintf('AnimationController: Resetting animation to safe state...\n');
                
                % Force stop any running animation
                obj.stopAnimation();
                
                % Reset to safe default values
                obj.animation_speed = CT_FS_Config.DEFAULT_ANIMATION_SPEED;
                obj.frame_rate = CT_FS_Config.DEFAULT_FRAME_RATE;
                obj.current_harmonic = 1;
                obj.animation_direction = 1;
                obj.is_animating = false;
                
                % Clear any cached data
                obj.original_signal = [];
                obj.time_vector = [];
                obj.fundamental_freq = 1;
                obj.max_harmonics = CT_FS_Config.DEFAULT_HARMONICS;
                obj.coefficients_precomputed = false;
                obj.precomputed_coeffs = [];
                obj.precomputed_freqs = [];
                
                fprintf('AnimationController: Animation reset completed\n');
            catch ME
                fprintf('AnimationController: Reset animation error: %s\n', ME.message);
            end
        end
        
        function resumeAnimation(obj)
            % Resume the animation
            if ~isempty(obj.animation_timer) && ~obj.is_animating
                start(obj.animation_timer);
                obj.is_animating = true;
            end
        end
        
        function setSpeed(obj, speed)
            % Set animation speed using discrete speed levels to prevent stuck animation
            % Only allow specific speed levels: 0.5, 1.0, 1.5, 2.0, 2.5, 3.0
            valid_speeds = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
            
            % Find the closest valid speed
            [~, idx] = min(abs(valid_speeds - speed));
            obj.animation_speed = valid_speeds(idx);
            
            fprintf('AnimationController: Speed set to discrete level %.1f\n', obj.animation_speed);
            
            if ~isempty(obj.animation_timer) && obj.is_animating
                % Stop current animation and restart with new speed
                fprintf('AnimationController: Restarting animation with speed %.1f\n', obj.animation_speed);
                obj.stopAnimation();
                
                % Restart animation with new speed
                if ~isempty(obj.original_signal) && ~isempty(obj.time_vector)
                    obj.startAnimation(obj.original_signal, obj.time_vector, obj.max_harmonics, obj.fundamental_freq);
                end
            end
        end
        
        function speed = getValidSpeeds(obj)
            % Get list of valid speed levels
            speed = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
        end
        
        function nextSpeed = getNextSpeed(obj)
            % Get the next higher speed level
            valid_speeds = obj.getValidSpeeds();
            current_idx = find(valid_speeds == obj.animation_speed);
            if current_idx < length(valid_speeds)
                nextSpeed = valid_speeds(current_idx + 1);
            else
                nextSpeed = obj.animation_speed;  % Already at maximum
            end
        end
        
        function prevSpeed = getPreviousSpeed(obj)
            % Get the previous lower speed level
            valid_speeds = obj.getValidSpeeds();
            current_idx = find(valid_speeds == obj.animation_speed);
            if current_idx > 1
                prevSpeed = valid_speeds(current_idx - 1);
            else
                prevSpeed = obj.animation_speed;  % Already at minimum
            end
        end
        
        function step_size = getStepSizeForSpeed(obj, speed)
            % Get the appropriate step size for a given speed
            if speed <= 1.0
                step_size = 1;  % Normal step size for speeds <= 1.0x
            elseif speed <= 2.0
                step_size = 2;  % Skip every other harmonic for speeds 1.5x-2.0x
            else
                step_size = 3;  % Skip 2 harmonics for speeds > 2.0x
            end
        end
        
        function speed = getSpeed(obj)
            % Get current animation speed
            speed = obj.animation_speed;
        end
        
        function setFrameRate(obj, fps)
            % Set animation frame rate with robust handling
            obj.frame_rate = max(1, min(fps, 30));  % Conservative limit: max 30 FPS
            
            if ~isempty(obj.animation_timer) && obj.is_animating
                % Restart animation with new frame rate to prevent issues
                fprintf('AnimationController: Restarting animation with new frame rate %d\n', obj.frame_rate);
                obj.stopAnimation();
                
                % Restart animation with new frame rate
                if ~isempty(obj.original_signal) && ~isempty(obj.time_vector)
                    obj.startAnimation(obj.original_signal, obj.time_vector, obj.max_harmonics, obj.fundamental_freq);
                end
            end
        end
        
        function fps = getFrameRate(obj)
            % Get current frame rate
            fps = obj.frame_rate;
        end
        
        function setCurrentHarmonic(obj, harmonic)
            % Set current harmonic number (for manual stepping)
            obj.current_harmonic = max(1, min(harmonic, obj.max_harmonics));
        end
        
        function harmonic = getCurrentHarmonic(obj)
            % Get current harmonic number
            harmonic = obj.current_harmonic;
        end
        
        function setMaxHarmonics(obj, max_N)
            % Set maximum number of harmonics
            obj.max_harmonics = max(1, max_N);
        end
        
        function max_N = getMaxHarmonics(obj)
            % Get maximum number of harmonics
            max_N = obj.max_harmonics;
        end
        
        function setSmoothTransition(obj, smooth)
            % Enable/disable smooth transitions
            obj.smooth_transition = smooth;
        end
        
        function setPauseBetweenHarmonics(obj, pause_enabled)
            % Enable/disable pause between harmonics
            obj.pause_between_harmonics = pause_enabled;
        end
        
        function animating = isAnimating(obj)
            % Check if animation is currently running
            animating = obj.is_animating;
        end
        
        function progress = getProgress(obj)
            % Get animation progress (0 to 1)
            if obj.max_harmonics > 1
                progress = (obj.current_harmonic - 1) / (obj.max_harmonics - 1);
            else
                progress = 0;
            end
        end
        
        function stepForward(obj)
            % Step forward one harmonic manually
            if obj.current_harmonic < obj.max_harmonics
                obj.animation_direction = 1;
                obj.animateStep();
            end
        end
        
        function stepBackward(obj)
            % Step backward one harmonic manually
            if obj.current_harmonic > 1
                obj.animation_direction = -1;
                obj.current_harmonic = obj.current_harmonic - 1;
                obj.animateStep();
            end
        end
        
        function reset(obj)
            % Reset animation to beginning
            obj.stopAnimation();
            obj.current_harmonic = 1;
            obj.animation_direction = 1;
        end
        
        function jumpToHarmonic(obj, harmonic)
            % Jump to specific harmonic number
            harmonic = max(1, min(harmonic, obj.max_harmonics));
            obj.current_harmonic = harmonic;
            
            % Trigger update
            if ~isempty(obj.original_signal)
                obj.animateStep();
            end
        end
        
        function direction = getDirection(obj)
            % Get current animation direction
            direction = obj.animation_direction;
        end
        
        function setDirection(obj, direction)
            % Set animation direction (1 for forward, -1 for backward)
            obj.animation_direction = sign(direction);
        end
        
        function toggleDirection(obj)
            % Toggle animation direction
            obj.animation_direction = -obj.animation_direction;
        end
        
        function handleTimerError(obj, varargin)
            % Handle timer errors gracefully with enhanced recovery
            try
                fprintf('AnimationController: Timer error occurred at speed %.1fx, attempting recovery\n', obj.animation_speed);
                
                % Stop the current timer
                if ~isempty(obj.animation_timer) && isvalid(obj.animation_timer)
                    stop(obj.animation_timer);
                    delete(obj.animation_timer);
                end
                
                % Reset animation state
                obj.is_animating = false;
                obj.animation_timer = [];
                
                % Notify completion callback if available
                if ~isempty(obj.completion_callback)
                    try
                        obj.completion_callback();
                    catch ME
                        fprintf('AnimationController: Completion callback error: %s\n', ME.message);
                    end
                end
                
                fprintf('AnimationController: Timer error recovery completed\n');
                
            catch ME
                fprintf('AnimationController: Error during timer error handling: %s\n', ME.message);
                % Force reset state
                obj.is_animating = false;
                obj.animation_timer = [];
            end
        end
        
        function reverseAnimation(obj)
            % Reverse animation direction
            try
                if obj.is_animating
                    obj.toggleDirection();
                    fprintf('AnimationController: Animation direction reversed\n');
                else
                    fprintf('AnimationController: No active animation to reverse\n');
                end
            catch ME
                fprintf('AnimationController: Reverse animation error: %s\n', ME.message);
            end
        end
        
        function delete(obj)
            % Destructor - cleanup
            obj.stopAnimation();
        end
    end
end
