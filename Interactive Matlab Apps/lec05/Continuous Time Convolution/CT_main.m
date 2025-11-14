classdef CT_main < handle
    % ContinuousConvolutionVisualizerApp - Continuous-Time Convolution Visualizer
    %
    % This is the main application class for the Continuous-Time Convolution
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
    % - Support for various signal types (rect, tri, gauss, saw, chirp, etc.)
    % - Preset examples for educational use

    properties (Access = public)
        UIFigure, MainLayout, InputPanel, VisualizationPanel, ResultsPanel
        SignalxField, SignalhField, TimeStartField, TimeEndField, TimeStepField
        RunPauseButton, StepButton, StepBackButton, StepForwardButton, ResetButton, SpeedSlider, PresetsDropDown, ProgressGauge, HelpButton, DynamicYlimCheckbox, HDynamicYlimCheckbox, XDynamicYlimCheckbox, ImpulseScalingCheckbox
        AnimationAxes, ProductAxes, OutputAxes, XAxes, HAxes
        ResultTextArea, StatusBar, ExportButton
        % Separate time range controls
        CustomRangesButton, XTimeStartField, XTimeEndField, HTimeStartField, HTimeEndField
    end
    
    properties (Access = private)
        Parser, Engine, Animator, Plotter, Presets
        AppVersion char = '1.0'
        LastInputHash char = ''
        isPresetChanging logical = false
        IsBeingDeleted logical = false
    end
    
    methods (Access = private)
        function createComponents(app)
            screen_size = get(0, 'ScreenSize');
            app.UIFigure = uifigure('Visible', 'off', ...
                'Position', [50 50 screen_size(3)-100 screen_size(4)-150], ...
                'Name', ['Continuous Convolution Visualizer v' app.AppVersion], 'Color', [0.94 0.94 0.94]);
            
            app.MainLayout = uigridlayout(app.UIFigure, ...
                'ColumnWidth', {340, '1x', 320}, 'RowHeight', {'1x', 25}, ...
                'Padding', [10 10 10 10], 'ColumnSpacing', 10, 'RowSpacing', 5);
            
            app.InputPanel = uipanel(app.MainLayout, 'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94], 'Scrollable', 'on');
            app.InputPanel.Layout.Row = 1; app.InputPanel.Layout.Column = 1;
            
            app.VisualizationPanel = uipanel(app.MainLayout, 'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
            app.VisualizationPanel.Layout.Row = 1; app.VisualizationPanel.Layout.Column = 2;
            
            app.ResultsPanel = uipanel(app.MainLayout, 'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
            app.ResultsPanel.Layout.Row = 1; app.ResultsPanel.Layout.Column = 3;
            
            app.StatusBar = uilabel(app.MainLayout, 'Text', 'Ready.', 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', [0.5 0.5 0.5], 'FontColor', 'white');
            app.StatusBar.Layout.Row = 2; app.StatusBar.Layout.Column = [1 3];

            app.buildInputPanel();
            app.buildVisualizationPanel();
            app.buildResultsPanel();

            app.UIFigure.CloseRequestFcn = @(~,~) app.safeDelete();
            app.UIFigure.Visible = 'on';
            
            % Defer initial plotting to prevent startup race conditions
            timer('StartDelay', 0.1, 'TimerFcn', @(~,~) app.displayInitialSignals(), 'ExecutionMode', 'singleShot');
        end
        
        function buildInputPanel(app)
            pLayout = uigridlayout(app.InputPanel, 'RowHeight', {'1x'}, 'ColumnWidth', {'1x'}, 'Padding', [0 0 0 0]);
            mainCard = uipanel(pLayout, 'Title', 'Signal Input & Controls', 'FontWeight', 'bold', 'BackgroundColor', [0.97 0.97 0.97], 'Scrollable', 'on');
            
            cardLayout = uigridlayout(mainCard, 'RowHeight', {22, 28, 22, 28, 22, 28, 22, 28, 22, 30, 35, 10, 35, 35, 35, 35, 22, 25, 22, 25, 22, 25, 35, '1x'}, 'ColumnWidth', {'1x'}, 'RowSpacing', 5, 'Padding', [15 15 15 15]);

            % Signal inputs
            l1=uilabel(cardLayout,'Text','Signal x(t):','FontWeight','bold','FontColor',[0 .447 .741],'FontSize',10);
            l1.Layout.Row=1; l1.Layout.Column=1;
            app.SignalxField=uieditfield(cardLayout,'text','Value','rect(t,2)','FontSize',10,'Tooltip','Signal x(t) - Continuous-time input');
            app.SignalxField.Layout.Row=2; app.SignalxField.Layout.Column=1;

            l2=uilabel(cardLayout,'Text','Signal h(t):','FontWeight','bold','FontColor',[.85 .325 .098],'FontSize',10);
            l2.Layout.Row=3; l2.Layout.Column=1;
            app.SignalhField=uieditfield(cardLayout,'text','Value','exp(-t).*u(t)','FontSize',10,'Tooltip','Signal h(t) - Impulse response');
            app.SignalhField.Layout.Row=4; app.SignalhField.Layout.Column=1;

            % Time parameters in single row
            timeLabel=uilabel(cardLayout,'Text','Time Range:','FontWeight','bold','FontSize',10);
            timeLabel.Layout.Row=5; timeLabel.Layout.Column=1;
            
            timeGrid = uigridlayout(cardLayout, 'RowHeight', {25}, 'ColumnWidth', {'1x', '1x', '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 5);
            timeGrid.Layout.Row = 6; timeGrid.Layout.Column = 1;
            
            app.TimeStartField=uieditfield(timeGrid,'numeric','Value',-4,'FontSize',9,'Tooltip','Start time');
            app.TimeStartField.Layout.Row=1; app.TimeStartField.Layout.Column=1;
            
            app.TimeEndField=uieditfield(timeGrid,'numeric','Value',4,'FontSize',9,'Tooltip','End time');
            app.TimeEndField.Layout.Row=1; app.TimeEndField.Layout.Column=2;
            
            app.TimeStepField=uieditfield(timeGrid,'numeric','Value',0.02,'FontSize',9,'Tooltip','Time step size');
            app.TimeStepField.Layout.Row=1; app.TimeStepField.Layout.Column=3;

            % Custom ranges button
            app.CustomRangesButton=uibutton(cardLayout,'push','Text','Custom Ranges','FontWeight','bold','FontSize',10,'BackgroundColor',[0.3 0.6 0.9],'FontColor','white');
            app.CustomRangesButton.Layout.Row=7; app.CustomRangesButton.Layout.Column=1;
            
            % Separate time controls for x(t) and h(t) in single row
            lx1=uilabel(cardLayout,'Text','x(t) Time Range:','FontWeight','bold','FontSize',10,'FontColor',[0 .447 .741]);
            lx1.Layout.Row=8; lx1.Layout.Column=1;
            
            xTimeGrid = uigridlayout(cardLayout, 'RowHeight', {25}, 'ColumnWidth', {'1x', '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 5);
            xTimeGrid.Layout.Row = 9; xTimeGrid.Layout.Column = 1;
            
            app.XTimeStartField=uieditfield(xTimeGrid,'numeric','Value',-3,'FontSize',9,'Tooltip','x(t) start time');
            app.XTimeStartField.Layout.Row=1; app.XTimeStartField.Layout.Column=1;
            app.XTimeEndField=uieditfield(xTimeGrid,'numeric','Value',3,'FontSize',9,'Tooltip','x(t) end time');
            app.XTimeEndField.Layout.Row=1; app.XTimeEndField.Layout.Column=2;
            
            lh1=uilabel(cardLayout,'Text','h(t) Time Range:','FontWeight','bold','FontSize',10,'FontColor',[0.85 0.33 0.1]);
            lh1.Layout.Row=10; lh1.Layout.Column=1;
            
            hTimeGrid = uigridlayout(cardLayout, 'RowHeight', {25}, 'ColumnWidth', {'1x', '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 5);
            hTimeGrid.Layout.Row = 11; hTimeGrid.Layout.Column = 1;
            
            app.HTimeStartField=uieditfield(hTimeGrid,'numeric','Value',-3,'FontSize',9,'Tooltip','h(t) start time');
            app.HTimeStartField.Layout.Row=1; app.HTimeStartField.Layout.Column=1;
            app.HTimeEndField=uieditfield(hTimeGrid,'numeric','Value',3,'FontSize',9,'Tooltip','h(t) end time');
            app.HTimeEndField.Layout.Row=1; app.HTimeEndField.Layout.Column=2;
            
            % Initially disable custom range fields
            set([app.XTimeStartField, app.XTimeEndField, app.HTimeStartField, app.HTimeEndField], 'Enable', 'off');

            % Presets
            l6=uilabel(cardLayout,'Text','Presets:','FontWeight','bold','FontSize',10);
            l6.Layout.Row=12; l6.Layout.Column=1;
            app.PresetsDropDown=uidropdown(cardLayout,'FontSize',12,'FontWeight','bold','Tooltip','Predefined signal combinations','Position',[0 0 0 60]);
            app.PresetsDropDown.Layout.Row=13; app.PresetsDropDown.Layout.Column=1;
            
            % Control buttons
            spacer=uilabel(cardLayout,'Text','');
            spacer.Layout.Row=14; spacer.Layout.Column=1;

            app.RunPauseButton=uibutton(cardLayout,'push','Text','Run Animation','BackgroundColor',[.2 .7 .2],'FontWeight','bold','FontSize',11,'FontColor','w','Tooltip','Start/pause continuous-time convolution');
            app.RunPauseButton.Layout.Row=15; app.RunPauseButton.Layout.Column=1;

            % Step control buttons in a grid
            stepGrid = uigridlayout(cardLayout, 'RowHeight', {35}, 'ColumnWidth', {'1x', '1x', '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 5);
            stepGrid.Layout.Row = 16; stepGrid.Layout.Column = 1;

            app.StepBackButton=uibutton(stepGrid,'push','Text','Step Back','BackgroundColor',[.5 .3 .7],'FontSize',10,'FontColor','w','Tooltip','Step backward in animation');
            app.StepBackButton.Layout.Row=1; app.StepBackButton.Layout.Column=1;

            app.StepButton=uibutton(stepGrid,'push','Text','Single Step','BackgroundColor',[.3 .3 .7],'FontSize',10,'FontColor','w','Tooltip','Single convolution step');
            app.StepButton.Layout.Row=1; app.StepButton.Layout.Column=2;

            app.StepForwardButton=uibutton(stepGrid,'push','Text','Step Forward','BackgroundColor',[.5 .3 .7],'FontSize',10,'FontColor','w','Tooltip','Step forward in animation');
            app.StepForwardButton.Layout.Row=1; app.StepForwardButton.Layout.Column=3;

            app.ResetButton=uibutton(cardLayout,'push','Text','Reset','BackgroundColor',[.7 .3 .3],'FontWeight','bold','FontSize',11,'FontColor','w','Tooltip','Reset animation');
            app.ResetButton.Layout.Row=17; app.ResetButton.Layout.Column=1;

            % Speed control
            l7=uilabel(cardLayout,'Text','Animation Speed:','FontWeight','bold','FontSize',10);
            l7.Layout.Row=18; l7.Layout.Column=1;
            app.SpeedSlider=uislider(cardLayout,'Limits',[.1 20],'Value',1,'MajorTicks',[.1 1 5 10 20],'MajorTickLabels',{'0.1x','1x','5x','10x','20x'},'FontSize',9);
            app.SpeedSlider.Layout.Row=19; app.SpeedSlider.Layout.Column=1;

            % Dynamic Y-limits checkboxes
            app.DynamicYlimCheckbox=uicheckbox(cardLayout,'Text','Dynamic Y-limits for Product Plot','FontWeight','bold','FontSize',10,'Value',false);
            app.DynamicYlimCheckbox.Layout.Row=20; app.DynamicYlimCheckbox.Layout.Column=1;
            
            app.HDynamicYlimCheckbox=uicheckbox(cardLayout,'Text','Dynamic Y-limits for h(t) Plot','FontWeight','bold','FontSize',10,'Value',false);
            app.HDynamicYlimCheckbox.Layout.Row=21; app.HDynamicYlimCheckbox.Layout.Column=1;
            
            app.XDynamicYlimCheckbox=uicheckbox(cardLayout,'Text','Dynamic Y-limits for x(t) Plot','FontWeight','bold','FontSize',10,'Value',false);
            app.XDynamicYlimCheckbox.Layout.Row=22; app.XDynamicYlimCheckbox.Layout.Column=1;
            
            app.ImpulseScalingCheckbox=uicheckbox(cardLayout,'Text','Impulse Height Scaling (Area-based)','FontWeight','bold','FontSize',10,'Value',true);
            app.ImpulseScalingCheckbox.Layout.Row=23; app.ImpulseScalingCheckbox.Layout.Column=1;

            % Progress
            l8=uilabel(cardLayout,'Text','Progress:','FontWeight','bold','FontSize',10);
            l8.Layout.Row=24; l8.Layout.Column=1;
            app.ProgressGauge=uigauge(cardLayout,'linear','Limits',[0 100],'Value',0,'ScaleColors',[.8 .2 .2; .2 .8 .2],'ScaleColorLimits',[0 50; 50 100],'Position',[0 0 0 40]);
            app.ProgressGauge.Layout.Row=25; app.ProgressGauge.Layout.Column=1;

            % Help
            l9=uilabel(cardLayout,'Text','Help:','FontWeight','bold','FontSize',10);
            l9.Layout.Row=26; l9.Layout.Column=1;
            app.HelpButton=uibutton(cardLayout,'push','Text','Show Help','BackgroundColor',[.5 .5 .5],'FontSize',10,'FontColor','w');
            app.HelpButton.Layout.Row=27; app.HelpButton.Layout.Column=1;
        end

        function buildVisualizationPanel(app)
            pLayout = uigridlayout(app.VisualizationPanel, 'RowHeight', {'1x'}, 'ColumnWidth', {'1x'}, 'Padding', [0 0 0 0]);
            mainCard = uipanel(pLayout, 'Title', 'Continuous-Time Convolution Visualization', 'FontWeight', 'bold', 'BackgroundColor', [0.98 0.98 0.98], 'Scrollable', 'on');
            
            vizLayout = uigridlayout(mainCard, 'RowHeight',{300, 240, 300, 220, 220, 40}, 'ColumnWidth',{'1x'}, 'Padding', [15 15 15 15], 'RowSpacing', 12, 'Scrollable', 'on');
            
            % Create axes with enhanced styling
            app.AnimationAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.AnimationAxes.Layout.Row = 1; app.AnimationAxes.Layout.Column = 1;
            title(app.AnimationAxes, 'Animation: x(τ) and h(t-τ)');

            app.ProductAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.ProductAxes.Layout.Row = 2; app.ProductAxes.Layout.Column = 1;
            title(app.ProductAxes, 'Product: x(τ) × h(t-τ)');

            app.OutputAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.OutputAxes.Layout.Row = 3; app.OutputAxes.Layout.Column = 1;
            title(app.OutputAxes, 'Output y(t)');

            app.XAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.XAxes.Layout.Row = 4; app.XAxes.Layout.Column = 1;
            title(app.XAxes, 'x(t) - Input Signal');

            app.HAxes = uiaxes(vizLayout, 'BackgroundColor', 'white');
            app.HAxes.Layout.Row = 5; app.HAxes.Layout.Column = 1;
            title(app.HAxes, 'h(t) - Impulse Response');

            app.StatusBar = uilabel(vizLayout, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [0.9 0.9 0.9], 'Text', 'Continuous-Time Convolution Visualizer Ready!');
            app.StatusBar.Layout.Row = 6; app.StatusBar.Layout.Column = 1;
        end

        function buildResultsPanel(app)
            pLayout = uigridlayout(app.ResultsPanel, 'RowHeight', {'1x'}, 'ColumnWidth', {'1x'}, 'Padding', [0 0 0 0]);
            mainCard = uipanel(pLayout, 'Title', 'Results & MATLAB Comparison', 'FontWeight', 'bold', 'BackgroundColor', [0.97 0.97 0.97]);
             
            resultsLayout = uigridlayout(mainCard, 'RowHeight',{'1x', 40}, 'ColumnWidth',{'1x'}, 'Padding', [10 10 10 10], 'RowSpacing', 10);
             
            app.ResultTextArea = uitextarea(resultsLayout, 'Editable', 'off', 'FontName', 'Courier New', 'FontSize', 9, 'BackgroundColor', [0.98 0.98 0.98]);
            app.ResultTextArea.Layout.Row = 1; app.ResultTextArea.Layout.Column = 1;
            
            app.ExportButton = uibutton(resultsLayout, 'push', 'Text', 'Export Results', 'Enable', 'off', 'BackgroundColor', [.1 .5 .8], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 10);
            app.ExportButton.Layout.Row = 2; app.ExportButton.Layout.Column = 1;
        end
    end
    
    methods (Access = public)
        function app = CT_main()
            app.createComponents();
            app.initializeApp();
        end
        
        function initializeApp(app)
            app.Parser = CT_signal_parser();
            app.Engine = CT_convolution_engine();
            app.Animator = CT_animation_controller();
            app.Plotter = CT_plot_manager();
            app.Presets = CT_preset_manager();
            
            app.Plotter.initialize(app.XAxes, app.HAxes, app.AnimationAxes, app.ProductAxes, app.OutputAxes);
            app.Animator.initialize(app.Engine, app.Plotter);
            
            app.Animator.setStatusCallback(@(msg) app.updateStatus(msg, 'running'));
            app.Animator.setCompletionCallback(@() app.onAnimationComplete());
            app.Animator.setProgressCallback(@() app.updateProgress());

            app.setupCallbacks();
            
            app.PresetsDropDown.Items = [{'Custom'}, app.Presets.getAvailablePresets()];
            app.PresetsDropDown.Value = 'Rect * Exp Decay';
            app.onPresetChange();
            
            % Force display initial signals after a short delay to ensure UI is ready
            pause(0.2);
            app.displayInitialSignals();
            
            % Also try plotting with a timer to ensure it happens after UI is fully ready
            timer('StartDelay', 0.5, 'TimerFcn', @(~,~) app.displayInitialSignals(), 'ExecutionMode', 'singleShot');
        end
        
        function setupCallbacks(app)
            app.RunPauseButton.ButtonPushedFcn = @(~,~) app.onRunPause();
            app.StepButton.ButtonPushedFcn = @(~,~) app.onStep();
            app.StepBackButton.ButtonPushedFcn = @(~,~) app.onStepBack();
            app.StepForwardButton.ButtonPushedFcn = @(~,~) app.onStepForward();
            app.ResetButton.ButtonPushedFcn = @(~,~) app.onReset();
            app.SpeedSlider.ValueChangedFcn = @(~,~) app.onSpeedChange();
            app.PresetsDropDown.ValueChangedFcn = @(~,~) app.onPresetChange();
            app.DynamicYlimCheckbox.ValueChangedFcn = @(~,~) app.onDynamicYlimChange();
            app.HDynamicYlimCheckbox.ValueChangedFcn = @(~,~) app.onHDynamicYlimChange();
            app.XDynamicYlimCheckbox.ValueChangedFcn = @(~,~) app.onXDynamicYlimChange();
            app.ImpulseScalingCheckbox.ValueChangedFcn = @(~,~) app.onImpulseScalingChange();
            app.HelpButton.ButtonPushedFcn = @(~,~) app.onHelp();
            app.ExportButton.ButtonPushedFcn = @(~,~) app.onExport();
            app.CustomRangesButton.ButtonPushedFcn = @(~,~) app.onCustomRangesChange();
            
            inputFields = {app.SignalxField, app.SignalhField, app.TimeStartField, app.TimeEndField, app.TimeStepField, ...
                          app.XTimeStartField, app.XTimeEndField, app.HTimeStartField, app.HTimeEndField};
            for i = 1:length(inputFields)
                inputFields{i}.ValueChangedFcn = @(~,~) app.onInputChange();
            end
            
            % Setup keyboard shortcuts
            app.UIFigure.KeyPressFcn = @(src, event) app.onKeyPress(event);
        end
        
        function onRunPause(app)
            switch app.Animator.State
                case {'idle', 'completed', 'paused'}
                    if strcmp(app.Animator.State, 'paused')
                        app.Animator.start();
                    else
                        if app.hasInputChanged() || ~app.Engine.IsInitialized || strcmp(app.Animator.State, 'completed')
                            if ~app.initializeConvolution(), return; end
                        end
                        app.Animator.start();
                        app.toggleInputLock(true);
                    end
                case 'running'
                    app.Animator.pause();
            end
            app.updateUIState();
        end
        
        function onStep(app)
            if app.hasInputChanged() || ~app.Engine.IsInitialized || any(strcmp(app.Animator.State, {'idle', 'completed'}))
                if ~app.initializeConvolution(), return; end
                app.toggleInputLock(true);
            end
            app.Animator.step();
            app.updateUIState();
        end
        
        function onStepBack(app)
            if ~app.Engine.IsInitialized, return; end
            if app.hasInputChanged()
                if ~app.initializeConvolution(), return; end
                app.toggleInputLock(true);
            end
            
            app.Animator.stepBack();
            app.updateProgress();
            app.updateUIState();
        end
        
        function onStepForward(app)
            if ~app.Engine.IsInitialized, return; end
            if app.hasInputChanged()
                if ~app.initializeConvolution(), return; end
                app.toggleInputLock(true);
            end
            
            app.Animator.stepForward();
            app.updateProgress();
            app.updateUIState();
        end
        
        function onReset(app)
            app.Animator.reset();
            app.toggleInputLock(false);
            app.ProgressGauge.Value = 0;
            app.ExportButton.Enable = 'off';
            app.Plotter.clearAll();
            app.displayInitialSignals();
            app.updateUIState();
            app.ResultTextArea.Value = {'Ready to visualize convolution.', 'Press Run or Step to begin.'};
            app.updateStatus('System reset and ready.', 'info');
            app.LastInputHash = app.calculateInputHash();
        end

        function onInputChange(app)
            % Don't change preset to 'Custom' if we're in the middle of a preset change
            if ~app.isPresetChanging
                app.PresetsDropDown.Value = 'Custom';
            end
            
            % Always try to display signals, even if validation fails
            app.displayInitialSignals();
            
            if app.validateInputs()
                app.updateStatus('Inputs valid. Ready to run.', 'info');
            else
                app.updateStatus('Inputs invalid. Check signal expressions.', 'error');
            end
        end
        
        function onPresetChange(app)
            presetName = app.PresetsDropDown.Value;
            if strcmp(presetName, 'Custom'), return; end
            
            app.isPresetChanging = true; % Prevent onInputChange from changing preset back to 'Custom'
            
            try
                [x, h, ts, te, dt] = app.Presets.getPreset(presetName);
                app.SignalxField.Value = x; app.SignalhField.Value = h;
                app.TimeStartField.Value = ts; app.TimeEndField.Value = te;
                app.TimeStepField.Value = dt;
                
                app.displayInitialSignals(); % Show plots immediately after preset change
                app.updateStatus(sprintf('Preset "%s" loaded successfully.', presetName), 'info');
            catch ME
                app.updateStatus(sprintf('Error loading preset: %s', ME.message), 'error');
            end
            
            app.isPresetChanging = false;
        end
        
        function onAnimationComplete(app)
            app.toggleInputLock(false);
            app.ExportButton.Enable = 'on';
            app.updateUIState();
            app.updateStatus('Animation completed!', 'complete');
        end

        function onSpeedChange(app)
            app.Animator.setSpeed(app.SpeedSlider.Value);
        end
        
        function onDynamicYlimChange(app)
            % Update product plot y-limits based on checkbox state
            app.Plotter.setDynamicYlimEnabled(app.DynamicYlimCheckbox.Value);
            
            if app.Engine.IsInitialized
                [t_vals, y_vals] = app.Engine.getFullResult();
                if ~isempty(y_vals)
                    current_idx = app.Engine.current_t_index - 1;
                    app.Plotter.updateOutput(t_vals, y_vals, current_idx);
                end
            end
        end
        
        function onHDynamicYlimChange(app)
            % Update h(t) plot y-limits based on checkbox state
            app.Plotter.setHDynamicYlimEnabled(app.HDynamicYlimCheckbox.Value);
            
            if app.Engine.IsInitialized
                % Refresh the h(t) plot with new y-limits
                app.displayInitialSignals();
            end
        end
        
        function onXDynamicYlimChange(app)
            % Update x(t) plot y-limits based on checkbox state
            app.Plotter.setXDynamicYlimEnabled(app.XDynamicYlimCheckbox.Value);
            
            if app.Engine.IsInitialized
                % Refresh the x(t) plot with new y-limits
                app.displayInitialSignals();
            end
        end
        
        function onImpulseScalingChange(app)
            % Update impulse scaling based on checkbox state
            app.Plotter.setImpulseScalingEnabled(app.ImpulseScalingCheckbox.Value);
            
            if app.Engine.IsInitialized
                % Refresh the display to show new scaling
                app.displayInitialSignals();
                app.updateStatus('Impulse scaling updated for visualization.', 'info');
            end
        end
        
        function onCustomRangesChange(app)
            % Toggle custom ranges usage
            if strcmp(app.CustomRangesButton.Text, 'Custom Ranges')
                % Enable custom ranges
                app.CustomRangesButton.Text = 'Using Custom Ranges';
                app.CustomRangesButton.BackgroundColor = [0.2 0.8 0.2];
                % Enable custom range fields
                set([app.XTimeStartField, app.XTimeEndField, app.HTimeStartField, app.HTimeEndField], 'Enable', 'on');
                % Set default values from main time range
                app.XTimeStartField.Value = app.TimeStartField.Value;
                app.XTimeEndField.Value = app.TimeEndField.Value;
                app.HTimeStartField.Value = app.TimeStartField.Value;
                app.HTimeEndField.Value = app.TimeEndField.Value;
                app.updateStatus('Custom ranges enabled. Set different time ranges for x(t) and h(t).', 'info');
            else
                % Disable custom ranges
                app.CustomRangesButton.Text = 'Custom Ranges';
                app.CustomRangesButton.BackgroundColor = [0.3 0.6 0.9];
                % Disable custom range fields
                set([app.XTimeStartField, app.XTimeEndField, app.HTimeStartField, app.HTimeEndField], 'Enable', 'off');
                app.updateStatus('Custom ranges disabled. Using unified time range.', 'info');
            end
        end
        
        
        function onExport(app)
            [file, path] = uiputfile({'*.png';'*.jpg';'*.pdf'}, 'Export Visualization');
            if isequal(file,0), return; end
            app.updateStatus('Exporting...', 'info');
            try
                exportgraphics(app.UIFigure, fullfile(path, file), 'Resolution', 300);
                app.updateStatus(['Exported to ' file], 'complete');
            catch ME
                uialert(app.UIFigure, ME.message, 'Export Error');
                app.updateStatus('Export failed.', 'error');
            end
        end
        
        function onKeyPress(app, event)
            % Handle keyboard shortcuts
            switch event.Key
                case 'space'
                    % Toggle run/pause
                    app.onRunPause();
                case 's'
                    % Single step forward
                    app.onStepForward();
                case 'r'
                    % Reset
                    app.onReset();
                case 'h'
                    % Help
                    app.onHelp();
                case 'leftarrow'
                    % Step back
                    app.onStepBack();
                case 'rightarrow'
                    % Step forward
                    app.onStepForward();
                case 'escape'
                    % Pause if running
                    if strcmp(app.Animator.State, 'running')
                        app.Animator.pause();
                    end
                case 'e'
                    % Export
                    app.onExport();
            end
        end
        
        function success = initializeConvolution(app)
            success = false;
            if ~app.validateInputs(), return; end
            try
                app.Animator.reset();
                % Check if custom ranges are enabled
                if strcmp(app.CustomRangesButton.Text, 'Using Custom Ranges')
                    % Use custom ranges
                    app.Engine.initialize(app.SignalxField.Value, app.SignalhField.Value, ...
                        app.TimeStartField.Value, app.TimeEndField.Value, app.TimeStepField.Value, ...
                        app.XTimeStartField.Value, app.XTimeEndField.Value, ...
                        app.HTimeStartField.Value, app.HTimeEndField.Value);
                else
                    % Use unified time range
                app.Engine.initialize(app.SignalxField.Value, app.SignalhField.Value, ...
                    app.TimeStartField.Value, app.TimeEndField.Value, app.TimeStepField.Value);
                end
                
                [y_cust, y_mat, comp] = app.Engine.getConvolutionComparison();
                app.ResultTextArea.Value = {
                    'RESULTS & MATLAB COMPARISON', '', ...
                    sprintf('Status: %s', comp.status), ...
                    sprintf('Max Error: %.2e', comp.max_error), '', ...
                    'Our Result (y):', sprintf('[%s...]', num2str(y_cust(1:min(8,end)),'%.2f ')), '', ...
                    'MATLAB conv() (y_m):', sprintf('[%s...]', num2str(y_mat(1:min(8,end)),'%.2f ')), ''};

                app.LastInputHash = app.calculateInputHash();
                app.updateStatus('Engine initialized successfully.', 'info');
                success = true;
            catch ME
                app.updateStatus(ME.message, 'error');
                uialert(app.UIFigure, ME.message, 'Initialization Failed');
            end
        end
        
        function changed = hasInputChanged(app)
            changed = ~strcmp(app.calculateInputHash(), app.LastInputHash);
        end
        
        function hash = calculateInputHash(app)
             hash = strjoin({app.SignalxField.Value, app.SignalhField.Value, ...
                   num2str(app.TimeStartField.Value), num2str(app.TimeEndField.Value), ...
                   num2str(app.TimeStepField.Value)},'|');
        end

        function displayInitialSignals(app)
            try
                % Check if custom ranges are enabled
                if strcmp(app.CustomRangesButton.Text, 'Using Custom Ranges')
                    % Use custom ranges
                    dt = app.TimeStepField.Value;
                    t_x = app.XTimeStartField.Value:dt:app.XTimeEndField.Value;
                    t_h = app.HTimeStartField.Value:dt:app.HTimeEndField.Value;
                    
                    % Parse signals with their respective time ranges
                    x = app.Parser.parseSignal(app.SignalxField.Value, t_x, dt);
                    h = app.Parser.parseSignal(app.SignalhField.Value, t_h, dt);
                    
                    % Note: Impulse scaling is handled in the plot manager for visualization only
                    
                    % Use the union of time ranges for display
                    t_union = unique([t_x, t_h]);
                    t_union = sort(t_union);
                    
                    % Interpolate signals to the union time range
                    if length(t_x) > 1 && length(t_h) > 1 && length(t_union) > 1
                        try
                            % Use more robust interpolation for better signal preservation
                            x_interp = interp1(t_x, x, t_union, 'linear', 0);
                            h_interp = interp1(t_h, h, t_union, 'linear', 0);
                            
                            % Check for interpolation artifacts and fix them
                            if max(abs(diff(x_interp))) > 10 * max(abs(diff(x)))
                                % Interpolation introduced artifacts, use original
                                x_interp = x;
                            end
                            if max(abs(diff(h_interp))) > 10 * max(abs(diff(h)))
                                % Interpolation introduced artifacts, use original
                                h_interp = h;
                            end
                        catch
                            % Fallback to original vectors if interpolation fails
                            x_interp = x;
                            h_interp = h;
                        end
                    else
                        x_interp = x;
                        h_interp = h;
                    end
                    
                    app.Plotter.plotSignals(t_union, x_interp, h_interp, t_union);
                else
                    % Use unified time range
                t = app.TimeStartField.Value:app.TimeStepField.Value:app.TimeEndField.Value;
                dt = app.TimeStepField.Value;
                x = app.Parser.parseSignal(app.SignalxField.Value, t, dt);
                h = app.Parser.parseSignal(app.SignalhField.Value, t, dt);
                    
                    % Note: Impulse scaling is handled in the plot manager for visualization only
                    
                    app.Plotter.plotSignals(t, x, h, t);
                end
            catch ME, app.updateStatus(ME.message, 'error'); end
        end
        
        function valid = validateInputs(app)
            valid = true;
            white = [1,1,1]; red = [1,.85,.85];
            
            % Enhanced input validation with better error messages
            
            try 
                [t, dt, x_expr, h_expr] = app.getSignalParameters();
            catch ME
                app.updateStatus('Error: Invalid time vector parameters.', 'error');
                valid = false; return;
            end
            
            try, app.Parser.parseSignal(x_expr, t, dt); app.SignalxField.BackgroundColor=white;
            catch ME, app.SignalxField.BackgroundColor=red; app.updateStatus(sprintf('Invalid x(t): %s', ME.message), 'error'); valid=false; end
            try, app.Parser.parseSignal(h_expr, t, dt); app.SignalhField.BackgroundColor=white;
            catch ME, app.SignalhField.BackgroundColor=red; app.updateStatus(sprintf('Invalid h(t): %s', ME.message), 'error'); valid=false; end
            
            if app.TimeStartField.Value >= app.TimeEndField.Value
                app.TimeStartField.BackgroundColor=red; app.TimeEndField.BackgroundColor=red;
                app.updateStatus('Error: Time Start must be < Time End', 'error'); valid=false;
            else, app.TimeStartField.BackgroundColor=white; app.TimeEndField.BackgroundColor=white; end
            
            if app.TimeStepField.Value <= 0
                app.TimeStepField.BackgroundColor=red; app.updateStatus('Error: Time Step must be > 0', 'error'); valid=false;
            else, app.TimeStepField.BackgroundColor=white; end
            
            % Validate custom range inputs if enabled
            if strcmp(app.CustomRangesButton.Text, 'Using Custom Ranges')
                if app.XTimeStartField.Value >= app.XTimeEndField.Value
                    app.XTimeStartField.BackgroundColor=red; app.XTimeEndField.BackgroundColor=red;
                    app.updateStatus('Error: x(t) Start must be < x(t) End', 'error'); valid=false;
                else, app.XTimeStartField.BackgroundColor=white; app.XTimeEndField.BackgroundColor=white; end
                
                if app.HTimeStartField.Value >= app.HTimeEndField.Value
                    app.HTimeStartField.BackgroundColor=red; app.HTimeEndField.BackgroundColor=red;
                    app.updateStatus('Error: h(t) Start must be < h(t) End', 'error'); valid=false;
                else, app.HTimeStartField.BackgroundColor=white; app.HTimeEndField.BackgroundColor=white; end
            end
            
            app.RunPauseButton.Enable=valid; app.StepButton.Enable=valid;
        end
        
        function [t, dt, x_expr, h_expr] = getSignalParameters(app)
            ts = app.TimeStartField.Value;
            te = app.TimeEndField.Value;
            dt = app.TimeStepField.Value;
            t = ts:dt:te;
            x_expr = app.SignalxField.Value;
            h_expr = app.SignalhField.Value;
        end

        function updateUIState(app)
            switch app.Animator.State
                case 'idle', app.RunPauseButton.Text='Run'; app.RunPauseButton.BackgroundColor=[.2 .7 .2];
                case 'running', app.RunPauseButton.Text='Pause'; app.RunPauseButton.BackgroundColor=[.9 .6 .1];
                case 'paused', app.RunPauseButton.Text='Resume'; app.RunPauseButton.BackgroundColor=[.2 .7 .2];
                case 'completed', app.RunPauseButton.Text='Run'; app.RunPauseButton.BackgroundColor=[.2 .7 .2];
            end
        end

        function toggleInputLock(app, lock)
            if lock, stateStr = 'off'; else, stateStr = 'on'; end
            set([app.SignalxField, app.SignalhField, app.TimeStartField, app.TimeEndField, ...
                 app.TimeStepField, app.PresetsDropDown], 'Enable', stateStr);
            
            % Also disable custom range fields during animation if enabled
            if strcmp(app.CustomRangesButton.Text, 'Using Custom Ranges')
                set([app.XTimeStartField, app.XTimeEndField, app.HTimeStartField, app.HTimeEndField], 'Enable', stateStr);
            end
            
            % Reset button should always be enabled
            app.ResetButton.Enable = 'on';
        end

        function updateProgress(app)
            if ~isempty(app.Engine) && app.Engine.IsInitialized
                app.ProgressGauge.Value = app.Engine.getProgress();
            end
        end
        
        function updateStatus(app, msg, type)
            if isvalid(app) && isvalid(app.StatusBar)
                app.StatusBar.Text = msg;
                switch type
                    case 'info', app.StatusBar.BackgroundColor = [0.5 0.5 0.5];
                    case 'running', app.StatusBar.BackgroundColor = [0.22 0.49 0.86]; % Blue
                    case 'paused', app.StatusBar.BackgroundColor = [0.95 0.61 0.07]; % Orange
                    case 'complete', app.StatusBar.BackgroundColor = [0.29 0.69 0.33]; % Green
                    case 'error', app.StatusBar.BackgroundColor = [0.85 0.26 0.22]; % Red
                end
            end
        end
        
        function onHelp(app)
            help_text = sprintf(['CONTINUOUS-TIME CONVOLUTION VISUALIZER v%s\n\n', ...
                'OVERVIEW:\n', ...
                'This application visualizes continuous-time convolution step-by-step.\n\n', ...
                'HOW TO USE:\n', ...
                '1. Enter signals x(t) and h(t) in the input fields\n', ...
                '2. Set time parameters (start, end, step size)\n', ...
                '3. Click "Run Animation" to see the convolution process\n', ...
                '4. Use "Single Step" to go forward step-by-step\n', ...
                '5. Use "Step Back" and "Step Forward" for navigation\n', ...
                '6. Adjust animation speed with the slider\n\n', ...
                'SIGNAL TYPES SUPPORTED:\n', ...
                '• Rectangular pulse: rect(t,width)\n', ...
                '• Triangular pulse: tri(t,width)\n', ...
                '• Gaussian pulse: gauss(t,sigma)\n', ...
                '• Sawtooth wave: saw(t,period)\n', ...
                '• Chirp signal: chirp(t,f0,T,f1)\n', ...
                '• Unit step: u(t)\n', ...
                '• Delta function: delta(t), A*delta(t-t0)\n', ...
                '• Trigonometric: sin(t), cos(t), sinc(t)\n', ...
                '• Exponential: exp(-t), exp(-t).*u(t)\n', ...
                '• Absolute value: abs(t)\n', ...
                '• Noise signals: whitenoise(t), pinknoise(t), brownnoise(t)\n\n', ...
                'ADVANCED FEATURES:\n', ...
                '• Custom Ranges: Set different time domains for x(t) and h(t)\n', ...
                '• Impulse Scaling: Heights proportional to impulse areas\n', ...
                '• Dynamic Y-Limits: Automatic scaling for better visualization\n', ...
                '• Smart Scaling: Prevents tall impulses from squishing other signals\n\n', ...
                'OPERATIONS AND PRIORITY RULES:\n', ...
                '1. Parentheses: (expression) - highest priority\n', ...
                '2. Function calls: f(t) - function evaluation\n', ...
                '3. Multiplication: .* - element-wise multiplication\n', ...
                '4. Addition/Subtraction: +, - - left to right\n\n', ...
                'ALLOWED EXPRESSIONS:\n', ...
                '• Simple: rect(t,2), u(t), delta(t-1)\n', ...
                '• Scaled: 2*rect(t,1), 0.5*exp(-t)\n', ...
                '• Shifted: rect(t-1,2), u(t+0.5)\n', ...
                '• Combined: rect(t,2).*u(t), exp(-t).*u(t)\n', ...
                '• Scaled/Shifted Delta: 2.5*delta(t-1.5)\n\n', ...
                'NOT ALLOWED:\n', ...
                '• Division: / (use multiplication by reciprocal)\n', ...
                '• Complex numbers: 1+2i\n', ...
                '• Invalid functions: unknown(t)\n', ...
                '• Non-numeric parameters: rect(t,a)\n\n', ...
                'KEYBOARD SHORTCUTS:\n', ...
                '• Space: Run/Pause animation\n', ...
                '• S: Single step forward\n', ...
                '• R: Reset\n', ...
                '• H: Show this help\n', ...
                '• ←/→: Step back/forward\n', ...
                '• Escape: Pause if running\n', ...
                '• E: Export visualization\n\n', ...
                'The app compares results with MATLAB conv() function\n', ...
                'and verifies mathematical theory compliance.'], app.AppVersion);

            uialert(app.UIFigure, help_text, 'Convolution Visualizer Help', ...
                'Icon', 'info', 'Modal', true);
        end

        function safeDelete(app)
            app.IsBeingDeleted = true;
            if ~isempty(app.Animator), app.Animator.reset(); end
            if isvalid(app.UIFigure), delete(app.UIFigure); end
        end
    end
end