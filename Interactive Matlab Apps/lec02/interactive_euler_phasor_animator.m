function interactive_euler_phasor_animator
% INTERACTIVE EULER PHASOR ANIMATOR
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates complex exponential concepts
% through animated phasor visualization. Users can observe how complex
% exponentials rotate in the complex plane and generate sinusoidal signals.
% 
% FEATURES:
% - Real-time phasor animation in complex plane
% - Adjustable amplitude, frequency, and phase parameters
% - Time domain plots of real and imaginary components
% - Phase angle visualization with radians and π multiples
% - Start/Stop/Reset controls for animation
% 
% EDUCATIONAL PURPOSE:
% - Understanding complex exponentials and Euler's formula
% - Phasor representation of sinusoidal signals
% - Phase relationships in signal processing
% - Visual connection between complex plane and time domain

    % --- App State ---
    state.A       = 1.0;      % Amplitude
    state.omega   = 2*pi;     % Angular Frequency (rad/s), default is 1 Hz
    state.phiRad  = 0.0;      % Phase (radians)
    state.running = false;    % Animation running flag
    state.t0      = tic;      % Time reference for animation start
    state.last_t  = 0;        % Time reference for last plotted point

    % --- UI Constants ---
    Amax = 2.0;
    omegaMax = 5*pi;  % Max omega, e.g., 5*pi rad/s
    phiMax = 2*pi;    % Max phase
    wlen = 5.0;       % Time window to display (s)
    dt   = 0.05;      % Timer period for ~20 FPS (smooth and efficient)

    % --- UI Constants ---
    uiColors.bg = [0.96 0.96 0.96];
    uiColors.panel = [1 1 1];
    uiColors.text = [0.1 0.1 0.1];
    uiColors.primary = [0 0.4470 0.7410];
    uiColors.highlight = [0.8500 0.3250 0.0980];
    uiFonts.size = 12;
    uiFonts.title = 14;
    uiFonts.name = 'Helvetica Neue';

    % --- UI Figure and Layout ---
    fig = uifigure('Name','Interactive Euler Phasor Animator', 'Position',[100 100 1200 700], 'Color', uiColors.bg);
    fig.CloseRequestFcn = @(~,~) onClose();
    
    main = uigridlayout(fig,[3 2]);
    main.RowHeight = {'fit','1x','fit'};
    main.ColumnWidth = {'1x','1x'};
    main.Padding = [15 15 15 15];
    main.RowSpacing = 15;
    main.ColumnSpacing = 15;

    % --- Controls Panel with Explicit Layout ---
    pCtrl = uipanel(main,'Title','Controls','FontSize',uiFonts.title,'FontWeight','bold','BackgroundColor',uiColors.panel);
    pCtrl.Layout.Row = 1; pCtrl.Layout.Column = [1 2];
    ctrl = uigridlayout(pCtrl,[4 5]);
    ctrl.ColumnWidth = {'fit', '1x', 'fit', 'fit', 'fit'};
    ctrl.RowHeight = {'1x','1x','1x','fit'};
    ctrl.Padding = [12 12 12 12];
    ctrl.ColumnSpacing = 12;
    ctrl.RowSpacing = 8;
    
    % Help button
    helpBtn = uibutton(ctrl, 'Text', '?', 'FontSize', 16, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) showHelp());
    helpBtn.Layout.Row = 1; helpBtn.Layout.Column = 5;

    % --- Amplitude Controls (Row 1) ---
    lblA = uilabel(ctrl,'Text','Amplitude A','FontSize',uiFonts.size,'FontName',uiFonts.name,'FontWeight','bold');
    lblA.Layout.Row = 1; lblA.Layout.Column = 1;
    sA = uislider(ctrl,'Limits',[0 Amax],'Value',state.A, 'ValueChangedFcn',@(h,~) onA(h.Value),'FontName',uiFonts.name);
    sA.Layout.Row = 1; sA.Layout.Column = 2;
    eA = uieditfield(ctrl, 'numeric', 'Value', state.A, 'ValueChangedFcn',@(h,~) onA(h.Value),'FontSize',uiFonts.size,'FontName',uiFonts.name);
    eA.Layout.Row = 1; eA.Layout.Column = 3;
    
    % --- Angular Frequency Controls (Row 2) ---
    lblOmega = uilabel(ctrl,'Text','Angular Freq ω (rad/s)','FontSize',uiFonts.size,'FontName',uiFonts.name,'FontWeight','bold');
    lblOmega.Layout.Row = 2; lblOmega.Layout.Column = 1;
    sOmega = uislider(ctrl,'Limits',[0 omegaMax],'Value',state.omega, 'ValueChangedFcn',@(h,~) onOmega(h.Value),'FontName',uiFonts.name);
    sOmega.Layout.Row = 2; sOmega.Layout.Column = 2;
    eOmega = uieditfield(ctrl, 'numeric', 'Value', state.omega, 'ValueChangedFcn',@(h,~) onOmega(h.Value),'FontSize',uiFonts.size,'FontName',uiFonts.name);
    eOmega.Layout.Row = 2; eOmega.Layout.Column = 3;

    % --- Phase Controls (Row 3) ---
    lblPhi = uilabel(ctrl,'Text','Phase φ (rad)','FontSize',uiFonts.size,'FontName',uiFonts.name,'FontWeight','bold');
    lblPhi.Layout.Row = 3; lblPhi.Layout.Column = 1;
    sPhi = uislider(ctrl,'Limits',[-phiMax phiMax],'Value',state.phiRad, 'ValueChangedFcn',@(h,~) onPhi(h.Value),'FontName',uiFonts.name);
    sPhi.Layout.Row = 3; sPhi.Layout.Column = 2;
    ePhi = uieditfield(ctrl, 'numeric', 'Value', state.phiRad, 'ValueChangedFcn',@(h,~) onPhi(h.Value),'FontSize',uiFonts.size,'FontName',uiFonts.name);
    ePhi.Layout.Row = 3; ePhi.Layout.Column = 3;

    % --- Action Buttons (Row 4 and Spanning) ---
    btnReset = uibutton(ctrl,'Text','↺ Reset','FontSize',uiFonts.title,'FontName',uiFonts.name,'ButtonPushedFcn',@(~,~) resetControls());
    btnReset.Layout.Row = 4; btnReset.Layout.Column = 3;
    btn = uibutton(ctrl,'Text','▶ Start','FontSize',uiFonts.title,'FontWeight','bold','FontName',uiFonts.name,'ButtonPushedFcn',@(~,~) startStop());
    btn.Layout.Row = [1 4]; btn.Layout.Column = 4;

    % Programmatically set ticks for sliders in terms of pi
    setupPiTicks();

    % --- Axes Setup ---
    pC = uipanel(main,'Title','Complex Plane','FontSize',uiFonts.title,'FontWeight','bold','BackgroundColor',uiColors.panel);
    pC.Layout.Row = 2; pC.Layout.Column = 1;
    axC = uiaxes(pC);
    axC.NextPlot = 'add'; grid(axC,'on'); axC.DataAspectRatio = [1 1 1];
    axC.FontSize = uiFonts.size; axC.FontName = uiFonts.name;
    xlabel(axC,'Real','FontSize',uiFonts.size,'FontName',uiFonts.name); 
    ylabel(axC,'Imaginary','FontSize',uiFonts.size,'FontName',uiFonts.name); 
    title(axC,'z(t) = A e^{j(\omega t + \phi)}','FontSize',uiFonts.title,'FontName',uiFonts.name);

    pT = uipanel(main,'Title','Time Domain','FontSize',uiFonts.title,'FontWeight','bold','BackgroundColor',uiColors.panel);
    pT.Layout.Row = 2; pT.Layout.Column = 2;
    axT = uiaxes(pT);
    axT.NextPlot = 'add'; grid(axT,'on');
    axT.FontSize = uiFonts.size; axT.FontName = uiFonts.name;
    xlabel(axT,'Time (s)','FontSize',uiFonts.size,'FontName',uiFonts.name); 
    ylabel(axT,'Amplitude','FontSize',uiFonts.size,'FontName',uiFonts.name); 
    title(axT,'Real & Imaginary Parts','FontSize',uiFonts.title,'FontName',uiFonts.name);

    % --- Graphics Objects ---
    th = linspace(0,2*pi,300);
    plot(axC, cos(th), sin(th), 'Color', [0.7 0.7 0.7], 'LineStyle', '--', 'LineWidth', 1);
    
    % Unit circle with angle markers
    angles = 0:pi/6:2*pi;
    for i = 1:length(angles)
        plot(axC, [0.9*cos(angles(i)), cos(angles(i))], [0.9*sin(angles(i)), sin(angles(i))], ...
              'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
    end
    
    phasorLine = plot(axC, [0 state.A], [0 0], 'Color', uiColors.primary, 'LineWidth', 3);
    tipPoint   = plot(axC, 0, 0, 'o', 'MarkerFaceColor', uiColors.primary, 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    
    % Phase angle arc
    phaseArc = plot(axC, NaN, NaN, 'Color', uiColors.highlight, 'LineWidth', 2, 'LineStyle', '--');
    
    % Phase angle text
    phaseText = text(axC, 0, 0, '', 'FontSize', uiFonts.size, 'FontName', uiFonts.name, 'Color', uiColors.highlight, 'FontWeight', 'bold');
    
    tcos = animatedline(axT,'Color',uiColors.primary,'LineWidth',1.5);
    tsin = animatedline(axT,'Color',uiColors.highlight,'LineWidth',1.5);
    legend(axT,{'cos (Real)','sin (Imag)'},'Location','northeast','FontSize',uiFonts.size,'FontName',uiFonts.name);

    % --- Status Bar ---
    statusPanel = uipanel(main,'Title','Status','FontSize',uiFonts.size,'FontWeight','bold','BackgroundColor',uiColors.panel);
    statusPanel.Layout.Row = 3; statusPanel.Layout.Column = [1 2];
    statusGrid = uigridlayout(statusPanel,[1 3]);
    statusGrid.ColumnWidth = {'1x','fit','fit'};
    statusGrid.Padding = [8 8 8 8];
    
    statusLabel = uilabel(statusGrid,'Text','Ready','FontSize',uiFonts.size,'FontName',uiFonts.name);
    statusLabel.Layout.Row = 1; statusLabel.Layout.Column = 1;
    
    freqLabel = uilabel(statusGrid,'Text','f = 0.00 Hz','FontSize',uiFonts.size,'FontName',uiFonts.name,'FontWeight','bold');
    freqLabel.Layout.Row = 1; freqLabel.Layout.Column = 2;
    
    periodLabel = uilabel(statusGrid,'Text','T = 0.00 s','FontSize',uiFonts.size,'FontName',uiFonts.name,'FontWeight','bold');
    periodLabel.Layout.Row = 1; periodLabel.Layout.Column = 3;

    % --- Timer ---
    tm = timer('ExecutionMode','fixedSpacing','Period',dt, 'TimerFcn',@onTick);
    
    resetAnimation(); % Initial draw

    % --- Nested Functions (Callbacks and Logic) ---
    function onA(val)
        state.A = max(0, min(Amax, val));
        sA.Value = state.A; eA.Value = state.A;
        redrawStaticLimits();
        if ~state.running, updateStaticPhasorView(); end
        updateStatus();
    end
    function onOmega(val)
        state.omega = max(0, min(omegaMax, val));
        sOmega.Value = state.omega; eOmega.Value = state.omega;
        if ~state.running, updateStaticPhasorView(); end
        updateStatus();
    end
    function onPhi(val)
        state.phiRad = max(-phiMax, min(phiMax, val));
        sPhi.Value = state.phiRad; ePhi.Value = state.phiRad;
        if ~state.running, updateStaticPhasorView(); end
        updateStatus();
    end

    function startStop()
        if state.running
            stop(tm);
            state.running = false;
            btn.Text = '▶ Start';
            statusLabel.Text = 'Stopped';
        else
            % *** NEW: Reset time references for new plotting logic
            state.t0 = tic;
            state.last_t = 0; 
            
            clearpoints(tcos); clearpoints(tsin);
            xlim(axT,[0 wlen]);
            start(tm);
            state.running = true;
            btn.Text = '■ Stop';
            statusLabel.Text = 'Running';
        end
        updateStatus();
    end

    function onTick(~,~)
        % *** NEW: High-resolution plotting logic ***
        t_now = toc(state.t0);
        
        % Create a high-resolution time vector for the interval since the last frame
        % This ensures we have enough points to draw a smooth curve
        time_diff = t_now - state.last_t;
        num_interp_points = max(2, min(50, ceil(time_diff / 0.01)));  % Limit points to prevent memory issues
        t_interval = linspace(state.last_t, t_now, num_interp_points);
        
        % Calculate phasor values for the entire interval
        z = state.A * exp(1j * (state.omega * t_interval + state.phiRad));
        xr = real(z); 
        xi = imag(z);
        
        % Get the final phasor position from the interval
        final_xr = xr(end);
        final_xi = xi(end);
        
        % Update the phasor line to the final point in the interval
        set(phasorLine,'XData',[0 final_xr],'YData',[0 final_xi]);
        set(tipPoint,'XData',final_xr,'YData',final_xi);
        
        % Update phase visualization using the same values (eliminates redundant calculation)
        updatePhaseVisualization(final_xr, final_xi);
        
        % Add the entire chunk of high-resolution points to the time plot
        addpoints(tcos, t_interval, xr);
        addpoints(tsin, t_interval, xi);
        
        % Update the last plotted time
        state.last_t = t_now;
        
        % Implement sliding window to prevent memory leaks without jarring resets
        if t_now > wlen
            xlim(axT,[t_now-wlen t_now]);
            
            % Get current data from animated lines
            [x_data, y_cos] = getpoints(tcos);
            [~, y_sin] = getpoints(tsin);
            
            % Find points outside the current window
            stale_indices = x_data < (t_now - wlen);
            
            % If there are stale points, remove them smoothly
            if any(stale_indices)
                % Keep only recent data within the window
                keep_indices = ~stale_indices;
                x_trimmed = x_data(keep_indices);
                y_cos_trimmed = y_cos(keep_indices);
                y_sin_trimmed = y_sin(keep_indices);
                
                % Re-populate the animated lines with trimmed data
                clearpoints(tcos);
                clearpoints(tsin);
                
                % Add back the trimmed data
                if ~isempty(x_trimmed)
                    addpoints(tcos, x_trimmed, y_cos_trimmed);
                    addpoints(tsin, x_trimmed, y_sin_trimmed);
                end
            end
        end
        drawnow('limitrate');
    end

    function updateStaticPhasorView()
        z = state.A * exp(1j * state.phiRad);
        xr = real(z); xi = imag(z);
        set(phasorLine,'XData',[0 xr],'YData',[0 xi]);
        set(tipPoint,'XData',xr,'YData',xi);
        updatePhaseVisualization(xr, xi);
    end
    
    function updatePhaseVisualization(xr, xi)
        % Calculate current phase angle from position
        if state.A > 1e-6  % Use small threshold instead of exact zero
            currentPhase = atan2(xi, xr);
            
            % Draw phase angle arc from 0 to current phase
            arcRadius = min(state.A * 0.3, 0.3);
            arcAngles = linspace(0, currentPhase, 20);
            arcX = arcRadius * cos(arcAngles);
            arcY = arcRadius * sin(arcAngles);
            set(phaseArc, 'XData', arcX, 'YData', arcY);
            
            % Position phase text
            textX = arcRadius * cos(currentPhase/2) * 1.2;
            textY = arcRadius * sin(currentPhase/2) * 1.2;
            
            % Format phase in radians with pi multiples
            phaseInPi = currentPhase / pi;
            if abs(phaseInPi) < 0.01
                phaseStr = 'φ = 0';
            elseif abs(phaseInPi - 1) < 0.01
                phaseStr = 'φ = π';
            elseif abs(phaseInPi + 1) < 0.01
                phaseStr = 'φ = -π';
            elseif abs(phaseInPi - 0.5) < 0.01
                phaseStr = 'φ = π/2';
            elseif abs(phaseInPi + 0.5) < 0.01
                phaseStr = 'φ = -π/2';
            else
                phaseStr = sprintf('φ = %.2f rad', currentPhase);
            end
            
            set(phaseText, 'Position', [textX, textY, 0], 'String', phaseStr);
        else
            set(phaseArc, 'XData', NaN, 'YData', NaN);
            set(phaseText, 'String', '');
        end
    end

    function redrawStaticLimits()
        lim = Amax * 1.2;
        xlim(axC,[-lim lim]); ylim(axC,[-lim lim]);
        ylim(axT,[-Amax Amax]);
    end

    function resetAnimation()
        redrawStaticLimits();
        clearpoints(tcos); clearpoints(tsin);
        xlim(axT,[0 wlen]);
        updateStaticPhasorView();
    end

    function resetControls()
        if state.running, startStop(); end % Stop animation before resetting
        onA(1.0);
        onOmega(2*pi);
        onPhi(0.0);
        resetAnimation();
    end

    function setupPiTicks()
        sPhi.MajorTicks = -2*pi:pi/2:2*pi;
        sPhi.MajorTickLabels = {'-2π','-3π/2','-π','-π/2','0','π/2','π','3π/2','2π'};
        
        omegaTicks = 0:pi:omegaMax;
        sOmega.MajorTicks = omegaTicks;
        labels = cell(1, numel(omegaTicks));
        for i = 1:numel(omegaTicks)
            multiple = round(omegaTicks(i) / pi);
            if multiple == 0, labels{i} = '0';
            elseif multiple == 1, labels{i} = 'π';
            else, labels{i} = [num2str(multiple) 'π'];
            end
        end
        sOmega.MajorTickLabels = labels;
    end

    function updateStatus()
        if state.omega > 1e-6  % Use small threshold instead of exact zero
            freq = state.omega / (2*pi);
            period = 1 / freq;
            freqLabel.Text = sprintf('f = %.2f Hz', freq);
            periodLabel.Text = sprintf('T = %.3f s', period);
        else
            freqLabel.Text = 'f = 0.00 Hz';
            periodLabel.Text = 'T = ∞ s';
        end
    end

    function showHelp()
        helpText = ['HOW TO USE THIS APP:' newline newline ...
            '1. ANIMATION CONTROLS:' newline ...
            '   • Click "Start" to begin phasor rotation' newline ...
            '   • Use "Stop" to pause the animation' newline ...
            '   • Click "Reset" to return to initial position' newline newline ...
            '2. PARAMETER ADJUSTMENT:' newline ...
            '   • Amplitude: Changes the radius of the phasor' newline ...
            '   • Frequency: Controls rotation speed (rad/s)' newline ...
            '   • Phase: Sets initial angle (radians)' newline newline ...
            '3. VISUALIZATION:' newline ...
            '   • Complex Plane: Shows phasor rotation and phase angle' newline ...
            '   • Time Domain: Real and imaginary components over time' newline ...
            '   • Phase Arc: Visual representation of current phase' newline newline ...
            '4. KEY CONCEPTS:' newline ...
            '   • Euler''s Formula: e^(jθ) = cos(θ) + j·sin(θ)' newline ...
            '   • Phasor: Rotating vector representing complex exponential' newline ...
            '   • Real part = A·cos(ωt + φ), Imaginary part = A·sin(ωt + φ)' newline ...
            '   • Phase angle shows current position in rotation cycle'];
        
        % Create a figure with scrollable text
        helpFig = uifigure('Name', 'Help - Euler Phasor Animator', 'Position', [300 300 500 400]);
        helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
        
        % Create scrollable text area
        helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 480 380], ...
            'FontSize', 12, 'FontName', 'Consolas', 'Editable', 'off');
        
        % Add scrollbar
        helpTextArea.Scrollable = 'on';
    end

    function onClose()
        try
            if exist('tm', 'var') && isvalid(tm)
                stop(tm);
                delete(tm);
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