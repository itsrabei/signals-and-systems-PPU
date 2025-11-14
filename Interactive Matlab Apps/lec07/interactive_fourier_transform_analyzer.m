function interactive_fourier_transform_analyzer
% INTERACTIVE FOURIER TRANSFORM ANALYZER
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates the Fourier Transform (FT) and its
% properties through hands-on experimentation. Students can explore the
% relationship between time and frequency domains, understand the effects of
% different signal parameters, and visualize the mathematical concepts behind
% the Fourier Transform.
% 
% FEATURES:
% • Multiple signal types (rectangular, triangular, Gaussian, exponential)
% • Real-time FFT computation and visualization
% • Interactive parameter adjustment
% • Magnitude and phase spectrum analysis
% • Window function effects demonstration
% • Educational presets for common scenarios

    % --- Initialize App State ---
    state = struct();
    state.signalType = 'Rectangular';
    state.duration = 2.0;
    state.frequency = 1.0;
    state.amplitude = 1.0;
    state.samplingRate = 1000;
    state.windowType = 'Rectangular';
    state.showPhase = false;
    state.normalize = true;
    state.zeroPadding = false;
    state.isPlaying = false;
    state.player = [];
    
    % --- Create Main Figure ---
    fig = uifigure('Name', 'Interactive Fourier Transform Analyzer v1.0', ...
        'Position', [100 100 1400 800], ...
        'CloseRequestFcn', @onClose);
    
    % --- UI Layout ---
    mainGrid = uigridlayout(fig, [3 1], 'ColumnWidth', {'1x'}, ...
        'RowHeight', {'fit', '1x', 'fit'}, 'Padding', [10 10 10 10]);
    
    % Top Panel: Controls
    topPanel = uipanel(mainGrid, 'Title', 'Fourier Transform Controls', 'FontSize', 14, 'FontWeight', 'bold');
    topPanel.Layout.Row = 1;
    
    % Middle Panel: Visualization
    middlePanel = uipanel(mainGrid, 'Title', 'Time and Frequency Domain Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    middlePanel.Layout.Row = 2;
    
    % Bottom Panel: Status and Information
    bottomPanel = uipanel(mainGrid, 'Title', 'Analysis Results', 'FontSize', 14, 'FontWeight', 'bold');
    bottomPanel.Layout.Row = 3;
    
    % --- TOP PANEL: Controls ---
    topGrid = uigridlayout(topPanel, [2 4], 'ColumnWidth', {'1x', '1x', '1x', '1x'}, ...
        'RowHeight', {'fit', 'fit'}, 'Padding', [15 15 15 15]);
    
    % Signal Parameters
    signalPanel = uipanel(topGrid, 'Title', 'Signal Parameters', 'FontSize', 12, 'FontWeight', 'bold');
    signalPanel.Layout.Row = 1; signalPanel.Layout.Column = 1;
    
    signalGrid = uigridlayout(signalPanel, [4 2], 'RowHeight', repmat({'fit'}, 1, 4), ...
        'ColumnWidth', {'fit', '1x'}, 'Padding', [10 10 10 10]);
    
    % Signal type
    signalLabel = uilabel(signalGrid, 'Text', 'Signal Type:', 'FontSize', 11, 'FontWeight', 'bold');
    signalLabel.Layout.Row = 1; signalLabel.Layout.Column = 1;
    
    signalDropdown = uidropdown(signalGrid, 'Items', {'Rectangular', 'Triangular', 'Gaussian', 'Exponential', 'Custom'}, ...
        'Value', 'Rectangular', 'ValueChangedFcn', @updateSignal);
    signalDropdown.Layout.Row = 1; signalDropdown.Layout.Column = 2;
    
    % Frequency
    freqLabel = uilabel(signalGrid, 'Text', 'Frequency (Hz):', 'FontSize', 11, 'FontWeight', 'bold');
    freqLabel.Layout.Row = 2; freqLabel.Layout.Column = 1;
    
    freqSlider = uislider(signalGrid, 'Limits', [0.1 10], 'Value', state.frequency, ...
        'ValueChangedFcn', @updateFrequency);
    freqSlider.Layout.Row = 2; freqSlider.Layout.Column = 2;
    
    freqDisplay = uilabel(signalGrid, 'Text', sprintf('%.1f Hz', state.frequency), 'FontSize', 10);
    freqDisplay.Layout.Row = 3; freqDisplay.Layout.Column = 1;
    
    % Amplitude
    ampLabel = uilabel(signalGrid, 'Text', 'Amplitude:', 'FontSize', 11, 'FontWeight', 'bold');
    ampLabel.Layout.Row = 4; ampLabel.Layout.Column = 1;
    
    ampSlider = uislider(signalGrid, 'Limits', [0.1 5], 'Value', state.amplitude, ...
        'ValueChangedFcn', @updateAmplitude);
    ampSlider.Layout.Row = 4; ampSlider.Layout.Column = 2;
    
    % Analysis Parameters
    analysisPanel = uipanel(topGrid, 'Title', 'Analysis Parameters', 'FontSize', 12, 'FontWeight', 'bold');
    analysisPanel.Layout.Row = 1; analysisPanel.Layout.Column = 2;
    
    analysisGrid = uigridlayout(analysisPanel, [4 2], 'RowHeight', repmat({'fit'}, 1, 4), ...
        'ColumnWidth', {'fit', '1x'}, 'Padding', [10 10 10 10]);
    
    % Duration
    durLabel = uilabel(analysisGrid, 'Text', 'Duration (s):', 'FontSize', 11, 'FontWeight', 'bold');
    durLabel.Layout.Row = 1; durLabel.Layout.Column = 1;
    
    durSlider = uislider(analysisGrid, 'Limits', [0.5 5], 'Value', state.duration, ...
        'ValueChangedFcn', @updateDuration);
    durSlider.Layout.Row = 1; durSlider.Layout.Column = 2;
    
    % Sampling Rate
    fsLabel = uilabel(analysisGrid, 'Text', 'Sampling Rate:', 'FontSize', 11, 'FontWeight', 'bold');
    fsLabel.Layout.Row = 2; fsLabel.Layout.Column = 1;
    
    fsSlider = uislider(analysisGrid, 'Limits', [100 2000], 'Value', state.samplingRate, ...
        'ValueChangedFcn', @updateSamplingRate);
    fsSlider.Layout.Row = 2; fsSlider.Layout.Column = 2;
    
    % Window Type
    windowLabel = uilabel(analysisGrid, 'Text', 'Window:', 'FontSize', 11, 'FontWeight', 'bold');
    windowLabel.Layout.Row = 3; windowLabel.Layout.Column = 1;
    
    windowDropdown = uidropdown(analysisGrid, 'Items', {'Rectangular', 'Hamming', 'Hanning', 'Blackman'}, ...
        'Value', 'Rectangular', 'ValueChangedFcn', @updateWindow);
    windowDropdown.Layout.Row = 3; windowDropdown.Layout.Column = 2;
    
    % Display Options
    displayPanel = uipanel(topGrid, 'Title', 'Display Options', 'FontSize', 12, 'FontWeight', 'bold');
    displayPanel.Layout.Row = 1; displayPanel.Layout.Column = 3;
    
    displayGrid = uigridlayout(displayPanel, [4 1], 'RowHeight', repmat({'fit'}, 1, 4), ...
        'Padding', [10 10 10 10]);
    
    showPhaseChk = uicheckbox(displayGrid, 'Text', 'Show Phase', 'Value', false, ...
        'ValueChangedFcn', @updateDisplay);
    showPhaseChk.Layout.Row = 1;
    
    normalizeChk = uicheckbox(displayGrid, 'Text', 'Normalize', 'Value', true, ...
        'ValueChangedFcn', @updateDisplay);
    normalizeChk.Layout.Row = 2;
    
    zeroPaddingChk = uicheckbox(displayGrid, 'Text', 'Zero Padding', 'Value', false, ...
        'ValueChangedFcn', @updateDisplay);
    zeroPaddingChk.Layout.Row = 3;
    
    % Audio Controls
    audioPanel = uipanel(topGrid, 'Title', 'Audio Controls', 'FontSize', 12, 'FontWeight', 'bold');
    audioPanel.Layout.Row = 1; audioPanel.Layout.Column = 4;
    
    audioGrid = uigridlayout(audioPanel, [3 1], 'RowHeight', repmat({'fit'}, 1, 3), ...
        'Padding', [10 10 10 10]);
    
    playButton = uibutton(audioGrid, 'Text', '▶ Play Signal', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.7 0.2], 'FontColor', 'white', 'ButtonPushedFcn', @playSignal);
    playButton.Layout.Row = 1;
    
    exportButton = uibutton(audioGrid, 'Text', '💾 Export', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.4 0.8], 'FontColor', 'white', 'ButtonPushedFcn', @exportData);
    exportButton.Layout.Row = 2;
    
    helpButton = uibutton(audioGrid, 'Text', '❓ Help', 'FontSize', 12, 'FontWeight', 'bold', ...
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
    
    % Frequency domain plot (magnitude)
    axFreq = uiaxes(middleGrid);
    axFreq.Title.String = 'Frequency Domain (Magnitude)';
    axFreq.XLabel.String = 'Frequency (Hz)';
    axFreq.YLabel.String = 'Magnitude';
    axFreq.Layout.Row = 1; axFreq.Layout.Column = 2;
    grid(axFreq, 'on');
    
    % Phase plot
    axPhase = uiaxes(middleGrid);
    axPhase.Title.String = 'Frequency Domain (Phase)';
    axPhase.XLabel.String = 'Frequency (Hz)';
    axPhase.YLabel.String = 'Phase (rad)';
    axPhase.Layout.Row = 2; axPhase.Layout.Column = 1;
    grid(axPhase, 'on');
    
    % Window function plot
    axWindow = uiaxes(middleGrid);
    axWindow.Title.String = 'Window Function';
    axWindow.XLabel.String = 'Time (s)';
    axWindow.YLabel.String = 'Amplitude';
    axWindow.Layout.Row = 2; axWindow.Layout.Column = 2;
    grid(axWindow, 'on');
    
    % --- BOTTOM PANEL: Status and Information ---
    bottomGrid = uigridlayout(bottomPanel, [1 3], 'ColumnWidth', {'1x', '1x', '1x'}, ...
        'Padding', [15 15 15 15]);
    
    % Status display
    statusLabel = uilabel(bottomGrid, 'Text', 'Ready', 'FontSize', 12, 'FontName', 'Consolas');
    statusLabel.Layout.Row = 1; statusLabel.Layout.Column = 1;
    
    % Analysis results
    resultsLabel = uilabel(bottomGrid, 'Text', 'Analysis: Computing...', 'FontSize', 12, 'FontName', 'Consolas');
    resultsLabel.Layout.Row = 1; resultsLabel.Layout.Column = 2;
    
    % Equation display
    equationLabel = uilabel(bottomGrid, 'Text', 'X(ω) = ∫ x(t) e^(-jωt) dt', 'FontSize', 12, 'FontName', 'Times New Roman');
    equationLabel.Layout.Row = 1; resultsLabel.Layout.Column = 3;
    
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
            case 'Rectangular'
                signal = state.amplitude * (abs(time - state.duration/2) < 0.5/state.frequency);
            case 'Triangular'
                signal = state.amplitude * (1 - 2*abs(time - state.duration/2) * state.frequency);
                signal = max(0, signal);
            case 'Gaussian'
                sigma = 1/(4*state.frequency);
                signal = state.amplitude * exp(-((time - state.duration/2).^2)/(2*sigma^2));
            case 'Exponential'
                signal = state.amplitude * exp(-state.frequency * time);
            case 'Custom'
                signal = state.amplitude * (sin(2*pi*state.frequency*time) + 0.5*sin(2*pi*2*state.frequency*time));
        end
        
        % Apply window function
        window = getWindowFunction(length(signal));
        signal = signal .* window;
    end
    
    function window = getWindowFunction(N)
        % Generate window function
        switch state.windowType
            case 'Rectangular'
                window = ones(1, N);
            case 'Hamming'
                window = hamming(N)';
            case 'Hanning'
                window = hann(N)';
            case 'Blackman'
                window = blackman(N)';
        end
    end
    
    function [magnitude, phase, frequencies] = computeFFT(signal, time)
        % Compute FFT
        N = length(signal);
        
        % Zero padding if enabled
        if state.zeroPadding
            N_fft = 2^nextpow2(4*N); % 4x zero padding
        else
            N_fft = N;
        end
        
        % Compute FFT
        Y = fft(signal, N_fft);
        
        % Frequency vector
        fs = 1/(time(2) - time(1));
        frequencies = (0:N_fft-1) * fs / N_fft;
        frequencies = frequencies(1:floor(N_fft/2));
        
        % Magnitude and phase
        magnitude = abs(Y(1:floor(N_fft/2)));
        phase = angle(Y(1:floor(N_fft/2)));
        
        % Normalize if requested
        if state.normalize
            magnitude = magnitude / max(magnitude);
        end
    end
    
    % --- Callback Functions ---
    function updateSignal(src, ~)
        state.signalType = src.Value;
        updateVisualization();
    end
    
    function updateFrequency(src, ~)
        state.frequency = src.Value;
        freqDisplay.Text = sprintf('%.1f Hz', state.frequency);
        updateVisualization();
    end
    
    function updateAmplitude(src, ~)
        state.amplitude = src.Value;
        updateVisualization();
    end
    
    function updateDuration(src, ~)
        state.duration = src.Value;
        updateVisualization();
    end
    
    function updateSamplingRate(src, ~)
        state.samplingRate = src.Value;
        updateVisualization();
    end
    
    function updateWindow(src, ~)
        state.windowType = src.Value;
        updateVisualization();
    end
    
    function updateDisplay(src, ~)
        if src == showPhaseChk
            state.showPhase = src.Value;
        elseif src == normalizeChk
            state.normalize = src.Value;
        elseif src == zeroPaddingChk
            state.zeroPadding = src.Value;
        end
        updateVisualization();
    end
    
    function updateVisualization()
        try
            % Generate signal
            [signal, time] = generateSignal();
            
            % Compute FFT
            [magnitude, phase, frequencies] = computeFFT(signal, time);
            
            % Update time domain plot
            cla(axTime);
            plot(axTime, time, signal, 'b-', 'LineWidth', 2);
            axTime.Title.String = sprintf('Time Domain: %s Signal', state.signalType);
            grid(axTime, 'on');
            
            % Update frequency domain plot
            cla(axFreq);
            plot(axFreq, frequencies, magnitude, 'r-', 'LineWidth', 2);
            axFreq.Title.String = 'Frequency Domain (Magnitude)';
            grid(axFreq, 'on');
            
            % Update phase plot
            cla(axPhase);
            if state.showPhase
                plot(axPhase, frequencies, phase, 'g-', 'LineWidth', 2);
                axPhase.Title.String = 'Frequency Domain (Phase)';
            else
                plot(axPhase, frequencies, unwrap(phase), 'g-', 'LineWidth', 2);
                axPhase.Title.String = 'Frequency Domain (Unwrapped Phase)';
            end
            grid(axPhase, 'on');
            
            % Update window function plot
            cla(axWindow);
            window = getWindowFunction(length(signal));
            plot(axWindow, time, window, 'm-', 'LineWidth', 2);
            axWindow.Title.String = sprintf('Window Function: %s', state.windowType);
            grid(axWindow, 'on');
            
            % Update status
            statusLabel.Text = sprintf('Signal: %s, Freq: %.1f Hz, Amp: %.1f', ...
                state.signalType, state.frequency, state.amplitude);
            
            % Update results
            peakFreq = frequencies(magnitude == max(magnitude));
            resultsLabel.Text = sprintf('Peak Freq: %.2f Hz, Max Mag: %.3f', peakFreq(1), max(magnitude));
            
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
            [magnitude, phase, frequencies] = computeFFT(signal, time);
            
            % Get filename
            defaultName = sprintf('ft_analysis_%s_%.1fHz.mat', state.signalType, state.frequency);
            [filename, pathname] = uiputfile('*.mat', 'Save Analysis Data', defaultName);
            
            if filename ~= 0
                % Save data
                save(fullfile(pathname, filename), 'signal', 'time', 'magnitude', 'phase', 'frequencies', 'state');
                statusLabel.Text = sprintf('Data exported to: %s', filename);
            end
            
        catch ME
            statusLabel.Text = sprintf('Export error: %s', ME.message);
        end
    end
    
    function showHelp(~, ~)
        helpText = ['FOURIER TRANSFORM ANALYZER HELP' newline newline ...
            'BASIC CONTROLS:' newline ...
            '• Signal Type: Choose from different signal types' newline ...
            '• Frequency: Adjust the fundamental frequency' newline ...
            '• Amplitude: Control signal amplitude' newline ...
            '• Duration: Set signal length' newline ...
            '• Sampling Rate: Control time resolution' newline newline ...
            'ANALYSIS FEATURES:' newline ...
            '• Real-time FFT computation' newline ...
            '• Magnitude and phase spectrum' newline ...
            '• Window function effects' newline ...
            '• Zero padding options' newline newline ...
            'DISPLAY OPTIONS:' newline ...
            '• Show Phase: Toggle phase display' newline ...
            '• Normalize: Normalize magnitude spectrum' newline ...
            '• Zero Padding: Increase frequency resolution' newline newline ...
            'EDUCATIONAL VALUE:' newline ...
            '• Understand time-frequency relationships' newline ...
            '• Learn about window functions' newline ...
            '• Explore FFT properties' newline ...
            '• Practice signal analysis techniques'];
        
        helpFig = uifigure('Name', 'Help - Fourier Transform Analyzer v1.0', 'Position', [300 300 600 500]);
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

