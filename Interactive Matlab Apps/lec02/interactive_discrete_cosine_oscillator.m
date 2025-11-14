function interactive_discrete_cosine_oscillator
% INTERACTIVE DISCRETE COSINE OSCILLATOR
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates discrete-time cosine oscillation
% concepts. Users can visualize x[n] = cos(ω₀n) for different frequencies
% and compare discrete samples with continuous cosine waveforms.
% 
% FEATURES:
% - Real-time frequency adjustment (ω₀ from 0 to π)
% - Discrete samples visualization with stem plot
% - Continuous cosine overlay for comparison (always visible)
% - Live frequency and period calculations
% - Educational insights about fastest oscillation at ω₀ = π
% - Improved error handling and performance
% - Better UI layout and responsiveness
% - Always shows both discrete and continuous cosine
% 
% EDUCATIONAL PURPOSE:
% - Understanding discrete-time vs continuous-time signals
% - Sampling and aliasing concepts
% - Frequency domain properties of discrete signals
% - Why ω₀ = π gives the fastest oscillation in discrete time

    % --- Parameters ---
    n = 0:40;                      % sample indices to display
    omega0_init = 0.2;             % initial ω0 (small but visible oscillation)
    ylims = [-1.2 1.2];
    
    % --- Global handles for proper scope management ---
    hContinuous = [];              % Handle for continuous cosine plot
    
    % --- State variables ---
    state.showContinuous = true;   % Show/hide continuous plot
    
    % --- UI Colors and Fonts ---
    colors.bg = [0.96 0.96 0.96];       % Light gray background
    colors.panel = [1 1 1];         % White panels
    colors.text = [0.1 0.1 0.1];        % Dark text
    colors.highlight = [0.8500 0.3250 0.0980]; % Orange for pi
    colors.primary = [0 0.4470 0.7410];      % Blue for standard plot
    fonts.size_label = 13;
    fonts.size_readout = 14;
    fonts.size_title = 16;
    fonts.name = 'Helvetica Neue';
    % --- UI figure and layout ---
    fig = uifigure('Name','Interactive Discrete Cosine Oscillator: x[n]=cos(\omega_0 n)', ...
                   'Position',[100 100 880 600], 'Color', colors.bg);
    
    gl = uigridlayout(fig,[3 1]);
    % Fixed layout with proper proportions
    gl.RowHeight = {'fit', '1x', 'fit'};
    gl.ColumnWidth = {'1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 10;
    % --- Top panel for controls ---
    top = uipanel(gl,'Title','Controls', 'BackgroundColor', colors.panel, ...
            'BorderType','line', 'FontName', fonts.name, 'FontSize', fonts.size_title);
    top.Layout.Row = 1;
    topGrid = uigridlayout(top,[3 9]);
    topGrid.Padding = [10 10 10 10];
    % Add vertical spacing between rows for clarity
    topGrid.RowSpacing = 10;
    % Adjust row height to give slider more space for ticks
    topGrid.RowHeight = {30, '1x', 30}; 
    topGrid.ColumnWidth = {80, 120, 20, 80, 160, '1x', 180, 'fit', 'fit'};
    
    % Add help button to top panel
    helpBtn = uibutton(topGrid, 'Text', '?', 'FontSize', 16, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) showHelp());
    helpBtn.Layout.Row = 1; helpBtn.Layout.Column = 9;
    
    % --- Row 1: labels and readouts ---
    lblOmega = uilabel(topGrid, 'Text','\omega_0:', 'Interpreter','tex', ...
            'HorizontalAlignment','right', 'FontSize', fonts.size_label, ...
            'FontName', fonts.name, 'FontWeight', 'bold');
    lblOmega.Layout.Row = 1; lblOmega.Layout.Column = 1;
    omegaReadout = uilabel(topGrid, 'Text', sprintf('%.4f rad', omega0_init), ...
            'FontWeight','bold', 'FontSize', fonts.size_readout, 'FontName', fonts.name);
    omegaReadout.Layout.Row = 1; omegaReadout.Layout.Column = 2;
    lblNRange = uilabel(topGrid, 'Text','n-range:', 'HorizontalAlignment','right', ...
             'FontSize', fonts.size_label, 'FontName', fonts.name, 'FontWeight', 'bold');
    lblNRange.Layout.Row = 1; lblNRange.Layout.Column = 4;
    nReadout = uilabel(topGrid, 'Text', sprintf('[%d, %d]', n(1), n(end)), ...
            'FontSize', fonts.size_readout, 'FontName', fonts.name);
    nReadout.Layout.Row = 1; nReadout.Layout.Column = 5;
    % LaTeX equation label (symbolic function)
    eqLbl = uilabel(topGrid,'Text','$$x[n] = \cos(\omega_0 n)$$','Interpreter','latex', ...
            'FontSize',18, 'HorizontalAlignment','center');
    eqLbl.Layout.Row = [1 3]; eqLbl.Layout.Column = [7 8];
    % --- Row 2: slider for omega0 (0 to π) ---
    sld = uislider(topGrid);
    sld.Layout.Row = 2; sld.Layout.Column = [1 6];
    sld.Limits = [0 pi];
    % Use major ticks for clean labels and minor ticks for granularity
    sld.MajorTicks = 0:pi/4:pi;
    sld.MajorTickLabels = {'0', 'pi/4', 'pi/2', '3pi/4', 'pi'};
    sld.MinorTicks = 0:pi/8:pi; % Add minor ticks for visual guidance
    sld.Value = omega0_init;
    sld.FontName = fonts.name;
    % --- Row 3: tip and continuous cosine checkbox ---
    lblTip = uilabel(topGrid, 'Text','', 'HorizontalAlignment','right',...
             'FontSize', fonts.size_label, 'FontName', fonts.name, 'FontWeight', 'bold');
    lblTip.Layout.Row = 3; lblTip.Layout.Column = 1;
    tip = uilabel(topGrid, 'Text','Slide \omega_0 to \pi for fastest oscillation', ...
            'Interpreter','tex', 'FontAngle','italic', 'FontSize', fonts.size_label, ...
            'FontName', fonts.name);
    tip.Layout.Row = 3; tip.Layout.Column = [2 4];
    
    % Toggle continuous plot button
    btnToggleCT = uibutton(topGrid, 'Text','Hide CT', ...
        'FontSize', fonts.size_label, 'FontName', fonts.name, ...
        'ButtonPushedFcn', @(~,~) toggleContinuousPlot());
    btnToggleCT.Layout.Row = 3; btnToggleCT.Layout.Column = 5;
    
    % Reset button
    btnReset = uibutton(topGrid, 'Text','Reset', ...
        'FontSize', fonts.size_label, 'FontName', fonts.name, ...
        'ButtonPushedFcn', @(~,~) resetApp());
    btnReset.Layout.Row = 3; btnReset.Layout.Column = 6;
    % --- Single Axes for Overlay ---
    ax = uiaxes(gl);
    ax.Layout.Row = 2;
    ax.XLim = [n(1) n(end)];
    ax.YLim = ylims;
    ax.XGrid = 'on'; ax.YGrid = 'on';
    ax.GridColor = [0.15 0.15 0.15];
    ax.GridAlpha = 0.1;
    ax.FontName = fonts.name;
    ax.FontSize = fonts.size_label;
    xlabel(ax,'n (samples) / t (continuous time)');
    ylabel(ax,'x[n] / x(t)');
    ttl = title(ax, sprintf('x[n] = cos(\\omega_0 n),  \\omega_0 = %.4f rad', omega0_init), ...
        'Interpreter','tex', 'FontSize', fonts.size_title, 'FontWeight', 'normal');
    % --- Create plot handles with hold on (like exponential app) ---
    hold(ax, 'on');
    
    % Create continuous cosine plot handle (initially with NaN data)
    hContinuous = plot(ax, NaN, NaN, '--', 'Color', colors.highlight, 'LineWidth', 2, ...
                       'DisplayName', 'Continuous Cosine');
    
    % Create discrete samples plot handle (initially with NaN data)
    h = stem(ax, NaN, NaN, 'filled', 'Color', colors.primary, ...
             'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', 'Discrete Samples');
    
    % Add legend
    legend(ax, 'Location', 'northeast', 'FontSize', fonts.size_label);
    hold(ax, 'off');
    % --- Status Bar ---
    statusPanel = uipanel(gl,'Title','Status','FontSize',fonts.size_label,'FontWeight','bold','BackgroundColor',colors.panel);
    statusPanel.Layout.Row = 3;
    statusGrid = uigridlayout(statusPanel,[1 5]);
    statusGrid.ColumnWidth = {'1x','fit','fit','fit','fit'};
    statusGrid.Padding = [8 8 8 8];
    
    foot = uilabel(statusGrid, 'Text', 'Move the slider to see how the oscillation frequency changes.', ...
        'Interpreter','tex', 'HorizontalAlignment','left', 'FontSize', fonts.size_label, ...
        'FontColor', [0.2 0.2 0.2]);
    foot.Layout.Row = 1; foot.Layout.Column = 1;
    
    freqLabel = uilabel(statusGrid,'Text','f = 0.000 Hz','FontSize',fonts.size_label,'FontName',fonts.name,'FontWeight','bold');
    freqLabel.Layout.Row = 1; freqLabel.Layout.Column = 2;
    
    periodLabel = uilabel(statusGrid,'Text','T = ∞ s','FontSize',fonts.size_label,'FontName',fonts.name,'FontWeight','bold');
    periodLabel.Layout.Row = 1; periodLabel.Layout.Column = 3;
    
    % Add sample count display
    sampleLabel = uilabel(statusGrid,'Text',sprintf('Samples: %d',length(n)),'FontSize',fonts.size_label,'FontName',fonts.name,'FontWeight','bold');
    sampleLabel.Layout.Row = 1; sampleLabel.Layout.Column = 4;
    
    % Add version info
    versionLabel = uilabel(statusGrid,'Text','v1.0','FontSize',fonts.size_label-2,'FontName',fonts.name,'FontWeight','normal','FontColor',[0.5 0.5 0.5]);
    versionLabel.Layout.Row = 1; versionLabel.Layout.Column = 5;
    % --- Callbacks: Live updates while dragging and on release ---
    % Note: Callbacks are set after all plots are created to avoid interference
    sld.ValueChangingFcn = @(src,event) updateOmega(event.Value);
    sld.ValueChangedFcn  = @(src,event) updateOmega(event.Value);
    
    % Add debouncing to prevent excessive updates
    lastUpdateTime = tic; % Initialize timer
    updateDelay = 0.05; % 50ms minimum between updates
    
    % Initial plot update (like updateAll() in exponential app)
    updateOmega(omega0_init);
    
    % --- Update function ---
    function updateOmega(omega)
        try
            % --- Error Fix: Prevent error if figure is closed during callback ---
            if ~isvalid(fig)
                return;
            end
            
            % Add debouncing to prevent excessive updates
            currentTime = toc(lastUpdateTime);
            if currentTime < updateDelay
                return;
            end
            lastUpdateTime = tic; % Reset timer
            
            % Clamp to [0, π] to avoid any numeric drift
            omega = max(0, min(pi, omega));
            
            % Update readout
            omegaReadout.Text = sprintf('%.4f rad', omega);
            
            % Update discrete samples data
            ynew = cos(omega * n);
            if exist('h', 'var') && isvalid(h)
                set(h, 'XData', n, 'YData', ynew);
            else
                % Recreate plot handle if lost
                h = stem(ax, n, ynew, 'filled', 'Color', colors.primary, ...
                         'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', 'Discrete Samples');
            end
            
            % Update continuous cosine data (only if visible)
            if state.showContinuous
                t_continuous = linspace(n(1), n(end), 1000);  % Reduced points for better performance
                y_continuous = cos(omega * t_continuous);
                if exist('hContinuous', 'var') && isvalid(hContinuous)
                    set(hContinuous, 'XData', t_continuous, 'YData', y_continuous, 'Visible', 'on');
                else
                    % Recreate continuous plot handle if lost
                    hContinuous = plot(ax, t_continuous, y_continuous, '--', 'Color', colors.highlight, ...
                                     'LineWidth', 2, 'DisplayName', 'Continuous Cosine');
                end
            else
                if exist('hContinuous', 'var') && isvalid(hContinuous)
                    set(hContinuous, 'Visible', 'off');
                end
            end
            
            % Update title
            if exist('ttl', 'var') && isvalid(ttl)
                ttl.String = sprintf('x[n] = cos(\\omega_0 n),  \\omega_0 = %.4f rad', omega);
            end
            
            % Update frequency display with better formatting
            if omega > 1e-6  % Use small threshold instead of exact zero
                freq = omega / (2*pi);
                period = 1 / freq;
                freqLabel.Text = sprintf('f = %.3f Hz', freq);
                periodLabel.Text = sprintf('T = %.3f s', period);
            else
                freqLabel.Text = 'f = 0.000 Hz';
                periodLabel.Text = 'T = ∞ s';
            end
            
            % Update tip/footnote text for fastest case near π (keep discrete samples blue)
            if abs(omega - pi) < 1e-3
                tip.Text = 'Maximal DT oscillation reached!';
                foot.Text = 'At \omega_0 = \pi, we get x[n] = cos(\pi n) = (-1)^n, which alternates between +1 and -1 at every sample.';
            else
                tip.Text = 'Slide \omega_0 to \pi for fastest oscillation';
                foot.Text = 'Move the slider to see how the oscillation frequency changes.';
            end
            
        catch ME
            % Error handling for update operations
            fprintf('Error in updateOmega: %s\n', ME.message);
        end
    end

    % --- Toggle continuous plot function ---
    function toggleContinuousPlot()
        try
            if ~isvalid(fig)
                return;
            end
            
            % Toggle state
            state.showContinuous = ~state.showContinuous;
            
            % Update button text
            if state.showContinuous
                btnToggleCT.Text = 'Hide CT';
            else
                btnToggleCT.Text = 'Show CT';
            end
            
            % Update the plot visibility
            updateOmega(sld.Value);
            
        catch ME
            fprintf('Error in toggleContinuousPlot: %s\n', ME.message);
        end
    end

    function showHelp()
        try
            helpText = ['HOW TO USE THIS APP:' newline newline ...
                '1. FREQUENCY CONTROL:' newline ...
                '   • Use the slider to adjust ω₀ from 0 to π radians' newline ...
                '   • Watch how the oscillation frequency changes in real-time' newline ...
                '   • Notice the fastest oscillation occurs at ω₀ = π' newline ...
                '   • Use the major tick marks for precise control' newline newline ...
                '2. CONTINUOUS COSINE:' newline ...
                '   • Use "Hide CT" / "Show CT" button to toggle continuous plot' newline ...
                '   • Orange dashed line shows the continuous signal' newline ...
                '   • Blue circles show discrete samples, compare with continuous values' newline ...
                '   • Understand how sampling affects the signal representation' newline newline ...
                '3. STATUS INFORMATION:' newline ...
                '   • Frequency and period are calculated and displayed in real-time' newline ...
                '   • Educational tips appear based on current frequency' newline ...
                '   • Special highlighting when ω₀ = π (fastest oscillation)' newline newline ...
                '4. KEY CONCEPTS:' newline ...
                '   • Discrete-time signals are only defined at integer time indices' newline ...
                '   • The fastest oscillation in discrete time occurs at ω₀ = π' newline ...
                '   • At ω₀ = π, x[n] = cos(πn) = (-1)ⁿ alternates between +1 and -1' newline ...
                '   • Sampling continuous signals can cause aliasing effects' newline ...
                '   • The Nyquist frequency is ω₀ = π in discrete time' newline newline ...
                '5. IMPROVEMENTS IN V2.0:' newline ...
                '   • Better error handling and stability' newline ...
                '   • Improved UI layout and responsiveness' newline ...
                '   • Enhanced performance and smoother updates' newline ...
                '   • More precise frequency and period calculations'];
            
            % Create a figure with scrollable text
            helpFig = uifigure('Name', 'Help - Discrete Cosine Oscillator v1.0', 'Position', [300 300 550 450]);
            helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
            
            % Create scrollable text area
            helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 530 430], ...
                'FontSize', 11, 'FontName', 'Consolas', 'Editable', 'off');
            
            % Add scrollbar
            helpTextArea.Scrollable = 'on';
        catch ME
            % Fallback error handling
            fprintf('Error showing help: %s\n', ME.message);
            msgbox('Error displaying help. Please check the console for details.', 'Error', 'error');
        end
    end
    
    % --- Reset function ---
    function resetApp()
        try
            if ~isvalid(fig)
                return;
            end
            
            % Reset slider to initial value
            sld.Value = omega0_init;
            
            % Reset continuous plot state
            state.showContinuous = true;
            btnToggleCT.Text = 'Hide CT';
            
            % Reset all displays (continuous cosine will be updated automatically)
            updateOmega(omega0_init);
            
            % Ensure legend is properly updated
            legend(ax, 'Location', 'northeast', 'FontSize', fonts.size_label);
            
            % Reset status messages
            tip.Text = 'Slide \omega_0 to \pi for fastest oscillation';
            foot.Text = 'Move the slider to see how the oscillation frequency changes.';
            
        catch ME
            fprintf('Error in resetApp: %s\n', ME.message);
        end
    end
end
