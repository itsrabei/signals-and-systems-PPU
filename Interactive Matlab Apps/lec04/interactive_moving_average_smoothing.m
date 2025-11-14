function interactive_moving_average_smoothing
% INTERACTIVE MOVING-AVERAGE SMOOTHING ON SENSOR DATA
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates moving-average filtering for
% noise reduction in sensor data. Users can load real or simulated noisy
% time series data and apply N-point moving-average filters to remove
% high-frequency noise while preserving signal characteristics.
% 
% FEATURES:
% - Load or generate noisy sensor data (temperature, ECG, etc.)
% - Apply N-point moving average filter: h[n] = (1/N)∑δ[n-k]
% - Real-time parameter adjustment and visualization
% - Before/after signal comparison
% - Mean squared error calculation against clean reference
% - Trade-off analysis between smoothing and temporal resolution
% - Educational presets for different sensor types
% 
% EDUCATIONAL PURPOSE:
% - Understanding moving-average filters and noise reduction
% - Learning about trade-offs between smoothing and resolution
% - Exploring signal processing in sensor applications
% - Understanding MSE as a performance metric

    % --- UI Constants ---
    uiColors.bg = [0.96 0.96 0.96];
    uiColors.panel = [1 1 1];
    uiColors.text = [0.1 0.1 0.1];
    uiColors.primary = [0 0.4470 0.7410];
    uiColors.highlight = [0.8500 0.3250 0.0980];
    uiColors.secondary = [0.4940 0.1840 0.5560];
    uiColors.noise = [0.8 0.2 0.2];
    uiColors.clean = [0.2 0.8 0.2];
    uiFonts.size = 12;
    uiFonts.title = 14;
    uiFonts.name = 'Helvetica Neue';

    % --- GUI Initialization ---
    fig = uifigure('Name','Interactive Moving-Average Smoothing', 'Position',[100 100 1200 800], 'Color', uiColors.bg);
    fig.CloseRequestFcn = @(src,event) onClose();
    
    % --- Data Generation/Selection ---
    dataType = questdlg('Select data source:', 'Data Source', ...
        'Generate Simulated Data', 'Load from File', 'Generate Simulated Data');
    
    if isempty(dataType) || strcmp(dataType, '')
        if isvalid(fig), delete(fig); end
        return;
    end
    
    if strcmp(dataType, 'Load from File')
        [filename, pathname] = uigetfile( ...
            {'*.mat;*.csv;*.txt','Data Files (*.mat,*.csv,*.txt)'}, ...
            'Select a data file to load');
        if isequal(filename,0)
            disp('User cancelled file selection.');
            if isvalid(fig), delete(fig); end
            return;
        end
        filepath = fullfile(pathname, filename);
        
        try
            data = loadDataFromFile(filepath);
        catch ME
            uialert(fig, sprintf('Could not load data file.\nError: %s', ME.message), ...
                'File Error', 'Icon', 'error');
            if isvalid(fig), delete(fig); end
            return;
        end
    else
        % Generate simulated data
        data = generateSimulatedData();
    end
    
    % Extract data components
    noisy_signal = data.noisy;
    clean_signal = data.clean;
    Fs = data.Fs;
    t = data.t;
    N = length(noisy_signal);
    
    % --- Layout Setup ---
    mainGrid = uigridlayout(fig, [2 2]);
    mainGrid.RowHeight   = {'fit', '1x'};
    mainGrid.ColumnWidth = {'fit', '1x'};
    mainGrid.Padding = [10 10 10 10];
    
    % Controls Panel
    controlPanel = uipanel(mainGrid, 'Title', 'Moving-Average Filter Controls', 'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;

    ctrl = uigridlayout(controlPanel, [5 6]);
    ctrl.RowHeight    = {'fit','fit','fit','fit','fit'};
    ctrl.ColumnWidth  = {'fit','fit','fit','fit','fit','fit'};
    ctrl.Padding      = [15 15 15 15];
    ctrl.ColumnSpacing = 15;
    ctrl.RowSpacing = 8;

    % Data info
    dataLabel = uilabel(ctrl, ...
        'Text', sprintf('Data: %s | Fs: %d Hz | Samples: %d | Duration: %.2f s', ...
        data.name, Fs, N, N/Fs), ...
        'HorizontalAlignment','left', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);
    dataLabel.Layout.Row = 1; 
    dataLabel.Layout.Column = [1 5];

    % Help button
    helpBtn = uibutton(ctrl, 'Text', '?', 'FontSize', 16, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) showHelp());
    helpBtn.Layout.Row = 1; 
    helpBtn.Layout.Column = 6;

    % Filter parameters
    filterLabel = uilabel(ctrl, 'Text', 'Filter Length N:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    filterLabel.Layout.Row = 2; filterLabel.Layout.Column = 1;
    
    filterSlider = uislider(ctrl, 'Limits', [1 50], 'Value', 5, ...
        'ValueChangedFcn', @(~,~) updateFilter());
    filterSlider.Layout.Row = 2; filterSlider.Layout.Column = 2;
    
    filterValue = uilabel(ctrl, 'Text', '5', 'FontSize', uiFonts.size);
    filterValue.Layout.Row = 2; filterValue.Layout.Column = 3;

    % Noise level (for generated data)
    if strcmp(dataType, 'Generate Simulated Data')
        noiseLabel = uilabel(ctrl, 'Text', 'Noise Level:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
        noiseLabel.Layout.Row = 2; noiseLabel.Layout.Column = 4;
        
        noiseSlider = uislider(ctrl, 'Limits', [0 1], 'Value', data.noise_level, ...
            'ValueChangedFcn', @(~,~) regenerateData());
        noiseSlider.Layout.Row = 2; noiseSlider.Layout.Column = 5;
        
        noiseValue = uilabel(ctrl, 'Text', sprintf('%.2f', data.noise_level), 'FontSize', uiFonts.size);
        noiseValue.Layout.Row = 2; noiseValue.Layout.Column = 6;
    end

    % Presets and MSE
    presetLabel = uilabel(ctrl, 'Text', 'Data Presets:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    presetLabel.Layout.Row = 3; presetLabel.Layout.Column = 1;
    
    presetDropdown = uidropdown(ctrl, 'Items', {'Custom', 'Temperature Sensor', 'ECG Signal', 'Accelerometer', 'Pressure Sensor'}, ...
        'Value', 'Custom', 'ValueChangedFcn', @(~,~) loadPreset());
    presetDropdown.Layout.Row = 3; presetDropdown.Layout.Column = 2;

    mseLabel = uilabel(ctrl, 'Text', 'MSE vs Clean:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    mseLabel.Layout.Row = 3; mseLabel.Layout.Column = 3;
    
    mseText = uilabel(ctrl, 'Text', 'Calculating...', 'FontSize', uiFonts.size, 'FontName', 'Consolas');
    mseText.Layout.Row = 3; mseText.Layout.Column = [4 6];

    % Analysis controls
    analysisLabel = uilabel(ctrl, 'Text', 'Analysis:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    analysisLabel.Layout.Row = 4; analysisLabel.Layout.Column = 1;
    
    showCleanChk = uicheckbox(ctrl, 'Text','Show Clean Reference', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updatePlots());
    showCleanChk.Layout.Row = 4; showCleanChk.Layout.Column = 2;

    showErrorChk = uicheckbox(ctrl, 'Text','Show Error Signal', 'Value', false, ...
        'FontSize', uiFonts.size, 'ValueChangedFcn', @(~,~) updatePlots());
    showErrorChk.Layout.Row = 4; showErrorChk.Layout.Column = 3;

    exportBtn = uibutton(ctrl, 'Text', 'Export Results', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) exportResults());
    exportBtn.Layout.Row = 4; exportBtn.Layout.Column = 4;

    % Plot area
    plotPanel = uipanel(mainGrid, 'Title','Signal Analysis & Filtering Results', 'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    plotPanel.Layout.Row = 2;
    plotPanel.Layout.Column = [1 2];

    gridPlots = uigridlayout(plotPanel, [3 1]);
    gridPlots.RowHeight = {'1x','1x','1x'};
    gridPlots.ColumnWidth = {'1x'};
    gridPlots.RowSpacing = 10;
    gridPlots.Padding = [10 10 10 10];

    ax1 = uiaxes(gridPlots); ax1.Layout.Row = 1; 
    ax1.FontSize = uiFonts.size; ax1.FontName = uiFonts.name;
    title(ax1, 'Noisy Input Signal', 'FontSize', uiFonts.title, 'FontWeight', 'bold'); 
    grid(ax1,'on');
    
    ax2 = uiaxes(gridPlots); ax2.Layout.Row = 2; 
    ax2.FontSize = uiFonts.size; ax2.FontName = uiFonts.name;
    title(ax2, 'Moving-Average Filtered Signal', 'FontSize', uiFonts.title, 'FontWeight', 'bold'); 
    grid(ax2,'on');
    
    ax3 = uiaxes(gridPlots); ax3.Layout.Row = 3; 
    ax3.FontSize = uiFonts.size; ax3.FontName = uiFonts.name;
    title(ax3, 'Filter Analysis', 'FontSize', uiFonts.title, 'FontWeight', 'bold'); 
    grid(ax3,'on');

    xlabel(ax3, 'Time (s)', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax1, 'Amplitude', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax2, 'Amplitude', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax3, 'Amplitude', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);

    % --- App State ---
    filtered_signal = [];
    filter_impulse = [];
    mse_value = 0;

    % --- Initialize plots ---
    updateFilter();

    % --- Callbacks ---
    function updateFilter()
        if isempty(noisy_signal), return; end
        
        % Update filter length label
        N_filter = round(filterSlider.Value);
        filterValue.Text = sprintf('%d', N_filter);
        
        % Create moving-average filter h[n] = (1/N)∑δ[n-k]
        h = ones(N_filter, 1) / N_filter;
        
        % Apply filter using convolution
        filtered_signal = conv(noisy_signal, h, 'same');
        
        % Calculate MSE against clean reference
        if ~isempty(clean_signal)
            mse_value = mean((filtered_signal - clean_signal).^2);
            mseText.Text = sprintf('%.6f', mse_value);
        else
            mseText.Text = 'N/A (no clean reference)';
        end
        
        % Store filter impulse response
        filter_impulse = h;
        
        % Update plots
        updatePlots();
    end

    function updatePlots()
        if isempty(noisy_signal) || isempty(filtered_signal), return; end
        
        % Plot 1: Noisy input signal
        cla(ax1);
        plot(ax1, t, noisy_signal, 'Color', uiColors.noise, 'LineWidth', 1.5, 'DisplayName', 'Noisy Signal');
        if showCleanChk.Value && ~isempty(clean_signal)
            hold(ax1, 'on');
            plot(ax1, t, clean_signal, 'Color', uiColors.clean, 'LineWidth', 2, 'DisplayName', 'Clean Reference');
            hold(ax1, 'off');
            legend(ax1, 'Location', 'best');
        end
        
        % Dynamic x and y limits for plot 1
        xlim(ax1, [0, max(t)]);
        y_max_1 = max(abs(noisy_signal)) * 1.1;
        if showCleanChk.Value && ~isempty(clean_signal)
            y_max_1 = max([y_max_1, max(abs(clean_signal)) * 1.1]);
        end
        if y_max_1 == 0, y_max_1 = 1; end
        ylim(ax1, [-y_max_1, y_max_1]);
        
        % Plot 2: Filtered signal
        cla(ax2);
        plot(ax2, t, filtered_signal, 'Color', uiColors.primary, 'LineWidth', 1.5, 'DisplayName', 'Filtered Signal');
        if showCleanChk.Value && ~isempty(clean_signal)
            hold(ax2, 'on');
            plot(ax2, t, clean_signal, 'Color', uiColors.clean, 'LineWidth', 2, 'DisplayName', 'Clean Reference');
            hold(ax2, 'off');
            legend(ax2, 'Location', 'best');
        end
        
        % Dynamic x and y limits for plot 2
        xlim(ax2, [0, max(t)]);
        y_max_2 = max(abs(filtered_signal)) * 1.1;
        if showCleanChk.Value && ~isempty(clean_signal)
            y_max_2 = max([y_max_2, max(abs(clean_signal)) * 1.1]);
        end
        if y_max_2 == 0, y_max_2 = 1; end
        ylim(ax2, [-y_max_2, y_max_2]);
        
        % Plot 3: Filter analysis
        cla(ax3);
        if showErrorChk.Value && ~isempty(clean_signal)
            % Show error signal
            error_signal = filtered_signal - clean_signal;
            plot(ax3, t, error_signal, 'Color', uiColors.highlight, 'LineWidth', 1.5, 'DisplayName', 'Error Signal');
            ylabel(ax3, 'Error', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);
            
            % Dynamic limits for error signal
            xlim(ax3, [0, max(t)]);
            y_max_3 = max(abs(error_signal)) * 1.1;
            if y_max_3 == 0, y_max_3 = 1; end
            ylim(ax3, [-y_max_3, y_max_3]);
        else
            % Show filter impulse response
            t_h = (0:length(filter_impulse)-1)/Fs;
            stem(ax3, t_h, filter_impulse, 'Color', uiColors.secondary, 'LineWidth', 2, 'MarkerSize', 4, 'DisplayName', 'h[n]');
            ylabel(ax3, 'h[n]', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);
            
            % Dynamic limits for impulse response
            xlim(ax3, [0, max(t_h)]);
            y_max_3 = max(abs(filter_impulse)) * 1.1;
            if y_max_3 == 0, y_max_3 = 1; end
            ylim(ax3, [-y_max_3, y_max_3]);
        end
        
        drawnow;
    end

    function loadPreset()
        preset = presetDropdown.Value;
        
        switch preset
            case 'Temperature Sensor'
                filterSlider.Value = 10;
                if strcmp(dataType, 'Generate Simulated Data')
                    noiseSlider.Value = 0.1;
                    regenerateData();
                end
            case 'ECG Signal'
                filterSlider.Value = 3;
                if strcmp(dataType, 'Generate Simulated Data')
                    noiseSlider.Value = 0.05;
                    regenerateData();
                end
            case 'Accelerometer'
                filterSlider.Value = 15;
                if strcmp(dataType, 'Generate Simulated Data')
                    noiseSlider.Value = 0.2;
                    regenerateData();
                end
            case 'Pressure Sensor'
                filterSlider.Value = 8;
                if strcmp(dataType, 'Generate Simulated Data')
                    noiseSlider.Value = 0.15;
                    regenerateData();
                end
        end
        
        updateFilter();
    end

    function regenerateData()
        if strcmp(dataType, 'Generate Simulated Data')
            data.noise_level = noiseSlider.Value;
            noiseValue.Text = sprintf('%.2f', data.noise_level);
            
            % Regenerate data with new noise level
            new_data = generateSimulatedData(data.noise_level);
            noisy_signal = new_data.noisy;
            clean_signal = new_data.clean;
            
            % Update data label
            dataLabel.Text = sprintf('Data: %s | Fs: %d Hz | Samples: %d | Duration: %.2f s', ...
                data.name, Fs, N, N/Fs);
            
            updateFilter();
        end
    end

    function data = generateSimulatedData(noise_level)
        if nargin < 1
            noise_level = 0.1;
        end
        
        % Generate clean signal (combination of sinusoids)
        Fs = 100;  % 100 Hz sampling rate
        t = (0:999)/Fs;  % 10 seconds of data
        
        % Create a realistic sensor signal
        clean = 2*sin(2*pi*0.5*t) + 0.5*sin(2*pi*2*t) + 0.3*sin(2*pi*5*t) + 0.1*t;
        
        % Add noise
        noisy = clean + noise_level * randn(size(clean));
        
        data = struct();
        data.noisy = noisy;
        data.clean = clean;
        data.Fs = Fs;
        data.t = t;
        data.name = 'Simulated Sensor Data';
        data.noise_level = noise_level;
    end

    function data = loadDataFromFile(filepath)
        [~, ~, ext] = fileparts(filepath);
        
        switch lower(ext)
            case '.mat'
                loaded = load(filepath);
                % Try to find signal data
                fields = fieldnames(loaded);
                if any(contains(fields, 'signal'))
                    data.noisy = loaded.signal;
                elseif any(contains(fields, 'data'))
                    data.noisy = loaded.data;
                else
                    data.noisy = loaded.(fields{1});
                end
                data.clean = [];  % No clean reference for loaded data
                data.Fs = 100;  % Default sampling rate
                data.t = (0:length(data.noisy)-1)/data.Fs;
                data.name = 'Loaded Data';
                
            case {'.csv', '.txt'}
                data.noisy = csvread(filepath);
                data.noisy = data.noisy(:);  % Ensure column vector
                data.clean = [];  % No clean reference for loaded data
                data.Fs = 100;  % Default sampling rate
                data.t = (0:length(data.noisy)-1)/data.Fs;
                data.name = 'Loaded Data';
                
            otherwise
                error('Unsupported file format');
        end
    end

    function exportResults()
        % Export filtered signal and analysis results
        [filename, pathname] = uiputfile({'*.mat', 'MATLAB Data (*.mat)'}, 'Export Results');
        if isequal(filename, 0), return; end
        
        results = struct();
        results.original_signal = noisy_signal;
        results.filtered_signal = filtered_signal;
        results.clean_signal = clean_signal;
        results.filter_length = round(filterSlider.Value);
        results.mse = mse_value;
        results.sampling_rate = Fs;
        results.time_vector = t;
        results.filter_impulse = filter_impulse;
        
        save(fullfile(pathname, filename), 'results');
        uialert(fig, sprintf('Results exported to %s', filename), 'Export Complete', 'Icon', 'success');
    end

    function showHelp()
        helpText = ['MOVING-AVERAGE SMOOTHING ON SENSOR DATA' newline newline ...
            'OVERVIEW:' newline ...
            'This app demonstrates moving-average filtering for noise reduction' newline ...
            'in sensor data. The filter removes high-frequency noise while' newline ...
            'preserving the underlying signal characteristics.' newline newline ...
            'MOVING-AVERAGE FILTER:' newline ...
            'The N-point moving-average filter is defined as:' newline ...
            'h[n] = (1/N)∑δ[n-k] for k=0 to N-1' newline ...
            'This creates a low-pass filter that averages N consecutive samples.' newline newline ...
            'CONTROLS:' newline ...
            '• Filter Length N: Number of samples to average (1-50)' newline ...
            '• Noise Level: Amount of noise in generated data (0-1)' newline ...
            '• Data Presets: Pre-configured settings for different sensor types' newline ...
            '• Show Clean Reference: Display the original clean signal' newline ...
            '• Show Error Signal: Display the difference between filtered and clean' newline newline ...
            'TRADE-OFFS:' newline ...
            '• Larger N: More smoothing, less temporal resolution' newline ...
            '• Smaller N: Less smoothing, better temporal resolution' newline ...
            '• Optimal N depends on signal characteristics and noise level' newline newline ...
            'PERFORMANCE METRICS:' newline ...
            '• MSE (Mean Squared Error): Measures difference from clean reference' newline ...
            '• Lower MSE indicates better noise reduction' newline ...
            '• MSE helps find optimal filter length' newline newline ...
            'SENSOR PRESETS:' newline ...
            '• Temperature Sensor: Slow changes, moderate noise' newline ...
            '• ECG Signal: Fast changes, low noise tolerance' newline ...
            '• Accelerometer: High-frequency content, high noise' newline ...
            '• Pressure Sensor: Medium changes, moderate noise' newline newline ...
            'EDUCATIONAL CONCEPTS:' newline ...
            '• Moving-average filters and noise reduction' newline ...
            '• Trade-offs between smoothing and resolution' newline ...
            '• Signal processing in sensor applications' newline ...
            '• Performance metrics for filter evaluation'];
        
        % Create a figure with scrollable text
        helpFig = uifigure('Name', 'Help - Moving-Average Smoothing', 'Position', [300 300 600 500]);
        helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
        
        % Create scrollable text area
        helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 580 480], ...
            'FontSize', 12, 'FontName', 'Consolas', 'Editable', 'off');
    end

    function onClose()
        if isvalid(fig)
            delete(fig);
        end
    end
end
