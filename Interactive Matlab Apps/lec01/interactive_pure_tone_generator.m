function interactive_pure_tone_generator
% INTERACTIVE PURE TONE GENERATOR
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app generates pure sinusoidal tones for audio
% testing and signal analysis. Students can explore frequency relationships,
% amplitude effects, and basic audio concepts through hands-on experimentation.
% 
% FEATURES:
% • Frequency range: 10 Hz to 25 kHz (full human hearing range)
% • Amplitude control with visual feedback
% • Real-time waveform visualization
% • Audio playback with pause/resume
% • Export to WAV files
% • Musical presets for common frequencies

    % --- Initialize App State ---
    state = struct();
    state.freq = 440;           % Default: A4 note
    state.amplitude = 1.0;      % Default amplitude (increased for more dynamic effects)
    state.duration = 2.0;       % Default duration in seconds
    state.sampleRate = 44100;   % CD quality
    state.isPlaying = false;
    state.isPaused = false;
    state.player = [];
    state.phase = 0;            % Phase offset
    
    % --- Create Main Figure ---
    fig = uifigure('Name', 'Interactive Pure Tone Generator v1.0', ...
        'Position', [100 100 1000 600], ...
        'CloseRequestFcn', @onClose);
    
    % --- UI Layout ---
    mainGrid = uigridlayout(fig, [2 1], 'ColumnWidth', {'1x'}, ...
        'RowHeight', {'fit', '1x'}, 'Padding', [10 10 10 10]);
    
    % Top Panel: Controls
    topPanel = uipanel(mainGrid, 'Title', 'Tone Controls', 'FontSize', 14, 'FontWeight', 'bold');
    topPanel.Layout.Row = 1;
    
    % Bottom Panel: Visualization
    bottomPanel = uipanel(mainGrid, 'Title', 'Waveform Visualization', 'FontSize', 14, 'FontWeight', 'bold');
    bottomPanel.Layout.Row = 2;
    
    % --- TOP PANEL: Basic Controls (Horizontal Layout) ---
    topGrid = uigridlayout(topPanel, [3 7], 'ColumnWidth', repmat({'fit'}, 1, 7), ...
        'RowHeight', repmat({'fit'}, 1, 3), 'Padding', [15 15 15 15]);
    
    % Frequency Control
    freqLabel = uilabel(topGrid, 'Text', 'Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
    freqLabel.Layout.Row = 1; freqLabel.Layout.Column = 1;
    
    % Use logarithmic scale for better frequency selection
    logLimits = [log10(10), log10(22000)];
    freqSlider = uislider(topGrid, 'Limits', logLimits, 'Value', log10(state.freq), ...
        'ValueChangingFcn', @updateFreqDisplay, 'ValueChangedFcn', @updateFrequency);
    freqSlider.Layout.Row = 2; freqSlider.Layout.Column = 1;
    
    freqDisplay = uilabel(topGrid, 'Text', sprintf('%.1f Hz', state.freq), ...
        'FontSize', 11, 'FontName', 'Consolas');
    freqDisplay.Layout.Row = 3; freqDisplay.Layout.Column = 1;
    
    % Amplitude Control (Increased range for more dynamic effects)
    ampLabel = uilabel(topGrid, 'Text', 'Amplitude', 'FontSize', 12, 'FontWeight', 'bold');
    ampLabel.Layout.Row = 1; ampLabel.Layout.Column = 2;
    
    ampSlider = uislider(topGrid, 'Limits', [0 2], 'Value', state.amplitude, ...
        'ValueChangingFcn', @updateAmpDisplay, 'ValueChangedFcn', @updateAmplitude);
    ampSlider.Layout.Row = 2; ampSlider.Layout.Column = 2;
    
    ampDisplay = uilabel(topGrid, 'Text', sprintf('%.2f', state.amplitude), ...
        'FontSize', 11, 'FontName', 'Consolas');
    ampDisplay.Layout.Row = 3; ampDisplay.Layout.Column = 2;
    
    % Duration Control
    durLabel = uilabel(topGrid, 'Text', 'Duration (seconds)', 'FontSize', 12, 'FontWeight', 'bold');
    durLabel.Layout.Row = 1; durLabel.Layout.Column = 3;
    
    durSlider = uislider(topGrid, 'Limits', [0.1 10], 'Value', state.duration, ...
        'ValueChangingFcn', @updateDurDisplay, 'ValueChangedFcn', @updateDuration);
    durSlider.Layout.Row = 2; durSlider.Layout.Column = 3;
    
    durDisplay = uilabel(topGrid, 'Text', sprintf('%.1f s', state.duration), ...
        'FontSize', 11, 'FontName', 'Consolas');
    durDisplay.Layout.Row = 3; durDisplay.Layout.Column = 3;
    
    % Musical Presets
    presetLabel = uilabel(topGrid, 'Text', 'Musical Presets', 'FontSize', 12, 'FontWeight', 'bold');
    presetLabel.Layout.Row = 1; presetLabel.Layout.Column = 4;
    
    presetDropdown = uidropdown(topGrid, 'Items', {'Custom', 'A4 (440 Hz)', 'C4 (261.6 Hz)', 'E4 (329.6 Hz)', ...
        'G4 (392.0 Hz)', 'A5 (880 Hz)', 'C5 (523.3 Hz)', 'Bass A (55 Hz)', 'High C (1046.5 Hz)'}, ...
        'ValueChangedFcn', @selectPreset);
    presetDropdown.Layout.Row = 2; presetDropdown.Layout.Column = 4;
    
    % Audio Controls
    playButton = uibutton(topGrid, 'Text', 'Play', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.7 0.2], 'FontColor', 'white', 'ButtonPushedFcn', @togglePlayback);
    playButton.Layout.Row = 2; playButton.Layout.Column = 5;
    
    % Export Button
    exportButton = uibutton(topGrid, 'Text', 'Export WAV', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.4 0.8], 'FontColor', 'white', 'ButtonPushedFcn', @exportAudio);
    exportButton.Layout.Row = 2; exportButton.Layout.Column = 6;
    
    % Help Button
    helpButton = uibutton(topGrid, 'Text', 'Help', 'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.6 0.3 0.8], 'FontColor', 'white', 'ButtonPushedFcn', @showHelp);
    helpButton.Layout.Row = 2; helpButton.Layout.Column = 7;
    
    % --- BOTTOM PANEL: Visualization ---
    bottomGrid = uigridlayout(bottomPanel, [1 1], 'RowHeight', {'1x'}, ...
        'Padding', [15 15 15 15]);
    
    % Main waveform plot
    axMain = uiaxes(bottomGrid, 'FontSize', 10);
    axMain.Layout.Row = 1;
    axMain.XLabel.String = 'Time (s)';
    axMain.YLabel.String = 'Amplitude';
    axMain.Title.String = 'Pure Tone Waveform';
    grid(axMain, 'on');
    box(axMain, 'on');
    
    % --- Initialize Plots ---
    updateVisualization();
    
    % --- Helper Functions ---
    function [y, t] = generateSignal(duration)
        % Helper function to generate the audio signal based on the current state
        t = 0:1/state.sampleRate:duration;
        t = t(1:end-1); % Ensure time vector has correct length

        % Generate pure tone
        y = state.amplitude * sin(2*pi * state.freq * t + state.phase);
    end
    
    % --- Callback Functions ---
    function updateFreqDisplay(src, ~)
        currentFreq = 10^src.Value; % Convert from log scale
        freqDisplay.Text = sprintf('%.1f Hz', currentFreq);
    end
    
    function updateFrequency(src, ~)
        state.freq = 10^src.Value; % Convert from log scale
        freqDisplay.Text = sprintf('%.1f Hz', state.freq);
        presetDropdown.Value = 'Custom'; % Update dropdown to show Custom when slider moved
        updateVisualization();
    end
    
    function updateAmpDisplay(src, ~)
        ampDisplay.Text = sprintf('%.2f', src.Value);
    end
    
    function updateAmplitude(src, ~)
        state.amplitude = src.Value;
        ampDisplay.Text = sprintf('%.2f', state.amplitude);
        updateVisualization();
    end
    
    function updateDurDisplay(src, ~)
        durDisplay.Text = sprintf('%.1f s', src.Value);
    end
    
    function updateDuration(src, ~)
        state.duration = src.Value;
        durDisplay.Text = sprintf('%.1f s', state.duration);
        updateVisualization();
    end
    
    function togglePlayback(~, ~)
        % Case 1: Sound is currently playing -> Pause it
        if state.isPlaying && ~state.isPaused
            if ~isempty(state.player) && isvalid(state.player)
                pause(state.player);
                state.isPaused = true;
                playButton.Text = 'Resume';
                playButton.BackgroundColor = [0.2 0.7 0.2]; % Green for "go"
            end
        % Case 2: Sound is paused -> Resume it
        elseif state.isPlaying && state.isPaused
            if ~isempty(state.player) && isvalid(state.player)
                resume(state.player);
                state.isPaused = false;
                playButton.Text = 'Pause';
                playButton.BackgroundColor = [0.8 0.4 0.2]; % Orange for "pause"
            end
        % Case 3: Sound is stopped -> Start new playback
        else
            generateAndPlay();
        end
    end
    
    function generateAndPlay()
        try
            [y, ~] = generateSignal(state.duration);
            
            % Create and play audio
            state.player = audioplayer(y, state.sampleRate);
            state.player.StopFcn = @(~,~) onPlaybackComplete();
            play(state.player);
            
            state.isPlaying = true;
            playButton.Text = '⏸ Pause';
            playButton.BackgroundColor = [0.8 0.4 0.2];
            
        catch ME
            uialert(fig, sprintf('Error generating audio: %s', ME.message), 'Audio Error', 'Icon', 'error');
        end
    end
    
    function onPlaybackComplete()
        state.isPlaying = false;
        state.isPaused = false; % Reset paused state
        playButton.Text = '▶ Play';
        playButton.BackgroundColor = [0.2 0.7 0.2];
    end
    
    function exportAudio(~, ~)
        try
            [y, ~] = generateSignal(state.duration);
            
            % Get filename
            defaultName = sprintf('tone_%.1fHz_%.1fs.wav', state.freq, state.duration);
            [filename, pathname] = uiputfile('*.wav', 'Save Audio File', defaultName);
            
            if filename ~= 0
                audiowrite(fullfile(pathname, filename), y, state.sampleRate);
                uialert(fig, sprintf('Audio exported successfully!\nFile: %s', filename), ...
                    'Export Complete', 'Icon', 'success');
            end
            
        catch ME
            uialert(fig, sprintf('Error exporting audio: %s', ME.message), 'Export Error', 'Icon', 'error');
        end
    end
    
    function updateVisualization()
        try
            % Generate signal for visualization (first 100ms for clarity)
            vis_duration = min(state.duration, 0.1);
            [y, t] = generateSignal(vis_duration);
            
            % Update main plot with new color and padding
            cla(axMain);
            plot(axMain, t*1000, y, 'Color', [0.8 0.2 0.4], 'LineWidth', 2.5); % Changed to magenta/pink color
            axMain.XLabel.String = 'Time (ms)';
            axMain.YLabel.String = 'Amplitude';
            axMain.Title.String = sprintf('Pure Tone: %.1f Hz, Amp: %.2f', state.freq, state.amplitude);
            grid(axMain, 'on');
            
            % Add padding to y-axis for better visualization
            if ~isempty(y)
                y_max = max(abs(y));
                y_padding = y_max * 0.2; % 20% padding
                axMain.YLim = [-y_max - y_padding, y_max + y_padding];
            end
            
        catch ME
            % Handle visualization errors gracefully
            cla(axMain);
        end
    end
    
    function selectPreset(src, ~)
        switch src.Value
            case 'A4 (440 Hz)'
                state.freq = 440;
            case 'C4 (261.6 Hz)'
                state.freq = 261.6;
            case 'E4 (329.6 Hz)'
                state.freq = 329.6;
            case 'G4 (392.0 Hz)'
                state.freq = 392.0;
            case 'A5 (880 Hz)'
                state.freq = 880;
            case 'C5 (523.3 Hz)'
                state.freq = 523.3;
            case 'Bass A (55 Hz)'
                state.freq = 55;
            case 'High C (1046.5 Hz)'
                state.freq = 1046.5;
        end
        
        if ~strcmp(src.Value, 'Custom')
            freqSlider.Value = log10(state.freq); % Convert to log scale for slider
            freqDisplay.Text = sprintf('%.1f Hz', state.freq);
            updateVisualization();
        end
    end
    
    function showHelp(~, ~)
        helpText = ['PURE TONE GENERATOR HELP' newline newline ...
            'BASIC CONTROLS:' newline ...
            '• Frequency Slider: Adjust tone frequency (10 Hz - 22 kHz)' newline ...
            '• Amplitude Slider: Control volume (0.0 - 2.0)' newline ...
            '• Duration Slider: Set tone length (0.1 - 10 seconds)' newline ...
            '• Play Button: Start/stop audio playback' newline ...
            '• Export Button: Save audio as WAV file' newline newline ...
            'MUSICAL PRESETS:' newline ...
            '• Quick access to common musical frequencies' newline ...
            '• A4 (440 Hz) is the standard tuning note' newline ...
            '• C4 (261.6 Hz) is middle C on piano' newline newline ...
            'VISUALIZATION:' newline ...
            '• Time domain waveform display' newline ...
            '• Real-time updates as you adjust parameters' newline newline ...
            'EDUCATIONAL VALUE:' newline ...
            '• Explore frequency relationships' newline ...
            '• Understand amplitude effects' newline ...
            '• Learn about pure sinusoidal tones' newline ...
            '• Practice audio analysis techniques'];
        
        helpFig = uifigure('Name', 'Help - Pure Tone Generator v1.0', 'Position', [300 300 600 500]);
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