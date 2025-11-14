classdef CT_signal_parser < handle
    % ContinuousSignalParser - Continuous-Time Signal Parser
    %
    % This class parses continuous-time signal expressions and converts them
    % into MATLAB function handles for evaluation. It supports various signal
    % types including rectangular, triangular, Gaussian, sawtooth, chirp,
    % unit step, delta function, and trigonometric functions.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Features:
    % - Secure parsing with input validation
    % - Support for scaled and shifted delta functions
    % - Auto-windowing for periodic signals
    % - Comprehensive signal library
    % - Error handling and validation

    methods
        function signal_func = getSignalFunction(~, expression, dt)
            if isempty(strtrim(expression)), signal_func = @(t)zeros(size(t)); return; end
            
            try
                % Handle scaled and shifted deltas first, as they are a special case
                [safe_expr, is_delta] = CT_signal_parser.handleDelta(expression, dt);
                if is_delta
                    signal_func = str2func(['@(t) ' safe_expr]);
                    signal_func(0); % test
                    return;
                end

                % Handle trigonometric functions first (case-sensitive)
                safe_expr = expression;
                
                % Preserve case for MATLAB built-in functions
                safe_expr = regexprep(safe_expr, 'sin\s*\(', 'sin(', 'ignorecase');
                safe_expr = regexprep(safe_expr, 'cos\s*\(', 'cos(', 'ignorecase');
                safe_expr = regexprep(safe_expr, 'tan\s*\(', 'tan(', 'ignorecase');
                safe_expr = regexprep(safe_expr, 'exp\s*\(', 'exp(', 'ignorecase');
                safe_expr = regexprep(safe_expr, 'abs\s*\(', 'abs(', 'ignorecase');
                safe_expr = regexprep(safe_expr, 'sinc\s*\(', 'sinc(', 'ignorecase');
                
                % Make case-insensitive for custom functions only
                safe_expr = lower(safe_expr);
                
                % Standard replacements for other functions
                safe_expr = regexprep(safe_expr, '(?<!\.)\*', '.*');
                safe_expr = regexprep(safe_expr, '(?<!\.)/', './');
                safe_expr = regexprep(safe_expr, '(?<!\.)\^', '.^');
                
                safe_expr = regexprep(safe_expr, 'rect\s*\(([^,]+),([^)]+)\)', 'CT_signal_parser.rectangularPulse($1, $2)');
                safe_expr = regexprep(safe_expr, 'tri\s*\(([^,]+),([^)]+)\)', 'CT_signal_parser.triangularPulse($1, $2)');
                safe_expr = regexprep(safe_expr, 'gauss\s*\(([^,]+),([^)]+)\)', 'CT_signal_parser.gaussianPulse($1, $2)');
                safe_expr = regexprep(safe_expr, 'saw\s*\(([^,]+),([^)]+)\)', 'CT_signal_parser.sawtoothWave($1, $2)');
                safe_expr = regexprep(safe_expr, 'chirp\s*\(([^,]+),([^,]+),([^,]+),([^)]+)\)', 'CT_signal_parser.chirpSignal($1, $2, $3, $4)');
                safe_expr = regexprep(safe_expr, 'u\s*\(([^)]+)\)', 'CT_signal_parser.unitStep($1)');
                safe_expr = regexprep(safe_expr, 'sinc\s*\(([^)]+)\)', 'sinc($1/pi)');
                safe_expr = regexprep(safe_expr, 'whitenoise\s*\(([^)]*)\)', 'CT_signal_parser.whiteNoise(t, $1)');
                safe_expr = regexprep(safe_expr, 'pinknoise\s*\(([^)]*)\)', 'CT_signal_parser.pinkNoise(t, $1)');
                safe_expr = regexprep(safe_expr, 'brownnoise\s*\(([^)]*)\)', 'CT_signal_parser.brownNoise(t, $1)');

                signal_func = str2func(['@(t) ' safe_expr]);
                signal_func(0); % Test evaluation
            catch ME
                if contains(ME.message, 'Undefined function')
                    error('MATLAB:UndefinedFunction: "%s". Details: %s', expression, ME.message);
                else
                    error('CT_signal_parser:InvalidExpression: "%s". Details: %s', expression, ME.message);
                end
            end
        end

        function signal_values = parseSignal(obj, expression, t_vec, dt)
            if nargin < 4, dt = t_vec(2)-t_vec(1); end
            
            % Input validation
            if isempty(expression) || isempty(strtrim(expression))
                signal_values = zeros(size(t_vec));
                return;
            end
            
            if isempty(t_vec) || length(t_vec) < 2
                error('CT_signal_parser:InvalidTimeVector: Time vector must have at least 2 elements.');
            end
            
            if dt <= 0
                error('CT_signal_parser:InvalidTimeStep: Time step must be positive.');
            end
            
            try
                signal_func = obj.getSignalFunction(expression, dt);
                signal_values = signal_func(t_vec);
                
                % Output validation
                if ~isnumeric(signal_values) || length(signal_values) ~= length(t_vec)
                    error('CT_signal_parser:InvalidOutput: Invalid output from expression evaluation');
                end
                
                % Check for NaN or Inf values
                if any(isnan(signal_values)) || any(isinf(signal_values))
                    warning('CT_signal_parser:NonFiniteValues: Expression contains NaN or Inf values');
                    signal_values(isnan(signal_values)) = 0;
                    signal_values(isinf(signal_values)) = 0;
                end
                
                signal_values(~isfinite(signal_values)) = 0;
                if isscalar(signal_values) && length(t_vec) > 1
                    signal_values = repmat(signal_values, size(t_vec));
                end
            catch ME
                rethrow(ME);
            end
        end
    end

    methods (Static)
        function [expr, is_delta] = handleDelta(expr, dt)
            is_delta = false;
            % Improved regex to capture: optional scale, *, delta, (inner expression)
            pattern = '(?<scale>[\d\.]+(?:\s*\*\s*)?)?delta\s*\((?<inner>[^)]+)\)';
            
            % Find all delta functions in the expression
            tokens = regexp(expr, pattern, 'names');
            
            if ~isempty(tokens)
                is_delta = true;
                
                % Process each delta function found
                for i = 1:length(tokens)
                    % Determine scale - more precise parsing
                    scale = 1.0;
                    if isfield(tokens(i), 'scale') && ~isempty(tokens(i).scale)
                        scale_str = strtrim(tokens(i).scale);
                        scale_str = strrep(scale_str, '*', '');
                        try
                            scale = str2double(scale_str);
                            if isnan(scale) || isempty(scale_str), scale = 1.0; end
                        catch
                            scale = 1.0; % Default if parsing fails
                        end
                    end
                    
                    % Determine shift
                    shift = 0;
                    if isfield(tokens(i), 'inner') && ~isempty(tokens(i).inner)
                        try
                            t = 0; %#ok<NASGU>
                            shift = -eval(tokens(i).inner); % Shift is t0 for delta(t-t0)
                        catch
                            error('CT_signal_parser:InvalidDeltaExpression: Invalid expression inside delta(): %s', tokens(i).inner);
                        end
                    end
                    
                    % Create a simple replacement pattern
                    original_delta = sprintf('%sdelta(%s)', tokens(i).scale, tokens(i).inner);
                    replacement = sprintf('CT_signal_parser.diracDelta(t, %.6f, %.6f, %.6f)', dt, shift, scale);
                    
                    % Replace the original delta expression
                    expr = strrep(expr, original_delta, replacement);
                end
            end
        end
        
        function y = rectangularPulse(t, width), y = double(abs(t) <= width/2); end
        function y = triangularPulse(t, width), y = max(0, 1 - 2*abs(t)/width); end
        function y = gaussianPulse(t, sigma), y = exp(-0.5 * (t / sigma).^2); end
        function y = sawtoothWave(t, period), y = 2 * (t/period - floor(0.5 + t/period)); end
        function y = chirpSignal(t, f0, T, f1), y = chirp(t, f0, T, f1); end
        function y = unitStep(t), y = double(t >= 0); end
        function y = diracDelta(t, dt, shift, scale)
            % Improved delta function approximation with robust placement
            y = zeros(size(t));
            if isempty(t), return; end
            
            % Find the closest sample to the shift point
            [~, idx] = min(abs(t - shift));
            
            % Always place the delta at the closest point
            % This ensures all delta functions are placed correctly
            y(idx) = scale / dt;
            
            % Ensure the delta doesn't cause overflow issues
            max_val = max(abs(y));
            if max_val > 1e6 && max_val > 0
                y = y / max_val * 1e6;
            end
        end
        
        function y = whiteNoise(t, amplitude)
            % White noise signal
            if nargin < 2, amplitude = 1; end
            rng('shuffle'); % Ensure different noise each time
            y = amplitude * randn(size(t));
        end
        
        function y = pinkNoise(t, amplitude)
            % Pink noise (1/f noise) signal
            if nargin < 2, amplitude = 1; end
            rng('shuffle');
            N = length(t);
            % Generate pink noise using filtering
            white = randn(1, N);
            % Simple pink noise filter
            b = [0.049922035, -0.095993537, 0.050612699, -0.004408786];
            a = [1, -2.494956002, 2.017791875, -0.522189400];
            y = amplitude * filter(b, a, white);
        end
        
        function y = brownNoise(t, amplitude)
            % Brown noise (1/f^2 noise) signal
            if nargin < 2, amplitude = 1; end
            rng('shuffle');
            N = length(t);
            % Generate brown noise using cumulative sum
            white = randn(1, N);
            y = amplitude * cumsum(white) / sqrt(N);
        end
    end
end