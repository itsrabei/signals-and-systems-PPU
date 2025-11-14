function DT_Fourier_Series_App()
    % DT FOURIER SERIES VISUALIZATION APP - GROUPED CONTROLS VERSION
    % Interactive Discrete-Time Fourier Series Visualization with Proper Control Grouping
    % Author: Ahmed Rabei - TEFO, 2025
    % 
    % This app demonstrates Discrete-Time Fourier series synthesis and analysis
    % with properly grouped controls in titled sections for better organization.

    % --- Enhanced UI Setup ---
    fig = uifigure('Name', 'Interactive Discrete-Time Fourier Series Visualization', ...
        'Position', [100 100 1400 900], 'Color', [0.96 0.96 0.96], ...
        'CloseRequestFcn', @onClose);

    % Enhanced color scheme
    uiColors = struct();
    uiColors.bg = [0.96 0.96 0.96];
    uiColors.panel = [1 1 1];
    uiColors.text = [0.1 0.1 0.1];
    uiColors.primary = [0 0.4470 0.7410];
    uiColors.highlight = [0.8500 0.3250 0.0980];
    uiColors.secondary = [0.4940 0.1840 0.5560];
    uiColors.dt_signal = [0.8 0.2 0.6];

    % Enhanced font settings
    uiFonts = struct();
    uiFonts.size = 12;
    uiFonts.title = 14;
    uiFonts.math = 'Times New Roman';
    uiFonts.name = 'Arial';

    % Main layout
    mainGrid = uigridlayout(fig, [3 1]);
    mainGrid.RowHeight   = {'fit', '1x', 100};
    mainGrid.ColumnWidth = {'1x'};
    mainGrid.Padding = [10 10 10 10];
    
    % Main Controls Container
    controlContainer = uipanel(mainGrid, 'Title', 'DT Fourier Series Controls', ...
        'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    controlContainer.Layout.Row = 1;
    controlContainer.Layout.Column = 1;

    % Main control grid layout - 4 sections side by side
    mainCtrlGrid = uigridlayout(controlContainer, [1 3]);
    mainCtrlGrid.ColumnWidth = {'1x', '1x', '1x'};
    mainCtrlGrid.RowHeight = {'fit'};
    mainCtrlGrid.Padding = [10 10 10 10];
    mainCtrlGrid.ColumnSpacing = 10;

    % --- Initialize Enhanced Modules ---
    try
        dt_fs_math = DT_FS_Math();
        animation_controller = DT_FS_AnimationController(dt_fs_math);
        plot_manager = DT_FS_PlotManager();
    catch ME
        fprintf('Module initialization error: %s\n', ME.message);
        uialert(fig, sprintf('Failed to initialize modules: %s', ME.message), 'Initialization Error', 'Icon', 'error');
        return;
    end

    % --- Enhanced App State ---
    app_state = struct();
    app_state.original_signal = [];
    app_state.fourier_signal = [];
    app_state.sample_indices = [];
    app_state.coefficients = [];
    app_state.frequencies = [];
    app_state.harmonics = [];
    app_state.error_metrics = [];
    app_state.is_initialized = false;
    app_state.current_signal_type = 'Square Wave';
    app_state.current_period = 20;
    app_state.current_N = 10;

    % --- GROUPED CONTROL SECTIONS ---
    
    % === SIGNAL CONTROL SECTION ===
    signalPanel = uipanel(mainCtrlGrid, 'Title', 'Signal Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    signalPanel.Layout.Row = 1; signalPanel.Layout.Column = 1;
    
    signalGrid = uigridlayout(signalPanel, [5 3]);
    signalGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
    signalGrid.ColumnWidth = {'fit', '1x', 'fit'};
    signalGrid.Padding = [10 10 10 10];
    signalGrid.RowSpacing = 8;
    signalGrid.ColumnSpacing = 10;
    
    
    % Signal selection
    signalLabel = uilabel(signalGrid, 'Text', 'Signal Type:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    signalLabel.Layout.Row = 1; signalLabel.Layout.Column = 1;
    
    signalDropdown = uidropdown(signalGrid, 'Items', {'Square Wave', 'Sawtooth', 'Triangle', 'Sine Wave', 'Cosine Wave', 'Custom'}, ...
        'Value', 'Square Wave', 'ValueChangedFcn', @(~,~) updateSignal());
    signalDropdown.Layout.Row = 1; signalDropdown.Layout.Column = 2;

    % Fourier series parameters
    harmonicsLabel = uilabel(signalGrid, 'Text', 'Max Harmonics:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    harmonicsLabel.Layout.Row = 2; harmonicsLabel.Layout.Column = 1;
    
    harmonicsValue = uilabel(signalGrid, 'Text', '10', 'FontSize', uiFonts.size, 'HorizontalAlignment', 'right');
    harmonicsValue.Layout.Row = 2; harmonicsValue.Layout.Column = 3;
    
    % Slider now controls number of harmonic pairs (0 => DC only)
    harmonicsSlider = uislider(signalGrid, 'Limits', [0 50], 'Value', 10, ...
        'ValueChangedFcn', @(~,~) updateFourier(), ...
        'ValueChangingFcn', @(src, event) sliderChanging(src, event, harmonicsValue));
    harmonicsSlider.Layout.Row = 2; harmonicsSlider.Layout.Column = 2;

    % Period control
    periodLabel = uilabel(signalGrid, 'Text', 'Period (N):', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    periodLabel.Layout.Row = 3; periodLabel.Layout.Column = 1;
    
    periodValue = uilabel(signalGrid, 'Text', '20', 'FontSize', uiFonts.size, 'HorizontalAlignment', 'right');
    periodValue.Layout.Row = 3; periodValue.Layout.Column = 3;
    
    periodSlider = uislider(signalGrid, 'Limits', [4 100], 'Value', 20, ...
        'ValueChangedFcn', @(~,~) updateSignal(), ...
        'ValueChangingFcn', @(src, event) sliderChanging(src, event, periodValue));
    periodSlider.Layout.Row = 3; periodSlider.Layout.Column = 2;

    % Help button
    helpBtn = uibutton(signalGrid, 'Text', 'Help', 'ButtonPushedFcn', @(~,~) showHelp());
    helpBtn.Layout.Row = 4; helpBtn.Layout.Column = 1;

    % Export button
    exportBtn = uibutton(signalGrid, 'Text', 'Export', 'ButtonPushedFcn', @(~,~) exportData());
    exportBtn.Layout.Row = 4; exportBtn.Layout.Column = 2;

    % === ANIMATION CONTROL SECTION ===
    animationPanel = uipanel(mainCtrlGrid, 'Title', 'Animation Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    animationPanel.Layout.Row = 1; animationPanel.Layout.Column = 2;
    
    animationGrid = uigridlayout(animationPanel, [5 7]);
    animationGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
    animationGrid.ColumnWidth = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    animationGrid.Padding = [10 10 10 10];
    animationGrid.RowSpacing = 8;
    animationGrid.ColumnSpacing = 10;

    % Animation buttons
    playBtn = uibutton(animationGrid, 'Text', 'Play', 'ButtonPushedFcn', @(~,~) playAnimation());
    playBtn.Layout.Row = 1; playBtn.Layout.Column = 1;
    
    stopBtn = uibutton(animationGrid, 'Text', 'Stop', 'ButtonPushedFcn', @(~,~) stopAnimation(), 'Enable', 'off');
    stopBtn.Layout.Row = 1; stopBtn.Layout.Column = 2;
    
    % Reverse button removed as redundant

    % Speed control
    speedLabel = uilabel(animationGrid, 'Text', 'Speed:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    speedLabel.Layout.Row = 3; speedLabel.Layout.Column = 1;
    
    % Speed buttons
    speed05Btn = uibutton(animationGrid, 'Text', '0.5x', 'ButtonPushedFcn', @(~,~) setSpeed(0.5));
    speed05Btn.Layout.Row = 3; speed05Btn.Layout.Column = 2;
    
    speed10Btn = uibutton(animationGrid, 'Text', '1.0x', 'ButtonPushedFcn', @(~,~) setSpeed(1.0));
    speed10Btn.Layout.Row = 3; speed10Btn.Layout.Column = 3;
    
    speed15Btn = uibutton(animationGrid, 'Text', '1.5x', 'ButtonPushedFcn', @(~,~) setSpeed(1.5));
    speed15Btn.Layout.Row = 3; speed15Btn.Layout.Column = 4;
    
    speed20Btn = uibutton(animationGrid, 'Text', '2.0x', 'ButtonPushedFcn', @(~,~) setSpeed(2.0));
    speed20Btn.Layout.Row = 3; speed20Btn.Layout.Column = 5;
    
    speed25Btn = uibutton(animationGrid, 'Text', '2.5x', 'ButtonPushedFcn', @(~,~) setSpeed(2.5));
    speed25Btn.Layout.Row = 3; speed25Btn.Layout.Column = 6;
    
    speed30Btn = uibutton(animationGrid, 'Text', '3.0x', 'ButtonPushedFcn', @(~,~) setSpeed(3.0));
    speed30Btn.Layout.Row = 3; speed30Btn.Layout.Column = 7;
    
    % Set initial button color for default speed (1.0x)
    speed10Btn.BackgroundColor = [0.2 0.6 1.0];  % Blue for default speed
    
    % Sample duration controls
    durationLabel = uilabel(animationGrid, 'Text', 'Sample Duration:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    durationLabel.Layout.Row = 4; durationLabel.Layout.Column = 1;
    
    duration01Btn = uibutton(animationGrid, 'Text', '0.1s', 'ButtonPushedFcn', @(~,~) setSampleDuration(0.1));
    duration01Btn.Layout.Row = 4; duration01Btn.Layout.Column = 2;
    
    duration05Btn = uibutton(animationGrid, 'Text', '0.5s', 'ButtonPushedFcn', @(~,~) setSampleDuration(0.5));
    duration05Btn.Layout.Row = 4; duration05Btn.Layout.Column = 3;
    
    duration10Btn = uibutton(animationGrid, 'Text', '1.0s', 'ButtonPushedFcn', @(~,~) setSampleDuration(1.0));
    duration10Btn.Layout.Row = 4; duration10Btn.Layout.Column = 4;
    
    % Set initial button color for default duration (0.5s)
    duration05Btn.BackgroundColor = [0.2 0.6 1.0];  % Blue for default duration

    % === DISPLAY CONTROL SECTION ===
    displayPanel = uipanel(mainCtrlGrid, 'Title', 'Display Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    displayPanel.Layout.Row = 1; displayPanel.Layout.Column = 3;
    
    displayGrid = uigridlayout(displayPanel, [5 1]);
    displayGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
    displayGrid.ColumnWidth = {'1x'};
    displayGrid.Padding = [10 10 10 10];
    displayGrid.RowSpacing = 5;

    % Display options
    % Gibbs phenomenon checkbox removed as requested

    showOrthogonalityChk = uicheckbox(displayGrid, 'Text', 'Show Orthogonality', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showOrthogonalityChk.Layout.Row = 2;

    showSpectrumChk = uicheckbox(displayGrid, 'Text', 'Show Spectrum', 'Value', true, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showSpectrumChk.Layout.Row = 3;

    % Error display removed - error analysis is shown in Properties plot

    showConvergenceChk = uicheckbox(displayGrid, 'Text', 'Show Convergence', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showConvergenceChk.Layout.Row = 4;

    % Show Properties checkbox removed as requested

    % Figure Control section removed as requested

    % --- PLOT AREA ---
    plotContainer = uipanel(mainGrid, 'Title', 'DT Fourier Series Visualization', ...
        'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    plotContainer.Layout.Row = 2;
    plotContainer.Layout.Column = 1;

    % Create 2x2 grid for plots
    plotGrid = uigridlayout(plotContainer, [2 2]);
    plotGrid.RowHeight = {'1x', '1x'};
    plotGrid.ColumnWidth = {'1x', '1x'};
    plotGrid.Padding = [10 10 10 10];
    plotGrid.RowSpacing = 10;
    plotGrid.ColumnSpacing = 10;

    % Create axes
    timeAxis = uiaxes(plotGrid);
    timeAxis.Layout.Row = 1; timeAxis.Layout.Column = 1;
    title(timeAxis, 'Discrete-Time Domain', 'FontSize', uiFonts.size);
    
    freqAxis = uiaxes(plotGrid);
    freqAxis.Layout.Row = 1; freqAxis.Layout.Column = 2;
    title(freqAxis, 'DTFS Magnitude Spectrum', 'FontSize', uiFonts.size);
    
    harmonicsAxis = uiaxes(plotGrid);
    harmonicsAxis.Layout.Row = 2; harmonicsAxis.Layout.Column = 1;
    title(harmonicsAxis, 'Individual Harmonics', 'FontSize', uiFonts.size);
    
    propertiesAxis = uiaxes(plotGrid);
    propertiesAxis.Layout.Row = 2; propertiesAxis.Layout.Column = 2;
    title(propertiesAxis, 'DTFS Properties & Analysis', 'FontSize', uiFonts.size);

    % --- STATUS AREA ---
    statusContainer = uipanel(mainGrid, 'Title', 'Status & Information', ...
        'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    statusContainer.Layout.Row = 3;
    statusContainer.Layout.Column = 1;

    statusGrid = uigridlayout(statusContainer, [4 1]);
    statusGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    statusGrid.ColumnWidth = {'1x'};
    statusGrid.Padding = [10 10 10 10];
    statusGrid.RowSpacing = 5;

    % Status label
    statusLabel = uilabel(statusGrid, 'Text', 'Ready - DT Fourier Series Visualization', ...
        'FontSize', uiFonts.size, 'FontWeight', 'bold');
    statusLabel.Layout.Row = 1;

    % Error metrics label
    metricsLabel = uilabel(statusGrid, 'Text', 'MSE: 0.000 | SNR: ∞ dB | Convergence: 100%', ...
        'FontSize', uiFonts.size);
    metricsLabel.Layout.Row = 2;

    % Mathematical equation label
    equationLabel = uilabel(statusGrid, 'Text', 'x[n] = Σ[k=0 to N-1] X[k]e^(j2πkn/N)', ...
        'FontSize', uiFonts.size, 'FontName', uiFonts.math);
    equationLabel.Layout.Row = 3;

    % Progress bar
    progressBar = uiprogressdlg(fig, 'Title', 'Processing', 'Message', 'Initializing...', 'Indeterminate', 'on');

    % --- INITIALIZE PLOT MANAGER ---
    try
        plot_manager.setAxes(timeAxis, freqAxis, harmonicsAxis, propertiesAxis);
        plot_manager.setFourierMath(dt_fs_math);
        close(progressBar);
    catch ME
        close(progressBar);
        fprintf('Plot manager initialization error: %s\n', ME.message);
        uialert(fig, sprintf('Failed to initialize plot manager: %s', ME.message), 'Initialization Error', 'Icon', 'error');
        return;
    end

    % --- INITIALIZE ANIMATION CONTROLLER ---
    try
        animation_controller.setUpdateCallback(@updateAnimationCallback);
        animation_controller.setCompletionCallback(@animationCompleted);
        animation_controller.setProgressCallback(@updateProgress);
    catch ME
        fprintf('Animation controller initialization error: %s\n', ME.message);
    end

    % --- INITIALIZE APP ---
    try
        updateSignal();
        updateFourier();
        app_state.is_initialized = true;
        statusLabel.Text = 'Ready - DT Fourier Series Visualization';
    catch ME
        fprintf('App initialization error: %s\n', ME.message);
        statusLabel.Text = sprintf('Initialization Error: %s', ME.message);
    end

    % --- HELPER FUNCTIONS ---
    function sliderChanging(src, event, labelHandle)
        % Update slider label in real-time during dragging
        try
            labelHandle.Text = num2str(round(event.Value));
        catch ME
            fprintf('Slider changing error: %s\n', ME.message);
        end
    end

    % --- CALLBACK FUNCTIONS ---
    
    function updateSignal()
        try
            statusLabel.Text = 'Generating discrete signal...';
            
            % Get current parameters
            signal_type = signalDropdown.Value;
            N = round(periodSlider.Value);
            periodValue.Text = num2str(N);
            
            % Generate sample indices
            n = (0:N-1)';
            
            % Generate signal based on type
            switch signal_type
                case 'Square Wave'
                    signal = square(2*pi*(0:N-1)/N)';
                case 'Sawtooth'
                    signal = sawtooth(2*pi*(0:N-1)/N)';
                case 'Triangle'
                    signal = sawtooth(2*pi*(0:N-1)/N, 0.5)';
                case 'Sine Wave'
                    signal = sin(2*pi*(0:N-1)/N)';
                case 'Cosine Wave'
                    signal = cos(2*pi*(0:N-1)/N)';
                case 'Custom'
                    % Custom signal: combination of sine waves
                    signal = (0.5*sin(2*pi*(0:N-1)/N) + 0.3*sin(4*pi*(0:N-1)/N) + 0.2*sin(6*pi*(0:N-1)/N))';
                otherwise
                    signal = square(2*pi*(0:N-1)/N)';
            end
            
            % Keep original signal amplitude for proper DTFS analysis
            % (No normalization to preserve mathematical accuracy)
            
            % Update app state
            app_state.original_signal = signal;
            app_state.sample_indices = n;
            app_state.current_signal_type = signal_type;
            app_state.current_period = N;
            
            % Update harmonics slider limits to match available harmonic pairs
            % (0 => DC only, 1 => DC+±1, ...)
            pair_max = max(0, floor((N - 1) / 2));
            harmonicsSlider.Limits = [0, pair_max];
            if harmonicsSlider.Value > pair_max
                harmonicsSlider.Value = pair_max;
                harmonicsValue.Text = num2str(pair_max); % Update text label
            end
            
            % Update Fourier analysis
            updateFourier();
            
            statusLabel.Text = sprintf('Ready - %s signal with period %d', signal_type, N);
            
        catch ME
            fprintf('Signal generation error: %s\n', ME.message);
            statusLabel.Text = sprintf('Signal Error: %s', ME.message);
        end
    end

    function updateFourier()
        try
            if isempty(app_state.original_signal)
                return;
            end
            
            statusLabel.Text = 'Computing DTFS coefficients...';
            
            % Get current parameters
            N = app_state.current_period;
            % Interpret slider as number of harmonic pairs
            pair_count = round(harmonicsSlider.Value);
            % Clamp to available pairs
            pair_count = max(0, min(pair_count, floor((length(app_state.original_signal) - 1) / 2)));
            harmonicsValue.Text = num2str(pair_count);
            
            % Calculate DTFS coefficients
            [coefficients, frequencies, magnitude, phase] = dt_fs_math.calculateFourierCoefficients(...
                app_state.original_signal, app_state.sample_indices, length(app_state.original_signal));
            
            % Synthesize Fourier series
            [fourier_signal, ~] = dt_fs_math.synthesizeFourierSeries(...
                coefficients, frequencies, app_state.sample_indices, pair_count);
            
            % Generate individual harmonics for visualization
            harmonics = dt_fs_math.generateHarmonics(coefficients, frequencies, app_state.sample_indices, pair_count);
            
            % Calculate error metrics
            error_metrics = dt_fs_math.calculateErrorMetrics(app_state.original_signal, fourier_signal);
            
            % Update app state - show all coefficients in spectrum, but limit synthesis
            app_state.coefficients = coefficients;  % Show all coefficients in spectrum
            app_state.frequencies = frequencies;    % Show all frequencies in spectrum
            app_state.fourier_signal = fourier_signal;
            app_state.harmonics = harmonics;
            app_state.error_metrics = error_metrics;
            app_state.current_N = pair_count;
            
            % Update plots
            updatePlots();
            
            % Update status
            statusLabel.Text = sprintf('Ready - %s signal with %d harmonics at period %d', ...
                app_state.current_signal_type, pair_count, N);
            
        catch ME
            fprintf('Fourier analysis error: %s\n', ME.message);
            statusLabel.Text = sprintf('Fourier Error: %s', ME.message);
        end
    end

    function updatePlots()
        try
            if isempty(app_state.original_signal)
                return;
            end
            
            % Update plot manager data
            plot_manager.updateData(app_state.original_signal, app_state.fourier_signal, ...
                app_state.sample_indices, app_state.coefficients, app_state.frequencies, ...
                app_state.harmonics);
            
            % Update all plots
            plot_manager.updateAllPlots();
            
            % Update metrics
            if ~isempty(app_state.error_metrics)
                metricsLabel.Text = sprintf('MSE: %.4f | SNR: %.1f dB | Convergence: %.1f%%', ...
                    app_state.error_metrics.mse, app_state.error_metrics.snr_db, ...
                    app_state.error_metrics.convergence * 100);
            end
            
        catch ME
            fprintf('Plot update error: %s\n', ME.message);
            statusLabel.Text = sprintf('Plot Error: %s', ME.message);
        end
    end

    function updateDisplay()
        try
            % Update plot manager display options
            plot_manager.setDisplayOptions(showOrthogonalityChk.Value, ...
                showSpectrumChk.Value, false, false, ...
                showConvergenceChk.Value);
            
            % Update plots
            updatePlots();
            
            statusLabel.Text = 'Display options updated';
            
        catch ME
            fprintf('Display update error: %s\n', ME.message);
            statusLabel.Text = sprintf('Display Error: %s', ME.message);
        end
    end

    % updateFigureDisplay function removed as Figure Control section was deleted

    function playAnimation()
        try
            if isempty(app_state.original_signal)
                statusLabel.Text = 'Error: No signal to animate';
                return;
            end
            
            % Pass pair count to animation controller
            pair_count = round(harmonicsSlider.Value);
            animation_controller.startAnimation(app_state.original_signal, app_state.sample_indices, ...
                pair_count, app_state.current_period);
            
            playBtn.Enable = 'off';
            stopBtn.Enable = 'on';
            statusLabel.Text = 'Animation started';
            
        catch ME
            fprintf('Animation start error: %s\n', ME.message);
            statusLabel.Text = 'Animation error occurred';
        end
    end

    function stopAnimation()
        try
            animation_controller.stopAnimation();
            playBtn.Enable = 'on';
            stopBtn.Enable = 'off';
            statusLabel.Text = 'Animation stopped';
            
        catch ME
            fprintf('Animation stop error: %s\n', ME.message);
            statusLabel.Text = 'Animation stop error occurred';
        end
    end

    % reverseAnimation function removed as reverse button was removed

    function setSpeed(speed)
        try
            animation_controller.setSpeed(speed);
            statusLabel.Text = sprintf('Animation speed set to %.1fx', speed);
            
            % Update button colors - reset all to default, then highlight selected
            speed_buttons = [speed05Btn, speed10Btn, speed15Btn, speed20Btn, speed25Btn, speed30Btn];
            speed_values = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
            
            % Reset all buttons to default color
            for i = 1:length(speed_buttons)
                speed_buttons(i).BackgroundColor = [0.94 0.94 0.94];  % Default gray
            end
            
            % Highlight selected button with blue color
            selected_idx = find(abs(speed_values - speed) < 0.01);
            if ~isempty(selected_idx)
                speed_buttons(selected_idx).BackgroundColor = [0.2 0.6 1.0];  % Blue
            end
            
        catch ME
            fprintf('Speed update error: %s\n', ME.message);
            statusLabel.Text = 'Speed update error occurred';
        end
    end

    function setSampleDuration(duration)
        try
            animation_controller.setSampleDuration(duration);
            statusLabel.Text = sprintf('Sample duration set to %.1fs', duration);
            
            % Update button colors - reset all to default, then highlight selected
            duration_buttons = [duration01Btn, duration05Btn, duration10Btn];
            duration_values = [0.1, 0.5, 1.0];
            
            % Reset all buttons to default color
            for i = 1:length(duration_buttons)
                duration_buttons(i).BackgroundColor = [0.94 0.94 0.94];  % Default gray
            end
            
            % Highlight selected button with blue color
            selected_idx = find(abs(duration_values - duration) < 0.01);
            if ~isempty(selected_idx)
                duration_buttons(selected_idx).BackgroundColor = [0.2 0.6 1.0];  % Blue
            end
            
        catch ME
            fprintf('Sample duration update error: %s\n', ME.message);
            statusLabel.Text = 'Sample duration update error occurred';
        end
    end

    function updateAnimationCallback(animation_data)
        try
            if nargin > 0 && ~isempty(animation_data)
                % Update app state with animation data
                app_state.fourier_signal = animation_data.fourier_signal;
                app_state.coefficients = animation_data.coefficients;
                app_state.frequencies = animation_data.frequencies;
                app_state.harmonics = animation_data.harmonics;
                app_state.error_metrics = animation_data.error_metrics;
                
                % Set current harmonic count (DC + pair_count columns)
                plot_manager.setCurrentHarmonicCount(max(1, animation_data.current_harmonic + 1));
                
                % Update plots
                updatePlots();
                
                % Update equation with current harmonic count
                equationLabel.Text = sprintf('x[n] = DC + sum_{k=1}^{%d} X[±k]e^{±j2πkn/N}', max(0, animation_data.current_harmonic));
            end
            
        catch ME
            fprintf('Animation callback error: %s\n', ME.message);
        end
    end

    function animationCompleted()
        try
            playBtn.Enable = 'on';
            stopBtn.Enable = 'off';
            statusLabel.Text = 'Animation completed';
            
        catch ME
            fprintf('Animation completion error: %s\n', ME.message);
        end
    end

    function updateProgress(progress, current_harmonic, max_harmonics)
        try
            if nargin >= 3
                % Display progress with proper labeling for pairs
                if current_harmonic == -1
                    statusLabel.Text = sprintf('Animation: Starting (%.1f%%)', progress * 100);
                elseif current_harmonic == 0
                    statusLabel.Text = sprintf('Animation: DC Component (%.1f%%)', progress * 100);
                else
                    statusLabel.Text = sprintf('Animation: ±%d Pair (%d of %d) (%.1f%%)', ...
                        current_harmonic, current_harmonic, max_harmonics, progress * 100);
                end
            end
            
        catch ME
            fprintf('Progress update error: %s\n', ME.message);
        end
    end

    function exportData()
        try
            % Create file dialog
            [filename, pathname] = uiputfile({'*.mat', 'MATLAB Data Files (*.mat)'; ...
                '*.fig', 'MATLAB Figure Files (*.fig)'; ...
                '*.png', 'PNG Image Files (*.png)'; ...
                '*.pdf', 'PDF Files (*.pdf)'}, ...
                'Export Data', 'dtfs_export.mat');
            
            if filename ~= 0
                [~, ~, ext] = fileparts(filename);
                
                switch lower(ext)
                    case '.mat'
                        % Export data
                        plot_manager.exportData(fullfile(pathname, filename));
                    case {'.fig', '.png', '.pdf'}
                        % Ask user which plot to export
                        plot_choice = uiconfirm(fig, ...
                            'Which plot would you like to export?', ...
                            'Select Plot', ...
                            'Options', {'Time Domain', 'Frequency Domain', 'Harmonics', 'Properties', 'Cancel'}, ...
                            'DefaultOption', 1, ...
                            'CancelOption', 5);
                        
                        if ~strcmp(plot_choice, 'Cancel')
                            % Select the appropriate axis
                            switch plot_choice
                                case 'Time Domain'
                                    selected_axis = timeAxis;
                                case 'Frequency Domain'
                                    selected_axis = freqAxis;
                                case 'Harmonics'
                                    selected_axis = harmonicsAxis;
                                case 'Properties'
                                    selected_axis = propertiesAxis;
                            end
                            
                            % Export the selected plot
                            plot_manager.exportPlot(selected_axis, fullfile(pathname, filename), ext(2:end));
                        else
                            statusLabel.Text = 'Export cancelled';
                            return;
                        end
                    otherwise
                        statusLabel.Text = 'Unsupported export format';
                        return;
                end
                
                statusLabel.Text = sprintf('Data exported to %s', filename);
            end
            
        catch ME
            fprintf('Export error: %s\n', ME.message);
            statusLabel.Text = sprintf('Export Error: %s', ME.message);
        end
    end

    function showHelp()
        try
            help_text = {
                'DT Fourier Series Visualization Help';
                '';
                'This app demonstrates Discrete-Time Fourier Series (DTFS) concepts:';
                '';
                '1. Signal Control:';
                '   - Select different signal types';
                '   - Adjust period (N) and number of harmonics';
                '';
                '2. Animation Control:';
                '   - Play/Stop animation to see harmonic convergence';
                '   - Reverse direction and adjust speed';
                '';
                '3. Display Control:';
                '   - Toggle various analysis features';
                '   - Show orthogonality, spectrum, etc.';
                '';
                '4. Figure Control:';
                '   - Show/hide individual plots';
                '';
                'The DTFS formula: x[n] = Σ[k=0 to N-1] X[k]e^(j2πkn/N)';
                'where X[k] = (1/N)Σ[n=0 to N-1] x[n]e^(-j2πkn/N)';
                '';
                'Error Signal Equation: e[n] = x[n] - x̂[n]';
                'where x̂[n] is the synthesized signal using DTFS coefficients';
            };
            
            uialert(fig, strjoin(help_text, '\n'), 'Help', 'Icon', 'info');
            
        catch ME
            fprintf('Help display error: %s\n', ME.message);
        end
    end

    function onClose(~, ~)
        try
            % Stop animation and clean up timers
            if exist('animation_controller', 'var') && ~isempty(animation_controller)
                animation_controller.stopAnimation();
                % Force cleanup of any remaining timers
                try
                    if isa(animation_controller, 'DT_FS_AnimationController') && ...
                       ~isempty(animation_controller.animation_timer) && ...
                       isvalid(animation_controller.animation_timer)
                        stop(animation_controller.animation_timer);
                        delete(animation_controller.animation_timer);
                    end
                catch
                    % Ignore cleanup errors
                end
            end
            
            % Clear any remaining timers
            timers = timerfind;
            if ~isempty(timers)
                stop(timers);
                delete(timers);
            end
            
            % Close the figure
            delete(fig);
            
        catch ME
            % Multiple fallback levels for robust shutdown
            fprintf('Cleanup error: %s\n', ME.message);
            try
                delete(fig);
            catch
                close all force;  % Last resort
            end
        end
    end
end
