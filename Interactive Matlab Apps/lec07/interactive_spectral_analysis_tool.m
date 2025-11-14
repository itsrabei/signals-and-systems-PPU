function interactive_spectral_analysis_tool
% INTERACTIVE SPECTRAL ANALYSIS TOOL
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app provides comprehensive spectral analysis tools
% for educational purposes. Students can explore power spectral density,
% spectrograms, and advanced frequency domain analysis techniques.
% 
% FEATURES:
% • Power Spectral Density (PSD) analysis
% • Spectrogram visualization
% • Multiple window functions
% • Frequency resolution control
% • Noise analysis and filtering
% • Educational presets for common scenarios

    % --- Initialize App State ---
    state = struct();
    state.analysisType = 'PSD';
    state.signalType = 'Sine Wave';
    state.frequency = 100;
    state.amplitude = 1.0;
    state.duration = 2.0;
    state.samplingRate = 1000;
    state.windowType = 'Hamming';
    state.windowLength = 256;
    state.overlap = 0.5;
    state.noiseLevel = 0.0;
    state.filterType = 'None';
    state.filterFreq = 200;
    state.isPlaying = false;
    state.player = [];
    
    % --- Create Main Figure ---
    fig = uifigure('Name', 'Interactive Spectral Analysis Tool v1.0', ...
        'Position', [100 100 1600 900], ...
        'CloseRequestFcn', @onClose);
    
    % --- UI Layout ---
    mainGrid = uigridlayout(fig, [3 1], 'ColumnWidth', {'1x'}, ...
        'RowHeight', {'fit', '1x', 'fit'}, 'Padding', [10 10 10 10]);
    
    % Top Panel: Controls
    topPanel = uipanel(mainGrid, 'Title', 'Spectral Analysis Controls', 'FontSize', 14, 'FontWeight', 'bold');
    topPanel.Layout.Row = 1;
    
    % Middle Panel: Visualization
    middlePanel = uipanel(mainGrid, 'Title', 'Spectral Analysis Results', 'FontSize', 14, 'FontWeight', 'bold');
    middlePanel.Layout.Row = 2;
    
    % Bottom Panel: Status and Information
    bottomPanel = uipanel(mainGrid, 'Title', 'Analysis Information', 'FontSize', 14, 'FontWeight', 'bold');
    bottomPanel.Layout.Row = 3;
    
    % --- TOP PANEL: Controls ---
    topGrid = uigridlayout(topPanel, [2 4], 'ColumnWidth', {'1x', '1x', '1x', '1x'}, ...
        'RowHeight', {'fit', 'fit'}, 'Padding', [15 15 15 15]);
    
    % Analysis Type
    analysisPanel = uipanel(topGrid, 'Title', 'Analysis Type', 'FontSize', 12, 'FontWeight', 'bold');
    analysisPanel.Layout.Row = 1; analysisPanel.Layout.Column = 1;
    
    analysisGrid = uigridlayout(analysisPanel, [3 1], 'RowHeight', repmat({'fit'}, 1, 3), ...
        'Padding', [10 10 10 10]);
    
    analysisDropdown = uidropdown(analysisGrid, 'Items', {'PSD', 'Spectrogram', 'Welch PSD', 'Periodogram'}, ...
        'Value', 'PSD', 'ValueChangedFcn', @updateAnalysis);
    analysisDropdown.Layout.Row = 1;
    
    % Signal Parameters
    signalPanel = uipanel(topGrid, 'Title', 'Signal Parameters', 'FontSize', 12, 'FontWeight', 'bold');
    signalPanel.Layout.Row = 1; signalPanel.Layout.Column = 2;
    
    signalGrid = uigridlayout(signalPanel, [4 2], 'RowHeight', repmat({'fit'}, 1, 4), ...
        'ColumnWidth', {'fit', '1x'}, 'Padding', [10 10 10 10]);
    
    signalLabel = uilabel(signalGrid, 'Text', 'Signal Type:', 'FontSize', 11, 'FontWeight', 'bold');
    signalLabel.Layout.Row = 1; signalLabel.Layout.Column = 1;
    
    signalDropdown = uidropdown(signalGrid, 'Items', {'Sine Wave', 'Chirp', 'Noise', 'Multi-tone', 'Custom'}, ...
        'Value', 'Sine Wave', 'ValueChangedFcn', @updateSignal);
    signalDropdown.Layout.Row = 1; signalDropdown.Layout.Column = 2;
    
    freqLabel = uilabel(signalGrid, 'Text', 'Frequency (Hz):', 'FontSize', 11, 'FontWeight', 'bold');
    freqLabel.Layout.Row = 2; freqLabel.Layout.Column = 1;
    
    freqSlider = uislider(signalGrid, 'Limits', [1 500], 'Value', state.frequency, ...
        'ValueChangedFcn', @updateFrequency);
    freqSlider.Layout.Row = 2; freqSlider.Layout.Column = 2;
    
    ampLabel = uilabel(signalGrid, 'Text', 'Amplitude:', 'FontSize', 11, 'FontWeight', 'bold');
    ampLabel.Layout.Row = 3; ampLabel.Layout.Column = 1;
    
    ampSlider = uislider(signalGrid, 'Limits', [0.1 5], 'Value', state.amplitude, ...
        'ValueChangedFcn', @updateAmplitude);
    ampSlider.Layout.Row = 3; ampSlider.Layout.Column = 2;
    
    noiseLabel = uilabel(signalGrid, 'Text', 'Noise Level:', 'FontSize', 11, 'FontWeight', 'bold');
    noiseLabel.Layout.Row = 4; noiseLabel.Layout.Column = 1;
    
    noiseSlider = uislider(signalGrid, 'Limits', [0 1], 'Value', state.noiseLevel, ...
        'ValueChangedFcn', @updateNoise);
    noiseSlider.Layout.Row = 4; noiseSlider.Layout.Column = 2;
    
    % Window Parameters
    windowPanel = uipanel(topGrid, 'Title', 'Window Parameters', 'FontSize', 12, 'FontWeight', 'bold');
    windowPanel.Layout.Row = 1; windowPanel.Layout.Column = 3;
    
    windowGrid = uigridlayout(windowPanel, [4 2], 'RowHeight', repmat({'fit'}, 1, 4), ...
        'ColumnWidth', {'fit', '1x'}, 'Padding', [10 10 10 10]);
    
    windowLabel = uilabel(windowGrid, 'Text', 'Window Type:', 'FontSize', 11, 'FontWeight', 'bold');
    windowLabel.Layout.Row = 1; windowLabel.Layout.Column = 1;
    
    windowDropdown = uidropdown(windowGrid, 'Items', {'Hamming', 'Hanning', 'Blackman', 'Kaiser', 'Rectangular'}, ...
        'Value', 'Hamming', 'ValueChangedFcn', @updateWindow);
    windowDropdown.Layout.Row = 1; windowDropdown.Layout.Column = 2;
    
    windowLengthLabel = uilabel(windowGrid, 'Text', 'Window Length:', 'FontSize', 11, 'FontWeight', 'bold');
    windowLengthLabel.Layout.Row = 2; windowLengthLabel.Layout.Column = 1;
    
    windowLengthSlider = uislider(windowGrid, 'Limits', [64 1024], 'Value', state.windowLength, ...
        'ValueChangedFcn', @updateWindowLength);
    windowLengthSlider.Layout.Row = 2; windowLengthSlider.Layout.Column = 2;
    
    overlapLabel = uilabel(windowGrid, 'Text', 'Overlap (%):', 'FontSize', 11, 'FontWeight', 'bold');
    overlapLabel.Layout.Row = 3; overlapLabel.Layout.Column = 1;
    
    overlapSlider = uislider(windowGrid, 'Limits', [0 0.9], 'Value', state.overlap, ...
        'ValueChangedFcn', @updateOverlap);
    overlapSlider.Layout.Row = 3; overlapSlider.Layout.Column = 2;
    
    % Controls
    controlPanel = uipanel(topGrid, 'Title', 'Controls', 'FontSize', 12, 'FontWeight', 'bold');
    controlPanel.Layout.Row = 1; controlPanel.Layout.Column = 4;
    
    controlGrid = uigridlayout(controlPanel, [4 1], 'RowHeight', repmat({'fit'}, 1, 4), ...
        'Padding', [10 10 10 10]);
    
    playButton = uibutton(controlGrid, 'Text', '▶ Play Signal', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.7 0.2], 'FontColor', 'white', 'ButtonPushedFcn', @playSignal);
    playButton.Layout.Row = 1;
    
    exportButton = uibutton(controlGrid, 'Text', '💾 Export', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.4 0.8], 'FontColor', 'white', 'ButtonPushedFcn', @exportData);
    exportButton.Layout.Row = 2;
    
    helpButton = uibutton(controlGrid, 'Text', '❓ Help', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.6 0.3 0.8], 'FontColor', 'white', 'ButtonPushedFcn', @showHelp);
    helpButton.Layout.Row = 3;
    
    % --- MIDDLE PANEL: Visualization ---
    middleGrid = uigridlayout(middlePanel, [2 2], 'RowHeight', {'1x', '1x'}, ...
        'ColumnWidth', {'1x', '1x'}, 'Padding', [15 15 15 15]);
    
    % Time domain plot
    axTime = uiaxes(middleGrid);
    axTime.Title.String = 'Time Domain Signal';
    axTime.XLabel.String = 'Time (s)';
    axTime.YLabel.String = 'Amplitude';
    axTime.Layout.Row = 1; axTime.Layout.Column = 1;
    grid(axTime, 'on');
    
    % Frequency domain plot
    axFreq = uiaxes(middleGrid);
    axFreq.Title.String = 'Frequency Domain Analysis';
    axFreq.XLabel.String = 'Frequency (Hz)';
    axFreq.YLabel.String = 'Magnitude (dB)';
    axFreq.Layout.Row = 1; axFreq.Layout.Column = 2;
    grid(axFreq, 'on');
    
    % Spectrogram plot
    axSpec = uiaxes(middleGrid);
    axSpec.Title.String = 'Spectrogram';
    axSpec.XLabel.String = 'Time (s)';
    axSpec.YLabel.String = 'Frequency (Hz)';
    axSpec.Layout.Row = 2; axSpec.Layout.Column = 1;
    
    % Window function plot
    axWindow = uiaxes(middleGrid);
    axWindow.Title.String = 'Window Function';
    axWindow.XLabel.String = 'Sample';
    axWindow.YLabel.String = 'Amplitude';
    axWindow.Layout.Row = 2; axWindow.Layout.Column = 2;
    grid(axWindow, 'on');
    
    % --- BOTTOM PANEL: Status and Information ---
    bottomGrid = uigridlayout(bottomPanel, [1 4], 'ColumnWidth', {'1x', '1x', '1x', '1x'}, ...
        'Padding', [15 15 15 15]);
    
    % Status display
    statusLabel = uilabel(bottomGrid, 'Text', 'Ready', 'FontSize', 12, 'FontName', 'Consolas');
    statusLabel.Layout.Row = 1; statusLabel.Layout.Column = 1;
    
    % Analysis results
    resultsLabel = uilabel(bottomGrid, 'Text', 'Analysis: Computing...', 'FontSize', 12, 'FontName', 'Consolas');
    resultsLabel.Layout.Row = 1; resultsLabel.Layout.Column = 2;
    
    % Frequency resolution
    resolutionLabel = uilabel(bottomGrid, 'Text', 'Resolution: 0 Hz', 'FontSize', 12, 'FontName', 'Consolas');
    resolutionLabel.Layout.Row = 1; resolutionLabel.Layout.Column = 3;
    
    % Equation display
    equationLabel = uilabel(bottomGrid, 'Text', 'P(ω) = |X(ω)|²', 'FontSize', 12, 'FontName', 'Times New Roman');
    equationLabel.Layout.Row = 1; equationLabel.Layout.Column = 4;
    
    % --- Initialize Visualization ---
    updateVisualization();
    
    % --- Helper Functions ---
    function [signal, time] = generateSignal()
        % Generate time vector
        dt = 1/state.samplingRate;
        time = 0:dt:state.duration;
        time = time(1:end-1); % Ensure correct length
        
        % Generate signal based on type
        switch state.signalType
            case 'Sine Wave'
                signal = state.amplitude * sin(2*pi*state.frequency*time);
            case 'Chirp'
                signal = state.amplitude * chirp(time, 0, state.duration, state.frequency);
            case 'Noise'
                signal = state.amplitude * randn(size(time));
            case 'Multi-tone'
                signal = state.amplitude * (sin(2*pi*state.frequency*time) + 0.5*sin(2*pi*2*state.frequency*time) + 0.3*sin(2*pi*3*state.frequency*time));
            case 'Custom'
                signal = state.amplitude * (sin(2*pi*state.frequency*time) + 0.3*sin(2*pi*3*state.frequency*time + pi/4));
        end
        
        % Add noise if specified
        if state.noiseLevel > 0
            noise = state.noiseLevel * randn(size(signal));
            signal = signal + noise;
        end
    end
    
    function window = getWindowFunction(N)
        % Generate window function
        switch state.windowType
            case 'Hamming'
                window = hamming(N)';
            case 'Hanning'
                window = hann(N)';
            case 'Blackman'
                window = blackman(N)';
            case 'Kaiser'
                window = kaiser(N, 5)';
            case 'Rectangular'
                window = ones(1, N);
        end
    end
    
    function [psd, frequencies] = computePSD(signal, time)
        % Compute Power Spectral Density
        fs = 1/(time(2) - time(1));
        
        switch state.analysisType
            case 'PSD'
                [psd, frequencies] = pwelch(signal, [], [], [], fs);
            case 'Welch PSD'
                [psd, frequencies] = pwelch(signal, [], [], [], fs);
            case 'Periodogram'
                [psd, frequencies] = periodogram(signal, [], [], fs);
            case 'Spectrogram'
                [psd, frequencies, ~] = spectrogram(signal, state.windowLength, round(state.overlap*state.windowLength), [], fs);
                psd = mean(abs(psd).^2, 2);
        end
        
        % Convert to dB
        psd = 10*log10(psd + eps);
    end
    
    function [S, F, T] = computeSpectrogram(signal, time)
        % Compute spectrogram
        fs = 1/(time(2) - time(1));
        window = getWindowFunction(state.windowLength);
        
        [S, F, T] = spectrogram(signal, window, round(state.overlap*state.windowLength), [], fs);
        S = 10*log10(abs(S) + eps);
    end
    
    % --- Callback Functions ---
    function updateAnalysis(src, ~)
        state.analysisType = src.Value;
        updateVisualization();
    end
    
    function updateSignal(src, ~)
        state.signalType = src.Value;
        updateVisualization();
    end
    
    function updateFrequency(src, ~)
        state.frequency = src.Value;
        updateVisualization();
    end
    
    function updateAmplitude(src, ~)
        state.amplitude = src.Value;
        updateVisualization();
    end
    
    function updateNoise(src, ~)
        state.noiseLevel = src.Value;
        updateVisualization();
    end
    
    function updateWindow(src, ~)
        state.windowType = src.Value;
        updateVisualization();
    end
    
    function updateWindowLength(src, ~)
        state.windowLength = round(src.Value);
        updateVisualization();
    end
    
    function updateOverlap(src, ~)
        state.overlap = src.Value;
        updateVisualization();
    end
    
    function updateVisualization()
        try
            % Generate signal
            [signal, time] = generateSignal();
            
            % Update time domain plot
            cla(axTime);
            plot(axTime, time, signal, 'b-', 'LineWidth', 1.5);
            axTime.Title.String = sprintf('Time Domain: %s Signal', state.signalType);
            grid(axTime, 'on');
            
            % Compute spectral analysis
            [psd, frequencies] = computePSD(signal, time);
            
            % Update frequency domain plot
            cla(axFreq);
            plot(axFreq, frequencies, psd, 'r-', 'LineWidth', 2);
            axFreq.Title.String = sprintf('%s Analysis', state.analysisType);
            grid(axFreq, 'on');
            
            % Compute spectrogram
            [S, F, T] = computeSpectrogram(signal, time);
            
            % Update spectrogram plot
            cla(axSpec);
            imagesc(axSpec, T, F, S);
            axSpec.Title.String = 'Spectrogram';
            axSpec.YDir = 'normal';
            colorbar(axSpec);
            
            % Update window function plot
            cla(axWindow);
            window = getWindowFunction(state.windowLength);
            plot(axWindow, 1:length(window), window, 'm-', 'LineWidth', 2);
            axWindow.Title.String = sprintf('Window: %s (Length: %d)', state.windowType, state.windowLength);
            grid(axWindow, 'on');
            
            % Update status
            statusLabel.Text = sprintf('Signal: %s, Freq: %.1f Hz, Noise: %.2f', ...
                state.signalType, state.frequency, state.noiseLevel);
            
            % Update results
            peakFreq = frequencies(psd == max(psd));
            resultsLabel.Text = sprintf('Peak Freq: %.2f Hz, Max PSD: %.1f dB', peakFreq(1), max(psd));
            
            % Update frequency resolution
            df = frequencies(2) - frequencies(1);
            resolutionLabel.Text = sprintf('Resolution: %.2f Hz', df);
            
        catch ME
            statusLabel.Text = sprintf('Error: %s', ME.message);
        end
    end
    
    function playSignal(~, ~)
        try
            [signal, ~] = generateSignal();
            
            % Normalize for audio playback
            if max(abs(signal)) > 0
                signal = signal / max(abs(signal)) * 0.8; % Prevent clipping
            end
            
            % Create and play audio
            state.player = audioplayer(signal, state.samplingRate);
            state.player.StopFcn = @onPlaybackComplete;
            play(state.player);
            
            state.isPlaying = true;
            playButton.Text = '⏸ Stop';
            playButton.BackgroundColor = [0.8 0.4 0.2];
            statusLabel.Text = 'Playing signal...';
            
        catch ME
            statusLabel.Text = sprintf('Playback error: %s', ME.message);
        end
    end
    
    function onPlaybackComplete()
        state.isPlaying = false;
        playButton.Text = '▶ Play Signal';
        playButton.BackgroundColor = [0.2 0.7 0.2];
        statusLabel.Text = 'Playback complete';
    end
    
    function exportData(~, ~)
        try
            [signal, time] = generateSignal();
            [psd, frequencies] = computePSD(signal, time);
            [S, F, T] = computeSpectrogram(signal, time);
            
            % Get filename
            defaultName = sprintf('spectral_analysis_%s_%.1fHz.mat', state.signalType, state.frequency);
            [filename, pathname] = uiputfile('*.mat', 'Save Analysis Data', defaultName);
            
            if filename ~= 0
                % Save data
                save(fullfile(pathname, filename), 'signal', 'time', 'psd', 'frequencies', 'S', 'F', 'T', 'state');
                statusLabel.Text = sprintf('Data exported to: %s', filename);
            end
            
        catch ME
            statusLabel.Text = sprintf('Export error: %s', ME.message);
        end
    end
    
    function showHelp(~, ~)
        helpText = ['SPECTRAL ANALYSIS TOOL HELP' newline newline ...
            'ANALYSIS TYPES:' newline ...
            '• PSD: Power Spectral Density using Welch method' newline ...
            '• Spectrogram: Time-frequency representation' newline ...
            '• Welch PSD: Welch method for PSD estimation' newline ...
            '• Periodogram: Basic periodogram method' newline newline ...
            'SIGNAL TYPES:' newline ...
            '• Sine Wave: Pure sinusoidal signal' newline ...
            '• Chirp: Frequency-swept signal' newline ...
            '• Noise: Random noise signal' newline ...
            '• Multi-tone: Multiple frequency components' newline ...
            '• Custom: User-defined signal' newline newline ...
            'WINDOW FUNCTIONS:' newline ...
            '• Hamming: Good frequency resolution' newline ...
            '• Hanning: Good time resolution' newline ...
            '• Blackman: Excellent sidelobe suppression' newline ...
            '• Kaiser: Adjustable sidelobe level' newline ...
            '• Rectangular: No windowing' newline newline ...
            'EDUCATIONAL VALUE:' newline ...
            '• Understand spectral analysis concepts' newline ...
            '• Learn about window functions' newline ...
            '• Explore time-frequency analysis' newline ...
            '• Practice signal processing techniques'];
        
        helpFig = uifigure('Name', 'Help - Spectral Analysis Tool v1.0', 'Position', [300 300 600 500]);
        helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
        
        helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 580 480], ...
            'FontSize', 11, 'FontName', 'Consolas', 'Editable', 'off');
    end
    
    function onClose(~, ~)
        % Clean up audio player
        if ~isempty(state.player) && isvalid(state.player)
            stop(state.player);
            delete(state.player);
        end
        
        % Close figure
        delete(fig);
    end
end

