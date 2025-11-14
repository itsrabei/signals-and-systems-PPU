% INTERACTIVE SIGNAL TRANSFORMATION TOOL
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates time domain signal transformations
% by allowing users to visualize various signal types and apply time shifting,
% scaling, and reversal operations in real-time. Users can explore different
% signal types and see the effects of parameter changes on signal behavior.
% 
% FEATURES:
% - Multiple signal types: exponential, gaussian, sinc, and chirp
% - Real-time parameter control with sliders
% - Time shifting, scaling, and reversal operations
% - Combined transformation operations
% - Visual comparison of original and transformed signals
% - Interactive parameter adjustment with immediate feedback
% 
% EDUCATIONAL PURPOSE:
% - Understanding time domain signal transformations
% - Visualizing effects of time shifting and scaling
% - Exploring different signal types and their properties
% - Interactive parameter control and signal analysis
% - Mathematical concepts of signal transformation
% 
% Notes:
% - Supports multiple signal types with different characteristics
% - Real-time parameter updates with visual feedback
% - Combined transformations show interaction effects
% - Adaptive axis limits for optimal visualization

function Time_transformation_examples
    t = linspace(-8, 8, 2000);
    
    t0 = 0.9;
    alpha = 1.3;
    
    signal_type = 'exponential';
    
    signal_definitions = struct();
    signal_definitions.exponential = @(z) ((z >= 1) & (z <= 3)) .* exp(-(z - 2)) + ((z >= 4) & (z <= 5));
    signal_definitions.gaussian = @(z) exp(-((z - 2).^2) / 0.5) .* ((z >= 0) & (z <= 4));
    signal_definitions.sinc = @(z) sinc(z - 2) .* ((z >= -2) & (z <= 6));
    signal_definitions.chirp = @(z) sin(2*pi*(z + 0.1*z.^2)) .* ((z >= 1) & (z <= 5));
    
    signal_shape = signal_definitions.(signal_type);
    x = signal_shape(t);
    
    fig = figure('Name', 'Signal Transformation Tool', 'Position', [50 50 1600 900], ...
                 'Color', [0.98 0.98 0.98], 'Resize', 'on', 'NumberTitle', 'off');
    fig.MenuBar = 'none';
    fig.ToolBar = 'none';
    
    tl = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    ax1 = nexttile;
    plot(ax1, t, x, 'k', 'LineWidth', 2.5);
    title(ax1, sprintf('Original: %s', signal_type), 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax1, 'on'); xlim(ax1, [-1 7]);
    xlabel(ax1, 'Time (s)', 'FontSize', 12); ylabel(ax1, 'Amplitude', 'FontSize', 12);
    
    ax2 = nexttile;
    plot(ax2, t, x, 'k--', 'LineWidth', 1.5);
    hold(ax2, 'on');
    pShifted = plot(ax2, t, zeros(size(t)), 'r', 'LineWidth', 2.5);
    hold(ax2, 'off');
    title(ax2, 'Shifted: x(t - t_0)', 'Interpreter', 'tex', 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax2, 'on'); xlim(ax2, [-1 7]);
    xlabel(ax2, 'Time (s)', 'FontSize', 12); ylabel(ax2, 'Amplitude', 'FontSize', 12);
    
    ax3 = nexttile;
    plot(ax3, t, x, 'k--', 'LineWidth', 1.5);
    hold(ax3, 'on');
    plot(ax3, t, signal_shape(-t), 'g', 'LineWidth', 2.5);
    hold(ax3, 'off');
    title(ax3, 'Reversed: x(-t)', 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax3, 'on'); xlim(ax3, [-6 6]);
    xlabel(ax3, 'Time (s)', 'FontSize', 12); ylabel(ax3, 'Amplitude', 'FontSize', 12);
    
    ax4 = nexttile;
    plot(ax4, t, x, 'k--', 'LineWidth', 1.5);
    hold(ax4, 'on');
    pScaled = plot(ax4, t, zeros(size(t)), 'm', 'LineWidth', 2.5);
    hold(ax4, 'off');
    title(ax4, 'Scaled: x(\alpha t)', 'Interpreter', 'tex', 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax4, 'on'); xlim(ax4, [0 6]);
    xlabel(ax4, 'Time (s)', 'FontSize', 12); ylabel(ax4, 'Amplitude', 'FontSize', 12);
    
    ax5 = nexttile;
    plot(ax5, t, x, 'k--', 'LineWidth', 1.5);
    hold(ax5, 'on');
    pCombined = plot(ax5, t, zeros(size(t)), 'b', 'LineWidth', 2.5);
    hold(ax5, 'off');
    title(ax5, 'Combined: x(\alpha(t - t_0))', 'Interpreter', 'tex', 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax5, 'on'); xlim(ax5, [-8 8]);
    xlabel(ax5, 'Time (s)', 'FontSize', 12); ylabel(ax5, 'Amplitude', 'FontSize', 12);
    
    ax6 = nexttile;
    hAnalysis = plot(ax6, t, x, 'k', 'LineWidth', 2);
    title(ax6, 'Signal Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax6, 'on'); xlim(ax6, [-1 7]);
    xlabel(ax6, 'Time (s)', 'FontSize', 12); ylabel(ax6, 'Amplitude', 'FontSize', 12);
    
    axControls = nexttile(6);
    
    panel_pos = axControls.Position;
    delete(axControls);
    
    panel = uipanel(fig, 'Position', panel_pos, 'Title', 'Parameters', 'FontSize', 12, ...
                    'BackgroundColor', [0.95 0.95 0.95]);
    
    uicontrol(panel, 'Style', 'text', 'String', 'Time Shift t_0:', 'Units', 'normalized', ...
        'Position', [0.05 0.65 0.4 0.2], 'HorizontalAlignment', 'left', 'FontSize', 11);
    sliderT0 = uicontrol(panel, 'Style', 'slider', 'Min', -3, 'Max', 3, 'Value', t0, ...
        'Units', 'normalized', 'Position', [0.05 0.5 0.8 0.15]);
    txtT0 = uicontrol(panel, 'Style', 'text', 'String', num2str(t0, 3), 'Units', 'normalized', ...
        'Position', [0.86 0.5 0.12 0.15], 'FontSize', 11);
    
    uicontrol(panel, 'Style', 'text', 'String', 'Time Scale \alpha:', 'Units', 'normalized', ...
        'Position', [0.05 0.25 0.4 0.2], 'HorizontalAlignment', 'left', 'FontSize', 11);
    sliderAlpha = uicontrol(panel, 'Style', 'slider', 'Min', 0.1, 'Max', 3, 'Value', alpha, ...
        'Units', 'normalized', 'Position', [0.05 0.1 0.8 0.15]);
    txtAlpha = uicontrol(panel, 'Style', 'text', 'String', num2str(alpha, 3), 'Units', 'normalized', ...
        'Position', [0.86 0.1 0.12 0.15], 'FontSize', 11);
        
    sliderT0.Callback = @updatePlots;
    sliderAlpha.Callback = @updatePlots;
    
    updatePlots();
    
    function updatePlots(~,~)
        try
            t0_current = sliderT0.Value;
            alpha_current = sliderAlpha.Value;
            
            txtT0.String = sprintf('%.2f', t0_current);
            txtAlpha.String = sprintf('%.2f', alpha_current);
        
        x_shifted  = signal_shape(t - t0_current);
        x_scaled   = signal_shape(alpha_current * t);
        x_combined = signal_shape(alpha_current * (t - t0_current));
                  
        pShifted.YData = x_shifted;
        pScaled.YData = x_scaled;
        pCombined.YData = x_combined;
        
        if alpha_current > 0
            t_min = 1/alpha_current;
            t_max = 5/alpha_current;
            xlim(ax4, [max(0, t_min-0.5), t_max+0.5]);
        else
            xlim(ax4, [0, 6]);
        end
        
        if alpha_current > 0
            t_combined_min = (1 + t0_current)/alpha_current;
            t_combined_max = (5 + t0_current)/alpha_current;
            xlim_min = min(-8, t_combined_min - 1);
            xlim_max = max(8, t_combined_max + 1);
            xlim(ax5, [xlim_min, xlim_max]);
        else
            xlim(ax5, [-8, 8]);
        end
        
        if isvalid(hAnalysis)
            try
                hAnalysis.YData = x_combined;
            catch
                cla(ax6);
                hAnalysis = plot(ax6, t, x_combined, 'k', 'LineWidth', 2);
                title(ax6, 'Signal Analysis', 'FontSize', 14, 'FontWeight', 'bold');
                grid(ax6, 'on'); xlim(ax6, [-1 7]);
                xlabel(ax6, 'Time (s)', 'FontSize', 12); ylabel(ax6, 'Amplitude', 'FontSize', 12);
            end
        end
        
        drawnow;
        catch ME
            warning('Plot update failed: %s', ME.message);
        end
    end
    
    
end