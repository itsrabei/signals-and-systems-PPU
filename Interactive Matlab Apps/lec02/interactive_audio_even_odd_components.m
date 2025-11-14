function interactive_audio_even_odd_components
% INTERACTIVE AUDIO EVEN/ODD COMPONENTS ANALYZER
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates signal decomposition concepts
% by analyzing audio signals into their even and odd components. Users
% can load audio files and explore the mathematical properties of
% signal symmetry.
% 
% FEATURES:
% - Load and analyze audio files of various formats
% - Decompose signals into even and odd components
% - Visualize original, even, odd, and reconstructed signals
% - Audio playback of individual components
% - Mathematical verification of decomposition properties
% 
% EDUCATIONAL PURPOSE:
% - Understanding even and odd signal properties
% - Signal decomposition and reconstruction
% - Orthogonality concepts in signal processing
% - Energy conservation in signal analysis
    %
    % Notes:
    % - Even/Odd decomposition about the midpoint uses x_rev = flipud(x)
    %   and xe = 0.5*(x + x_rev), xo = 0.5*(x - x_rev).
    % - Time axis is centered at 0 for visual symmetry.
    % - Subtitle is wrapped in try/catch for older MATLAB versions.

    % --- UI Constants ---
    uiColors.bg = [0.96 0.96 0.96];
    uiColors.panel = [1 1 1];
    uiColors.text = [0.1 0.1 0.1];
    uiColors.primary = [0 0.4470 0.7410];
    uiColors.highlight = [0.8500 0.3250 0.0980];
    uiFonts.size = 12;
    uiFonts.title = 14;
    uiFonts.name = 'Helvetica Neue';

    % --- GUI Initialization ---
    fig = uifigure('Name','Interactive Audio: Even/Odd Components', 'Position',[100 100 1060 760], 'Color', uiColors.bg);
    fig.CloseRequestFcn = @(src,event) onClose();
    
    % Add help button
    helpBtn = uibutton(fig, 'Text', '?', 'Position', [10 10 30 30], ...
        'FontSize', 16, 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) showHelp());
    
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
        
        % Validate audio data
        if isempty(x) || length(x) < 2
            uialert(fig, 'Audio file is too short or empty.', 'File Error', 'Icon', 'error');
            if isvalid(fig), delete(fig); end
            return;
        end
        
        if Fs <= 0
            uialert(fig, 'Invalid sampling rate in audio file.', 'File Error', 'Icon', 'error');
            if isvalid(fig), delete(fig); end
            return;
        end
        
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
    x(~isfinite(x)) = 0;  % sanitize NaN/Inf just in case

    % --- Basic sizes and time axes ---
    N = length(x);
    tc = ((0:N-1) - (N-1)/2) / Fs;           % centered at 0 (midpoint symmetry)
    
    % --- Even and Odd components w.r.t. clip midpoint ---
    x_rev  = flipud(x);                      % reversal around midpoint
    x_even = 0.5*(x + x_rev);
    x_odd  = 0.5*(x - x_rev);

    % --- Layout Setup ---
    mainGrid = uigridlayout(fig, [2 1]);
    mainGrid.RowHeight   = {'fit', '1x'};
    mainGrid.ColumnWidth = {'1x'};
    
    % Controls Panel
    controlPanel = uipanel(mainGrid, 'Title', 'Controls', 'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    controlPanel.Layout.Row = 1;

    ctrl = uigridlayout(controlPanel, [3 7]);
    ctrl.RowHeight    = {'fit','fit','fit'};
    ctrl.ColumnWidth  = {'1x','fit','fit','fit','fit','fit','fit'};
    ctrl.Padding      = [10 10 10 10];
    ctrl.ColumnSpacing = 12;

    % File label with truncation for long filenames
    displayName = filename;
    if length(displayName) > 30
        displayName = [displayName(1:27) '...'];
    end
    fileLabel = uilabel(ctrl, ...
        'Text', sprintf('File: %s | Fs: %d Hz | Samples: %d', displayName, Fs, N), ...
        'HorizontalAlignment','left', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);
    fileLabel.Layout.Row = 1; 
    fileLabel.Layout.Column = [1 7];

    % Diagnostics label (orthogonality/energy/reconstruction)
    diagLabel = uilabel(ctrl, 'Text', '', 'HorizontalAlignment','left', 'FontName','Consolas', 'FontSize', uiFonts.size);
    diagLabel.Layout.Row = 2; 
    diagLabel.Layout.Column = [1 7];

    % Play buttons and controls
    playOrigBtn = uibutton(ctrl, 'Text', '▶ Play Original', 'FontSize', uiFonts.size, 'FontName', uiFonts.name, ...
        'ButtonPushedFcn', @(~,~) playSignal('original'));
    playEvenBtn = uibutton(ctrl, 'Text', '▶ Play Even', 'FontSize', uiFonts.size, 'FontName', uiFonts.name, ...
        'ButtonPushedFcn', @(~,~) playSignal('even'));
    playOddBtn  = uibutton(ctrl, 'Text', '▶ Play Odd', 'FontSize', uiFonts.size, 'FontName', uiFonts.name, ...
        'ButtonPushedFcn', @(~,~) playSignal('odd'));
    stopBtn     = uibutton(ctrl, 'Text', '■ Stop', 'FontSize', uiFonts.size, 'FontName', uiFonts.name, ...
        'ButtonPushedFcn', @(~,~) stopSound(), 'Enable','off');
    normChk     = uicheckbox(ctrl, 'Text','Normalize playback', 'Value', true, 'FontSize', uiFonts.size, 'FontName', uiFonts.name);
    
    % Progress indicator
    progressLabel = uilabel(ctrl, 'Text', '', 'HorizontalAlignment','center', 'FontSize', uiFonts.size, 'FontName', uiFonts.name, 'FontWeight', 'bold');
    progressLabel.Layout.Row = 3; progressLabel.Layout.Column = 7;

    playOrigBtn.Layout.Row = 3; playOrigBtn.Layout.Column = 2;
    playEvenBtn.Layout.Row = 3; playEvenBtn.Layout.Column = 3;
    playOddBtn.Layout.Row  = 3; playOddBtn.Layout.Column  = 4;
    stopBtn.Layout.Row     = 3; stopBtn.Layout.Column     = 5;
    normChk.Layout.Row     = 3; normChk.Layout.Column     = 6;

    % Plot area with three synchronized axes
    plotPanel = uipanel(mainGrid, 'Title','Signals (Centered at 0 s)', 'FontSize', uiFonts.title, 'FontWeight', 'bold', 'BackgroundColor', uiColors.panel);
    plotPanel.Layout.Row = 2;

    gridPlots = uigridlayout(plotPanel, [3 1]);
    gridPlots.RowHeight = {'1x','1x','1x'};
    gridPlots.ColumnWidth = {'1x'};
    gridPlots.RowSpacing = 10;
    gridPlots.Padding = [10 10 10 10];

    ax1 = uiaxes(gridPlots); ax1.Layout.Row = 1; 
    ax1.FontSize = uiFonts.size; ax1.FontName = uiFonts.name;
    title(ax1, 'Original', 'FontSize', uiFonts.title, 'FontName', uiFonts.name, 'FontWeight', 'bold'); 
    grid(ax1,'on');
    
    ax2 = uiaxes(gridPlots); ax2.Layout.Row = 2; 
    ax2.FontSize = uiFonts.size; ax2.FontName = uiFonts.name;
    title(ax2, 'Even Component', 'FontSize', uiFonts.title, 'FontName', uiFonts.name, 'FontWeight', 'bold'); 
    grid(ax2,'on');
    
    ax3 = uiaxes(gridPlots); ax3.Layout.Row = 3; 
    ax3.FontSize = uiFonts.size; ax3.FontName = uiFonts.name;
    title(ax3, 'Odd Component', 'FontSize', uiFonts.title, 'FontName', uiFonts.name, 'FontWeight', 'bold'); 
    grid(ax3,'on');

    xlabel(ax3, 'Time centered at 0 (s)', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax1, 'Amp', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax2, 'Amp', 'FontSize', uiFonts.size, 'FontName', uiFonts.name); 
    ylabel(ax3, 'Amp', 'FontSize', uiFonts.size, 'FontName', uiFonts.name);

    % Plot signals on centered time axis
    plot(ax1, tc, x, 'Color', uiColors.primary, 'LineWidth', 1.5);
    plot(ax2, tc, x_even, 'Color', uiColors.highlight, 'LineWidth', 1.5);
    plot(ax3, tc, x_odd, 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);

    % Reference symmetry line at 0 s
    xline(ax1, 0, ':k'); xline(ax2, 0, ':k'); xline(ax3, 0, ':k');

    % Link x-axes for synchronized zoom/pan and set x-limits symmetrically
    linkaxes([ax1, ax2, ax3], 'x');
    tmax = max(abs(tc));
    if ~isfinite(tmax) || tmax <= 0, tmax = 1; end
    xlim(ax1, [-tmax, tmax]);
    xlim(ax2, [-tmax, tmax]);
    xlim(ax3, [-tmax, tmax]);

    % Consistent y-limits across all plots
    y_max = max([max(abs(x)), max(abs(x_even)), max(abs(x_odd))]) * 1.1;
    if ~isfinite(y_max) || y_max <= 0, y_max = 1; end
    ylim(ax1, [-y_max, y_max]);
    ylim(ax2, [-y_max, y_max]);
    ylim(ax3, [-y_max, y_max]);

    % Display reconstruction and diagnostics
    reconErr = norm(x - (x_even + x_odd), 2);
    dotEO = sum(x_even .* x_odd);
    E  = sum(x.^2);
    Ee = sum(x_even.^2);
    Eo = sum(x_odd.^2);
    relErr = reconErr / max(1e-10, sqrt(E));  % Prevent division by zero

    diagText = sprintf('dot(xe,xo)=%.3e   |   E=%.3e   Ee+Eo=%.3e   |   ||x-(xe+xo)||_2=%.3e   relErr=%.3e', ...
                       dotEO, E, Ee+Eo, reconErr, relErr);
    diagLabel.Text = diagText;

    % Subtitle with fallback for older versions
    try
        subtitle(ax1, sprintf('Reconstruction: ||x - (xe + xo)||_2 = %.3e', reconErr), 'Interpreter','none');
    catch
        title(ax1, sprintf('Original | Recon ||x - (xe + xo)||_2 = %.3e', reconErr), 'Interpreter','none');
    end

    % --- App State ---
    player = [];

    % --- Callbacks ---
    function playSignal(which)
        stopSound();
        switch which
            case 'original'
                s = x; sigName = 'Original';
            case 'even'
                s = x_even; sigName = 'Even';
            case 'odd'
                s = x_odd; sigName = 'Odd';
            otherwise
                return;
        end

        % Optional normalization for comfortable listening
        if normChk.Value
            peak = max(1e-6, max(abs(s)));  % Increased minimum to prevent excessive amplification
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
        progressLabel.Text = sprintf('Playing %s...', sigName);
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
        progressLabel.Text = 'Ready';
    end

    function setButtonsDuringPlay(activeName, isPlaying)
        if ~isvalid(playOrigBtn) || ~isvalid(playEvenBtn) || ~isvalid(playOddBtn) || ~isvalid(stopBtn)
            return;
        end
        if isPlaying
            playOrigBtn.Enable = 'off';
            playEvenBtn.Enable = 'off';
            playOddBtn.Enable  = 'off';
            stopBtn.Enable     = 'on';
            % Indicate which one is active
            switch activeName
                case 'Original', playOrigBtn.Text = 'Playing...';
                case 'Even',     playEvenBtn.Text = 'Playing...';
                case 'Odd',      playOddBtn.Text  = 'Playing...';
            end
        else
            playOrigBtn.Text = '▶ Play Original';
            playEvenBtn.Text = '▶ Play Even';
            playOddBtn.Text  = '▶ Play Odd';
            playOrigBtn.Enable = 'on';
            playEvenBtn.Enable = 'on';
            playOddBtn.Enable  = 'on';
            stopBtn.Enable     = 'off';
        end
        drawnow;
    end

    function showHelp()
        helpText = ['HOW TO USE THIS APP:' newline newline ...
            '1. LOAD AUDIO FILE:' newline ...
            '   • Click "Load Audio" to select a file' newline ...
            '   • Supported formats: WAV, MP3, FLAC, M4A' newline ...
            '   • The app will automatically analyze the signal' newline newline ...
            '2. SIGNAL COMPONENTS:' newline ...
            '   • Original: The loaded audio signal' newline ...
            '   • Even: xe[n] = 0.5(x[n] + x[-n])' newline ...
            '   • Odd: xo[n] = 0.5(x[n] - x[-n])' newline ...
            '   • Reconstructed: xe[n] + xo[n] (should equal original)' newline newline ...
            '3. AUDIO PLAYBACK:' newline ...
            '   • Click "Play" buttons to hear each component' newline ...
            '   • Use "Normalize" checkbox to adjust volume' newline ...
            '   • Compare the sound of even vs odd components' newline newline ...
            '4. MATHEMATICAL VERIFICATION:' newline ...
            '   • Check orthogonality: even and odd components are orthogonal' newline ...
            '   • Energy conservation: total energy is preserved' newline ...
            '   • Reconstruction accuracy: original = even + odd' newline newline ...
            'KEY CONCEPTS:' newline ...
            '• Even signals: x[n] = x[-n] (symmetric about origin)' newline ...
            '• Odd signals: x[n] = -x[-n] (antisymmetric about origin)' newline ...
            '• Any signal can be decomposed into even and odd parts' newline ...
            '• Even and odd components are orthogonal to each other'];
        
        % Create a figure with scrollable text
        helpFig = uifigure('Name', 'Help - Audio Even/Odd Components Analyzer', 'Position', [300 300 500 400]);
        helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
        
        % Create scrollable text area
        helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 480 380], ...
            'FontSize', 12, 'FontName', 'Consolas', 'Editable', 'off');
        
        % Add scrollbar
        helpTextArea.Scrollable = 'on';
    end

    function onClose()
        try
            if ~isempty(player) && isvalid(player)
                if isplaying(player)
                    stop(player);
                end
                delete(player);
            end
        catch
            % Ignore errors during cleanup
        end
        try
            if isvalid(fig)
                delete(fig);
            end
        catch
            % Ignore errors during cleanup
        end
    end
end
