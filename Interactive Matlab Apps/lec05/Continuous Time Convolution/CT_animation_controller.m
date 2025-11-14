classdef CT_animation_controller < handle
    % ContinuousAnimationController - Animation Control for Continuous Convolution Visualizer
    %
    % This class manages the step-by-step animation of the continuous convolution process.
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
        Engine, Plotter
        State char = 'idle' % idle, running, paused, completed
        IsRunning logical = false
        SpeedMultiplier double = 1.0
    end
    
    properties (Access = private)
        AnimationTimer
        StatusCallback, CompletionCallback, ProgressCallback
        lastFrameTime = 0;
    end
    
    methods
        function initialize(obj, engine, plotter)
            obj.Engine = engine; obj.Plotter = plotter;
        end
        
        function setStatusCallback(obj, fcn), obj.StatusCallback = fcn; end
        function setCompletionCallback(obj, fcn), obj.CompletionCallback = fcn; end
        function setProgressCallback(obj, fcn), obj.ProgressCallback = fcn; end
        
        function setSpeed(obj, speed)
            obj.SpeedMultiplier = max(0.1, min(speed, 10.0));
            obj.updateTimerPeriod();
        end
        
        function start(obj)
            if obj.IsRunning || ~obj.Engine.IsInitialized, return; end
            if isempty(obj.AnimationTimer) || ~isvalid(obj.AnimationTimer), obj.createTimer(); end
            start(obj.AnimationTimer);
            obj.IsRunning = true; obj.State = 'running';
        end
        
        function pause(obj)
            if ~obj.IsRunning, return; end
            if ~isempty(obj.AnimationTimer) && isvalid(obj.AnimationTimer), stop(obj.AnimationTimer); end
            obj.IsRunning = false; obj.State = 'paused';
        end
        
        function step(obj)
            if obj.IsRunning, obj.pause(); end
            if ~obj.Engine.IsInitialized, return; end
            obj.State = 'paused';
            obj.animationStep();
        end
        
        function reset(obj)
            obj.stopTimer();
            if ~isempty(obj.Engine), obj.Engine.reset(); end
            obj.IsRunning = false; obj.State = 'idle';
        end
        
        function stepForward(obj)
            % Step forward one frame
            if ~obj.Engine.IsInitialized || obj.Engine.isAnimationComplete(), return; end
            
            [x, h_s, p, conv_val, t] = obj.Engine.computeStepForward();
            if ~isempty(x)
                obj.redrawCurrentFrame(x, h_s, p, conv_val, t);
            end
        end
        
        function stepBack(obj)
            % Step backward one frame
            if ~obj.Engine.IsInitialized || obj.Engine.current_t_index <= 1, return; end
            
            [x, h_s, p, conv_val, t] = obj.Engine.computeStepBack();
            if ~isempty(x)
                obj.redrawCurrentFrame(x, h_s, p, conv_val, t);
            end
        end
        
        function redrawCurrentFrame(obj, x, h_s, p, conv_val, t)
            % Redraw the current frame
            if isempty(obj.Plotter), return; end
            
            try
                [t_vals, y_vals] = obj.Engine.getFullResult();
                current_idx = obj.Engine.current_t_index - 1;
                
                obj.Plotter.updateAnimation(obj.Engine.tau_vector, x, h_s, p, t);
                obj.Plotter.updateOutput(t_vals, y_vals, current_idx);
                
                if ~isempty(obj.StatusCallback)
                    obj.StatusCallback(sprintf('t = %.2f, y(t) = %.4f', t, conv_val));
                end
                if ~isempty(obj.ProgressCallback)
                    obj.ProgressCallback();
                end
            catch ME
                % Handle redraw errors gracefully
                if ~isempty(obj.StatusCallback)
                    obj.StatusCallback(sprintf('Redraw error: %s', ME.message));
                end
            end
        end
        
        function delete(obj), obj.stopTimer(); end
    end
    
    methods (Access = private)
        function createTimer(obj)
            obj.stopTimer();
            period = max(0.01, 0.1 / obj.SpeedMultiplier);
            obj.AnimationTimer = timer('ExecutionMode','fixedRate', 'BusyMode','drop', ...
                'Period',period, 'TimerFcn',@(~,~)obj.animationStep());
        end
        
        function updateTimerPeriod(obj)
            if ~isempty(obj.AnimationTimer) && isvalid(obj.AnimationTimer)
                wasRunning = obj.IsRunning;
                if wasRunning, stop(obj.AnimationTimer); end
                period = max(0.001, round(0.1 / obj.SpeedMultiplier, 3)); % Round to millisecond precision
                obj.AnimationTimer.Period = period;
                if wasRunning, start(obj.AnimationTimer); end
            end
        end
        
        function animationStep(obj)
            if obj.Engine.isAnimationComplete(), obj.completeAnimation(); return; end

            try
                % Optimized animation step with reduced computation
                [x, h_s, p, conv_val, t] = obj.Engine.computeStep();
                
                % Skip zero output steps for clearer animation (optimized)
                if abs(conv_val) < 1e-6 && ~obj.Engine.isAnimationComplete()
                    % Skip up to 5 zero steps for performance
                    skip_count = 0;
                    while skip_count < 5 && ~obj.Engine.isAnimationComplete()
                        [x, h_s, p, conv_val, t] = obj.Engine.computeStep();
                        if abs(conv_val) > 1e-6 || obj.Engine.isAnimationComplete()
                            break;
                        end
                        skip_count = skip_count + 1;
                    end
                end
                
                if ~isempty(x) && ~obj.Engine.isAnimationComplete()
                    % Only update plots if not at the end
                    [t_vals, y_vals] = obj.Engine.getFullResult();
                    current_idx = obj.Engine.current_t_index - 1;
                    
                    % Batch plot updates for better performance
                    obj.Plotter.updateAnimation(obj.Engine.tau_vector, x, h_s, p, t);
                    obj.Plotter.updateOutput(t_vals, y_vals, current_idx);
                end
                
                obj.updateProgress();
                obj.updateStatus(sprintf('t = %.2f, y(t) = %.4f', t, conv_val));
                
                % Memory optimization every 100 steps
                if mod(obj.Engine.current_t_index, 100) == 0
                    obj.Engine.optimizeMemory();
                end
            catch ME
                % Handle animation errors gracefully
                obj.pause();
                obj.updateStatus(sprintf('Animation error: %s', ME.message));
            end
        end
        
        function completeAnimation(obj)
            if ~strcmp(obj.State, 'completed')
                obj.stopTimer(); obj.IsRunning = false; obj.State = 'completed';
                if ~isempty(obj.CompletionCallback), obj.CompletionCallback(); end
            end
        end
        
        function stopTimer(obj)
            if ~isempty(obj.AnimationTimer) && isvalid(obj.AnimationTimer)
                stop(obj.AnimationTimer); delete(obj.AnimationTimer);
                obj.AnimationTimer = [];
            end
        end
        
        function updateStatus(obj, msg), if ~isempty(obj.StatusCallback), obj.StatusCallback(msg); end, end
        function updateProgress(obj), if ~isempty(obj.ProgressCallback), obj.ProgressCallback(); end, end
    end
end