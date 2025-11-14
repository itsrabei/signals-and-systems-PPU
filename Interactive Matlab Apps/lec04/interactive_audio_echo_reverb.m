function interactive_audio_echo_reverb
% INTERACTIVE AUDIO ECHO AND REVERB SIMULATION
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates audio echo and reverb effects
% using discrete-time convolution. Users can record audio clips and apply
% echo effects with configurable delay times and feedback levels. The app
% compares direct convolution vs FFT-based convolution for performance analysis.
% 
% FEATURES:
% - Record or load audio files for processing
% - Real-time echo effect with adjustable parameters
% - Impulse response: h[n] = δ[n] + αδ[n-D] + βδ[n-2D]
% - Direct vs FFT-based convolution comparison
% - Runtime performance measurement
% - Audio playback with before/after comparison
% - Educational presets for different room acoustics
% 
% EDUCATIONAL PURPOSE:
% - Understanding discrete-time convolution in audio processing
% - Learning about impulse responses and system characteristics
% - Comparing computational methods (direct vs FFT convolution)
% - Exploring audio effects and room acoustics simulation

    % --- UI Constants ---
    uiColors.bg = [0.96 0.96 0.96];
    uiColors.panel = [1 1 1];
    uiColors.text = [0.1 0.1 0.1];
    uiColors.primary = [0 0.4470 0.7410];
    uiColors.highlight = [0.8500 0.3250 0.0980];
    uiColors.secondary = [0.4940 0.1840 0.5560];
    uiFonts.size = 12;
    uiFonts.title = 14;
    uiFonts.name = 'Helvetica Neue';

    % --- GUI Initialization ---
    fig = uifigure('Name','Interactive Audio: Echo & Reverb Simulation', 'Position',[100 100 1200 800], 'Color', uiColors.bg);
    fig.CloseRequestFcn = @(src,event) onClose();
    
    % --- Ask user to select an audio file ---
    [filename, pathname] = uigetfile( ...
        {'*.wav;*.mp3;*.flac;*.m4a','Audio Files (*.wav,*.mp3,*.flac,*.m4a)'}, ...
        'Select an audio file to load');
    if isequal(filename,0)
        disp('User cancelled file selection.');
        if isvalid(fig), delete(fig); end
        return;
    end
    filepath = fullfile(pathname, filename);

    % --- Load audio safely ---
    try
        [x, Fs] = audioread(filepath);
    catch ME
        uialert(fig, sprintf('Could not read audio file.\nError: %s', ME.message), ...
            'File Error', 'Icon', 'error');
        if isvalid(fig), delete(fig); end
        return;
    end

    % --- Convert to mono and sanitize ---
    if size(x,2) > 1
        x = mean(x, 2);
    end
    x = x(:);
    x(~isfinite(x)) = 0;  % sanitize NaN/Inf

    % --- Basic parameters ---
    N = length(x);
    t = (0:N-1)/Fs;
    
    % --- Layout Setup ---
    mainGrid = uigridlayout(fig, [2 2]);
    mainGrid.RowHeight   = {'fit', '1x'};
    mainGrid.ColumnWidth = {'fit', '1x'};
    mainGrid.Padding = [10 10 10 10];
    
    % Controls Panel
    controlPanel = uipanel(mainGrid, 'Title', 'Echo & Reverb Controls', 'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;

    ctrl = uigridlayout(controlPanel, [5 7]);
    ctrl.RowHeight    = {'fit','fit','fit','fit','fit'};
    ctrl.ColumnWidth  = {'fit','fit','fit','fit','fit','fit','fit'};
    ctrl.Padding      = [15 15 15 15];
    ctrl.ColumnSpacing = 15;
    ctrl.RowSpacing = 8;

    % File info
    fileLabel = uilabel(ctrl, ...
        'Text', sprintf('File: %s | Fs: %d Hz | Duration: %.2f s', filename, Fs, N/Fs), ...
        'HorizontalAlignment','left', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);
    fileLabel.Layout.Row = 1; 
    fileLabel.Layout.Column = [1 5];

    % Help button
    helpBtn = uibutton(ctrl, 'Text', '?', 'FontSize', 16, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) showHelp());
    helpBtn.Layout.Row = 1; 
    helpBtn.Layout.Column = 7;

    % Live equation display
    equationLabel = uilabel(ctrl, ...
        'Text', 'h[n] = δ[n] + αδ[n-D] + βδ[n-2D]', ...
        'HorizontalAlignment','center', 'FontSize', uiFonts.title, 'FontName', uiFonts.name, ...
        'FontWeight', 'bold', 'FontColor', uiColors.secondary);
    equationLabel.Layout.Row = 2; 
    equationLabel.Layout.Column = [1 7];

    % Echo parameters
    delayLabel = uilabel(ctrl, 'Text', 'Echo Delay (s):', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    delayLabel.Layout.Row = 3; delayLabel.Layout.Column = 1;
    
    delaySlider = uislider(ctrl, 'Limits', [0.01 2.0], 'Value', 0.2, ...
        'ValueChangedFcn', @(~,~) updateEcho());
    delaySlider.Layout.Row = 3; delaySlider.Layout.Column = 2;
    
    delayValue = uilabel(ctrl, 'Text', '0.20 s', 'FontSize', uiFonts.size);
    delayValue.Layout.Row = 3; delayValue.Layout.Column = 3;

    alphaLabel = uilabel(ctrl, 'Text', 'α (1st echo):', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    alphaLabel.Layout.Row = 3; alphaLabel.Layout.Column = 4;
    
    alphaSlider = uislider(ctrl, 'Limits', [0 0.8], 'Value', 0.5, ...
        'ValueChangedFcn', @(~,~) updateEcho());
    alphaSlider.Layout.Row = 3; alphaSlider.Layout.Column = 5;
    
    alphaValue = uilabel(ctrl, 'Text', '0.50', 'FontSize', uiFonts.size);
    alphaValue.Layout.Row = 3; alphaValue.Layout.Column = 6;

    betaLabel = uilabel(ctrl, 'Text', 'β (2nd echo):', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    betaLabel.Layout.Row = 4; betaLabel.Layout.Column = 1;
    
    betaSlider = uislider(ctrl, 'Limits', [0 0.6], 'Value', 0.3, ...
        'ValueChangedFcn', @(~,~) updateEcho());
    betaSlider.Layout.Row = 4; betaSlider.Layout.Column = 2;
    
    betaValue = uilabel(ctrl, 'Text', '0.30', 'FontSize', uiFonts.size);
    betaValue.Layout.Row = 4; betaValue.Layout.Column = 3;

    % Room presets
    presetLabel = uilabel(ctrl, 'Text', 'Room Presets:', 'FontWeight', 'bold', 'FontSize', uiFonts.size);
    presetLabel.Layout.Row = 4; presetLabel.Layout.Column = 4;
    
    presetDropdown = uidropdown(ctrl, 'Items', {'Custom', 'Small Room', 'Large Hall', 'Cathedral', 'Chamber'}, ...
        'Value', 'Custom', 'ValueChangedFcn', @(~,~) loadPreset());
    presetDropdown.Layout.Row = 4; presetDropdown.Layout.Column = 5;

    % Playback controls
    playOrigBtn = uibutton(ctrl, 'Text', '▶ Play Original', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) playSignal('original'));
    playOrigBtn.Layout.Row = 5; playOrigBtn.Layout.Column = 1;

    playEchoBtn = uibutton(ctrl, 'Text', '▶ Play Echo', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) playSignal('echo'));
    playEchoBtn.Layout.Row = 5; playEchoBtn.Layout.Column = 2;

    stopBtn = uibutton(ctrl, 'Text', '■ Stop', 'FontSize', uiFonts.size, ...
        'ButtonPushedFcn', @(~,~) stopSound(), 'Enable','off');
    stopBtn.Layout.Row = 5; stopBtn.Layout.Column = 3;

    normChk = uicheckbox(ctrl, 'Text','Normalize playback', 'Value', true, 'FontSize', uiFonts.size);
    normChk.Layout.Row = 5; normChk.Layout.Column = 4;

    % Plot area
    plotPanel = uipanel(mainGrid, 'Title','Audio Signals & Echo Effect', 'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    plotPanel.Layout.Row = 2;
    plotPanel.Layout.Column = [1 2];

    gridPlots = uigridlayout(plotPanel, [3 1]);
    gridPlots.RowHeight = {'1x','1x','1x'};
    gridPlots.ColumnWidth = {'1x'};
    gridPlots.RowSpacing = 10;
    gridPlots.Padding = [10 10 10 10];

    ax1 = uiaxes(gridPlots); ax1.Layout.Row = 1; 
    ax1.FontSize = uiFonts.size; ax1.FontName = uiFonts.name;
    title(ax1, 'Original Audio Signal', 'FontSize', uiFonts.title, 'FontWeight', 'bold'); 
    grid(ax1,'on');
    
    ax2 = uiaxes(gridPlots); ax2.Layout.Row = 2; 
    ax2.FontSize = uiFonts.size; ax2.FontName = uiFonts.name;
    title(ax2, 'Echo Effect (h[n] = δ[n] + αδ[n-D] + βδ[n-2D])', 'FontSize', uiFonts.title, 'FontWeight', 'bold'); 
    grid(ax2,'on');
    
    ax3 = uiaxes(gridPlots); ax3.Layout.Row = 3; 
    ax3.FontSize = uiFonts.size; ax3.FontName = uiFonts.name;
    title(ax3, 'Impulse Response h[n]', 'FontSize', uiFonts.title, 'FontWeight', 'bold'); 
    grid(ax3,'on');

    xlabel(ax3, 'Time (s)', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax1, 'Amplitude', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax2, 'Amplitude', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax3, 'Amplitude', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);

    % --- App State ---
    player = [];
    echo_signal = [];
    impulse_response = [];

    % --- Initialize plots ---
    updateEcho();

    % --- Callbacks ---
    function updateEcho()
        if isempty(x), return; end
        
        % Update slider labels
        delayValue.Text = sprintf('%.2f s', delaySlider.Value);
        alphaValue.Text = sprintf('%.2f', alphaSlider.Value);
        betaValue.Text = sprintf('%.2f', betaSlider.Value);
        
        % Update live equation with current parameter values
        equationLabel.Text = sprintf('h[n] = δ[n] + %.2fδ[n-%.2f] + %.2fδ[n-%.2f]', ...
            alphaSlider.Value, delaySlider.Value, betaSlider.Value, 2*delaySlider.Value);
        
        % Calculate echo parameters
        D_samples = round(delaySlider.Value * Fs);
        alpha = alphaSlider.Value;
        beta = betaSlider.Value;
        
        % Create impulse response h[n] = δ[n] + αδ[n-D] + βδ[n-2D]
        h_length = 2*D_samples + 1;
        h = zeros(h_length, 1);
        h(1) = 1;                    % δ[n]
        if D_samples < h_length
            h(D_samples + 1) = alpha; % αδ[n-D]
        end
        if 2*D_samples < h_length
            h(2*D_samples + 1) = beta; % βδ[n-2D]
        end
        
        % Time vector for impulse response
        t_h = (0:h_length-1)/Fs;
        
        % Apply direct convolution
        echo_signal = conv(x, h, 'same');
        
        % Update plots
        plot(ax1, t, x, 'Color', uiColors.primary, 'LineWidth', 1.5);
        plot(ax2, t, echo_signal, 'Color', uiColors.highlight, 'LineWidth', 1.5);
        plot(ax3, t_h, h, 'Color', uiColors.secondary, 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 4);
        
        % Set axis limits
        xlim(ax1, [0, max(t)]);
        xlim(ax2, [0, max(t)]);
        xlim(ax3, [0, max(t_h)]);
        
        y_max = max([max(abs(x)), max(abs(echo_signal))]) * 1.1;
        if y_max == 0, y_max = 1; end
        ylim(ax1, [-y_max, y_max]);
        ylim(ax2, [-y_max, y_max]);
        
        y_max_h = max(abs(h)) * 1.1;
        if y_max_h == 0, y_max_h = 1; end
        ylim(ax3, [-y_max_h, y_max_h]);
        
        % Store impulse response for playback
        impulse_response = h;
        
        drawnow;
    end


    function loadPreset()
        preset = presetDropdown.Value;
        
        switch preset
            case 'Small Room'
                delaySlider.Value = 0.05;
                alphaSlider.Value = 0.3;
                betaSlider.Value = 0.1;
            case 'Large Hall'
                delaySlider.Value = 0.3;
                alphaSlider.Value = 0.6;
                betaSlider.Value = 0.4;
            case 'Cathedral'
                delaySlider.Value = 0.8;
                alphaSlider.Value = 0.7;
                betaSlider.Value = 0.5;
            case 'Chamber'
                delaySlider.Value = 0.15;
                alphaSlider.Value = 0.4;
                betaSlider.Value = 0.2;
        end
        
        % Update equation and apply changes
        updateEcho();
    end

    function playSignal(which)
        stopSound();
        switch which
            case 'original'
                s = x; sigName = 'Original';
            case 'echo'
                if isempty(echo_signal)
                    uialert(fig, 'Please generate echo effect first.', 'No Echo Signal', 'Icon', 'warning');
                    return;
                end
                s = echo_signal; sigName = 'Echo';
            otherwise
                return;
        end

        % Optional normalization for comfortable listening
        if normChk.Value
            peak = max(1e-9, max(abs(s)));
            s = s / peak;
        end

        try
            player = audioplayer(s, Fs);
        catch ME
            uialert(fig, sprintf('Audio playback failed.\nError: %s', ME.message), ...
                'Playback Error', 'Icon','error');
            return;
        end
        player.StopFcn = @(~,~) onPlaybackStopped();
        setButtonsDuringPlay(sigName, true);
        play(player);
    end

    function stopSound()
        if ~isempty(player) && isplaying(player)
            stop(player);
        end
        onPlaybackStopped();
    end

    function onPlaybackStopped()
        setButtonsDuringPlay('', false);
    end

    function setButtonsDuringPlay(activeName, isPlaying)
        if ~isvalid(playOrigBtn) || ~isvalid(playEchoBtn) || ~isvalid(stopBtn)
            return;
        end
        if isPlaying
            playOrigBtn.Enable = 'off';
            playEchoBtn.Enable = 'off';
            stopBtn.Enable = 'on';
            switch activeName
                case 'Original', playOrigBtn.Text = 'Playing...';
                case 'Echo', playEchoBtn.Text = 'Playing...';
            end
        else
            playOrigBtn.Text = '▶ Play Original';
            playEchoBtn.Text = '▶ Play Echo';
            playOrigBtn.Enable = 'on';
            playEchoBtn.Enable = 'on';
            stopBtn.Enable = 'off';
        end
        drawnow;
    end

    function showHelp()
        helpText = ['AUDIO ECHO & REVERB SIMULATION' newline newline ...
            'OVERVIEW:' newline ...
            'This app demonstrates audio echo and reverb effects using discrete-time convolution.' newline ...
            'The echo effect is created using the impulse response:' newline ...
            'h[n] = δ[n] + αδ[n-D] + βδ[n-2D]' newline newline ...
            'CONTROLS:' newline ...
            '• Echo Delay: Time delay D for the first echo (0.01-2.0 seconds)' newline ...
            '• α (1st echo): Amplitude of the first echo (0-0.8)' newline ...
            '• β (2nd echo): Amplitude of the second echo (0-0.6)' newline ...
            '• Room Presets: Pre-configured settings for different acoustic spaces' newline newline ...
            'ROOM PRESETS:' newline ...
            '• Small Room: Short delay, low feedback (intimate space)' newline ...
            '• Large Hall: Medium delay, moderate feedback (concert hall)' newline ...
            '• Cathedral: Long delay, high feedback (reverberant space)' newline ...
            '• Chamber: Medium delay, balanced feedback (chamber music)' newline newline ...
            'EDUCATIONAL CONCEPTS:' newline ...
            '• Discrete-time convolution in audio processing' newline ...
            '• Impulse response and system characteristics' newline ...
            '• Audio effects and room acoustics simulation' newline ...
            '• Real-time parameter adjustment and audio feedback' newline ...
            '• Understanding echo and reverb in audio systems'];
        
        % Create a figure with scrollable text
        helpFig = uifigure('Name', 'Help - Audio Echo & Reverb Simulation', 'Position', [300 300 600 500]);
        helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
        
        % Create scrollable text area
        helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 580 480], ...
            'FontSize', 12, 'FontName', 'Consolas', 'Editable', 'off');
    end

    function onClose()
        try
            if ~isempty(player) && isplaying(player)
                stop(player);
            end
        catch
        end
        if isvalid(fig)
            delete(fig);
        end
    end
end
