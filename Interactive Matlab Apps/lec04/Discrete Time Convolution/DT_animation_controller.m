classdef DT_animation_controller < handle
    % AnimationController - Animation Control for Convolution Visualizer
    %
    % This class manages the step-by-step animation of the convolution process.
    % It handles timer control, animation states, and provides smooth playback
    % with adjustable speed and step-by-step navigation.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Features:
    % - Smooth animation with configurable speed
    % - Step-by-step forward/backward navigation
    % - Timer management with error handling
    % - Animation state tracking

    properties (SetAccess = private)
        Engine DT_convolution_engine
        Plotter DT_plot_manager
        State char = 'idle'
        IsRunning logical = false
    end

    properties (Access = private)
        AnimationTimer
        IsLocked logical = false
        StatusCallback function_handle
        CompletionCallback function_handle
        DefaultSpeed double = 1.0
        MinSpeed double = 0.1
        MaxSpeed double = 20.0  % Increased max speed
        SpeedMultiplier double = 1.0
    end

    methods
        function initialize(obj, engine, plotter)
            % Initialize with engine and plotter references
            if ~isa(engine, 'DT_convolution_engine')
                error('AnimationController:InvalidEngine', 'Engine must be a DT_convolution_engine instance');
            end
            
            if ~isa(plotter, 'DT_plot_manager')
                error('AnimationController:InvalidPlotter', 'Plotter must be a DT_plot_manager instance');
            end

            obj.Engine = engine;
            obj.Plotter = plotter;
            obj.State = 'idle';
            obj.IsRunning = false;
        end

        function setStatusCallback(obj, fcn)
            if isa(fcn, 'function_handle')
                obj.StatusCallback = fcn;
            else
                error('AnimationController:InvalidCallback', 'Status callback must be a function handle');
            end
        end

        function setCompletionCallback(obj, fcn)
            if isa(fcn, 'function_handle')
                obj.CompletionCallback = fcn;
            else
                error('AnimationController:InvalidCallback', 'Completion callback must be a function handle');
            end
        end

        function setSpeed(obj, speed)
            % Set animation speed with enhanced dynamic range
            if ~isnumeric(speed) || ~isscalar(speed) || speed <= 0
                error('AnimationController:InvalidSpeed', 'Speed must be a positive scalar');
            end
            
            % Clamp speed to valid range
            speed = max(obj.MinSpeed, min(speed, obj.MaxSpeed));
            obj.SpeedMultiplier = speed;
            
            % Update timer if it exists and is running
            if ~isempty(obj.AnimationTimer) && isvalid(obj.AnimationTimer)
                was_running = obj.IsRunning;
                if was_running
                    stop(obj.AnimationTimer);
                end
                
                % Dynamic period calculation - faster for higher speeds
                base_period = 0.5; % Base period in seconds
                obj.AnimationTimer.Period = base_period / speed;
                
                if was_running
                    start(obj.AnimationTimer);
                end
            end
        end

        function start(obj)
            % Start animation with safety checks
            if obj.IsLocked || obj.IsRunning
                return;
            end
            
            obj.IsLocked = true;
            try
                if strcmp(obj.State, 'completed')
                    obj.updateStatus('Animation already completed. Reset to run again.');
                    obj.IsLocked = false;
                    return;
                end
                
                if ~obj.Engine.IsInitialized
                    obj.updateStatus('Engine not initialized. Cannot start animation.');
                    obj.IsLocked = false;
                    return;
                end
                
                % Create or validate timer
                if ~obj.isValidTimer()
                    obj.createTimer();
                end
                
                % Start timer
                start(obj.AnimationTimer);
                obj.IsRunning = true;
                obj.State = 'running';
                obj.updateStatus('Animation running...');
                
            catch ME
                obj.updateStatus(['Error starting animation: ' ME.message]);
                obj.stopTimer();
                obj.State = 'idle';
            end
            
            obj.IsLocked = false;
        end

        function pause(obj)
            % Pause running animation
            if ~obj.IsRunning
                return;
            end
            
            try
                if obj.isValidTimer()
                    stop(obj.AnimationTimer);
                end
                obj.IsRunning = false;
                obj.State = 'paused';
                obj.updateStatus('Animation paused.');
            catch ME
                obj.updateStatus(['Error pausing animation: ' ME.message]);
            end
        end

        function step(obj)
            % Enhanced step function with better continuation
            % Pause if running to allow single step
            if obj.IsRunning
                obj.pause();
            end
            
            try
                if ~obj.Engine.IsInitialized
                    obj.updateStatus('Engine not initialized. Cannot step.');
                    return;
                end
                
                % Execute the animation step
                obj.animationStep();
                
                % Update state appropriately
                if obj.Engine.isAnimationComplete()
                    obj.completeAnimation();
                else
                    % Set state to paused so user can continue stepping or start again
                    obj.State = 'paused';
                    obj.updateStatus('Step completed. Ready for next step or Run.');
                end
                
            catch ME
                obj.updateStatus(['Error in step: ' ME.message]);
                obj.State = 'idle';
            end
        end

        function reset(obj)
            % Reset animation to initial state
            obj.stopTimer();
            
            if ~isempty(obj.Engine) && isvalid(obj.Engine)
                obj.Engine.reset();
            end
            
            if ~isempty(obj.Plotter) && isvalid(obj.Plotter)
                obj.Plotter.clearAllPlots();
            end
            
            obj.IsRunning = false;
            obj.State = 'idle';
            obj.updateStatus('Animation reset.');
        end

        function delete(obj)
            % Cleanup when object is destroyed
            obj.stopTimer();
        end

        function speed = getCurrentSpeed(obj)
            % Get current animation speed
            if obj.isValidTimer()
                speed = 0.5 / obj.AnimationTimer.Period; % Reverse calculation
            else
                speed = obj.SpeedMultiplier;
            end
        end

        function state = getCurrentState(obj)
            % Get current state information
            state = struct();
            state.State = obj.State;
            state.IsRunning = obj.IsRunning;
            state.Speed = obj.getCurrentSpeed();
            state.HasValidTimer = obj.isValidTimer();
            
            if ~isempty(obj.Engine)
                state.Progress = obj.Engine.getProgress();
                state.IsComplete = obj.Engine.isAnimationComplete();
            else
                state.Progress = 0;
                state.IsComplete = false;
            end
        end
    end

    methods (Access = private)
        function createTimer(obj)
            % Create new timer with enhanced settings for smooth animation
            obj.stopTimer();
            
            try
                % Improved period calculation for smoother animation
                base_period = max(0.05, 0.5 / obj.SpeedMultiplier); % Minimum 50ms for smoothness
                
                obj.AnimationTimer = timer(...
                    'ExecutionMode', 'fixedRate', ...
                    'BusyMode', 'queue', ...  % Changed from 'drop' to 'queue' for smoother animation
                    'Period', base_period, ...
                    'TimerFcn', @(src, evt) obj.safeAnimationStep(), ...
                    'StopFcn', @(src, evt) obj.handleTimerStop(), ...
                    'ErrorFcn', @(src, evt) obj.handleTimerError(evt));
                    
                fprintf('AnimationController: Timer created with period %.3f seconds\n', base_period);
            catch ME
                error('AnimationController:TimerCreationFailed', ...
                    'Failed to create timer: %s', ME.message);
            end
        end

        function safeAnimationStep(obj)
            % Wrapper for animation step with error handling
            try
                obj.animationStep();
            catch ME
                obj.updateStatus(['Animation step error: ' ME.message]);
                obj.stopTimer();
                obj.State = 'idle';
                obj.IsRunning = false;
            end
        end

        function animationStep(obj)
            % Enhanced animation step with better visualization
            if ~obj.Engine.IsInitialized
                obj.completeAnimation();
                return;
            end
            
            % Get step results from engine
            [y_n, h_shifted, product, current_n] = obj.Engine.computeStep();
            
            % Check if animation is complete
            if obj.Engine.isAnimationComplete()
                obj.completeAnimation();
                return;
            end
            
            % FIXED: Update plots with all parameters including current index
            if ~isempty(obj.Plotter) && isvalid(obj.Plotter)
                current_idx = obj.Engine.current_index - 1; % Get correct current index
                obj.Plotter.updateAnimationStep(h_shifted, product, y_n, current_n, current_idx);
            end
            
            % Update status with current values
            if isfinite(y_n) && isfinite(current_n)
                obj.updateStatus(sprintf('n=%.2f, y[n]=%.4f', current_n, y_n));
            else
                obj.updateStatus('Processing step...');
            end
        end

        function completeAnimation(obj)
            % Handle animation completion
            obj.stopTimer();
            obj.IsRunning = false;
            obj.State = 'completed';
            obj.updateStatus('Animation completed.');
            
            % Call completion callback if set
            if ~isempty(obj.CompletionCallback)
                try
                    obj.CompletionCallback();
                catch ME
                    warning('AnimationController:CallbackError', ...
                        'Error in completion callback: %s', ME.message);
                end
            end
        end

        function handleTimerError(obj, errEvent)
            % Handle timer errors
            msg = 'Timer error occurred';
            try
                if ~isempty(errEvent) && isstruct(errEvent) && isfield(errEvent, 'Data')
                    if isfield(errEvent.Data, 'message')
                        msg = errEvent.Data.message;
                    elseif isfield(errEvent.Data, 'identifier')
                        msg = sprintf('Timer error: %s', errEvent.Data.identifier);
                    end
                end
            catch
                % Use default message if error parsing fails
            end
            
            obj.updateStatus(['Timer Error: ' msg '. Animation stopped.']);
            obj.stopTimer();
            obj.State = 'idle';
            obj.IsRunning = false;
        end

        function handleTimerStop(obj)
            % Handle timer stop events
            if strcmp(obj.State, 'running')
                obj.IsRunning = false;
                obj.State = 'paused';
            end
        end

        function stopTimer(obj)
            % Safely stop and delete timer
            if ~isempty(obj.AnimationTimer)
                try
                    if isvalid(obj.AnimationTimer)
                        if strcmp(obj.AnimationTimer.Running, 'on')
                            stop(obj.AnimationTimer);
                        end
                        delete(obj.AnimationTimer);
                    end
                catch ME
                    warning('AnimationController:TimerStopError', ...
                        'Error stopping timer: %s', ME.message);
                end
                obj.AnimationTimer = [];
            end
        end

        function isValid = isValidTimer(obj)
            % Check if timer is valid and usable
            isValid = ~isempty(obj.AnimationTimer) && ...
                      isvalid(obj.AnimationTimer) && ...
                      isa(obj.AnimationTimer, 'timer');
        end

        function updateStatus(obj, msg)
            % Update status with callback if available
            if ~isempty(obj.StatusCallback)
                try
                    obj.StatusCallback(msg);
                catch ME
                    warning('AnimationController:StatusCallbackError', ...
                        'Error in status callback: %s', ME.message);
                end
            end
        end
    end
end