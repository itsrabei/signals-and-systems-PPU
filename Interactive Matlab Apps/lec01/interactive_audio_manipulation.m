% INTERACTIVE AUDIO MANIPULATION TOOL
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates time domain signal transformations
% by allowing users to manipulate audio signals in real-time. Users can
% apply various transformations including time shifting, scaling, reversal,
% and noise addition while hearing the results.
% 
% FEATURES:
% - Load and analyze audio files of various formats
% - Real-time audio manipulation with visual feedback
% - Time shifting, scaling, and reversal operations
% - Noise addition with adjustable levels
% - Audio playback of transformed signals
% - Interactive parameter control with sliders
% 
% EDUCATIONAL PURPOSE:
% - Understanding time domain signal transformations
% - Real-time signal processing concepts
% - Audio signal analysis and manipulation
% - Interactive parameter control and feedback
% 
% Notes:
% - Supports WAV, MP3, and FLAC audio formats
% - Converts stereo to mono for processing
% - Real-time parameter updates with visual feedback
% - Audio playback with proper cleanup on close

function interactive_audio_manipulation
    fig = uifigure('Name','Interactive Audio Manipulation', 'Position',[100 100 950 650]);
    fig.CloseRequestFcn = @(src,event) onClose();
    
    [filename, pathname] = uigetfile({'*.wav;*.mp3;*.flac','Audio Files (*.wav,*.mp3,*.flac)'},...
        'Select an audio file to load');
    if isequal(filename,0)
        disp('User cancelled file selection.');
        if isvalid(fig), close(fig); end
        return;
    end
    filepath = fullfile(pathname, filename);
    
    try
        [x, Fs] = audioread(filepath);
    catch ME
        uialert(fig, sprintf('Could not read audio file.\nError: %s', ME.message), 'File Error', 'Icon', 'error');
        if isvalid(fig), close(fig); end
        return;
    end
    
    x = mean(x, 2);
    t_x = (0:length(x)-1)/Fs;
    
    mainGrid = uigridlayout(fig, [2 1]);
    mainGrid.RowHeight = {'fit', '1x'};
    
    controlPanel = uipanel(mainGrid, 'Title', 'Playback Controls', 'FontSize', 14);
    controlPanel.Layout.Row = 1;
    controlsGrid = uigridlayout(controlPanel, [3 6]);
    controlsGrid.ColumnWidth = {'1x', '1.5x', '1.5x', '1.5x', 'fit', 'fit'};
    controlsGrid.RowHeight = {'fit', 'fit', 'fit'};
    controlsGrid.Padding = [10 10 10 10];
    controlsGrid.ColumnSpacing = 15;
    
    labelMode = uilabel(controlsGrid, 'Text', 'Mode', 'HorizontalAlignment', 'center', 'FontWeight','bold');
    popupPlayMode = uidropdown(controlsGrid, 'Items', {'Original','Time Shifted','Time Scaled','Time Reversed','Noisy'}, ...
        'Value', 'Original', 'ValueChangedFcn', @(src,event) updateAudio());
    labelMode.Layout.Row = 1; labelMode.Layout.Column = 1;
    popupPlayMode.Layout.Row = 2; popupPlayMode.Layout.Column = 1;
    
    labelDelayTitle = uilabel(controlsGrid, 'Text', 'Time Shift (s)', 'HorizontalAlignment', 'center', 'FontWeight','bold');
    labelDelayVal = uilabel(controlsGrid, 'Text', 'Delay: 0.00 s', 'HorizontalAlignment', 'center');
    sliderDelay = uislider(controlsGrid, 'Limits', [0 2], 'Value', 0.0, ...
        'ValueChangingFcn', @(src,event) updateLabel(labelDelayVal, 'Delay: %.2f s', event.Value), ...
        'ValueChangedFcn', @(src,event) updateAudio());
    labelDelayTitle.Layout.Row = 1;  labelDelayTitle.Layout.Column = 2;
    sliderDelay.Layout.Row = 2;      sliderDelay.Layout.Column = 2;
    labelDelayVal.Layout.Row = 3;    labelDelayVal.Layout.Column = 2;
    
    labelScaleTitle = uilabel(controlsGrid, 'Text', 'Time Scale (x)', 'HorizontalAlignment', 'center', 'FontWeight','bold');
    labelScaleVal = uilabel(controlsGrid, 'Text', 'Scale: 1.00', 'HorizontalAlignment', 'center');
    sliderScale = uislider(controlsGrid, 'Limits', [0.25 4], 'Value', 1.0, ...
        'ValueChangingFcn', @(src,event) updateLabel(labelScaleVal, 'Scale: %.2f', event.Value), ...
        'ValueChangedFcn', @(src,event) updateAudio());
    labelScaleTitle.Layout.Row = 1;  labelScaleTitle.Layout.Column = 3;
    sliderScale.Layout.Row = 2;      sliderScale.Layout.Column = 3;
    labelScaleVal.Layout.Row = 3;    labelScaleVal.Layout.Column = 3;
    
    labelNoiseTitle = uilabel(controlsGrid, 'Text', 'Noise Level', 'HorizontalAlignment', 'center', 'FontWeight','bold');
    labelNoiseVal = uilabel(controlsGrid, 'Text', 'Noise: 0.000', 'HorizontalAlignment', 'center');
    sliderNoise = uislider(controlsGrid, 'Limits', [0 0.2], 'Value', 0.0, ...
        'ValueChangingFcn', @(src,event) updateLabel(labelNoiseVal, 'Noise: %.3f', event.Value), ...
        'ValueChangedFcn', @(src,event) updateAudio());
    labelNoiseTitle.Layout.Row = 1;  labelNoiseTitle.Layout.Column = 4;
    sliderNoise.Layout.Row = 2;      sliderNoise.Layout.Column = 4;
    labelNoiseVal.Layout.Row = 3;    labelNoiseVal.Layout.Column = 4;
    
    playButton = uibutton(controlsGrid, 'Text', '▶ Play', 'FontSize', 14, 'ButtonPushedFcn', @playSound);
    stopButton = uibutton(controlsGrid, 'Text', '■ Stop', 'FontSize', 14, 'ButtonPushedFcn', @stopSound);
    playButton.Layout.Row = 2; playButton.Layout.Column = 5;
    stopButton.Layout.Row = 2; stopButton.Layout.Column = 6;
    stopButton.Enable = 'off';
    
    ax = uiaxes(mainGrid);
    ax.Layout.Row = 2;
    hPlot = plot(ax, t_x, x);
    title(ax, sprintf('Audio Signal - %s (Original)', filename), 'Interpreter', 'none');
    xlabel(ax, 'Time (s)'); ylabel(ax, 'Amplitude'); grid(ax, 'on');
    y_max = max(abs(x)) * 1.1;
    if y_max == 0, y_max = 1; end; ylim(ax, [-y_max, y_max]);
    
    player = [];
    manipulated_signal = x;
    
    try
        updateAudio();
    catch ME
        warning('Initial updateAudio failed: %s', ME.message);
    end
    
    function updateAudio()
        play_mode = popupPlayMode.Value;
        manageUIState(play_mode);
        
        delay_sec = sliderDelay.Value;
        scale_factor = sliderScale.Value;
        noise_level = sliderNoise.Value;
        
        local_manipulated_signal = [];
        time_vec = t_x;
        title_str = play_mode;
        
        switch play_mode
            case 'Original'
                local_manipulated_signal = x;
            case 'Time Shifted'
                shift_samples = round(delay_sec * Fs);
                if shift_samples >= length(x)
                    local_manipulated_signal = zeros(size(x));
                else
                    local_manipulated_signal = [zeros(shift_samples, 1); x(1:end-shift_samples)];
                end
                title_str = sprintf('Time Shifted by %.2f s', delay_sec);
            case 'Time Scaled'
                [p, q] = rat(1/scale_factor);
                local_manipulated_signal = resample(x, p, q);
                time_vec = (0:length(local_manipulated_signal)-1)/Fs;
                title_str = sprintf('Time Scaled by %.2fx', scale_factor);
            case 'Time Reversed'
                local_manipulated_signal = flipud(x);
            case 'Noisy'
                local_manipulated_signal = x + noise_level*randn(size(x));
                title_str = sprintf('Noisy (Level %.3f)', noise_level);
        end
        manipulated_signal = local_manipulated_signal;
        
        hPlot.XData = time_vec;
        hPlot.YData = manipulated_signal;
        title(ax, sprintf('Audio Signal - %s (%s)', filename, title_str), 'Interpreter', 'none');
        if ~isempty(time_vec) && max(time_vec) > 0
            xlim(ax, [0, max(time_vec)]);
        else
            xlim(ax, [0, max(t_x)]);
        end
        
        new_y_max = max(abs(manipulated_signal)) * 1.1;
        if new_y_max == 0, new_y_max = 1; end
        ylim(ax, [-new_y_max, new_y_max]);
        
        drawnow;
        
        if isvalid(playButton)
            playButton.Text = '▶ Play';
            playButton.Enable = 'on';
            stopButton.Enable = 'off';
        end
    end
    
    function updateLabel(labelHandle, formatSpec, value)
        if isvalid(labelHandle)
            labelHandle.Text = sprintf(formatSpec, value);
            drawnow('limitrate');
        end
    end
    
    function playSound(~,~)
        stopSound(); 
        player = audioplayer(manipulated_signal, Fs);
        player.StopFcn = @(~,~) onPlaybackStopped();
        play(player);
        if isvalid(playButton)
            playButton.Enable = 'off';
            playButton.Text = 'Playing...';
        end
        if isvalid(stopButton)
            stopButton.Enable = 'on';
        end
    end
    
    function stopSound(~,~)
        if ~isempty(player) && isplaying(player)
            stop(player);
        end
        onPlaybackStopped();
    end
    
    function onPlaybackStopped()
        if isvalid(playButton) && isvalid(stopButton)
            playButton.Enable = 'on';
            playButton.Text = '▶ Play';
            stopButton.Enable = 'off';
        end
    end
    
    function manageUIState(mode)
        isShift = strcmp(mode, 'Time Shifted');
        isScale = strcmp(mode, 'Time Scaled');
        isNoise = strcmp(mode, 'Noisy');
        
        sliderDelay.Enable = isShift;
        sliderScale.Enable = isScale;
        sliderNoise.Enable = isNoise;
    end
    
    function onClose()
        if ~isempty(player) && isplaying(player)
            stop(player);
        end
        delete(fig);
    end
end