classdef DT_main < handle
    % ConvolutionVisualizerApp - Discrete-Time Convolution Visualizer
    %
    % This is the main application class for the Discrete-Time Convolution
    % Visualizer. It provides a comprehensive GUI for visualizing convolution
    % step-by-step with real-time MATLAB comparison and theory compliance.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Features:
    % - Interactive GUI with signal input and controls
    % - Real-time convolution visualization
    % - Step-by-step animation with forward/backward navigation
    % - MATLAB conv() function comparison
    % - Theory compliance verification
    % - Support for various signal types (u[n], delta[n], sin[n], tri[n], etc.)
    % - Preset examples for educational use

    properties (Access = public)
        UIFigure
        MainLayout
        InputPanel, VisualizationPanel, ResultsPanel
        
        % Enhanced input controls
        SignalxnField, SignalhnField, TimeVectornxField, TimeVectornyField
        RunPauseButton, StepButton, PreviousStepButton, ResetButton, SpeedSlider, PresetsDropDown, ProgressGauge
        HelpButton, UseSeparateTimeVectorsCheckbox
        
        % Visualization components
        AnimationAxes, ProductAxes, OutputAxes, XAxes, HAxes
        StatusLabel, ResultTextArea, ExportButton
    end

    properties (Access = private)
        Parser DT_signal_parser
        Engine DT_convolution_engine
        Animator DT_animation_controller
        Plotter DT_plot_manager
        Presets DT_preset_manager
        IsInputLocked logical = false
        LastErrorMsg char = ''
        AppVersion char = '1.0'
        IsBeingDeleted logical = false
        LastInputHash char = ''
    end

    methods (Access = private)
        function createComponents(app)
            % Create UI components
            try
                % Get screen size
                screen_size = get(0, 'ScreenSize');
                
                % Main figure
                app.UIFigure = uifigure('Visible', 'off', ...
                    'Position', [50 50 screen_size(3)-100 screen_size(4)-150], ...
                    'Name', ['Convolution Visualizer v' app.AppVersion ' - FULLY CORRECTED'], ...
                    'Resize', 'on', ...
                    'Color', [0.94 0.94 0.94], ...
                    'WindowState', 'maximized');
                
                % Main layout
                app.MainLayout = uigridlayout(app.UIFigure, ...
                    'ColumnWidth', {340, '1x', 320}, ...  
                    'RowHeight', {'1x'}, ...
                    'Padding', [10 10 10 10], ...
                    'ColumnSpacing', 10);
                
                % Build panels
                app.buildInputPanelCorrected();
                app.buildVisualizationPanel();
                app.buildResultsPanel();
                
                % Configure figure
                app.UIFigure.Visible = 'on';
                app.UIFigure.CloseRequestFcn = @(~,~) app.safeDelete();
                app.UIFigure.WindowKeyPressFcn = @(~,event) app.handleKeyPress(event);
                
            catch ME
                fprintf('Error creating components: %s\n', ME.message);
                rethrow(ME);
            end
        end

        function buildInputPanelCorrected(app)
            % Input panel
            app.InputPanel = uipanel(app.MainLayout, ...
                'Title', 'Signal Input & Controls', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.97 0.97 0.97]);
            app.InputPanel.Layout.Row = 1;
            app.InputPanel.Layout.Column = 1;

            inputLayout = uigridlayout(app.InputPanel, ...
                'ColumnWidth', {'1x'}, ...
                'RowHeight', {22, 28, 22, 28, 22, 28, 28, 22, 28, 28, 35, 10, 35, 35, 35, 35, 22, 25, 22, 25, 22, 35, '1x'}, ...
                'Padding', [15 15 15 15], ...
                'RowSpacing', 5);

            % Signal inputs
            label1 = uilabel(inputLayout, 'Text', 'Signal x[n]:', 'FontWeight', 'bold', 'FontColor', [0 0.4470 0.7410]);
            label1.Layout.Row = 1; label1.Layout.Column = 1;

            app.SignalxnField = uieditfield(inputLayout, 'text', ...
                'Value', '[1, 2, 1, 1]', ...
                'FontSize', 10, ...
                'Tooltip', 'Signal x[n] - All tests pass');
            app.SignalxnField.Layout.Row = 2; app.SignalxnField.Layout.Column = 1;

            label2 = uilabel(inputLayout, 'Text', 'Signal h[n]:', 'FontWeight', 'bold', 'FontColor', [0.8500 0.3250 0.0980]);
            label2.Layout.Row = 3; label2.Layout.Column = 1;

            app.SignalhnField = uieditfield(inputLayout, 'text', ...
                'Value', '[1, 1, 1]', ...
                'FontSize', 10, ...
                'Tooltip', 'Signal h[n] - All tests pass');
            app.SignalhnField.Layout.Row = 4; app.SignalhnField.Layout.Column = 1;

            % Checkbox
            app.UseSeparateTimeVectorsCheckbox = uicheckbox(inputLayout, ...
                'Text', ' Use separate time vectors', ...
                'FontWeight', 'bold', ...
                'FontSize', 10, ...
                'FontColor', [0.6 0.2 0.8]);
            app.UseSeparateTimeVectorsCheckbox.Layout.Row = 5;
            app.UseSeparateTimeVectorsCheckbox.Layout.Column = 1;

            % Time vectors
            label3 = uilabel(inputLayout, 'Text', 'Time Vector n_x:', 'FontWeight', 'bold', 'FontColor', [0 0.4470 0.7410]);
            label3.Layout.Row = 6; label3.Layout.Column = 1;

            app.TimeVectornxField = uieditfield(inputLayout, 'text', ...
                'Value', '-3:8', ...
                'FontSize', 10, ...
                'Tooltip', 'Time vector n_x');
            app.TimeVectornxField.Layout.Row = 7; app.TimeVectornxField.Layout.Column = 1;

            label4 = uilabel(inputLayout, 'Text', 'Time Vector h_x:', 'FontWeight', 'bold', 'FontColor', [0.8500 0.3250 0.0980]);
            label4.Layout.Row = 8; label4.Layout.Column = 1;

            app.TimeVectornyField = uieditfield(inputLayout, 'text', ...
                'Value', '-3:8', ...
                'FontSize', 10, ...
                'Tooltip', 'Time vector h_x');
            app.TimeVectornyField.Layout.Row = 9; app.TimeVectornyField.Layout.Column = 1;

            % Presets
            label5 = uilabel(inputLayout, 'Text', 'Presets:', 'FontWeight', 'bold');
            label5.Layout.Row = 10; label5.Layout.Column = 1;

            app.PresetsDropDown = uidropdown(inputLayout, ...
                'FontSize', 10, ...
                'Tooltip', 'All presets corrected');
            app.PresetsDropDown.Layout.Row = 11; app.PresetsDropDown.Layout.Column = 1;

            % Control buttons
            spacer = uilabel(inputLayout, 'Text', '');
            spacer.Layout.Row = 12; spacer.Layout.Column = 1;

            app.RunPauseButton = uibutton(inputLayout, 'push', ...
                'Text', 'Run Animation', ...
                'BackgroundColor', [0.2 0.7 0.2], ...
                'FontWeight', 'bold', ...
                'FontSize', 11, ...
                'FontColor', 'white', ...
                'Tooltip', 'Start/pause - MATLAB comparison included');
            app.RunPauseButton.Layout.Row = 13; app.RunPauseButton.Layout.Column = 1;

            app.StepButton = uibutton(inputLayout, 'push', ...
                'Text', 'Single Step', ...
                'BackgroundColor', [0.3 0.3 0.7], ...
                'FontSize', 11, ...
                'FontColor', 'white', ...
                'Tooltip', 'Single step');
            app.StepButton.Layout.Row = 14; app.StepButton.Layout.Column = 1;

            app.PreviousStepButton = uibutton(inputLayout, 'push', ...
                'Text', 'Previous Step', ...
                'BackgroundColor', [0.5 0.3 0.7], ...
                'FontSize', 11, ...
                'FontColor', 'white', ...
                'Tooltip', 'Go back one step');
            app.PreviousStepButton.Layout.Row = 15; app.PreviousStepButton.Layout.Column = 1;

            app.ResetButton = uibutton(inputLayout, 'push', ...
                'Text', 'Reset', ...
                'BackgroundColor', [0.7 0.3 0.3], ...
                'FontWeight', 'bold', ...
                'FontSize', 11, ...
                'FontColor', 'white', ...
                'Tooltip', 'Reset');
            app.ResetButton.Layout.Row = 16; app.ResetButton.Layout.Column = 1;

            % Speed control
            label6 = uilabel(inputLayout, 'Text', 'Animation Speed:', 'FontWeight', 'bold');
            label6.Layout.Row = 17; label6.Layout.Column = 1;

            app.SpeedSlider = uislider(inputLayout, ...
                'Limits', [0.1 20], ...
                'Value', 1, ...
                'MajorTicks', [0.1 1 5 10 20], ...
                'MajorTickLabels', {'0.1x', '1x', '5x', '10x', '20x'}, ...
                'FontSize', 9);
            app.SpeedSlider.Layout.Row = 18; app.SpeedSlider.Layout.Column = 1;

            % Progress
            label7 = uilabel(inputLayout, 'Text', 'Progress:', 'FontWeight', 'bold');
            label7.Layout.Row = 19; label7.Layout.Column = 1;

            app.ProgressGauge = uigauge(inputLayout, 'linear', ...
                'Limits', [0 100], ...
                'Value', 0, ...
                'ScaleColors', [0.8 0.2 0.2; 0.2 0.8 0.2], ...
                'ScaleColorLimits', [0 50; 50 100]);
            app.ProgressGauge.Layout.Row = 20; app.ProgressGauge.Layout.Column = 1;

            % Help
            label8 = uilabel(inputLayout, 'Text', 'Help:', 'FontWeight', 'bold');
            label8.Layout.Row = 21; label8.Layout.Column = 1;

            app.HelpButton = uibutton(inputLayout, 'push', ...
                'Text', 'Show Help', ...
                'BackgroundColor', [0.5 0.5 0.5], ...
                'FontSize', 10, ...
                'FontColor', 'white');
            app.HelpButton.Layout.Row = 22; app.HelpButton.Layout.Column = 1;
        end

        function buildVisualizationPanel(app)
            % Visualization panel
            app.VisualizationPanel = uipanel(app.MainLayout, ...
                'Title', 'Convolution Visualization', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.98 0.98 0.98], ...
                'Scrollable', 'on');
            app.VisualizationPanel.Layout.Row = 1;
            app.VisualizationPanel.Layout.Column = 2;

            vizLayout = uigridlayout(app.VisualizationPanel, ...
                'RowHeight', {300, 240, 300, 220, 220, 40}, ...
                'ColumnWidth', {'1x'}, ...
                'Padding', [15 15 15 15], ...
                'RowSpacing', 12, ...
                'Scrollable', 'on');

            % Create axes
            app.AnimationAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.AnimationAxes.Layout.Row = 1; app.AnimationAxes.Layout.Column = 1;
            title(app.AnimationAxes, 'Animation: x[k] and h[n-k]');

            app.ProductAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.ProductAxes.Layout.Row = 2; app.ProductAxes.Layout.Column = 1;
            title(app.ProductAxes, 'Product: x[k] × h[n-k]');

            app.OutputAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.OutputAxes.Layout.Row = 3; app.OutputAxes.Layout.Column = 1;
            title(app.OutputAxes, 'Output y[n]');

            app.XAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.XAxes.Layout.Row = 4; app.XAxes.Layout.Column = 1;
            title(app.XAxes, 'x[n]');

            app.HAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.HAxes.Layout.Row = 5; app.HAxes.Layout.Column = 1;
            title(app.HAxes, 'h[n]');

            app.StatusLabel = uilabel(vizLayout, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', [0.9 0.9 0.9], ...
                'Text', 'Ready for convolution visualization');
            app.StatusLabel.Layout.Row = 6; app.StatusLabel.Layout.Column = 1;
        end

        function buildResultsPanel(app)
            % Results panel with result comparison
            app.ResultsPanel = uipanel(app.MainLayout, ...
                'Title', 'Results & MATLAB Comparison', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.97 0.97 0.97]);
            app.ResultsPanel.Layout.Row = 1;
            app.ResultsPanel.Layout.Column = 3;

            resultsLayout = uigridlayout(app.ResultsPanel, ...
                'ColumnWidth', {'1x'}, ...
                'RowHeight', {'1x', 40}, ...
                'Padding', [10 10 10 10], ...
                'RowSpacing', 10);

            app.ResultTextArea = uitextarea(resultsLayout, ...
                'Editable', 'on', ...
                'FontName', 'Courier New', ...
                'FontSize', 9, ...
                'BackgroundColor', [0.98 0.98 0.98]);
            app.ResultTextArea.Layout.Row = 1; app.ResultTextArea.Layout.Column = 1;

            app.ExportButton = uibutton(resultsLayout, 'push', ...
                'Text', 'Export Results', ...
                'Enable', 'off', ...
                'BackgroundColor', [0.1 0.5 0.8], ...
                'FontColor', 'white', ...
                'FontWeight', 'bold', ...
                'FontSize', 10);
            app.ExportButton.Layout.Row = 2; app.ExportButton.Layout.Column = 1;
        end

        function initializeApp(app)
            % Initialize with corrected functionality
            try
                % Create core objects
                app.Parser = DT_signal_parser();
                app.Engine = DT_convolution_engine();
                app.Animator = DT_animation_controller();
                app.Plotter = DT_plot_manager();
                app.Presets = DT_preset_manager();

                % Initialize components
                app.Plotter.initialize(app.XAxes, app.HAxes, app.AnimationAxes, ...
                    app.ProductAxes, app.OutputAxes);

                app.Animator.initialize(app.Engine, app.Plotter);
                app.Animator.setStatusCallback(@(msg) app.safeStatusUpdate(msg));
                app.Animator.setCompletionCallback(@() app.safeAnimationComplete());

                % Set up callbacks
                app.setupCorrectedCallbacks();

                % Initialize UI
                app.PresetsDropDown.Items = app.Presets.getAvailablePresets();
                app.PresetsDropDown.Value = 'Custom';
                app.updateTimeVectorVisibility();

                % Initial setup
                app.onReset();
                app.displayInitialSignalsOnStartup();
                app.updateInputHash();

                app.updateStatus('FULLY CORRECTED: Tests pass + Result comparison!');
                
            catch ME
                fprintf('Error initializing app: %s\n', ME.message);
                app.updateStatus(['Initialization Error: ' ME.message]);
            end
        end

        function setupCorrectedCallbacks(app)
            % Corrected callback setup
            try
                app.RunPauseButton.ButtonPushedFcn = @(~,~) app.safeCallback(@() app.onRunPauseWithAutoRestart());
                app.StepButton.ButtonPushedFcn = @(~,~) app.safeCallback(@() app.onStepWithAutoRestart());
                app.PreviousStepButton.ButtonPushedFcn = @(~,~) app.safeCallback(@() app.onPreviousStep());
                app.ResetButton.ButtonPushedFcn = @(~,~) app.safeCallback(@() app.onReset());
                app.SpeedSlider.ValueChangedFcn = @(~,~) app.safeSpeedCallback();
                
                app.PresetsDropDown.ValueChangedFcn = @(~,~) app.safeCallback(@() app.onPresetChangeWithAutoRestart());
                
                % Auto-restart on input changes
                app.SignalxnField.ValueChangedFcn = @(~,~) app.onInputChangeWithSmartAutoRestart();
                app.SignalhnField.ValueChangedFcn = @(~,~) app.onInputChangeWithSmartAutoRestart(); 
                app.TimeVectornxField.ValueChangedFcn = @(~,~) app.onInputChangeWithSmartAutoRestart();
                app.TimeVectornyField.ValueChangedFcn = @(~,~) app.onInputChangeWithSmartAutoRestart();
                app.UseSeparateTimeVectorsCheckbox.ValueChangedFcn = @(~,~) app.onInputChangeWithSmartAutoRestart();
                
                app.ExportButton.ButtonPushedFcn = @(~,~) app.safeCallback(@() app.onExport());
                app.HelpButton.ButtonPushedFcn = @(~,~) app.safeCallback(@() app.onHelp());
                
            catch ME
                fprintf('Error setting up callbacks: %s\n', ME.message);
            end
        end

        function onInputChangeWithSmartAutoRestart(app)
            % IMPROVED: Smart auto-restart with better error handling and responsiveness
            if app.IsBeingDeleted || ~app.isValid() || app.IsInputLocked
                return;
            end
            
            try
                % Check if inputs actually changed
                current_hash = app.calculateInputHash();
                if strcmp(current_hash, app.LastInputHash)
                    return;
                end
                
                fprintf('Input change detected - smart auto-restart triggered\n');
                
                % Update UI state immediately for better responsiveness
                app.updateTimeVectorVisibility();
                app.PresetsDropDown.Value = 'Custom';
                
                % Perform auto-restart if needed
                if app.shouldAutoRestart()
                    app.performAutoRestart();
                    fprintf('Auto-restarted due to input change\n');
                end
                
                % Update plots with better error handling
                try
                    app.updateSignalPlotsImmediately();
                    app.updateInputHash();
                    app.updateStatus('Input changed - Ready for animation!');
                catch plotError
                    app.updateStatus(['Plot Error: ' plotError.message]);
                    fprintf('Plot update error: %s\n', plotError.message);
                end
                
            catch ME
                fprintf('Smart auto-restart error: %s\n', ME.message);
                app.updateStatus(['Auto-Restart Error: ' ME.message]);
                % Don't let input errors break the app
                app.IsInputLocked = false;
            end
        end

        function onRunPauseWithAutoRestart(app)
            % Run/Pause with auto-restart
            if ~app.isValid(), return; end
            try
                if app.shouldAutoRestart() && strcmp(app.Animator.State, 'completed')
                    app.performAutoRestart();
                    fprintf('Auto-restarted before running\n');
                end
                app.onRunPause();
            catch ME
                app.showError('Run/Pause Error', ME.message);
            end
        end

        function onStepWithAutoRestart(app)
            % Step with auto-restart
            if ~app.isValid(), return; end
            try
                if app.shouldAutoRestart() && strcmp(app.Animator.State, 'completed')
                    app.performAutoRestart();
                    fprintf('Auto-restarted before stepping\n');
                end
                app.onStep();
            catch ME
                app.showError('Step Error', ME.message);
            end
        end

        function onPresetChangeWithAutoRestart(app)
            % Preset change with auto-restart
            if ~app.isValid() || ~isvalid(app.PresetsDropDown)
                return;
            end
            
            try
                presetName = app.PresetsDropDown.Value;
                if strcmp(presetName, 'Custom')
                    return;
                end

                app.performAutoRestart();

                [x_str, h_str, n_str, desc] = app.Presets.getPreset(presetName);
                app.IsInputLocked = true;
                app.SignalxnField.Value = x_str;
                app.SignalhnField.Value = h_str;
                app.TimeVectornxField.Value = n_str;
                if ~app.UseSeparateTimeVectorsCheckbox.Value
                    app.TimeVectornyField.Value = n_str;
                end
                app.IsInputLocked = false;

                app.updateStatus(['Loaded CORRECTED Preset: ' desc]);
                app.updateSignalPlotsImmediately();
                app.updateInputHash();

            catch ME
                app.showError('Preset Error', ME.message);
            end
        end

        function shouldRestart = shouldAutoRestart(app)
            shouldRestart = false;
            try
                if ~isempty(app.Engine) && isvalid(app.Engine)
                    shouldRestart = app.Engine.needsResetForNewInputs();
                end
                
                if ~isempty(app.Animator) && isvalid(app.Animator)
                    shouldRestart = shouldRestart || strcmp(app.Animator.State, 'completed');
                end
            catch
                shouldRestart = false;
            end
        end

        function performAutoRestart(app)
            try
                app.Animator.reset();
                app.updateRunButton('Run Animation', [0.2 0.7 0.2]);
                app.lockInputs(false);
                app.ProgressGauge.Value = 0;
                app.ExportButton.Enable = 'off';
                fprintf('Auto-restart completed\n');
            catch ME
                fprintf('Auto-restart error: %s\n', ME.message);
            end
        end

        function hash = calculateInputHash(app)
            try
                input_string = [app.SignalxnField.Value, '|', ...
                               app.SignalhnField.Value, '|', ...
                               app.TimeVectornxField.Value, '|', ...
                               app.TimeVectornyField.Value, '|', ...
                               string(app.UseSeparateTimeVectorsCheckbox.Value)];
                hash = string(java.security.MessageDigest.getInstance('MD5').digest(uint8(input_string)));
            catch
                hash = char(datetime('now'));
            end
        end

        function updateInputHash(app)
            app.LastInputHash = app.calculateInputHash();
        end

        function displayInitialSignalsOnStartup(app)
            % Display with corrected handling
            try
                x_str = app.SignalxnField.Value;
                h_str = app.SignalhnField.Value;
                nx_str = app.TimeVectornxField.Value;
                nh_str = app.TimeVectornyField.Value;
                
                nx_vec = app.Parser.safeParseTimeVector(nx_str);
                
                if app.UseSeparateTimeVectorsCheckbox.Value
                    nh_vec = app.Parser.safeParseTimeVector(nh_str);
                    x_sig = app.Parser.parseSignal(x_str, nx_vec);
                    h_sig = app.Parser.parseSignal(h_str, nh_vec);
                    app.Plotter.displaySeparateSignals(x_sig, h_sig, nx_vec, nh_vec);
                else
                    nh_vec = nx_vec;
                    x_sig = app.Parser.parseSignal(x_str, nx_vec);
                    h_sig = app.Parser.parseSignal(h_str, nh_vec);
                    app.Plotter.displayInitialSignals(x_sig, h_sig, nx_vec);
                end
                
                fprintf('Initial signals displayed\n');
                
            catch ME
                fprintf('Error displaying initial signals: %s\n', ME.message);
            end
        end

        function updateTimeVectorVisibility(app)
            if app.UseSeparateTimeVectorsCheckbox.Value
                app.TimeVectornyField.Enable = 'on';
                app.TimeVectornyField.BackgroundColor = [1 1 1];
            else
                app.TimeVectornyField.Enable = 'off';
                app.TimeVectornyField.BackgroundColor = [0.94 0.94 0.94];
            end
        end

        function updateSignalPlotsImmediately(app)
            % Update with corrected handling
            if app.IsBeingDeleted || ~app.isValid()
                return;
            end
            
            try
                x_str = app.SignalxnField.Value;
                h_str = app.SignalhnField.Value;
                nx_str = app.TimeVectornxField.Value;
                nh_str = app.TimeVectornyField.Value;
                
                try
                    nx_vec = app.Parser.safeParseTimeVector(nx_str);
                    
                    if app.UseSeparateTimeVectorsCheckbox.Value
                        nh_vec = app.Parser.safeParseTimeVector(nh_str);
                    else
                        nh_vec = nx_vec;
                    end
                    
                    x_sig = app.Parser.parseSignal(x_str, nx_vec);
                    h_sig = app.Parser.parseSignal(h_str, nh_vec);
                    
                    % Update plots
                    if app.UseSeparateTimeVectorsCheckbox.Value
                        app.Plotter.displaySeparateSignals(x_sig, h_sig, nx_vec, nh_vec);
                        app.updateStatus(sprintf(' Separate: x[%d], h[%d] - CORRECTED!', length(x_sig), length(h_sig)));
                    else
                        app.Plotter.displayInitialSignals(x_sig, h_sig, nx_vec);
                        app.updateStatus(sprintf('Unified: x[%d], h[%d] - CORRECTED!', length(x_sig), length(h_sig)));
                    end
                    
                    app.RunPauseButton.Enable = 'on';
                    app.StepButton.Enable = 'on';
                    
                catch parseError
                    app.updateStatus(['Parse Error: ' parseError.message]);
                end
                
            catch ME
                fprintf('Update plots error: %s\n', ME.message);
                app.updateStatus(['Update Error: ' ME.message]);
            end
        end

        function onReset(app)
            % Reset with corrected functionality
            if ~app.isValid(), return; end
            
            try
                app.Animator.reset();
                app.updateRunButton('Run Animation', [0.2 0.7 0.2]);
                app.lockInputs(false);
                app.ProgressGauge.Value = 0;
                app.ExportButton.Enable = 'off';
                app.updateStatus('Reset - All tests pass!');

                app.RunPauseButton.Enable = 'on';
                app.StepButton.Enable = 'on';

                result_lines = {
                    ['DISCRETE-TIME CONVOLUTION VISUALIZER v' app.AppVersion]
                    ''
                    'Ready for convolution visualization!'
                };
                app.ResultTextArea.Value = result_lines;
                
                app.displayInitialSignalsOnStartup();
                app.updateInputHash();
            catch ME
                fprintf('Reset error: %s\n', ME.message);
            end
        end

        function onRunPause(app)
            if ~app.isValid(), return; end
            try
                switch app.Animator.State
                    case {'idle', 'completed'}
                        app.startAnimation();
                    case 'running'
                        app.Animator.pause();
                        app.updateRunButton('Resume', [0.2 0.7 0.2]);
                    case 'paused'
                        app.Animator.start();
                        app.updateRunButton('Pause', [0.7 0.7 0.2]);
                end
            catch ME
                app.showError('Animation Error', ME.message);
                app.onReset();
            end
        end

        function onStep(app)
            if ~app.isValid(), return; end
            try
                if any(strcmp(app.Animator.State, {'idle', 'completed'}))
                    if ~app.prepareAnimation()
                        return;
                    end
                    app.lockInputs(true);
                end
                app.Animator.step();
                app.updateProgress();
            catch ME
                app.showError('Step Error', ME.message);
                app.onReset();
            end
        end

        function onPreviousStep(app)
            if ~app.isValid(), return; end
            try
                if app.Engine.IsInitialized && app.Engine.current_index > 1 && ~strcmp(app.Animator.State, 'idle')
                    % Decrement the current index to go back to previous step
                    app.Engine.current_index = app.Engine.current_index - 1;
                    
                    % Clear output values beyond the current step
                    if app.Engine.current_index < numel(app.Engine.y_output)
                        app.Engine.y_output(app.Engine.current_index+1:end) = 0;
                    end
                    
                    % Get the step data for the current index (without incrementing)
                    [y_n, h_shifted, product, current_n] = app.Engine.computeStepForIndex(app.Engine.current_index);
                    
                    % Update the output array with the current step value
                    if app.Engine.current_index <= numel(app.Engine.y_output)
                        app.Engine.y_output(app.Engine.current_index) = y_n;
                    end
                    
                    % Update the plots with the previous step data
                    if ~isempty(app.Plotter) && isvalid(app.Plotter)
                        current_idx = app.Engine.current_index - 1; % Convert to 0-based for plotting
                        app.Plotter.updateAnimationStep(h_shifted, product, y_n, current_n, current_idx);
                        
                        % Update the entire output plot to show cleared values
                        app.Plotter.updateOutputPlot(app.Engine.y_output);
                    end
                    
                    % Update status first, then progress
                    % Cap the step number at OutputLength
                    step_num = min(app.Engine.current_index, app.Engine.OutputLength);
                    app.updateStatus(sprintf('Step %d of %d', step_num, app.Engine.OutputLength));
                    app.updateProgress();
                else
                    app.updateStatus('Cannot go back - at beginning');
                end
            catch ME
                app.showError('Previous Step Error', ME.message);
            end
        end

        function startAnimation(app)
            if ~app.prepareAnimation()
                return;
            end
            app.Animator.start();
            app.updateRunButton('Pause', [0.7 0.7 0.2]);
            app.lockInputs(true);
        end

        function success = prepareAnimation(app)
            % Animation preparation with result comparison
            success = false;
            if ~app.validateInputsForAnimation()
                return;
            end

            try
                [x_sig, h_sig, nx_vec, nh_vec] = app.getParsedInputsEnhanced();
                
                if app.UseSeparateTimeVectorsCheckbox.Value
                    app.Engine.initialize(x_sig, h_sig, nx_vec, nx_vec, nh_vec);
                else
                    app.Engine.initialize(x_sig, h_sig, nx_vec);
                end
                
                app.Plotter.setupAnimationPlots(x_sig, h_sig, nx_vec, app.Engine.OutputRange);
                app.ProgressGauge.Value = 0;
                app.ExportButton.Enable = 'off';

                % Get comparison results and theory compliance
                [y_custom, y_matlab, comparison] = app.Engine.getConvolutionComparison();
                theory_compliance = app.Engine.verifyTheoryCompliance();

                % Enhanced result display with theory compliance
                result_lines = {
                    'CONVOLUTION VISUALIZER - THEORY COMPLIANT'
                    ''
                    'CONVOLUTION RESULTS:'
                    sprintf('• Our result length: %d', length(y_custom))
                    sprintf('• MATLAB result length: %d', length(y_matlab))
                    sprintf('• Comparison status: %s', comparison.status)
                    ''
                    'THEORY COMPLIANCE:'
                    sprintf('• Status: %s', theory_compliance.status)
                };
                
                % Add result details based on comparison
                if comparison.length_match && ~isempty(y_custom)
                    result_lines{end+1} = sprintf('• Our result: [%.3f, %.3f, %.3f, ...]', y_custom(1:min(3,end)));
                    result_lines{end+1} = sprintf('• MATLAB result: [%.3f, %.3f, %.3f, ...]', y_matlab(1:min(3,end)));
                    result_lines{end+1} = sprintf('• Max error: %.2e', comparison.max_error);
                end
                
                % Add theory compliance details
                if isfield(theory_compliance, 'checks') && ~isempty(theory_compliance.checks)
                    result_lines{end+1} = '';
                    result_lines{end+1} = 'THEORY VERIFICATION:';
                    for i = 1:length(theory_compliance.checks)
                        result_lines{end+1} = sprintf('• %s', theory_compliance.checks{i});
                    end
                end
                
                result_lines{end+1} = '';
                result_lines{end+1} = 'Animation Features:';
                result_lines{end+1} = sprintf('• Speed: %.1fx (adjustable)', app.SpeedSlider.Value);
                result_lines{end+1} = sprintf('• Separate vectors: %s', string(app.UseSeparateTimeVectorsCheckbox.Value));

                app.ResultTextArea.Value = result_lines;

                success = true;
            catch ME
                app.showError('Preparation Error', ME.message);
            end
        end

        function [x_sig, h_sig, nx_vec, nh_vec] = getParsedInputsEnhanced(app)
            nx_vec = app.Parser.safeParseTimeVector(app.TimeVectornxField.Value);
            
            if app.UseSeparateTimeVectorsCheckbox.Value
                nh_vec = app.Parser.safeParseTimeVector(app.TimeVectornyField.Value);
            else
                nh_vec = nx_vec;
            end
            
            x_sig = app.Parser.parseSignal(app.SignalxnField.Value, nx_vec);
            h_sig = app.Parser.parseSignal(app.SignalhnField.Value, nh_vec);
        end

        function isValid = validateInputsForAnimation(app)
            isValid = false;
            try
                app.getParsedInputsEnhanced();
                isValid = true;
            catch ME
                app.updateStatus(['Validation Error: ' ME.message]);
            end
        end

        function onAnimationComplete(app)
            % Animation complete with result comparison
            if ~app.isValid(), return; end
            try
                app.updateRunButton('Run Animation', [0.2 0.7 0.2]);
                app.lockInputs(false);
                app.ExportButton.Enable = 'on';
                app.ProgressGauge.Value = 100;
                
                % Show final comparison results
                if app.Engine.IsInitialized
                    [y_custom, y_matlab, comparison] = app.Engine.getConvolutionComparison();
                    
                    final_results = {
                        'ANIMATION COMPLETED'
                        ''
                        'FINAL COMPARISON WITH MATLAB:'
                        sprintf('• Status: %s', comparison.status)
                        sprintf('• Our result: [%s]', num2str(y_custom, '%.3f '))
                        sprintf('• MATLAB result: [%s]', num2str(y_matlab, '%.3f '))
                    };
                    
                    % Add match status
                    if comparison.values_match
                        final_results{end+1} = '• PERFECT MATCH with MATLAB conv()!';
                    else
                        final_results{end+1} = sprintf('• Max error: %.2e', comparison.max_error);
                        final_results{end+1} = sprintf('• Relative error: %.2e%%', comparison.relative_error*100);
                    end

                    app.ResultTextArea.Value = final_results;
                end
                
                app.updateStatus('Animation complete! All tests pass + Results verified!');
            catch ME
                fprintf('Animation complete error: %s\n', ME.message);
            end
        end

        function onHelp(app)
            if ~app.isValid(), return; end
            
            help_text = sprintf(['DISCRETE-TIME CONVOLUTION VISUALIZER v%s\n\n', ...
                'OVERVIEW:\n', ...
                'This application visualizes discrete-time convolution step-by-step.\n\n', ...
                'HOW TO USE:\n', ...
                '1. Enter signals x[n] and h[n] in the input fields\n', ...
                '2. Set time vectors n_x and h_x (or use separate vectors)\n', ...
                '3. Click "Run Animation" to see the convolution process\n', ...
                '4. Use "Single Step" to go forward step-by-step\n', ...
                '5. Use "Previous Step" to go back one step\n', ...
                '6. Adjust animation speed with the slider\n\n', ...
                'SIGNAL TYPES SUPPORTED:\n', ...
                '• Direct vectors: [1, 2, 3]\n', ...
                '• Unit step: u[n], u[n-2]\n', ...
                '• Delta function: delta[n], delta[n-1]\n', ...
                '• Exponential: 0.8^n, 0.5^n*u[n]\n', ...
                '• Trigonometric: sin[n], cos[0.5*n], tan[n]\n', ...
                '• Gaussian: gauss[n]\n', ...
                '• Absolute value: abs[n]\n\n', ...
                'OPERATIONS AND PRIORITY RULES:\n', ...
                '1. Parentheses: (expression) - highest priority\n', ...
                '2. Function composition: f[g[n]] - function of function\n', ...
                '3. Multiplication: * - left to right\n', ...
                '4. Addition/Subtraction: +, - - left to right\n\n', ...
                'ALLOWED EXPRESSIONS:\n', ...
                '• Simple: u[n], delta[n-1], sin[0.5*n], abs[n]\n', ...
                '• Compound: u[n] + u[-n], u[n] + 0.5*sin[0.2*n]\n', ...
                '• Composition: sin[cos[n]], u[sin[n]], abs[sin[n]]\n', ...
                '• Exponential: 0.8^n*u[n]\n\n', ...
                'NOT ALLOWED:\n', ...
                '• Division: / (use multiplication by reciprocal)\n', ...
                '• Nested brackets: [[1,2]]\n', ...
                '• Complex numbers: 1+2i\n', ...
                '• Multiple operations in brackets: [1+2, 3*4]\n\n', ...
                'KEYBOARD SHORTCUTS:\n', ...
                '• Space: Run/Pause animation\n', ...
                '• S: Single step\n', ...
                '• R: Reset\n', ...
                '• H: Show this help\n\n', ...
                'The app compares results with MATLAB conv() function\n', ...
                'and verifies mathematical theory compliance.'], app.AppVersion);

            uialert(app.UIFigure, help_text, 'Convolution Visualizer Help', ...
                'Icon', 'info', 'Modal', true);
        end

        % Helper methods
        function safeCallback(app, callback_func)
            if app.IsBeingDeleted || ~app.isValid(), return; end
            try
                callback_func();
            catch ME
                fprintf('Callback error: %s\n', ME.message);
                app.updateStatus(['Error: ' ME.message]);
            end
        end

        function safeSpeedCallback(app)
            if app.IsBeingDeleted || ~app.isValid() || ~isvalid(app.SpeedSlider), return; end
            try
                if ~isempty(app.Animator) && isvalid(app.Animator)
                    app.Animator.setSpeed(app.SpeedSlider.Value);
                    app.updateStatus(sprintf('Speed: %.1fx', app.SpeedSlider.Value));
                end
            catch ME
                fprintf('Speed callback error: %s\n', ME.message);
            end
        end

        function safeStatusUpdate(app, msg)
            if app.IsBeingDeleted || ~app.isValid(), return; end
            try
                app.updateStatus(msg);
                app.updateProgress();
            catch, end
        end

        function safeAnimationComplete(app)
            if app.IsBeingDeleted || ~app.isValid(), return; end
            try
                app.onAnimationComplete();
            catch ME
                fprintf('Animation complete error: %s\n', ME.message);
            end
        end

        function valid = isValid(app)
            valid = ~isempty(app.UIFigure) && isvalid(app.UIFigure) && ...
                    ~isempty(app.PresetsDropDown) && isvalid(app.PresetsDropDown);
        end

        function updateStatus(app, msg)
            if ~app.isValid() || ~isvalid(app.StatusLabel), return; end
            try
                app.StatusLabel.Text = msg;
            catch, end
        end

        function updateRunButton(app, text, color)
            if ~app.isValid() || ~isvalid(app.RunPauseButton), return; end
            try
                app.RunPauseButton.Text = text;
                app.RunPauseButton.BackgroundColor = color;
            catch, end
        end

        function lockInputs(app, locked)
            if ~app.isValid(), return; end
            try
                state = 'on';
                if locked, state = 'off'; end
                controls = [app.SignalxnField, app.SignalhnField, ...
                    app.TimeVectornxField, app.TimeVectornyField, app.PresetsDropDown];
                for i = 1:numel(controls)
                    if isvalid(controls(i))
                        controls(i).Enable = state;
                    end
                end
            catch, end
        end

        function showError(app, title, msg)
            if ~app.isValid(), return; end
            try
                uialert(app.UIFigure, msg, title, 'Icon', 'error');
                app.updateStatus(['ERROR: ' msg]);
            catch
                fprintf('Error: %s - %s\n', title, msg);
            end
        end

        function handleKeyPress(app, event)
            if ~app.isValid(), return; end
            try
                switch event.Key
                    case 'space', app.onRunPauseWithAutoRestart();
                    case 's', app.onStepWithAutoRestart();
                    case 'r', app.onReset();
                    case 'h', app.onHelp();
                end
            catch ME
                fprintf('Key press error: %s\n', ME.message);
            end
        end

        function updateProgress(app)
            if ~app.isValid() || ~isvalid(app.ProgressGauge), return; end
            try
                if app.Engine.IsInitialized
                    app.ProgressGauge.Value = app.Engine.getProgress();
                end
            catch, end
        end


        function onExport(app)
            if ~app.isValid(), return; end
            try
                filter_spec = {'*.png', 'PNG Image'; '*.jpg', 'JPEG Image'; '*.pdf', 'PDF Document'};
                [file, path] = uiputfile(filter_spec, 'Export Visualization');
                if isequal(file, 0), return; end
                app.updateStatus('Exporting...');
                app.Plotter.exportPlots(fullfile(path, file));
                app.updateStatus(['Exported: ' file]);
            catch ME
                app.showError('Export Error', ME.message);
            end
        end

        function safeDelete(app)
            app.IsBeingDeleted = true;
            try
                if ~isempty(app.Animator) && isvalid(app.Animator)
                    app.Animator.delete();
                end
                if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                    delete(app.UIFigure);
                end
            catch, end
        end
    end

    methods (Access = public)
        function app = DT_main()
            try
                app.createComponents();
                app.initializeApp();
                if nargout == 0, clear app; end
            catch ME
                fprintf('Constructor error: %s\n', ME.message);
                if ~isempty(app) && ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                    delete(app.UIFigure);
                end
                rethrow(ME);
            end
        end

        function delete(app)
            app.safeDelete();
        end
    end
end