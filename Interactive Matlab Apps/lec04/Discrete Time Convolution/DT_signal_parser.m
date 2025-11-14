classdef DT_signal_parser < handle
    % SignalParser - Signal Expression Parser for Convolution Visualizer
    %
    % This class parses various signal expressions and converts them to
    % discrete-time signals. It supports direct vectors, symbolic expressions,
    % and mathematical functions commonly used in signal processing.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Supported Signal Types:
    % - Direct vectors: [1, 2, 3]
    % - Unit step: u[n], u[n-k]
    % - Delta function: delta[n], delta[n-k]
    % - Exponential: 0.8^n, 0.5^n*u[n]
    % - Trigonometric: sin[n], cos[n], tan[n]
    % - Gaussian: gauss[n]
    % - Sawtooth: saw[n]
    % - Compound expressions: n + u[n], 0.8^n*u[n]
    
    methods
        function signal = parseSignal(~, input_str, n_vec)
            % Main entry point with enhanced error handling
            try
                input_str = strtrim(input_str);
                
                % Debug output
                fprintf('SignalParser: Parsing "%s" with n_vec [%.2f:%.2f] length %d\n', ...
                    input_str, min(n_vec), max(n_vec), length(n_vec));
                
                % Validate inputs
                if isempty(input_str)
                    error('SignalParser:EmptyInput', 'Input string is empty');
                end
                
                if isempty(n_vec)
                    error('SignalParser:EmptyTimeVector', 'Time vector is empty');
                end
                
                % Ensure n_vec is sorted and increasing
                if numel(n_vec) > 1 && any(diff(n_vec) <= 0)
                    warning('SignalParser:SortingTimeVector', 'Time vector was not sorted - fixing automatically');
                    n_vec = sort(n_vec);
                end
                
                % Determine parsing method
                if startsWith(input_str, '[') && endsWith(input_str, ']')
                    signal = DT_signal_parser.safeParseDirectVector(input_str, n_vec);
                else
                    signal = DT_signal_parser.parseSymbolicExpressionFixed(input_str, n_vec);
                end
                
                % Validate output
                if numel(signal) ~= numel(n_vec)
                    error('SignalParser:LengthMismatch', ...
                        'Output signal length (%d) does not match time vector length (%d)', ...
                        numel(signal), numel(n_vec));
                end
                
                if any(~isfinite(signal))
                    warning('SignalParser:NonFiniteValues', 'Signal contains non-finite values');
                    signal(~isfinite(signal)) = 0;
                end
                
                fprintf('SignalParser: Successfully parsed signal with range [%.3f, %.3f]\n', ...
                    min(signal), max(signal));
                
            catch ME
                fprintf('SignalParser Error: %s\n', ME.message);
                error('SignalParser:ParseError', 'Failed to parse signal "%s": %s', input_str, ME.message);
            end
        end
    end

    methods (Static)
        function n_vec = safeParseTimeVector(n_str)
            % Parse time vector with comprehensive validation
            try
                n_str = strtrim(n_str);
                fprintf('SignalParser: Parsing time vector "%s"\n', n_str);
                
                if isempty(n_str)
                    error('SignalParser:EmptyTimeString', 'Time vector string is empty');
                end
                
                if contains(n_str, ':')
                    n_vec = DT_signal_parser.parseColonNotation(n_str);
                elseif startsWith(n_str, '[') && endsWith(n_str, ']')
                    n_vec = DT_signal_parser.parseBracketNotation(n_str);
                else
                    n_vec = str2double(n_str);
                    if isnan(n_vec)
                        error('SignalParser:InvalidNumber', 'Cannot parse "%s" as a number', n_str);
                    end
                end
                
                % Ensure row vector
                n_vec = n_vec(:)';
                
                % FIXED: Ensure strictly increasing
                if numel(n_vec) > 1
                    if any(diff(n_vec) <= 0)
                        fprintf('Warning: Time vector was not strictly increasing - sorting...\n');
                        n_vec_original = n_vec;
                        n_vec = sort(n_vec);
                        
                        if any(diff(n_vec) <= 0)
                            n_vec = unique(n_vec);
                            fprintf('Removed duplicate values from time vector\n');
                        end
                        
                        if any(diff(n_vec) <= 0)
                            error('SignalParser:NonIncreasingAfterSort', ...
                                'Time vector cannot be made strictly increasing. Original: [%s]', ...
                                mat2str(n_vec_original));
                        end
                    end
                end
                
                % Final validation
                if isempty(n_vec)
                    error('SignalParser:EmptyResult', 'Parsed time vector is empty');
                end
                
                if ~isreal(n_vec)
                    error('SignalParser:ComplexValues', 'Time vector must be real');
                end
                
                if any(~isfinite(n_vec))
                    error('SignalParser:NonFiniteValues', 'Time vector contains non-finite values');
                end
                
                fprintf('SignalParser: Successfully parsed time vector [%.2f:%.2f] with %d points\n', ...
                    min(n_vec), max(n_vec), length(n_vec));
                
            catch ME
                fprintf('Time vector parsing error: %s\n', ME.message);
                error('SignalParser:InvalidTimeVector', 'Could not parse time vector "%s": %s', n_str, ME.message);
            end
        end

        function n_vec = parseColonNotation(n_str)
            % Parse colon notation with enhanced error checking
            try
                if count(n_str, ':') == 1
                    parts = sscanf(n_str, '%f:%f');
                    if numel(parts) ~= 2
                        error('Invalid start:end format');
                    end
                    start_val = parts(1);
                    end_val = parts(2);
                    
                    if start_val >= end_val
                        error('Start value (%.3f) must be less than end value (%.3f)', start_val, end_val);
                    end
                    
                    n_vec = start_val:end_val;
                    
                elseif count(n_str, ':') == 2
                    parts = sscanf(n_str, '%f:%f:%f');
                    if numel(parts) ~= 3
                        error('Invalid start:step:end format');
                    end
                    start_val = parts(1);
                    step_val = parts(2);
                    end_val = parts(3);
                    
                    if step_val == 0
                        error('Step size cannot be zero');
                    end
                    
                    if step_val > 0 && start_val >= end_val
                        error('For positive step, start (%.3f) must be less than end (%.3f)', start_val, end_val);
                    end
                    
                    if step_val < 0 && start_val <= end_val
                        error('For negative step, start (%.3f) must be greater than end (%.3f)', start_val, end_val);
                    end
                    
                    n_vec = start_val:step_val:end_val;
                else
                    error('Invalid colon notation - too many colons');
                end
                
                if isempty(n_vec)
                    error('Colon notation resulted in empty vector');
                end
                
            catch ME
                error('Error parsing colon notation "%s": %s', n_str, ME.message);
            end
        end

        function n_vec = parseBracketNotation(n_str)
            % Parse bracket notation with enhanced validation
            try
                content = n_str(2:end-1);
                content = strtrim(content);
                
                if isempty(content)
                    error('Empty brackets not allowed');
                end
                
                % Enhanced regex for numbers including scientific notation
                tokens = regexp(content, '[-+]?\d*\.?\d+([eE][-+]?\d+)?', 'match');
                if isempty(tokens)
                    error('No valid numbers found in brackets');
                end
                
                n_vec = str2double(tokens);
                if any(isnan(n_vec))
                    error('Invalid numbers in bracket notation');
                end
                
            catch ME
                error('Error parsing bracket notation "%s": %s', n_str, ME.message);
            end
        end

        function signal = safeParseDirectVector(input_str, n_vec)
            % Parse direct vector notation with robust error handling
            try
                values = DT_signal_parser.parseBracketNotation(input_str);
                signal = zeros(size(n_vec));
                
                if isempty(values)
                    return;
                end
                
                len_values = numel(values);
                len_n_vec = numel(n_vec);
                
                if len_values > len_n_vec
                    warning('SignalParser:VectorTruncated', ...
                        'Input vector has %d elements but time vector has only %d. Truncating.', ...
                        len_values, len_n_vec);
                    signal = values(1:len_n_vec);
                elseif len_values < len_n_vec
                    signal(1:len_values) = values;
                else
                    signal = values;
                end
                
                if numel(signal) ~= numel(n_vec)
                    error('Signal length mismatch after processing');
                end
                
            catch ME
                error('SignalParser:DirectVectorError', 'Error parsing direct vector: %s', ME.message);
            end
        end

        function result = parseSymbolicExpressionFixed(expression, n)
            % FIXED: Parse symbolic expressions with proper MATLAB functions
            try
                fprintf('SignalParser: Parsing symbolic expression "%s"\n', expression);
                
                % Remove all spaces
                expr_clean = strrep(expression, ' ', '');
                
                % Try compound expressions first - FIXED
                result = DT_signal_parser.parseCompoundExpressionFixed(expr_clean, n);
                if ~isempty(result)
                    return;
                end
                
                % Try single function expressions
                result = DT_signal_parser.parseSingleFunctionFixed(expr_clean, n);
                if ~isempty(result)
                    return;
                end
                
                % Try simple expressions
                result = DT_signal_parser.parseSimpleExpressionFixed(expr_clean, n);
                if ~isempty(result)
                    return;
                end
                
                error('Unable to parse expression "%s"', expression);
                
            catch ME
                error('SignalParser:SymbolicError', 'Error parsing symbolic expression "%s": %s', expression, ME.message);
            end
        end

        function result = parseCompoundExpressionFixed(expr, n)
            % FIXED: Handle compound expressions with proper MATLAB functions
            result = [];
            
            try
                % Pattern 1: addition (n + u[n], u[n] + 0.5*sin[0.2*n])
                if contains(expr, '+') && ~startsWith(expr, '+')
                    % Find the rightmost + that's not part of a number or function
                    plus_positions = strfind(expr, '+');
                    for i = length(plus_positions):-1:1
                        pos = plus_positions(i);
                        if pos > 1
                            % Check if this + is not part of a number or function
                            if pos == 1 || ~ismember(expr(pos-1), '0123456789eE.')
                                term1_str = strtrim(expr(1:pos-1));
                                term2_str = strtrim(expr(pos+1:end));
                                
                                term1 = DT_signal_parser.evaluateTermFixed(term1_str, n);
                                term2 = DT_signal_parser.evaluateTermFixed(term2_str, n);
                                
                                if ~isempty(term1) && ~isempty(term2)
                                    result = term1 + term2;
                                    return;
                                end
                            end
                        end
                    end
                end
                
                % Pattern 2: subtraction (n - u[n])
                if contains(expr, '-') && ~startsWith(expr, '-')
                    % Find last minus that's not part of a negative number
                    minus_positions = strfind(expr, '-');
                    for i = length(minus_positions):-1:1
                        pos = minus_positions(i);
                        if pos > 1
                            % Check if this minus is part of a number
                            if pos == 1 || ~ismember(expr(pos-1), '0123456789')
                                term1_str = expr(1:pos-1);
                                term2_str = expr(pos+1:end);
                                
                                term1 = DT_signal_parser.evaluateTermFixed(term1_str, n);
                                term2 = DT_signal_parser.evaluateTermFixed(term2_str, n);
                                
                                if ~isempty(term1) && ~isempty(term2)
                                    result = term1 - term2;
                                    return;
                                end
                            end
                        end
                    end
                end
                
                % Pattern 3: multiplication (0.8^n * u[n])
                if contains(expr, '*')
                    % FIXED: Use proper string splitting
                    mult_positions = strfind(expr, '*');
                    for i = 1:length(mult_positions)
                        pos = mult_positions(i);
                        term1_str = expr(1:pos-1);
                        term2_str = expr(pos+1:end);
                        
                        term1 = DT_signal_parser.evaluateTermFixed(term1_str, n);
                        term2 = DT_signal_parser.evaluateTermFixed(term2_str, n);
                        
                        if ~isempty(term1) && ~isempty(term2)
                            result = term1 .* term2;
                            return;
                        end
                    end
                end
                
            catch ME
                fprintf('Error in compound expression parsing: %s\n', ME.message);
            end
        end

        function result = parseSingleFunctionFixed(expr, n)
            % FIXED: Handle single function expressions with validation
            result = [];
            
            try
                % Unit step function u[n] or u[n-k]
                unit_step_pattern = '^u\[(.*?)\]$';
                match = regexp(expr, unit_step_pattern, 'tokens');
                if ~isempty(match)
                    arg_str = match{1}{1};
                    arg_val = DT_signal_parser.evaluateArgumentFixed(arg_str, n);
                    result = double(arg_val >= 0);
                    return;
                end
                
                % Delta function
                delta_pattern = '^delta\[(.*?)\]$';
                match = regexp(expr, delta_pattern, 'tokens');
                if ~isempty(match)
                    arg_str = match{1}{1};
                    arg_val = DT_signal_parser.evaluateArgumentFixed(arg_str, n);
                    result = double(abs(arg_val) < 1e-10);
                    return;
                end
                
                % Trigonometric functions
                trig_pattern = '^(sin|cos|tan)\[(.*?)\]$';
                match = regexp(expr, trig_pattern, 'tokens');
                if ~isempty(match) && numel(match{1}) == 2
                    func_name = match{1}{1};
                    arg_str = match{1}{2};
                    arg_val = DT_signal_parser.evaluateArgumentFixed(arg_str, n);
                    
                    switch func_name
                        case 'sin'
                            result = sin(arg_val);
                        case 'cos'
                            result = cos(arg_val);
                        case 'tan'
                            result = tan(arg_val);
                    end
                    return;
                end
                
                % New signal types: gauss, abs
                new_signal_pattern = '^(gauss|abs)\[(.*?)\]$';
                match = regexp(expr, new_signal_pattern, 'tokens');
                if ~isempty(match) && numel(match{1}) == 2
                    func_name = match{1}{1};
                    arg_str = match{1}{2};
                    arg_val = DT_signal_parser.evaluateArgumentFixed(arg_str, n);
                    
                    switch func_name
                        case 'gauss'
                            % Gaussian: gauss[n] = exp(-n^2/2)
                            result = exp(-arg_val.^2 / 2);
                        case 'abs'
                            % Absolute value: abs[n] = |n|
                            result = abs(arg_val);
                    end
                    return;
                end
                
                % Function composition: f[g[n]] - function of function
                composition_pattern = '^(u|delta|sin|cos|tan|gauss|abs)\[(.*?)\]$';
                match = regexp(expr, composition_pattern, 'tokens');
                if ~isempty(match) && numel(match{1}) == 2
                    outer_func = match{1}{1};
                    inner_expr = match{1}{2};
                    
                    % Check if inner expression is a function
                    inner_func_pattern = '^(u|delta|sin|cos|tan|gauss|abs)\[(.*?)\]$';
                    inner_match = regexp(inner_expr, inner_func_pattern, 'tokens');
                    
                    if ~isempty(inner_match) && numel(inner_match{1}) == 2
                        % This is a composition f[g[n]]
                        inner_func = inner_match{1}{1};
                        inner_arg = inner_match{1}{2};
                        inner_arg_val = DT_signal_parser.evaluateArgumentFixed(inner_arg, n);
                        
                        % Evaluate inner function first
                        inner_result = DT_signal_parser.evaluateInnerFunction(inner_func, inner_arg_val);
                        
                        % Then evaluate outer function
                        result = DT_signal_parser.evaluateOuterFunction(outer_func, inner_result);
                        return;
                    end
                end
                
            catch ME
                fprintf('Error in single function parsing: %s\n', ME.message);
            end
        end

        function result = parseSimpleExpressionFixed(expr, n)
            % FIXED: Handle simple expressions with error checking
            result = [];
            
            try
                if strcmp(expr, 'n')
                    result = n;
                    return;
                end
                
                % Pattern: coefficient * n
                mult_n_pattern = '^([+-]?[0-9]*\.?[0-9]+)\*n$';
                match = regexp(expr, mult_n_pattern, 'tokens');
                if ~isempty(match)
                    coeff = str2double(match{1}{1});
                    if ~isnan(coeff)
                        result = coeff * n;
                        return;
                    end
                end
                
                % Pattern: base^n
                power_pattern = '^([+-]?[0-9]*\.?[0-9]+)\^n$';
                match = regexp(expr, power_pattern, 'tokens');
                if ~isempty(match)
                    base = str2double(match{1}{1});
                    if ~isnan(base)
                        result = base .^ n;
                        return;
                    end
                end
                
                % Try constant
                const_val = str2double(expr);
                if ~isnan(const_val)
                    result = const_val * ones(size(n));
                    return;
                end
                
            catch ME
                fprintf('Error in simple expression parsing: %s\n', ME.message);
            end
        end

        function result = evaluateTermFixed(term_str, n)
            % FIXED: Safely evaluate individual terms
            result = [];
            
            try
                % Try single function first
                result = DT_signal_parser.parseSingleFunctionFixed(term_str, n);
                if ~isempty(result)
                    return;
                end
                
                % Try compound expression (for nested operations)
                result = DT_signal_parser.parseCompoundExpressionFixed(term_str, n);
                if ~isempty(result)
                    return;
                end
                
                % Try simple expression
                result = DT_signal_parser.parseSimpleExpressionFixed(term_str, n);
                if ~isempty(result)
                    return;
                end
                
            catch ME
                fprintf('Error evaluating term "%s": %s\n', term_str, ME.message);
            end
        end

        function result = evaluateArgumentFixed(arg_str, n)
            % FIXED: Safely evaluate function arguments
            try
                if strcmp(arg_str, 'n')
                    result = n;
                elseif strcmp(arg_str, '-n')
                    result = -n;
                elseif contains(arg_str, 'n')
                    % Handle common patterns safely
                    if startsWith(arg_str, 'n-')
                        offset_str = arg_str(3:end);
                        offset = str2double(offset_str);
                        if ~isnan(offset)
                            result = n - offset;
                        else
                            result = n;
                        end
                    elseif startsWith(arg_str, 'n+')
                        offset_str = arg_str(3:end);
                        offset = str2double(offset_str);
                        if ~isnan(offset)
                            result = n + offset;
                        else
                            result = n;
                        end
                    elseif contains(arg_str, '*n')
                        % FIXED: Use proper string functions
                        mult_pos = strfind(arg_str, '*n');
                        if ~isempty(mult_pos)
                            coeff_str = arg_str(1:mult_pos(1)-1);
                            coeff = str2double(coeff_str);
                            if ~isnan(coeff)
                                result = coeff * n;
                            else
                                result = n;
                            end
                        else
                            result = n;
                        end
                    else
                        result = n; % Safe fallback
                    end
                else
                    % Constant argument
                    const_val = str2double(arg_str);
                    if ~isnan(const_val)
                        result = const_val * ones(size(n));
                    else
                        result = zeros(size(n));
                    end
                end
                
                % Validate result
                if numel(result) ~= numel(n)
                    result = ones(size(n)) * result(1);
                end
                
            catch ME
                fprintf('Error evaluating argument "%s": %s\n', arg_str, ME.message);
                result = n; % Safe fallback
            end
        end

        function result = evaluateInnerFunction(func_name, arg_val)
            % Evaluate inner function for composition
            try
                switch func_name
                    case 'u'
                        result = double(arg_val >= 0);
                    case 'delta'
                        result = double(abs(arg_val) < 1e-10);
                    case 'sin'
                        result = sin(arg_val);
                    case 'cos'
                        result = cos(arg_val);
                    case 'tan'
                        result = tan(arg_val);
                    case 'abs'
                        result = abs(arg_val);
                    case 'gauss'
                        result = exp(-arg_val.^2 / 2);
                    otherwise
                        result = arg_val;
                end
            catch ME
                fprintf('Error evaluating inner function "%s": %s\n', ME.message);
                result = arg_val;
            end
        end

        function result = evaluateOuterFunction(func_name, arg_val)
            % Evaluate outer function for composition
            try
                switch func_name
                    case 'u'
                        result = double(arg_val >= 0);
                    case 'delta'
                        result = double(abs(arg_val) < 1e-10);
                    case 'sin'
                        result = sin(arg_val);
                    case 'cos'
                        result = cos(arg_val);
                    case 'tan'
                        result = tan(arg_val);
                    case 'abs'
                        result = abs(arg_val);
                    case 'gauss'
                        result = exp(-arg_val.^2 / 2);
                    otherwise
                        result = arg_val;
                end
            catch ME
                fprintf('Error evaluating outer function "%s": %s\n', ME.message);
                result = arg_val;
            end
        end
    end
end