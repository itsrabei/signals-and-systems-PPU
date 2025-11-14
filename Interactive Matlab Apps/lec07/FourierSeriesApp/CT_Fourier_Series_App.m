function CT_Fourier_Series_App()
    % CT FOURIER SERIES VISUALIZATION APP - GROUPED CONTROLS VERSION
    % Interactive Continuous-Time Fourier Series Visualization with Proper Control Grouping
    % Author: Ahmed Rabei - TEFO, 2025
    % 
    % This app demonstrates Continuous-Time Fourier series synthesis and analysis
    % with properly grouped controls in titled sections for better organization.

    % --- Enhanced UI Setup ---
    fig = uifigure('Name', 'Interactive Continuous-Time Fourier Series Visualization', ...
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
    uiColors.ct_signal = [0.1 0.3 0.8];

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
    controlContainer = uipanel(mainGrid, 'Title', 'CT Fourier Series Controls', ...
        'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    controlContainer.Layout.Row = 1;
    controlContainer.Layout.Column = 1;

    % Main control grid layout - 4 sections side by side
    mainCtrlGrid = uigridlayout(controlContainer, [1 4]);
    mainCtrlGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
    mainCtrlGrid.RowHeight = {'fit'};
    mainCtrlGrid.Padding = [10 10 10 10];
    mainCtrlGrid.ColumnSpacing = 10;

    % --- Initialize Enhanced Modules ---
    try
        ct_fs_math = CT_FS_Math();
        animation_controller = CT_FS_AnimationController(ct_fs_math);
        plot_manager = CT_FS_PlotManager();
    catch ME
        fprintf('Module initialization error: %s\n', ME.message);
        uialert(fig, sprintf('Failed to initialize modules: %s', ME.message), 'Initialization Error', 'Icon', 'error');
        return;
    end

    % --- Enhanced App State ---
    app_state = struct();
    app_state.original_signal = [];
    app_state.fourier_signal = [];
    app_state.time_vector = [];
    app_state.coefficients = [];
    app_state.frequencies = [];
    app_state.harmonics = [];
    app_state.error_metrics = [];
    app_state.is_initialized = false;
    app_state.current_signal_type = 'Square Wave';
    app_state.current_f0 = 1;
    app_state.current_N = 10;

    % --- GROUPED CONTROL SECTIONS ---
    
    % === SIGNAL CONTROL SECTION ===
    signalPanel = uipanel(mainCtrlGrid, 'Title', 'Signal Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    signalPanel.Layout.Row = 1; signalPanel.Layout.Column = 1;
    
    signalGrid = uigridlayout(signalPanel, [5 2]);
    signalGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
    signalGrid.ColumnWidth = {'fit', '1x'};
    signalGrid.Padding = [10 10 10 10];
    signalGrid.RowSpacing = 8;
    signalGrid.ColumnSpacing = 10;
    
    
    % Signal selection
    signalLabel = uilabel(signalGrid, 'Text', 'Signal Type:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    signalLabel.Layout.Row = 1; signalLabel.Layout.Column = 1;
    
    signalDropdown = uidropdown(signalGrid, 'Items', {'Square Wave', 'Sawtooth', 'Triangle', 'Half-Wave Rectified', 'Full-Wave Rectified', 'Custom'}, ...
        'Value', 'Square Wave', 'ValueChangedFcn', @(~,~) updateSignal());
    signalDropdown.Layout.Row = 1; signalDropdown.Layout.Column = 2;

    % Fourier series parameters
    harmonicsLabel = uilabel(signalGrid, 'Text', 'Max Harmonics:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    harmonicsLabel.Layout.Row = 2; harmonicsLabel.Layout.Column = 1;
    
    harmonicsSlider = uislider(signalGrid, 'Limits', [1 50], 'Value', 10, ...
        'ValueChangedFcn', @(~,~) updateFourier());
    harmonicsSlider.Layout.Row = 2; harmonicsSlider.Layout.Column = 2;
    
    % Fundamental frequency
    freqLabel = uilabel(signalGrid, 'Text', 'Fundamental f0 (Hz):', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    freqLabel.Layout.Row = 3; freqLabel.Layout.Column = 1;
    
    freqSlider = uislider(signalGrid, 'Limits', [0.1 5], 'Value', 1, ...
        'ValueChangedFcn', @(~,~) updateSignal());
    freqSlider.Layout.Row = 3; freqSlider.Layout.Column = 2;

    % Export buttons
    exportPlotsBtn = uibutton(signalGrid, 'Text', 'Export Plots', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) exportPlots());
    exportPlotsBtn.Layout.Row = 4; exportPlotsBtn.Layout.Column = 1;
    
    exportDataBtn = uibutton(signalGrid, 'Text', 'Export Data', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) exportData());
    exportDataBtn.Layout.Row = 4; exportDataBtn.Layout.Column = 2;
    
    % Help button
    helpBtn = uibutton(signalGrid, 'Text', '?', 'FontSize', 16, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) showHelp());
    helpBtn.Layout.Row = 5; helpBtn.Layout.Column = 1;

    % === ANIMATION CONTROL SECTION ===
    animPanel = uipanel(mainCtrlGrid, 'Title', 'Animation Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    animPanel.Layout.Row = 1; animPanel.Layout.Column = 2;
    
    animGrid = uigridlayout(animPanel, [4 2]);
    animGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    animGrid.ColumnWidth = {'fit', '1x'};
    animGrid.Padding = [10 10 10 10];
    animGrid.RowSpacing = 8;
    animGrid.ColumnSpacing = 10;
    
    % Animation controls
    playBtn = uibutton(animGrid, 'Text', '▶ Play', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) playAnimation());
    playBtn.Layout.Row = 1; playBtn.Layout.Column = 1;

    stopBtn = uibutton(animGrid, 'Text', '■ Stop', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) stopAnimation(), 'Enable', 'off');
    stopBtn.Layout.Row = 1; stopBtn.Layout.Column = 2;

    reverseBtn = uibutton(animGrid, 'Text', '◀ Reverse', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) reverseAnimation());
    reverseBtn.Layout.Row = 2; reverseBtn.Layout.Column = 1;

    % Discrete Speed control
    speedLabel = uilabel(animGrid, 'Text', 'Speed:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    speedLabel.Layout.Row = 3; speedLabel.Layout.Column = 1;
    
    % Speed buttons for discrete levels
    speedBtnGrid = uigridlayout(animGrid, [2 3]);
    speedBtnGrid.Layout.Row = 3; speedBtnGrid.Layout.Column = 2;
    speedBtnGrid.RowHeight = {'fit', 'fit'};
    speedBtnGrid.ColumnWidth = {'fit', 'fit', 'fit'};
    
    % Create speed buttons
    speedButtons = [];
    speedLevels = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
    for i = 1:length(speedLevels)
        speed = speedLevels(i);
        row = ceil(i/3);
        col = mod(i-1, 3) + 1;
        
        btn = uibutton(speedBtnGrid, 'Text', sprintf('%.1fx', speed), ...
            'ButtonPushedFcn', @(~,~) setDiscreteSpeed(speed));
        btn.Layout.Row = row;
        btn.Layout.Column = col;
        speedButtons = [speedButtons, btn];
    end
    
    % Highlight current speed (1.0x by default)
    currentSpeedButton = speedButtons(2);  % 1.0x button
    currentSpeedButton.BackgroundColor = [0.2 0.6 1.0];  % Blue highlight
    
    speedValue = uilabel(animGrid, 'Text', '1.0x', 'FontSize', uiFonts.size, 'FontWeight', 'bold');
    speedValue.Layout.Row = 4; speedValue.Layout.Column = 1;
    speedValue.HorizontalAlignment = 'right';

    % === DISPLAY CONTROL SECTION ===
    displayPanel = uipanel(mainCtrlGrid, 'Title', 'Display Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    displayPanel.Layout.Row = 1; displayPanel.Layout.Column = 3;
    
    displayGrid = uigridlayout(displayPanel, [4 2]);
    displayGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    displayGrid.ColumnWidth = {'fit', '1x'};
    displayGrid.Padding = [10 10 10 10];
    displayGrid.RowSpacing = 8;
    displayGrid.ColumnSpacing = 10;
    
    % Display options
    showGibbsChk = uicheckbox(displayGrid, 'Text', 'Show Gibbs', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showGibbsChk.Layout.Row = 1; showGibbsChk.Layout.Column = 1;

    showOrthogonalityChk = uicheckbox(displayGrid, 'Text', 'Orthogonality', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showOrthogonalityChk.Layout.Row = 1; showOrthogonalityChk.Layout.Column = 2;

    showSpectrumChk = uicheckbox(displayGrid, 'Text', 'Spectrum', 'Value', true, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showSpectrumChk.Layout.Row = 2; showSpectrumChk.Layout.Column = 1;


    showErrorChk = uicheckbox(displayGrid, 'Text', 'Error', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showErrorChk.Layout.Row = 2; showErrorChk.Layout.Column = 2;

    showConvergenceChk = uicheckbox(displayGrid, 'Text', 'Convergence', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateDisplay());
    showConvergenceChk.Layout.Row = 3; showConvergenceChk.Layout.Column = 1;


    % === FIGURE CONTROL SECTION ===
    figurePanel = uipanel(mainCtrlGrid, 'Title', 'Figure Control', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    figurePanel.Layout.Row = 1; figurePanel.Layout.Column = 4;
    
    figureGrid = uigridlayout(figurePanel, [8 2]);
    figureGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    figureGrid.ColumnWidth = {'fit', '1x'};
    figureGrid.Padding = [10 10 10 10];
    figureGrid.RowSpacing = 8;
    figureGrid.ColumnSpacing = 10;
    
    % Figure display controls
    showTimeDomainChk = uicheckbox(figureGrid, 'Text', 'Time Domain', 'Value', true, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateFigureDisplay());
    showTimeDomainChk.Layout.Row = 1; showTimeDomainChk.Layout.Column = 1;

    showFreqDomainChk = uicheckbox(figureGrid, 'Text', 'Frequency Domain', 'Value', true, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateFigureDisplay());
    showFreqDomainChk.Layout.Row = 1; showFreqDomainChk.Layout.Column = 2;

    showHarmonicsChk = uicheckbox(figureGrid, 'Text', 'Harmonics', 'Value', true, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateFigureDisplay());
    showHarmonicsChk.Layout.Row = 2; showHarmonicsChk.Layout.Column = 1;

    showPropertiesFigureChk = uicheckbox(figureGrid, 'Text', 'Properties', 'Value', true, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updateFigureDisplay());
    showPropertiesFigureChk.Layout.Row = 2; showPropertiesFigureChk.Layout.Column = 2;

    % Max harmonics display control
    maxHarmonicsLabel = uilabel(figureGrid, 'Text', 'Max Harmonics Display:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    maxHarmonicsLabel.Layout.Row = 3; maxHarmonicsLabel.Layout.Column = 1;
    
    maxHarmonicsDisplaySlider = uislider(figureGrid, 'Limits', [1 20], 'Value', 5, ...
        'ValueChangedFcn', @(~,~) updateMaxHarmonicsDisplay());
    maxHarmonicsDisplaySlider.Layout.Row = 3; maxHarmonicsDisplaySlider.Layout.Column = 2;

    % Plot element controls
    showOriginalSignalChk = uicheckbox(figureGrid, 'Text', 'Original Signal', 'Value', true, ...
        'FontSize', uiFonts.size-1, 'ValueChangedFcn', @(~,~) updatePlotElements());
    showOriginalSignalChk.Layout.Row = 4; showOriginalSignalChk.Layout.Column = 1;

    showFourierApproxChk = uicheckbox(figureGrid, 'Text', 'Fourier Approximation', 'Value', true, ...
        'FontSize', uiFonts.size-1, 'ValueChangedFcn', @(~,~) updatePlotElements());
    showFourierApproxChk.Layout.Row = 4; showFourierApproxChk.Layout.Column = 2;

    showErrorSignalChk = uicheckbox(figureGrid, 'Text', 'Error Signal', 'Value', false, ...
        'FontSize', uiFonts.size-1, 'ValueChangedFcn', @(~,~) updatePlotElements());
    showErrorSignalChk.Layout.Row = 5; showErrorSignalChk.Layout.Column = 1;

    showGridChk = uicheckbox(figureGrid, 'Text', 'Grid', 'Value', true, ...
        'FontSize', uiFonts.size-1, 'ValueChangedFcn', @(~,~) updatePlotElements());
    showGridChk.Layout.Row = 5; showGridChk.Layout.Column = 2;

    showLegendChk = uicheckbox(figureGrid, 'Text', 'Legend', 'Value', true, ...
        'FontSize', uiFonts.size-1, 'ValueChangedFcn', @(~,~) updatePlotElements());
    showLegendChk.Layout.Row = 6; showLegendChk.Layout.Column = 1;

    showMathNotationChk = uicheckbox(figureGrid, 'Text', 'Math Notation', 'Value', true, ...
        'FontSize', uiFonts.size-1, 'ValueChangedFcn', @(~,~) updatePlotElements());
    showMathNotationChk.Layout.Row = 6; showMathNotationChk.Layout.Column = 2;

    % --- Enhanced Plot Areas ---
    % Create plot grid layout
    plotGrid = uigridlayout(mainGrid, [2 2]);
    plotGrid.RowHeight = {'1x', '1x'};
    plotGrid.ColumnWidth = {'1x', '1x'};
    plotGrid.Padding = [5 5 5 5];
    plotGrid.RowSpacing = 5;
    plotGrid.ColumnSpacing = 5;
    plotGrid.Layout.Row = 2;
    plotGrid.Layout.Column = 1;
    
    
    % Time domain plot
    ax1 = uiaxes(plotGrid);
    ax1.Title.String = 'CT Signal Synthesis & Fourier Approximation';
    ax1.XLabel.String = 'Time (s)';
    ax1.YLabel.String = 'Amplitude';
    ax1.FontSize = uiFonts.size;
    ax1.FontName = uiFonts.name;
    ax1.Box = 'on';
    ax1.GridAlpha = 0.3;
    ax1.GridColor = [0.8 0.8 0.8];
    ax1.Layout.Row = 1; ax1.Layout.Column = 1;

    % Frequency domain plot
    ax2 = uiaxes(plotGrid);
    ax2.Title.String = 'Frequency Domain Spectrum';
    ax2.XLabel.String = 'Frequency (Hz)';
    ax2.YLabel.String = 'Magnitude';
    ax2.FontSize = uiFonts.size;
    ax2.FontName = uiFonts.name;
    ax2.Box = 'on';
    ax2.GridAlpha = 0.3;
    ax2.GridColor = [0.8 0.8 0.8];
    ax2.Layout.Row = 1; ax2.Layout.Column = 2;

    % Harmonics plot
    ax3 = uiaxes(plotGrid);
    ax3.Title.String = 'Individual Harmonics';
    ax3.XLabel.String = 'Time (s)';
    ax3.YLabel.String = 'Amplitude';
    ax3.FontSize = uiFonts.size;
    ax3.FontName = uiFonts.name;
    ax3.Box = 'on';
    ax3.GridAlpha = 0.3;
    ax3.GridColor = [0.8 0.8 0.8];
    ax3.Layout.Row = 2; ax3.Layout.Column = 1;

    % Properties plot
    ax4 = uiaxes(plotGrid);
    ax4.Title.String = 'Properties & Analysis';
    ax4.XLabel.String = 'Time (s)';
    ax4.YLabel.String = 'Amplitude';
    ax4.FontSize = uiFonts.size;
    ax4.FontName = uiFonts.name;
    ax4.Box = 'on';
    ax4.GridAlpha = 0.3;
    ax4.GridColor = [0.8 0.8 0.8];
    ax4.Layout.Row = 2; ax4.Layout.Column = 2;

    % --- Initialize Enhanced Plot Manager ---
    plot_manager.setAxes(ax1, ax2, ax3, ax4);
    plot_manager.setFourierMath(ct_fs_math);

    % --- Initialize Enhanced Animation Controller ---
    animation_controller.setUpdateCallback(@updateAnimationCallback);
    animation_controller.setCompletionCallback(@animationCompleteCallback);
    animation_controller.setProgressCallback(@updateProgressCallback);

    % --- Status and Metrics Display ---
    % Create a dedicated panel for status and metrics below the plots
    statusPanel = uipanel(mainGrid, 'Title', 'Status & Analysis', 'FontSize', uiFonts.size, ...
        'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    statusPanel.Layout.Row = 3;
    statusPanel.Layout.Column = 1;
    
    % Status display
    statusLabel = uilabel(statusPanel, 'Text', 'Ready', 'FontSize', uiFonts.size, ...
        'FontName', 'Consolas', 'FontColor', uiColors.primary);
    statusLabel.Position = [10, 50, 200, 20];
    
    % Equation display
    equationLabel = uilabel(statusPanel, 'Text', 'x(t) = a_0 + sum[n=1 to 10] [a_n*cos(n*omega_0*t) + b_n*sin(n*omega_0*t)]', ...
        'FontSize', uiFonts.size+2, 'FontName', uiFonts.math, 'FontColor', uiColors.ct_signal, 'FontWeight', 'bold');
    equationLabel.Position = [220, 50, 800, 25];
    
    % Metrics display
    metricsLabel = uilabel(statusPanel, 'Text', 'MSE: 0.000 | SNR: ∞ dB', ...
        'FontSize', uiFonts.size, 'FontName', 'Consolas', 'FontColor', uiColors.secondary);
    metricsLabel.Position = [10, 20, 400, 20];

    % --- Initialize Figure Display Layout ---
    updateFigureDisplay();
    
    % Ensure all controls are enabled
    harmonicsSlider.Enable = 'on';
    freqSlider.Enable = 'on';
    maxHarmonicsDisplaySlider.Enable = 'on';
    % Speed buttons are always enabled (no Enable property for buttons)

    % --- Enhanced Signal Generation ---
    function updateSignal()
        try
            signal_type = signalDropdown.Value;
            f0 = freqSlider.Value;
            
            % Enhanced input validation
            if isempty(signal_type) || ~ischar(signal_type)
                signal_type = 'Square Wave';
                signalDropdown.Value = signal_type;
            end
            
            if f0 <= 0 || f0 > 10 || ~isfinite(f0)
                f0 = max(0.1, min(f0, 10));
                freqSlider.Value = f0;
                statusLabel.Text = sprintf('Frequency clamped to %.1f Hz', f0);
            end
            
            T = 1/f0;  % Period
            
            % Update status
            statusLabel.Text = sprintf('Generating %s signal at %.1f Hz (3 periods)...', signal_type, f0);
            drawnow; % Force UI update
            
            % Enhanced time vector generation - THREE PERIODS for better visualization
            T = 1/f0;  % Period
            t_max = 3 * T;  % Three periods for better visualization
            min_samples = 300;  % Increased minimum for 3 periods
            max_samples = 10000;
            samples = max(min_samples, min(max_samples, round(3000 * f0)));  % Scale with frequency
            t = linspace(0, t_max, samples);
            
            % Generate original CT signal with enhanced error handling
            try
                switch signal_type
                    case 'Square Wave'
                        app_state.original_signal = square(2*pi*f0*t);
                    case 'Sawtooth'
                        app_state.original_signal = sawtooth(2*pi*f0*t);
                    case 'Triangle'
                        app_state.original_signal = sawtooth(2*pi*f0*t, 0.5);
                    case 'Half-Wave Rectified'
                        app_state.original_signal = max(0, sin(2*pi*f0*t));
                    case 'Full-Wave Rectified'
                        app_state.original_signal = abs(sin(2*pi*f0*t));
                    case 'Custom'
                        app_state.original_signal = sin(2*pi*f0*t) + 0.5*sin(2*pi*3*f0*t + pi/4) + 0.3*sin(2*pi*5*f0*t + pi/2);
                    otherwise
                        app_state.original_signal = square(2*pi*f0*t);
                        signal_type = 'Square Wave';
                        signalDropdown.Value = signal_type;
                end
            catch ME
                fprintf('Signal generation failed for %s: %s\n', signal_type, ME.message);
                app_state.original_signal = square(2*pi*f0*t);
                signal_type = 'Square Wave';
                signalDropdown.Value = signal_type;
            end
            
            % Validate generated signal
            if isempty(app_state.original_signal) || ~all(isfinite(app_state.original_signal))
                app_state.original_signal = square(2*pi*f0*t);
                statusLabel.Text = 'Warning: Generated fallback square wave signal';
            end
            
            % Normalize signal amplitude if needed
            max_amplitude = max(abs(app_state.original_signal));
            if max_amplitude > 0 && max_amplitude > 10
                app_state.original_signal = app_state.original_signal / max_amplitude;
            end
            
            app_state.time_vector = t;
            app_state.current_signal_type = signal_type;
            app_state.current_f0 = f0;
            app_state.is_initialized = true;
            
            % Update frequency value display
            
            % Update Fourier series
            updateFourier();
            
        catch ME
            handleError('Signal', sprintf('Signal generation error: %s', ME.message));
            % Generate fallback signal
            try
                t = linspace(0, 3, 1000);
                app_state.original_signal = square(2*pi*t);
                app_state.time_vector = t;
                app_state.current_signal_type = 'Square Wave';
                app_state.current_f0 = 1;
                app_state.is_initialized = true;
                updateFourier();
            catch
                statusLabel.Text = 'Critical error: Unable to generate any signal';
            end
        end
    end

    % --- Enhanced Fourier Analysis ---
    function updateFourier()
        try
            if isempty(app_state.original_signal) || ~app_state.is_initialized
                statusLabel.Text = 'No signal available for analysis';
                return;
            end
            
            N = round(harmonicsSlider.Value);
            f0 = freqSlider.Value;
            
            % Validate fundamental frequency against sampling rate
            dt = app_state.time_vector(2) - app_state.time_vector(1);
            fs = 1/dt;  % Sampling frequency
            
            % Check Nyquist criterion
            if f0 > fs/4  % Conservative limit to avoid aliasing
                warning('Fundamental frequency %.2f Hz may cause aliasing with sampling rate %.2f Hz', f0, fs);
                statusLabel.Text = sprintf('Warning: High frequency may cause aliasing');
            end
            
            % Enhanced input validation
            if N < 1 || N > 50 || ~isfinite(N)
                N = max(1, min(N, 50));
                harmonicsSlider.Value = N;
                statusLabel.Text = sprintf('Harmonics clamped to %d', N);
            end
            
            if f0 <= 0 || f0 > 10 || ~isfinite(f0)
                f0 = max(0.1, min(f0, 10));
                freqSlider.Value = f0;
                statusLabel.Text = sprintf('Frequency clamped to %.1f Hz', f0);
            end
            
            % Update status
            statusLabel.Text = sprintf('Computing Fourier series with %d harmonics...', N);
            drawnow; % Force UI update
            
            % Calculate Fourier coefficients with error handling
            try
                [coefficients, frequencies, magnitude, phase] = ct_fs_math.calculateFourierCoefficients(...
                    app_state.original_signal, app_state.time_vector, N, f0);
            catch ME
                fprintf('Coefficient calculation error: %s\n', ME.message);
                statusLabel.Text = sprintf('Coefficient calculation failed: %s', ME.message);
                return;
            end
            
            % Validate coefficients
            if isempty(coefficients) || ~all(isfinite(coefficients))
                statusLabel.Text = 'Error: Invalid Fourier coefficients calculated';
                return;
            end
            
            % Calculate Fourier series reconstruction with error handling
            try
                fourier_signal = ct_fs_math.synthesizeFourierSeries(app_state.time_vector, coefficients, frequencies, N);
            catch ME
                fprintf('Fourier synthesis error: %s\n', ME.message);
                statusLabel.Text = sprintf('Fourier synthesis failed: %s', ME.message);
                return;
            end
            
            % Validate synthesized signal
            if isempty(fourier_signal) || ~all(isfinite(fourier_signal))
                statusLabel.Text = 'Error: Invalid Fourier signal synthesized';
                return;
            end
            
            % Calculate harmonics with error handling
            try
                harmonics = ct_fs_math.generateHarmonics(app_state.time_vector, coefficients, frequencies, N);
            catch ME
                fprintf('Harmonics generation error: %s\n', ME.message);
                harmonics = zeros(N+1, length(app_state.time_vector));
            end
            
            % Calculate error metrics with error handling
            try
                error_metrics = ct_fs_math.calculateErrorMetrics(...
                    app_state.original_signal, fourier_signal, app_state.time_vector);
            catch ME
                fprintf('Error metrics calculation error: %s\n', ME.message);
                error_metrics = struct('mse', 0, 'snr', Inf, 'convergence', 1);
            end
            
            % Update app state
            app_state.coefficients = coefficients;
            app_state.frequencies = frequencies;
            app_state.fourier_signal = fourier_signal;
            app_state.harmonics = harmonics;
            app_state.error_metrics = error_metrics;
            app_state.current_N = N;
            
            % Update plots with error handling
            try
                updatePlots();
            catch ME
                fprintf('Plot update error in updateFourier: %s\n', ME.message);
                statusLabel.Text = 'Plot update failed, but analysis completed';
            end
            
            % Update UI elements
            try
                updateEquation();
                updateMetrics();
            catch ME
                fprintf('UI update error: %s\n', ME.message);
            end
            
            % Update status
            statusLabel.Text = sprintf('Ready - %s signal with %d harmonics at %.1f Hz', ...
                app_state.current_signal_type, N, f0);
            
        catch ME
            handleError('Fourier', sprintf('Fourier analysis error: %s', ME.message));
        end
    end

    % --- Enhanced Plot Updates ---
    function updatePlots()
        try
            if isempty(app_state.original_signal), return; end
            
            % Update plot manager with current data
            plot_manager.updateData(app_state.original_signal, app_state.fourier_signal, ...
                app_state.time_vector, app_state.coefficients, app_state.frequencies, ...
                app_state.harmonics);
            
            % Update all plots
            plot_manager.updateAllPlots();
            
        catch ME
            fprintf('Plot update error: %s\n', ME.message);
            statusLabel.Text = 'Plot update error occurred';
        end
    end

    % --- Figure Display Control ---
    function updateFigureDisplay()
        try
            % Count visible figures
            visible_count = 0;
            if showTimeDomainChk.Value, visible_count = visible_count + 1; end
            if showFreqDomainChk.Value, visible_count = visible_count + 1; end
            if showHarmonicsChk.Value, visible_count = visible_count + 1; end
            if showPropertiesFigureChk.Value, visible_count = visible_count + 1; end
            
            % Update visibility - use grid layout
            if showTimeDomainChk.Value
                ax1.Visible = 'on';
                ax1.Title.String = 'CT Signal Synthesis & Fourier Approximation';
            else
                ax1.Visible = 'off';
                cla(ax1);
                text(ax1, 0.5, 0.5, 'Time Domain Display Disabled', ...
                    'HorizontalAlignment', 'center', 'FontSize', 14, 'FontName', 'Arial');
            end
            
            if showFreqDomainChk.Value
                ax2.Visible = 'on';
                ax2.Title.String = 'Frequency Domain Spectrum';
            else
                ax2.Visible = 'off';
                cla(ax2);
                text(ax2, 0.5, 0.5, 'Frequency Domain Display Disabled', ...
                    'HorizontalAlignment', 'center', 'FontSize', 14, 'FontName', 'Arial');
            end
            
            if showHarmonicsChk.Value
                ax3.Visible = 'on';
                ax3.Title.String = 'Individual Harmonics';
            else
                ax3.Visible = 'off';
                cla(ax3);
                text(ax3, 0.5, 0.5, 'Harmonics Display Disabled', ...
                    'HorizontalAlignment', 'center', 'FontSize', 14, 'FontName', 'Arial');
            end
            
            if showPropertiesFigureChk.Value
                ax4.Visible = 'on';
                ax4.Title.String = 'Properties & Analysis';
            else
                ax4.Visible = 'off';
                cla(ax4);
                text(ax4, 0.5, 0.5, 'Properties Display Disabled', ...
                    'HorizontalAlignment', 'center', 'FontSize', 14, 'FontName', 'Arial');
            end
            
        catch ME
            fprintf('Figure display error: %s\n', ME.message);
            statusLabel.Text = 'Figure display error occurred';
        end
    end

    % --- Animation Control Functions ---
    function playAnimation()
        try
            if isempty(app_state.original_signal)
                statusLabel.Text = 'Error: No signal to animate';
                return;
            end
            animation_controller.startAnimation(app_state.original_signal, app_state.time_vector, ...
                app_state.current_N, app_state.current_f0);
            playBtn.Enable = 'off';
            stopBtn.Enable = 'on';
            statusLabel.Text = 'Animation started';
        catch ME
            fprintf('Animation error: %s\n', ME.message);
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
            fprintf('Animation error: %s\n', ME.message);
            statusLabel.Text = 'Animation error occurred';
        end
    end
    
    function setDiscreteSpeed(speed)
        try
            if ~isempty(animation_controller)
                % Set the discrete speed
                animation_controller.setSpeed(speed);
                
                % Update speed value display
                speedValue.Text = sprintf('%.1fx', speed);
                
                % Update button highlights
                updateSpeedButtonHighlights(speed);
                
                fprintf('Speed set to discrete level: %.1fx\n', speed);
                statusLabel.Text = sprintf('Animation speed: %.1fx', speed);
            end
        catch ME
            handleError('Animation', sprintf('Set discrete speed error: %s', ME.message));
        end
    end
    
    function updateSpeedButtonHighlights(selectedSpeed)
        try
            % Reset all button colors
            for i = 1:length(speedButtons)
                speedButtons(i).BackgroundColor = [0.94 0.94 0.94];  % Default gray
            end
            
            % Highlight the selected speed button
            speedLevels = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
            selectedIdx = find(speedLevels == selectedSpeed);
            if ~isempty(selectedIdx)
                speedButtons(selectedIdx).BackgroundColor = [0.2 0.6 1.0];  % Blue highlight
            end
        catch ME
            fprintf('Error updating speed button highlights: %s\n', ME.message);
        end
    end

    function reverseAnimation()
        try
            animation_controller.reverseAnimation();
            statusLabel.Text = 'Animation reversed';
        catch ME
            fprintf('Animation error: %s\n', ME.message);
            statusLabel.Text = 'Animation error occurred';
        end
    end

    % updateSpeed function removed - now using discrete speed buttons

    % --- Display Control Functions ---
    function updateDisplay()
        try
            plot_manager.setDisplayOptions(...
                showGibbsChk.Value, ...
                showOrthogonalityChk.Value, ...
                showSpectrumChk.Value, ...
                false, ... % Properties checkbox removed
                showErrorChk.Value, ...
                showConvergenceChk.Value); % Convergence checkbox added
            
            updatePlots();
            statusLabel.Text = 'Display options updated';
        catch ME
            fprintf('Display update error: %s\n', ME.message);
            statusLabel.Text = 'Display update error occurred';
        end
    end

    function updatePlotElements()
        try
            plot_manager.setPlotElementVisibility(...
                showOriginalSignalChk.Value, ...
                showFourierApproxChk.Value, ...
                showErrorSignalChk.Value, ...
                showGridChk.Value, ...
                showLegendChk.Value, ...
                showMathNotationChk.Value);
            
            updatePlots();
            statusLabel.Text = 'Plot elements updated';
        catch ME
            fprintf('Plot elements error: %s\n', ME.message);
            statusLabel.Text = 'Plot elements error occurred';
        end
    end

    function updateMaxHarmonicsDisplay()
        try
            max_harmonics_display = round(maxHarmonicsDisplaySlider.Value);
            plot_manager.setMaxHarmonicsDisplay(max_harmonics_display);
            updatePlots();
            statusLabel.Text = sprintf('Max harmonics display set to %d', max_harmonics_display);
        catch ME
            fprintf('Max harmonics display error: %s\n', ME.message);
            statusLabel.Text = 'Max harmonics display error occurred';
        end
    end

    % --- Animation Callbacks ---
    function updateAnimationCallback(animation_data)
        try
            if nargin > 0 && ~isempty(animation_data)
                % Use the pre-calculated data from animation controller
                app_state.fourier_signal = animation_data.fourier_signal;
                app_state.coefficients = animation_data.coefficients;
                app_state.frequencies = animation_data.frequencies;
                app_state.error_metrics = animation_data.error_metrics;
                app_state.current_N = animation_data.harmonic_number;
                
                % Update harmonics if available
                if isfield(animation_data, 'harmonics') && ~isempty(animation_data.harmonics)
                    app_state.harmonics = animation_data.harmonics;
                end
                
                % Update plots directly without recalculating
                updatePlots();
                
                % Update UI elements
                updateEquation();
                updateMetrics();
            else
                % Fallback to full recalculation if no data provided
                updateFourier();
            end
        catch ME
            fprintf('Animation callback error: %s\n', ME.message);
        end
    end

    function animationCompleteCallback()
        try
            % Check if UI objects still exist before accessing them
            if isvalid(playBtn) && isvalid(stopBtn)
                playBtn.Enable = 'on';
                stopBtn.Enable = 'off';
            end
        catch ME
            fprintf('Animation complete callback error: %s\n', ME.message);
        end
    end

    function updateProgressCallback(progress)
        try
            % Update progress display if needed
        catch ME
            fprintf('Progress update error: %s\n', ME.message);
        end
    end

    % --- Enhanced UI Update Functions ---
    function updateEquation()
        try
            N = round(harmonicsSlider.Value);
            
            % Try LaTeX formatting first for better mathematical display
            try
                equation_text = sprintf('$$x(t) = a_0 + \\sum_{n=1}^{%d} [a_n\\cos(n\\omega_0 t) + b_n\\sin(n\\omega_0 t)]$$', N);
                equationLabel.Text = equation_text;
                equationLabel.Interpreter = 'latex';
            catch
                % Fallback to simple text if LaTeX fails
                equation_text = sprintf('x(t) = a₀ + Σ[n=1 to %d] [aₙcos(nω₀t) + bₙsin(nω₀t)]', N);
                equationLabel.Text = equation_text;
                equationLabel.Interpreter = 'none';
            end
        catch ME
            fprintf('Equation update error: %s\n', ME.message);
            % Last resort fallback
            equationLabel.Text = 'x(t) = a₀ + Σ[n=1 to N] [aₙcos(nω₀t) + bₙsin(nω₀t)]';
            equationLabel.Interpreter = 'none';
        end
    end

    function updateMetrics()
        try
            if ~isempty(app_state.error_metrics)
                mse = app_state.error_metrics.mse;
                snr = app_state.error_metrics.snr;
                
                if isinf(snr)
                    snr_text = '∞';
                else
                    snr_text = sprintf('%.1f', snr);
                end
                
                metrics_text = sprintf('MSE: %.4f | SNR: %s dB', mse, snr_text);
                metricsLabel.Text = metrics_text;
            else
                metricsLabel.Text = 'MSE: 0.000 | SNR: ∞ dB';
            end
        catch ME
            fprintf('Metrics update error: %s\n', ME.message);
        end
    end


    % --- Export Functions ---
    function exportPlots()
        try
            [filename, pathname] = uiputfile({'*.fig;*.png;*.pdf', 'All Supported Formats'; ...
                '*.fig', 'MATLAB Figure (*.fig)'; ...
                '*.png', 'PNG Image (*.png)'; ...
                '*.pdf', 'PDF Document (*.pdf)'}, ...
                'Export Plots', 'CT_Fourier_Series_Export');
            
            if filename ~= 0
                full_path = fullfile(pathname, filename);
                plot_manager.exportPlots(full_path);
                statusLabel.Text = sprintf('Plots exported to: %s', filename);
            end
        catch ME
            fprintf('Export plots error: %s\n', ME.message);
            statusLabel.Text = sprintf('Export error: %s', ME.message);
        end
    end

    function exportData()
        try
            [filename, pathname] = uiputfile({'*.mat', 'MATLAB Data (*.mat)'}, ...
                'Export Data', 'CT_Fourier_Series_Data.mat');
            
            if filename ~= 0
                full_path = fullfile(pathname, filename);
                plot_manager.exportData(full_path);
                statusLabel.Text = sprintf('Data exported to: %s', filename);
            end
        catch ME
            fprintf('Export data error: %s\n', ME.message);
            statusLabel.Text = sprintf('Data export error: %s', ME.message);
        end
    end


    % --- Help Function ---
    function showHelp()
        try
            helpText = ['CT FOURIER SERIES VISUALIZATION APP - GROUPED CONTROLS VERSION' newline newline ...
                'OVERVIEW:' newline ...
                'This app demonstrates Continuous-Time Fourier series synthesis and analysis' newline ...
                'with properly grouped controls for better organization and usability.' newline newline ...
                'CONTROL SECTIONS:' newline ...
                '• Signal Control: Preset selection, signal type, harmonics, and frequency settings' newline ...
                '• Animation Control: Play, stop, reverse, and speed controls' newline ...
                '• Display Control: Show/hide various analysis features' newline ...
                '• Figure Control: Control which figures to display and their elements' newline newline ...
                'FEATURES:' newline ...
                '• Educational presets for different learning scenarios' newline ...
                '• Dynamic axis scaling for all plots' newline ...
                '• Real-time legend control' newline ...
                '• Organized control interface' newline ...
                '• Professional visualization' newline newline ...
                'Author: Ahmed Rabei - TEFO, 2025'];
            
            uialert(fig, helpText, 'Help - CT Fourier Series App', 'Icon', 'info');
        catch ME
            fprintf('Help error: %s\n', ME.message);
        end
    end

    % --- Enhanced Error Handling ---
    function handleError(errorType, message, varargin)
        % Enhanced consolidated error handling for the application
        % Inputs:
        %   errorType - Type of error ('Signal', 'Fourier', 'Animation', 'Plot', 'UI')
        %   message - Error message
        %   varargin - Optional additional parameters
        
        try
            % Format error message with timestamp
            timestamp = datestr(now, 'HH:MM:SS');
            fullMessage = sprintf('[%s] CT_FS_%s: %s', timestamp, errorType, message);
            
            % Log error
            fprintf('%s\n', fullMessage);
            
            % Update status if UI is available with more informative messages
            if exist('statusLabel', 'var') && isvalid(statusLabel)
                switch errorType
                    case 'Signal'
                        statusLabel.Text = sprintf('Signal Error: %s - Using fallback square wave', message);
                    case 'Fourier'
                        statusLabel.Text = sprintf('Analysis Error: %s - Please check parameters', message);
                    case 'Animation'
                        statusLabel.Text = sprintf('Animation Error: %s - Animation stopped', message);
                    case 'Plot'
                        statusLabel.Text = sprintf('Display Error: %s - Plots cleared', message);
                    case 'UI'
                        statusLabel.Text = sprintf('Interface Error: %s - Some controls disabled', message);
                    otherwise
                        statusLabel.Text = sprintf('%s Error: %s', errorType, message);
                end
            end
            
            % Enhanced error type handling with better recovery
            switch errorType
                case 'Signal'
                    % Signal generation errors - try fallback with better error handling
                    if contains(message, 'generation') || contains(message, 'signal')
                        try
                            fprintf('Attempting signal generation fallback...\n');
                            t = linspace(0, 3, 1000);
                            app_state.original_signal = square(2*pi*t);
                            app_state.time_vector = t;
                            app_state.current_signal_type = 'Square Wave';
                            app_state.current_f0 = 1;
                            app_state.is_initialized = true;
                            updateFourier();
                            if exist('statusLabel', 'var') && isvalid(statusLabel)
                                statusLabel.Text = 'Fallback signal generated successfully';
                            end
                        catch fallbackError
                            fprintf('Fallback signal generation also failed: %s\n', fallbackError.message);
                            if exist('statusLabel', 'var') && isvalid(statusLabel)
                                statusLabel.Text = 'Critical: Unable to generate any signal';
                            end
                        end
                    end
                    
                case 'Fourier'
                    % Fourier analysis errors - clear state and provide guidance
                    app_state.coefficients = [];
                    app_state.frequencies = [];
                    app_state.fourier_signal = [];
                    app_state.error_metrics = [];
                    
                    % Provide user guidance
                    if exist('statusLabel', 'var') && isvalid(statusLabel)
                        statusLabel.Text = 'Fourier analysis failed - try reducing harmonics or frequency';
                    end
                    
                case 'Animation'
                    % Animation errors - stop and reset with better cleanup
                    if exist('animation_controller', 'var') && ~isempty(animation_controller)
                        try
                            animation_controller.stopAnimation();
                            if exist('playBtn', 'var') && isvalid(playBtn)
                                playBtn.Enable = 'on';
                            end
                            if exist('stopBtn', 'var') && isvalid(stopBtn)
                                stopBtn.Enable = 'off';
                            end
                        catch cleanupError
                            fprintf('Animation cleanup error: %s\n', cleanupError.message);
                        end
                    end
                    
                case 'Plot'
                    % Plot errors - clear axes with better error messages
                    try
                        if exist('ax1', 'var') && isvalid(ax1)
                            cla(ax1);
                            text(ax1, 0.5, 0.5, 'Plot Error - Data cleared', ...
                                'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'red');
                        end
                        if exist('ax2', 'var') && isvalid(ax2)
                            cla(ax2);
                            text(ax2, 0.5, 0.5, 'Plot Error - Data cleared', ...
                                'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'red');
                        end
                        if exist('ax3', 'var') && isvalid(ax3)
                            cla(ax3);
                            text(ax3, 0.5, 0.5, 'Plot Error - Data cleared', ...
                                'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'red');
                        end
                        if exist('ax4', 'var') && isvalid(ax4)
                            cla(ax4);
                            text(ax4, 0.5, 0.5, 'Plot Error - Data cleared', ...
                                'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'red');
                        end
                    catch plotError
                        fprintf('Plot cleanup error: %s\n', plotError.message);
                    end
                    
                case 'UI'
                    % UI errors - disable problematic controls with user notification
                    try
                        if exist('harmonicsSlider', 'var') && isvalid(harmonicsSlider)
                            harmonicsSlider.Enable = 'off';
                        end
                        if exist('freqSlider', 'var') && isvalid(freqSlider)
                            freqSlider.Enable = 'off';
                        end
                        if exist('statusLabel', 'var') && isvalid(statusLabel)
                            statusLabel.Text = 'UI Error - Some controls disabled for safety';
                        end
                    catch uiError
                        fprintf('UI error handling failed: %s\n', uiError.message);
                    end
            end
            
        catch ME
            % Fallback error handling with more detailed logging
            fprintf('Critical error in error handler: %s\n', ME.message);
            fprintf('Stack trace:\n');
            for i = 1:length(ME.stack)
                fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
            end
        end
    end

    % --- Cleanup Function ---
    function onClose(~, ~)
        try
            % Stop animation and clean up timers
            if exist('animation_controller', 'var') && ~isempty(animation_controller)
                animation_controller.stopAnimation();
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
            fprintf('Cleanup error: %s\n', ME.message);
            % Force close even if cleanup fails
            try
                delete(fig);
            catch
                % Last resort - force quit
                close all force;
            end
        end
    end

    % --- Initialize App ---
    try
        updateSignal();
        fprintf('CT Fourier Series App with Grouped Controls launched successfully!\n');
    catch ME
        fprintf('Initialization error: %s\n', ME.message);
    end
end
