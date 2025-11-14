classdef CT_tests < matlab.unittest.TestCase
    % CT_tests - Comprehensive Unit Test Suite for Continuous Convolution Visualizer
    %
    % This class provides comprehensive testing for all components of the
    % Continuous Convolution Visualizer, matching the structure and coverage
    % of the Discrete Time tests.
    %
    % Author: Ahmed Rabei - TEFO, 2025

    properties
        Parser CT_signal_parser
        Engine CT_convolution_engine
        Presets CT_preset_manager
        Plotter CT_plot_manager
        Animator CT_animation_controller
    end

    methods (TestMethodSetup)
        function createComponents(testCase)
            % Create fresh instances for each test
            testCase.Parser = CT_signal_parser();
            testCase.Engine = CT_convolution_engine();
            testCase.Presets = CT_preset_manager();
            testCase.Plotter = CT_plot_manager();
            testCase.Animator = CT_animation_controller();
        end
    end

    methods (Test)
        function testSignalParser_RectangularPulse(testCase)
            % Test rectangular pulse parsing
            t = -5:0.1:5;
            dt = 0.1;
            signal = testCase.Parser.parseSignal('rect(t,2)', t, dt);
            
            % Check that signal is 1 where |t| <= 1, 0 elsewhere
            expected = double(abs(t) <= 1);
            testCase.verifyEqual(signal, expected, 'AbsTol', 1e-10, ...
                'Rectangular pulse not parsed correctly.');
        end

        function testSignalParser_TriangularPulse(testCase)
            % Test triangular pulse parsing
            t = -3:0.1:3;
            dt = 0.1;
            signal = testCase.Parser.parseSignal('tri(t,2)', t, dt);
            
            % Check triangular pulse shape
            expected = max(0, 1 - abs(t));
            testCase.verifyEqual(signal, expected, 'AbsTol', 1e-10, ...
                'Triangular pulse not parsed correctly.');
        end

        function testSignalParser_UnitStep(testCase)
            % Test unit step function parsing
            t = -2:0.1:2;
            dt = 0.1;
            signal = testCase.Parser.parseSignal('u(t)', t, dt);
            
            % Check unit step: 1 for t >= 0, 0 for t < 0
            expected = double(t >= 0);
            testCase.verifyEqual(signal, expected, 'AbsTol', 1e-10, ...
                'Unit step function not parsed correctly.');
        end

        function testSignalParser_Exponential(testCase)
            % Test exponential function parsing
            t = 0:0.1:2;
            dt = 0.1;
            signal = testCase.Parser.parseSignal('exp(-t)', t, dt);
            
            % Check exponential decay
            expected = exp(-t);
            testCase.verifyEqual(signal, expected, 'AbsTol', 1e-10, ...
                'Exponential function not parsed correctly.');
        end

        function testSignalParser_ComplexExpression(testCase)
            % Test complex expression parsing
            t = -2:0.1:2;
            dt = 0.1;
            signal = testCase.Parser.parseSignal('exp(-t).*u(t)', t, dt);
            
            % Check complex expression: exp(-t) for t >= 0, 0 for t < 0
            expected = exp(-t) .* double(t >= 0);
            testCase.verifyEqual(signal, expected, 'AbsTol', 1e-10, ...
                'Complex expression not parsed correctly.');
        end

        function testSignalParser_ErrorHandling(testCase)
            % Test error handling for invalid expressions
            t = -1:0.1:1;
            dt = 0.1;
            
            % Test empty expression - should return zeros
            result = testCase.Parser.parseSignal('', t, dt);
            testCase.verifyEqual(result, zeros(size(t)), 'Empty input should return zeros.');
            
            % Test invalid function - should throw an error (test that error is thrown)
            try
                testCase.Parser.parseSignal('invalid_func(t)', t, dt);
                testCase.verifyFail('Expected an error to be thrown for invalid function');
            catch ME
                testCase.verifyTrue(contains(ME.message, 'Undefined function'), ...
                    'Expected error message to contain "Undefined function"');
            end
        end

        function testConvolutionEngine_Initialization(testCase)
            % Test engine initialization
            x_expr = 'rect(t,2)';
            h_expr = 'rect(t,1)';
            t_start = -3;
            t_end = 3;
            dt = 0.1;
            
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            
            testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                'Engine should be initialized after successful initialization.');
            testCase.verifyNotEmpty(testCase.Engine.convolution_result, ...
                'Convolution result should not be empty.');
        end

        function testConvolutionEngine_InitializationErrors(testCase)
            % Test initialization error handling
            
            % Test t_start >= t_end - should throw error
            try
                testCase.Engine.initialize('rect(t,1)', 'rect(t,1)', 5, 3, 0.1);
                testCase.verifyFail('Expected an error to be thrown for invalid time range');
            catch ME
                testCase.verifyTrue(contains(ME.message, 'Time Start must be less than Time End'), ...
                    'Expected error message to contain time range validation');
            end
            
            % Test dt <= 0 - should throw error
            try
                testCase.Engine.initialize('rect(t,1)', 'rect(t,1)', -3, 3, 0);
                testCase.verifyFail('Expected an error to be thrown for invalid time step');
            catch ME
                testCase.verifyTrue(contains(ME.message, 'Time Step must be positive'), ...
                    'Expected error message to contain time step validation');
            end
        end

        function testConvolutionEngine_Computation(testCase)
            % Test convolution computation
            x_expr = 'rect(t,1)';
            h_expr = 'rect(t,1)';
            t_start = -2;
            t_end = 2;
            dt = 0.1;
            
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            [y_custom, y_matlab, comparison] = testCase.Engine.getConvolutionComparison();
            
            testCase.verifyNotEmpty(y_custom, 'Custom convolution result should not be empty.');
            testCase.verifyNotEmpty(y_matlab, 'MATLAB convolution result should not be empty.');
            testCase.verifyTrue(comparison.max_error < 1e-10, ...
                'Convolution should match MATLAB result within tolerance.');
        end

        function testConvolutionEngine_StepComputation(testCase)
            % Test step-by-step computation
            x_expr = 'rect(t,1)';
            h_expr = 'rect(t,1)';
            t_start = -2;
            t_end = 2;
            dt = 0.1;
            
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            
            % Test first step
            [y_n, h_shifted, product, current_t] = testCase.Engine.computeStep();
            testCase.verifyNotEmpty(y_n, 'Step result should not be empty.');
            testCase.verifyNotEmpty(h_shifted, 'Shifted impulse response should not be empty.');
            testCase.verifyNotEmpty(product, 'Product should not be empty.');
            testCase.verifyTrue(isscalar(current_t), 'Current time should be scalar.');
        end

        function testConvolutionEngine_Progress(testCase)
            % Test progress tracking
            x_expr = 'rect(t,1)';
            h_expr = 'rect(t,1)';
            t_start = -2;
            t_end = 2;
            dt = 0.1;
            
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            
            % Test progress before any steps
            progress = testCase.Engine.getProgress();
            testCase.verifyEqual(progress, 0, 'Initial progress should be 0.');
            
            % Test progress after one step
            testCase.Engine.computeStep();
            progress = testCase.Engine.getProgress();
            testCase.verifyGreaterThan(progress, 0, 'Progress should be greater than 0 after step.');
        end

        function testConvolutionEngine_StateValidation(testCase)
            % Test state validation
            testCase.verifyFalse(testCase.Engine.IsInitialized, ...
                'Engine should not be initialized initially.');
            
            x_expr = 'rect(t,1)';
            h_expr = 'rect(t,1)';
            t_start = -2;
            t_end = 2;
            dt = 0.1;
            
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                'Engine should be initialized after initialization.');
        end

        function testPresetManager_Functionality(testCase)
            % Test preset manager basic functionality
            presets = testCase.Presets.getAvailablePresets();
            testCase.verifyNotEmpty(presets, 'Should have available presets.');
            
            % Test getting a specific preset - returns individual values, not struct
            [x_str, h_str, t_start, t_end, dt] = testCase.Presets.getPreset('Rect * Rect  ->  Triangle');
            testCase.verifyNotEmpty(x_str, 'Should return x expression.');
            testCase.verifyNotEmpty(h_str, 'Should return h expression.');
            testCase.verifyTrue(isnumeric(t_start), 'Should return numeric t_start.');
            testCase.verifyTrue(isnumeric(t_end), 'Should return numeric t_end.');
            testCase.verifyTrue(isnumeric(dt), 'Should return numeric dt.');
        end

        function testPresetManager_ErrorHandling(testCase)
            % Test preset manager error handling
            
            % Test getting non-existent preset - should throw error
            try
                testCase.Presets.getPreset('NonExistentPreset');
                testCase.verifyFail('Expected an error to be thrown for non-existent preset');
            catch ME
                testCase.verifyTrue(contains(ME.message, 'Preset not found'), ...
                    'Expected error message to contain preset not found');
            end
        end

        function testPlotManager_Initialization(testCase)
            % Test plot manager initialization
        fig = figure('Visible', 'off');
        x_ax = axes(fig);
        h_ax = axes(fig);
        anim_ax = axes(fig);
        prod_ax = axes(fig);
        out_ax = axes(fig);
        
            try
                testCase.Plotter.initialize(x_ax, h_ax, anim_ax, prod_ax, out_ax);
                testCase.verifyTrue(true, 'Plot manager should initialize successfully.');
            catch ME
                testCase.verifyFail(sprintf('Plot manager initialization failed: %s', ME.message));
            end
        
        close(fig);
        end

        function testAnimationController_Initialization(testCase)
            % Test animation controller initialization
            engine = CT_convolution_engine();
            plotter = CT_plot_manager();
            
            testCase.Animator.initialize(engine, plotter);
            testCase.verifyEqual(testCase.Animator.State, 'idle', ...
                'Initial state should be idle.');
        end

        function testAnimationController_SpeedControl(testCase)
            % Test animation speed control
            engine = CT_convolution_engine();
            plotter = CT_plot_manager();
            
            testCase.Animator.initialize(engine, plotter);
            
            % Test setting speed
            testCase.Animator.setSpeed(2.0);
            testCase.verifyEqual(testCase.Animator.SpeedMultiplier, 2.0, 'AbsTol', 1e-10, ...
                'Speed should be set to 2.0');
            
            % Test speed bounds
            testCase.Animator.setSpeed(20.0);
            testCase.verifyLessThanOrEqual(testCase.Animator.SpeedMultiplier, 10.0, ...
                'Speed should be capped at 10.0');
            
            testCase.Animator.setSpeed(0.05);
            testCase.verifyGreaterThanOrEqual(testCase.Animator.SpeedMultiplier, 0.1, ...
                'Speed should be floored at 0.1');
        end

        function testAnimationController_StateManagement(testCase)
            % Test animation state management
            engine = CT_convolution_engine();
            plotter = CT_plot_manager();
            
            testCase.Animator.initialize(engine, plotter);
            
            % Test initial state
            testCase.verifyEqual(testCase.Animator.State, 'idle', ...
                'Initial state should be idle.');
            testCase.verifyFalse(testCase.Animator.IsRunning, ...
                'Should not be running initially.');
        end

        function testIntegration_FullWorkflow(testCase)
            % Test complete workflow integration
            x_expr = 'rect(t,2)';
            h_expr = 'rect(t,1)';
            t_start = -3;
            t_end = 3;
            dt = 0.1;
            
            % Initialize engine
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                'Engine should be initialized.');
            
            % Get comparison results
            [y_custom, y_matlab, comparison] = testCase.Engine.getConvolutionComparison();
            testCase.verifyTrue(comparison.max_error < 1e-10, ...
                'Convolution should match MATLAB result.');
            
            % Test step computation
            [y_n, h_shifted, product, current_t] = testCase.Engine.computeStep();
            testCase.verifyNotEmpty(y_n, 'Step computation should work.');
        end

        function testIntegration_PresetWorkflow(testCase)
            % Test preset workflow integration
            [x_str, h_str, t_start, t_end, dt] = testCase.Presets.getPreset('Rect * Rect  ->  Triangle');
            
            % Initialize engine with preset data
            testCase.Engine.initialize(x_str, h_str, t_start, t_end, dt);
            
            testCase.verifyTrue(testCase.Engine.IsInitialized, ...
                'Engine should initialize with preset data.');
            
            % Test convolution computation
            [y_custom, y_matlab, comparison] = testCase.Engine.getConvolutionComparison();
            testCase.verifyTrue(comparison.max_error < 1e-10, ...
                'Preset convolution should match MATLAB result.');
        end

        function testErrorHandling_InvalidInputs(testCase)
            % Test error handling for various invalid inputs
            
            % Test empty expressions - should not throw error, returns zeros
            result = testCase.Parser.parseSignal('', -1:0.1:1, 0.1);
            testCase.verifyEqual(result, zeros(1, 21), 'Empty input should return zeros.');
            
            % Test invalid time range - should throw error
            try
                testCase.Engine.initialize('rect(t,1)', 'rect(t,1)', 5, 3, 0.1);
                testCase.verifyFail('Expected an error to be thrown for invalid time range');
            catch ME
                testCase.verifyTrue(contains(ME.message, 'Time Start must be less than Time End'), ...
                    'Expected error message to contain time range validation');
            end
            
            % Test invalid time step - should throw error
            try
                testCase.Engine.initialize('rect(t,1)', 'rect(t,1)', -3, 3, 0);
                testCase.verifyFail('Expected an error to be thrown for invalid time step');
            catch ME
                testCase.verifyTrue(contains(ME.message, 'Time Step must be positive'), ...
                    'Expected error message to contain time step validation');
            end
        end

        function testMathematicalCorrectness_ImpulseResponse(testCase)
            % Test mathematical correctness with impulse response
            x_expr = 'delta(t)';
            h_expr = 'rect(t,2)';
            t_start = -3;
            t_end = 3;
            dt = 0.1;
            
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            [y_custom, y_matlab, comparison] = testCase.Engine.getConvolutionComparison();
            
            % Impulse response should match the system response
            testCase.verifyTrue(comparison.max_error < 1e-10, ...
                'Impulse response should match system response.');
        end

        function testMathematicalCorrectness_Commutativity(testCase)
            % Test convolution commutativity: x*h = h*x
            x_expr = 'rect(t,1)';
            h_expr = 'rect(t,2)';
            t_start = -3;
            t_end = 3;
            dt = 0.1;
            
            % Test x*h
            testCase.Engine.initialize(x_expr, h_expr, t_start, t_end, dt);
            [y1, ~, ~] = testCase.Engine.getConvolutionComparison();
            
            % Test h*x
            testCase.Engine.initialize(h_expr, x_expr, t_start, t_end, dt);
            [y2, ~, ~] = testCase.Engine.getConvolutionComparison();
            
            % Results should be equal (commutativity)
            testCase.verifyEqual(y1, y2, 'AbsTol', 1e-10, ...
                'Convolution should be commutative.');
        end
    end
end
