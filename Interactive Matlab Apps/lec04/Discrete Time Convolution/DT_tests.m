classdef DT_tests < matlab.unittest.TestCase
    % runModularTests - Final corrected unit test suite
    % All expectations fixed to match mathematical definitions

    properties
        Parser DT_signal_parser
        Engine DT_convolution_engine
        Presets DT_preset_manager
    end

    methods (TestMethodSetup)
        function createComponents(testCase)
            % Create fresh instances for each test
            testCase.Parser = DT_signal_parser();
            testCase.Engine = DT_convolution_engine();
            testCase.Presets = DT_preset_manager();
        end
    end

    methods (Test)
        function testSignalParser_DirectVector(testCase)
            % Test direct vector parsing
            n_vec = -5:5;
            signal = testCase.Parser.parseSignal('[1, 2, 1]', n_vec);
            expected = zeros(1, 11);
            expected(1:3) = [1 2 1];
            testCase.verifyEqual(signal, expected, ...
                'Direct vector values are not positioned correctly.');
        end

        function testSignalParser_DirectVector_ZeroPadding(testCase)
            % Test zero padding for shorter vectors
            n_vec = -2:2; % 5 elements

            % Input has 3 elements, should be zero padded
            signal = testCase.Parser.parseSignal('[1, 2, 3]', n_vec);
            expected = [1, 2, 3, 0, 0]; % Zero padded to length 5
            testCase.verifyEqual(signal, expected, ...
                'Zero padding not working correctly.');
        end

        function testSignalParser_DirectVector_Truncation(testCase)
            % Test vector truncation when input is longer than time vector
            n_vec = -2:2; % 5 elements

            % Input has 7 elements, should be truncated with warning
            warning('off', 'SignalParser:VectorTruncated');
            signal = testCase.Parser.parseSignal('[1, 2, 3, 4, 5, 6, 7]', n_vec);
            warning('on', 'SignalParser:VectorTruncated');

            expected = [1, 2, 3, 4, 5]; % Only first 5 elements
            testCase.verifyEqual(signal, expected, ...
                'Vector truncation not working correctly.');
        end

        function testSignalParser_TimeVector(testCase)
            % Test various time vector formats
            testCase.verifyEqual(testCase.Parser.safeParseTimeVector('-2:2'), -2:2);
            testCase.verifyEqual(testCase.Parser.safeParseTimeVector('[-5 0 5]'), [-5 0 5]);
            testCase.verifyEqual(testCase.Parser.safeParseTimeVector('-4:2:4'), -4:2:4);
        end

        function testSignalParser_TimeVector_EdgeCases(testCase)
            % Test edge cases for time vector parsing

            % Single value
            testCase.verifyEqual(testCase.Parser.safeParseTimeVector('5'), 5);

            % Scientific notation
            testCase.verifyEqual(testCase.Parser.safeParseTimeVector('[1e-3 2E+1]'), [1e-3 2E+1], ...
                'AbsTol', 1e-10);

            % Empty bracket should throw error
            testCase.verifyError(@() testCase.Parser.safeParseTimeVector('[]'), ...
                'SignalParser:InvalidTimeVector');
        end

        function testSignalParser_Symbolic_Fixed(testCase)
            % Test symbolic expression parsing with correct implementation
            n_vec = -5:5; % [-5 -4 -3 -2 -1 0 1 2 3 4 5]

            % Unit step function u[n-2]: should be 1 when n-2 >= 0, i.e., n >= 2
            signal1 = testCase.Parser.parseSignal('u[n-2]', n_vec);
            expected1 = double(n_vec >= 2); % [0 0 0 0 0 0 0 1 1 1 1]
            testCase.verifyEqual(signal1, expected1, 'u[n-2] parsing failed.');

            % Simple exponential: 0.8^n
            signal2 = testCase.Parser.parseSignal('0.8^n', n_vec);
            expected2 = (0.8).^n_vec;
            testCase.verifyEqual(signal2, expected2, 'AbsTol', 1e-9, ...
                'Simple exponential 0.8^n parsing failed.');
        end

        function testSignalParser_SymbolicAdvanced_Fixed(testCase)
            % Test advanced symbolic expressions with correct expectations
            n_vec = -3:3; % [-3 -2 -1 0 1 2 3]

            % Delta function: delta[n-1] should be 1 when n-1 = 0, i.e., when n = 1
            signal1 = testCase.Parser.parseSignal('delta[n-1]', n_vec);
            expected1 = zeros(size(n_vec));
            expected1(n_vec == 1) = 1; % [0 0 0 0 1 0 0] - 1 at position where n=1
            testCase.verifyEqual(signal1, expected1, 'Delta function delta[n-1] parsing failed.');

            % Trigonometric function: sin[n]
            signal2 = testCase.Parser.parseSignal('sin[n]', n_vec);
            expected2 = sin(n_vec);
            testCase.verifyEqual(signal2, expected2, 'AbsTol', 1e-9, ...
                'Trigonometric function sin[n] parsing failed.');

            % FIXED: Simple addition: n + u[n]
            signal3 = testCase.Parser.parseSignal('n + u[n]', n_vec);
            expected3 = n_vec + double(n_vec >= 0);
            % For n_vec = [-3 -2 -1 0 1 2 3]:
            % n_vec = [-3 -2 -1 0 1 2 3]
            % u[n] = [0 0 0 1 1 1 1] (1 when n >= 0)  
            % n + u[n] = [-3 -2 -1 1 2 3 4]
            testCase.verifyEqual(signal3, expected3, 'AbsTol', 1e-9, ...
                'Addition expression n + u[n] parsing failed.');
        end

        function testSignalParser_CompoundExpressions(testCase)
            % Test compound expressions
            n_vec = -2:3; % [-2 -1 0 1 2 3]

            % Compound: 0.8^n * u[n]
            signal1 = testCase.Parser.parseSignal('0.8^n*u[n]', n_vec);
            expected1 = (0.8).^n_vec .* double(n_vec >= 0);
            testCase.verifyEqual(signal1, expected1, 'AbsTol', 1e-9, ...
                'Compound expression 0.8^n*u[n] parsing failed.');

            % Another compound: n * u[n-1]
            signal2 = testCase.Parser.parseSignal('n*u[n-1]', n_vec);
            expected2 = n_vec .* double(n_vec >= 1);
            testCase.verifyEqual(signal2, expected2, 'AbsTol', 1e-9, ...
                'Compound expression n*u[n-1] parsing failed.');
        end

        function testSignalParser_ErrorHandling(testCase)
            % Test error handling in parser
            n_vec = -2:2;

            % Empty input
            testCase.verifyError(@() testCase.Parser.parseSignal('', n_vec), ...
                'SignalParser:ParseError');

            % Invalid function
            testCase.verifyError(@() testCase.Parser.parseSignal('invalid_func[n]', n_vec), ...
                'SignalParser:ParseError');
        end

        function testConvolutionEngine_Initialization(testCase)
            % Test engine initialization with zero padding
            [x_str, h_str, n_str] = testCase.Presets.getPreset('Basic Rectangular Pulses');
            n_vec = testCase.Parser.safeParseTimeVector(n_str);
            x_sig = testCase.Parser.parseSignal(x_str, n_vec);
            h_sig = testCase.Parser.parseSignal(h_str, n_vec);

            testCase.Engine.initialize(x_sig, h_sig, n_vec);
            testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                'Engine should be initialized.');

            % Verify output length is reasonable
            testCase.verifyGreaterThan(testCase.Engine.OutputLength, 0, ...
                'Output length should be positive.');
        end

        function testConvolutionEngine_DifferentLengthSignals(testCase)
            % Test engine with different length signals (zero padding)
            n_vec = 0:5;
            x_sig = [1, 2]; % Length 2
            h_sig = [1, 1, 1]; % Length 3

            % Should work with zero padding
            testCase.Engine.initialize(x_sig, h_sig, n_vec);
            testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                'Engine should handle different length signals with zero padding.');
        end

        function testConvolutionEngine_InitializationErrors(testCase)
            % Test engine initialization error handling

            % Non-uniform time vector
            testCase.verifyError(@() testCase.Engine.initialize([1 2 3], [1 1 1], [0 1 3]), ...
                'ConvolutionEngine:NonUniformTimeVector');
        end

        function testConvolutionEngine_Computation_Fixed(testCase)
            % Test step-by-step computation with simple signals
            x_sig = [1, 1];
            h_sig = [1, 1];
            n_vec = 0:3;

            testCase.Engine.initialize(x_sig, h_sig, n_vec);

            y_computed = zeros(1, testCase.Engine.OutputLength);
            idx = 1;
            while ~testCase.Engine.isAnimationComplete()
                [y_n, ~, ~, ~] = testCase.Engine.computeStep();
                if ~isnan(y_n) && idx <= numel(y_computed)
                    y_computed(idx) = y_n;
                    idx = idx + 1;
                end
            end

            [~, y_final] = testCase.Engine.getCompleteOutput();
            % Only compare the computed portion
            computed_length = min(numel(y_computed), numel(y_final));
            testCase.verifyEqual(y_computed(1:computed_length), y_final(1:computed_length), 'AbsTol', 1e-9, ...
                'Step-by-step result does not match final output.');
        end

        function testConvolutionEngine_Progress(testCase)
            % Test progress tracking
            [x_str, h_str, n_str] = testCase.Presets.getPreset('Basic Rectangular Pulses');
            n_vec = testCase.Parser.safeParseTimeVector(n_str);
            x_sig = testCase.Parser.parseSignal(x_str, n_vec);
            h_sig = testCase.Parser.parseSignal(h_str, n_vec);

            testCase.Engine.initialize(x_sig, h_sig, n_vec);

            % Initial progress should be 0
            testCase.verifyEqual(testCase.Engine.getProgress(), 0, 'AbsTol', 1e-9);

            % Run a few steps and check progress increases
            prev_progress = 0;
            for i = 1:3
                if ~testCase.Engine.isAnimationComplete()
                    testCase.Engine.computeStep();
                    current_progress = testCase.Engine.getProgress();
                    testCase.verifyGreaterThanOrEqual(current_progress, prev_progress, ...
                        'Progress should not decrease');
                    prev_progress = current_progress;
                end
            end
        end

        function testConvolutionEngine_StateValidation(testCase)
            % Test state validation
            testCase.verifyTrue(testCase.Engine.validateState(), ...
                'Uninitialized engine should have valid state.');

            % Initialize with zero padding test
            x_sig = [1 2];
            h_sig = [1 1 1];
            n_vec = 0:4;
            testCase.Engine.initialize(x_sig, h_sig, n_vec);

            testCase.verifyTrue(testCase.Engine.validateState(), ...
                'Initialized engine should have valid state.');
        end

        function testPresetManager_Functionality(testCase)
            % Test preset manager functionality

            % Get available presets
            presets = testCase.Presets.getAvailablePresets();
            testCase.verifyTrue(iscell(presets));
            testCase.verifyTrue(ismember('Custom', presets));
            testCase.verifyGreaterThan(numel(presets), 1);

            % Test custom preset
            [x_str, h_str, n_str, desc] = testCase.Presets.getPreset('Custom');
            testCase.verifyEqual(x_str, '');
            testCase.verifyEqual(h_str, '');
            testCase.verifyEqual(n_str, '');
            testCase.verifyTrue(contains(desc, 'Custom'));

            % Test valid preset
            [x_str, h_str, n_str, desc] = testCase.Presets.getPreset('Basic Rectangular Pulses');
            testCase.verifyNotEqual(x_str, '');
            testCase.verifyNotEqual(h_str, '');
            testCase.verifyNotEqual(n_str, '');
            testCase.verifyNotEqual(desc, '');
        end

        function testPresetManager_Validation(testCase)
            % Test preset validation

            % Valid preset should validate
            testCase.verifyTrue(testCase.Presets.validatePreset('Basic Rectangular Pulses'));

            % Invalid preset should not validate  
            testCase.verifyFalse(testCase.Presets.validatePreset('NonExistentPreset'));

            % Custom should validate (returns empty strings)
            testCase.verifyTrue(testCase.Presets.validatePreset('Custom'));
        end

        function testIntegration_FullWorkflow_Fixed(testCase)
            % Test complete workflow integration - fixed for proper length matching
            
            % Use simple signals that we can predict exactly
            x_sig = [1, 1];
            h_sig = [1, 1];
            n_vec = 0:3;
            
            testCase.Engine.initialize(x_sig, h_sig, n_vec);

            % Run complete animation
            while ~testCase.Engine.isAnimationComplete()
                testCase.Engine.computeStep();
            end

            % Get results
            [~, y_engine] = testCase.Engine.getCompleteOutput();
            y_matlab = testCase.Engine.computeMatlabConvolution();

            % For x=[1,1] and h=[1,1], conv should give [1,2,1]
            testCase.verifyEqual(numel(y_engine), numel(y_matlab), ...
                'Output length should match MATLAB conv() length.');
            
            testCase.verifyEqual(y_engine, y_matlab, 'AbsTol', 1e-10, ...
                'Final engine output does not match MATLAB conv().');
        end

        function testConvolutionMathematics_ImpulseResponse(testCase)
            % Test convolution mathematics with impulse response
            x_sig = [1]; % delta[n]
            h_sig = [1, 0.5, 0.25]; % System impulse response
            n_vec = 0:2;
            
            testCase.Engine.initialize(x_sig, h_sig, n_vec);
            
            % For delta[n] * h[n], result should be h[n]
            [~, y_engine] = testCase.Engine.getCompleteOutput();
            y_matlab = testCase.Engine.computeMatlabConvolution();
            
            testCase.verifyEqual(y_engine, y_matlab, 'AbsTol', 1e-10, ...
                'Impulse response convolution should match MATLAB conv().');
        end

        function testConvolutionMathematics_StepResponse(testCase)
            % Test convolution mathematics with step response
            x_sig = [1, 1, 1]; % u[n] for n=0,1,2
            h_sig = [1, 0.5]; % System impulse response
            n_vec = 0:2;
            
            testCase.Engine.initialize(x_sig, h_sig, n_vec);
            
            % Run complete animation
            while ~testCase.Engine.isAnimationComplete()
                testCase.Engine.computeStep();
            end
            
            [~, y_engine] = testCase.Engine.getCompleteOutput();
            y_matlab = testCase.Engine.computeMatlabConvolution();
            
            testCase.verifyEqual(y_engine, y_matlab, 'AbsTol', 1e-10, ...
                'Step response convolution should match MATLAB conv().');
        end

        function testConvolutionMathematics_TimeIndexing(testCase)
            % Test convolution mathematics with proper time indexing
            x_sig = [1, 2, 3];
            h_sig = [1, 1];
            n_vec = 0:2;
            
            testCase.Engine.initialize(x_sig, h_sig, n_vec);
            
            % Get output time range
            [n_out, y_engine] = testCase.Engine.getCompleteOutput();
            y_matlab = testCase.Engine.computeMatlabConvolution();
            
            % Check that time indexing is correct
            expected_length = length(x_sig) + length(h_sig) - 1;
            testCase.verifyEqual(length(y_engine), expected_length, ...
                'Output length should be L+M-1 for signals of length L and M.');
            
            testCase.verifyEqual(y_engine, y_matlab, 'AbsTol', 1e-10, ...
                'Time-indexed convolution should match MATLAB conv().');
        end

        function testIntegration_MultiplePresets(testCase)
            % Test workflow with multiple presets
            preset_names = {'Triangular Wave Processing', 'Basic Rectangular Pulses'};

            for i = 1:numel(preset_names)
                preset_name = preset_names{i};

                % Test if preset exists
                if testCase.Presets.validatePreset(preset_name)
                    [x_str, h_str, n_str] = testCase.Presets.getPreset(preset_name);
                    n_vec = testCase.Parser.safeParseTimeVector(n_str);

                    x_sig = testCase.Parser.parseSignal(x_str, n_vec);
                    h_sig = testCase.Parser.parseSignal(h_str, n_vec);

                    testCase.Engine.initialize(x_sig, h_sig, n_vec);

                    % Verify initialization
                    testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                        sprintf('Engine should be initialized for preset: %s', preset_name));

                    % Run a few steps
                    step_count = 0;
                    while ~testCase.Engine.isAnimationComplete() && step_count < 5
                        [y_n, ~, ~, ~] = testCase.Engine.computeStep();

                        % Basic sanity checks
                        if ~isnan(y_n)
                            testCase.verifyTrue(isfinite(y_n), ...
                                sprintf('y_n should be finite for preset: %s', preset_name));
                        end

                        step_count = step_count + 1;
                    end

                    % Reset for next test
                    testCase.Engine.reset();
                end
            end
        end

        function testRobustness_EdgeCases(testCase)
            % Test robustness with edge cases

            % Zero signals - suppress expected warning
            warning('off', 'ConvolutionEngine:ZeroSignals');
            testCase.Engine.initialize(zeros(1,5), zeros(1,5), 0:4);
            warning('on', 'ConvolutionEngine:ZeroSignals');
            testCase.verifyTrue(testCase.Engine.IsInitialized);

            [y_n, ~, ~, ~] = testCase.Engine.computeStep();
            testCase.verifyEqual(y_n, 0, 'AbsTol', 1e-10);

            % Single element signals
            testCase.Engine.reset();
            testCase.Engine.initialize(1, 2, 0);
            testCase.verifyTrue(testCase.Engine.IsInitialized);

            % Very small signals
            testCase.Engine.reset();
            small_sig = 1e-10 * ones(1,3);
            warning('off', 'ConvolutionEngine:ZeroSignals');
            testCase.Engine.initialize(small_sig, small_sig, 0:2);
            warning('on', 'ConvolutionEngine:ZeroSignals');
            testCase.verifyTrue(testCase.Engine.IsInitialized);
        end

        function testDecimalParsing(testCase)
            % Test parsing of decimal numbers like .5, .7
            n_vec = -2:2;

            % Test leading decimal
            signal = testCase.Parser.parseSignal('[.5, 1, .75]', n_vec);
            expected = [0.5, 1, 0.75, 0, 0]; % Zero padded
            testCase.verifyEqual(signal, expected, 'AbsTol', 1e-10, ...
                'Leading decimal parsing with zero padding failed.');
        end
    end

    methods (TestMethodTeardown)
        function cleanupComponents(testCase)
            % Clean up after each test
            if ~isempty(testCase.Engine)
                testCase.Engine.reset();
            end
        end
    end
end