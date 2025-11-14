classdef DT_FS_PlotManager < handle
    % DT_FS_PLOT_MANAGER - Handles all plotting and visualization for DT Fourier Series
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 1.0
    %
    % This class manages all plotting functionality for the Discrete-Time Fourier
    % series app including time domain, frequency domain, harmonics, and properties plots.
    
    properties (Access = private)
        % Plot axes handles
        time_axis = [];
        freq_axis = [];
        harmonics_axis = [];
        properties_axis = [];
        
        % Math module reference
        fourier_math = [];
        
        % UI colors and fonts
        colors = struct();
        fonts = struct();
        
        % Plot data
        original_signal = [];
        fourier_signal = [];
        sample_indices = [];
        coefficients = [];
        frequencies = [];
        harmonics = [];
        current_harmonic_count = [];
        
        % Display options
        show_orthogonality = false;
        show_spectrum = true;
        show_properties = false;
        show_error = false;
        show_convergence = false;
        
        % Plot element visibility
        show_original_signal = true;
        show_fourier_signal = true;
        show_error_signal = false;
        show_grid = true;
        show_legend = true;
        show_math_notation = true;
        
        % Property settings
        time_shift = false;
        freq_shift = false;
        scaling = false;
        
        % Plot settings
        line_width = 2;
        marker_size = 6;
        grid_alpha = 0.3;
        max_harmonics_display = 5;
    end
    
    methods (Access = public)
        function obj = DT_FS_PlotManager()
            % Constructor - initialize plot manager
            obj.initializeColors();
            obj.initializeFonts();
        end
        
        function initializeColors(obj)
            % Initialize enhanced color scheme for DT Fourier Series
            obj.colors.bg = [0.96 0.96 0.96];
            obj.colors.panel = [1 1 1];
            obj.colors.text = [0.1 0.1 0.1];
            obj.colors.primary = [0 0.4470 0.7410];      % Blue
            obj.colors.highlight = [0.8500 0.3250 0.0980]; % Orange
            obj.colors.secondary = [0.4940 0.1840 0.5560]; % Purple
            obj.colors.harmonic = [0.2 0.8 0.2];          % Green
            obj.colors.orthogonal = [0.3 0.6 0.9];        % Light Blue
            obj.colors.error = [0.9 0.1 0.1];             % Dark Red
            obj.colors.convergence = [0.1 0.7 0.1];       % Dark Green
            obj.colors.dt_signal = [0.8 0.2 0.6];         % Magenta for DT
            obj.colors.grid = [0.8 0.8 0.8];              % Light Gray for grid
        end
        
        function initializeFonts(obj)
            % Initialize font settings
            obj.fonts.size = 12;
            obj.fonts.title = 14;
            obj.fonts.name = 'Helvetica Neue';
            obj.fonts.math = 'Times New Roman';
        end
        
        function setAxes(obj, time_ax, freq_ax, harmonics_ax, properties_ax)
            % Set axes handles
            obj.time_axis = time_ax;
            obj.freq_axis = freq_ax;
            obj.harmonics_axis = harmonics_ax;
            obj.properties_axis = properties_ax;
        end
        
        function setFourierMath(obj, fourier_math)
            % Set reference to Fourier math module
            obj.fourier_math = fourier_math;
        end
        
        function updateData(obj, original_signal, fourier_signal, sample_indices, coefficients, frequencies, harmonics)
            % Update plot data
            obj.original_signal = original_signal;
            obj.fourier_signal = fourier_signal;
            obj.sample_indices = sample_indices;
            obj.coefficients = coefficients;
            obj.frequencies = frequencies;
            obj.harmonics = harmonics;
        end
        
        function setDisplayOptions(obj, show_orthogonality, show_spectrum, show_properties, show_error, show_convergence)
            % Set display options
            obj.show_orthogonality = show_orthogonality;
            obj.show_spectrum = show_spectrum;
            obj.show_properties = show_properties;
            obj.show_error_signal = show_error;
            obj.show_convergence = show_convergence;
        end
        
        function setCurrentHarmonicCount(obj, harmonic_count)
            % Set current harmonic count for animation
            obj.current_harmonic_count = harmonic_count;
        end
        
        function setPlotElementVisibility(obj, show_original, show_fourier, show_error, show_grid, show_legend, show_math)
            % Set visibility of individual plot elements
            obj.show_original_signal = show_original;
            obj.show_fourier_signal = show_fourier;
            obj.show_error_signal = show_error;
            obj.show_grid = show_grid;
            obj.show_legend = show_legend;
            obj.show_math_notation = show_math;
        end
        
        function setPropertySettings(obj, time_shift, freq_shift, scaling)
            % Set property demonstration settings
            obj.time_shift = time_shift;
            obj.freq_shift = freq_shift;
            obj.scaling = scaling;
        end
        
        function setMaxHarmonicsDisplay(obj, max_harmonics)
            % Set maximum number of harmonics to display
            obj.max_harmonics_display = max_harmonics;
        end
        
        function updateAllPlots(obj)
            % Update all plots
            try
                obj.updateTimeDomainPlot();
                obj.updateFrequencyDomainPlot();
                obj.updateHarmonicsPlot();
                obj.updatePropertiesPlot();
            catch ME
                fprintf('DT_FS_PlotManager: Plot update error: %s\n', ME.message);
            end
        end
        
        function updateTimeDomainPlot(obj)
            % Update time domain plot
            try
                if isempty(obj.time_axis)
                    fprintf('DT_FS_PlotManager: Time axis not set\n');
                    return;
                end
                
                if isempty(obj.original_signal) || isempty(obj.sample_indices)
                    fprintf('DT_FS_PlotManager: No signal data available\n');
                    return;
                end
                
                % Validate data
                if length(obj.original_signal) ~= length(obj.sample_indices)
                    fprintf('DT_FS_PlotManager: Signal and index vector length mismatch\n');
                    return;
                end
                
                % Clear the axis
                cla(obj.time_axis);
                hold(obj.time_axis, 'on');
                
                % Plot original signal
                if obj.show_original_signal
                    stem(obj.time_axis, obj.sample_indices, obj.original_signal, ...
                        'Color', obj.colors.dt_signal, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'MarkerFaceColor', obj.colors.dt_signal, ...
                        'DisplayName', 'Original DT Signal');
                end
                
                % Plot Fourier approximation
                if obj.show_fourier_signal && ~isempty(obj.fourier_signal)
                    stem(obj.time_axis, obj.sample_indices, obj.fourier_signal, ...
                        'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'MarkerFaceColor', obj.colors.primary, ...
                        'DisplayName', 'DTFS Approximation');
                end
                
                % Error signal display removed - error analysis is shown in Properties plot
                
                
                % Configure axis
                obj.configureTimeAxis();
                
                % Add mathematical notation if requested
                if obj.show_math_notation
                    obj.addTimeDomainMathNotation();
                end
                
                hold(obj.time_axis, 'off');
                
            catch ME
                fprintf('DT_FS_PlotManager: Time domain plot error: %s\n', ME.message);
                % Display error message on plot
                cla(obj.time_axis);
                text(obj.time_axis, 0.5, 0.5, sprintf('Plot Error: %s', ME.message), ...
                    'HorizontalAlignment', 'center', 'FontSize', obj.fonts.size, 'Color', 'red');
            end
        end
        
        function updateFrequencyDomainPlot(obj)
            % Update frequency domain plot
            try
                if isempty(obj.freq_axis)
                    fprintf('DT_FS_PlotManager: Frequency axis not set\n');
                    return;
                end
                
                if isempty(obj.coefficients) || isempty(obj.frequencies)
                    fprintf('DT_FS_PlotManager: No frequency data available\n');
                    return;
                end
                
                % Clear the axis
                cla(obj.freq_axis);
                hold(obj.freq_axis, 'on');
                
                % Calculate magnitude spectrum
                magnitude = abs(obj.coefficients);
                
                % Shift the data for centered plotting
                magnitude_shifted = fftshift(magnitude);
                N = length(obj.frequencies);
                
                % Create symmetric frequency axis for both even and odd N
                if mod(N, 2) == 0
                    freq_axis_shifted = (-N/2 : N/2-1)';
                else
                    freq_axis_shifted = (-floor(N/2) : floor(N/2))';
                end
                
                % Plot magnitude spectrum
                if obj.show_spectrum
                    stem(obj.freq_axis, freq_axis_shifted, magnitude_shifted, ...
                        'Color', obj.colors.secondary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'MarkerFaceColor', obj.colors.secondary, ...
                        'DisplayName', 'Magnitude Spectrum');
                    
                    % Highlight DC component (frequency = 0)
                    dc_idx = find(freq_axis_shifted == 0, 1);
                    if ~isempty(dc_idx)
                        plot(obj.freq_axis, freq_axis_shifted(dc_idx), magnitude_shifted(dc_idx), ...
                            'go', 'MarkerSize', obj.marker_size+2, 'MarkerFaceColor', obj.colors.primary, ...
                            'DisplayName', 'DC Component');
                    end
                    
                    % Highlight fundamental frequency (first positive frequency)
                    fundamental_idx = find(freq_axis_shifted > 0, 1);
                    if ~isempty(fundamental_idx)
                        plot(obj.freq_axis, freq_axis_shifted(fundamental_idx), magnitude_shifted(fundamental_idx), ...
                            'ro', 'MarkerSize', obj.marker_size+2, 'MarkerFaceColor', obj.colors.highlight, ...
                            'DisplayName', 'Fundamental');
                    end
                end
                
                % Configure axis
                obj.configureFrequencyAxis();
                
                % Add mathematical notation if requested
                if obj.show_math_notation
                    obj.addFrequencyDomainMathNotation();
                    
                    % Add note about periodic nature of spectrum
                    if ~isempty(obj.frequencies)
                        N = length(obj.frequencies);
                        text(obj.freq_axis, 0.02, 0.98, sprintf('Periodic with period N = %d', N), ...
                            'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                            'FontWeight', 'bold', 'Color', obj.colors.secondary, ...
                            'BackgroundColor', 'white', 'EdgeColor', obj.colors.secondary);
                    end
                end
                
                hold(obj.freq_axis, 'off');
                
            catch ME
                fprintf('DT_FS_PlotManager: Frequency domain plot error: %s\n', ME.message);
                % Display error message on plot
                cla(obj.freq_axis);
                text(obj.freq_axis, 0.5, 0.5, sprintf('Plot Error: %s', ME.message), ...
                    'HorizontalAlignment', 'center', 'FontSize', obj.fonts.size, 'Color', 'red');
            end
        end
        
        function updateHarmonicsPlot(obj)
            % Update harmonics plot
            try
                if isempty(obj.harmonics_axis)
                    fprintf('DT_FS_PlotManager: Harmonics axis not set\n');
                    return;
                end
                
                if isempty(obj.harmonics) || isempty(obj.sample_indices)
                    fprintf('DT_FS_PlotManager: No harmonics data available\n');
                    return;
                end
                
                % Clear the axis
                cla(obj.harmonics_axis);
                hold(obj.harmonics_axis, 'on');
                
                % Plot individual harmonics with different colors
                % Use current harmonic count (DC + pairs) if available, otherwise use max_harmonics_display
                if isfield(obj, 'current_harmonic_count') && ~isempty(obj.current_harmonic_count)
                    num_harmonics_to_show = min(obj.current_harmonic_count, size(obj.harmonics, 2));
                else
                    num_harmonics_to_show = min(obj.max_harmonics_display, size(obj.harmonics, 2));
                end
                
                % Define harmonic colors (cycling through a color palette)
                harmonic_colors = [
                    [0.2 0.8 0.2];  % Green
                    [0.8 0.2 0.2];  % Red  
                    [0.2 0.2 0.8];  % Blue
                    [0.8 0.8 0.2];  % Yellow
                    [0.8 0.2 0.8];  % Magenta
                    [0.2 0.8 0.8];  % Cyan
                    [0.8 0.4 0.2];  % Orange
                    [0.4 0.2 0.8];  % Purple
                ];
                
                for i = 1:num_harmonics_to_show
                    if i <= size(obj.harmonics, 2)
                        % Cycle through colors
                        color_idx = mod(i-1, size(harmonic_colors, 1)) + 1;
                        harmonic_color = harmonic_colors(color_idx, :);
                        
                        % Create appropriate label for each harmonic component
                        if i == 1
                            label = 'DC Component';
                        else
                            label = sprintf('±%d Pair', i-1);
                        end
                        
                        stem(obj.harmonics_axis, obj.sample_indices, obj.harmonics(:, i), ...
                            'Color', harmonic_color, 'LineWidth', obj.line_width, ...
                            'MarkerSize', obj.marker_size, 'MarkerFaceColor', harmonic_color, ...
                            'DisplayName', label);
                    end
                end
                
                % Configure axis
                obj.configureHarmonicsAxis();
                
                % Add mathematical notation if requested
                if obj.show_math_notation
                    obj.addHarmonicsMathNotation();
                end
                
                hold(obj.harmonics_axis, 'off');
                
            catch ME
                fprintf('DT_FS_PlotManager: Harmonics plot error: %s\n', ME.message);
                % Display error message on plot
                cla(obj.harmonics_axis);
                text(obj.harmonics_axis, 0.5, 0.5, sprintf('Plot Error: %s', ME.message), ...
                    'HorizontalAlignment', 'center', 'FontSize', obj.fonts.size, 'Color', 'red');
            end
        end
        
        function updatePropertiesPlot(obj)
            % Update properties plot
            try
                if isempty(obj.properties_axis)
                    fprintf('DT_FS_PlotManager: Properties axis not set\n');
                    return;
                end
                
                % Clear the axis
                cla(obj.properties_axis);
                hold(obj.properties_axis, 'on');
                
                % Show different properties based on settings
                if obj.show_orthogonality
                    obj.plotOrthogonalityDemo();
                elseif obj.show_convergence
                    obj.plotConvergenceDemo();
                elseif obj.show_properties
                    obj.plotPropertiesDemo();
                else
                    % Default: show error analysis
                    obj.plotErrorAnalysis();
                end
                
                % Configure axis
                obj.configurePropertiesAxis();
                
                hold(obj.properties_axis, 'off');
                
            catch ME
                fprintf('DT_FS_PlotManager: Properties plot error: %s\n', ME.message);
                % Display error message on plot
                cla(obj.properties_axis);
                text(obj.properties_axis, 0.5, 0.5, sprintf('Plot Error: %s', ME.message), ...
                    'HorizontalAlignment', 'center', 'FontSize', obj.fonts.size, 'Color', 'red');
            end
        end
        
        function exportPlot(obj, axis_handle, filename, format)
            % Export plot to file
            try
                if isempty(axis_handle) || isempty(filename)
                    fprintf('DT_FS_PlotManager: Invalid export parameters\n');
                    return;
                end
                
                % Set the current figure to the axis parent
                fig = ancestor(axis_handle, 'figure');
                set(fig, 'CurrentAxes', axis_handle);
                
                % Export based on format
                switch lower(format)
                    case 'fig'
                        savefig(fig, filename);
                    case 'png'
                        print(fig, filename, '-dpng', '-r300');
                    case 'pdf'
                        print(fig, filename, '-dpdf', '-r300');
                    otherwise
                        fprintf('DT_FS_PlotManager: Unsupported export format: %s\n', format);
                        return;
                end
                
                fprintf('DT_FS_PlotManager: Plot exported to %s\n', filename);
                
            catch ME
                fprintf('DT_FS_PlotManager: Export error: %s\n', ME.message);
            end
        end
        
        function exportData(obj, filename)
            % Export plot data to MAT file
            try
                if isempty(filename)
                    fprintf('DT_FS_PlotManager: Invalid filename for data export\n');
                    return;
                end
                
                % Prepare data structure
                export_data = struct();
                export_data.original_signal = obj.original_signal;
                export_data.fourier_signal = obj.fourier_signal;
                export_data.sample_indices = obj.sample_indices;
                export_data.coefficients = obj.coefficients;
                export_data.frequencies = obj.frequencies;
                export_data.harmonics = obj.harmonics;
                export_data.timestamp = datetime('now');
                
                % Save to MAT file
                save(filename, 'export_data');
                fprintf('DT_FS_PlotManager: Data exported to %s\n', filename);
                
            catch ME
                fprintf('DT_FS_PlotManager: Data export error: %s\n', ME.message);
            end
        end
    end
    
    methods (Access = private)
        function configureTimeAxis(obj)
            % Configure time domain axis
            if obj.show_grid
                grid(obj.time_axis, 'on');
                grid(obj.time_axis, 'minor');
            else
                grid(obj.time_axis, 'off');
            end
            
            xlabel(obj.time_axis, 'Sample Index (n)', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            ylabel(obj.time_axis, 'Amplitude', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            title(obj.time_axis, 'Discrete-Time Domain', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
            
            % Dynamic axis limits
            if ~isempty(obj.sample_indices)
                xlim(obj.time_axis, [min(obj.sample_indices), max(obj.sample_indices)]);
                
                all_signals = [obj.original_signal];
                if ~isempty(obj.fourier_signal)
                    all_signals = [all_signals; obj.fourier_signal];
                end
                
                if ~isempty(all_signals)
                    ylim(obj.time_axis, [min(all_signals)*1.1, max(all_signals)*1.1]);
                end
            end
            
            if obj.show_legend
                legend(obj.time_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
            end
        end
        
        function configureFrequencyAxis(obj)
            % Configure frequency domain axis
            if obj.show_grid
                grid(obj.freq_axis, 'on');
                grid(obj.freq_axis, 'minor');
            else
                grid(obj.freq_axis, 'off');
            end
            
            xlabel(obj.freq_axis, 'Frequency Index (k)', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            ylabel(obj.freq_axis, 'Magnitude', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            title(obj.freq_axis, 'DTFS Magnitude Spectrum', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
            
            % Dynamic axis limits
            if ~isempty(obj.frequencies)
                N = length(obj.frequencies);
                
                % Create symmetric frequency axis for both even and odd N
                if mod(N, 2) == 0
                    freq_axis_shifted = (-N/2 : N/2-1)';
                else
                    freq_axis_shifted = (-floor(N/2) : floor(N/2))';
                end
                
                xlim(obj.freq_axis, [min(freq_axis_shifted), max(freq_axis_shifted)]);
                
                if ~isempty(obj.coefficients)
                    magnitude = abs(obj.coefficients);
                    ylim(obj.freq_axis, [0, max(magnitude)*1.1]);
                end
            end
            
            if obj.show_legend
                legend(obj.freq_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
            end
        end
        
        function configureHarmonicsAxis(obj)
            % Configure harmonics axis
            if obj.show_grid
                grid(obj.harmonics_axis, 'on');
                grid(obj.harmonics_axis, 'minor');
            else
                grid(obj.harmonics_axis, 'off');
            end
            
            xlabel(obj.harmonics_axis, 'Sample Index (n)', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            ylabel(obj.harmonics_axis, 'Amplitude', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            title(obj.harmonics_axis, 'Individual Harmonics', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
            
            % Dynamic axis limits
            if ~isempty(obj.sample_indices)
                xlim(obj.harmonics_axis, [min(obj.sample_indices), max(obj.sample_indices)]);
                
                if ~isempty(obj.harmonics) && all(isfinite(obj.harmonics(:))) && size(obj.harmonics, 1) > 0
                    y_min = min(obj.harmonics(:));
                    y_max = max(obj.harmonics(:));
                    if y_min ~= y_max
                        ylim(obj.harmonics_axis, [y_min*1.1, y_max*1.1]);
                    else
                        ylim(obj.harmonics_axis, [y_min-0.1, y_max+0.1]);
                    end
                else
                    ylim(obj.harmonics_axis, [-1, 1]);
                end
            end
            
            if obj.show_legend
                legend(obj.harmonics_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
            end
        end
        
        function configurePropertiesAxis(obj)
            % Configure properties axis with dynamic y-limits
            if obj.show_grid
                grid(obj.properties_axis, 'on');
                grid(obj.properties_axis, 'minor');
            else
                grid(obj.properties_axis, 'off');
            end
            
            xlabel(obj.properties_axis, 'Sample Index (n)', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            ylabel(obj.properties_axis, 'Amplitude', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
            title(obj.properties_axis, 'DTFS Properties & Analysis', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
            
            % Dynamic y-limits based on data
            try
                % Get all line objects from the axis
                line_objects = findobj(obj.properties_axis, 'Type', 'line');
                stem_objects = findobj(obj.properties_axis, 'Type', 'stem');
                all_objects = [line_objects; stem_objects];
                
                if ~isempty(all_objects)
                    % Collect all y-data from all objects
                    all_y_data = [];
                    for i = 1:length(all_objects)
                        if isprop(all_objects(i), 'YData') && ~isempty(all_objects(i).YData)
                            all_y_data = [all_y_data, all_objects(i).YData];
                        end
                    end
                    
                    if ~isempty(all_y_data) && all(isfinite(all_y_data))
                        y_min = min(all_y_data);
                        y_max = max(all_y_data);
                        y_range = y_max - y_min;
                        
                        % Add 10% padding
                        if y_range > 0
                            ylim(obj.properties_axis, [y_min - 0.1*y_range, y_max + 0.1*y_range]);
                        else
                            ylim(obj.properties_axis, [y_min - 0.1, y_max + 0.1]);
                        end
                    end
                end
            catch ME
                % Fallback to default limits if dynamic calculation fails
                ylim(obj.properties_axis, [-1, 1]);
            end
            
            if obj.show_legend
                legend(obj.properties_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
            end
        end
        
        function addTimeDomainMathNotation(obj)
            % Add mathematical notation to time domain plot
            if ~isempty(obj.original_signal) && ~isempty(obj.fourier_signal)
                % Add error equation
                text(obj.time_axis, 0.02, 0.02, ...
                    'Error: e[n] = x[n] - x̂[n]', ...
                    'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                    'FontName', obj.fonts.math, 'Color', obj.colors.error, ...
                    'BackgroundColor', 'white', 'EdgeColor', obj.colors.error, ...
                    'Interpreter', 'none', 'VerticalAlignment', 'bottom');
            end
        end
        
        function addFrequencyDomainMathNotation(obj)
            % Add mathematical notation to frequency domain plot
            if ~isempty(obj.coefficients)
                % Add DTFS equation
                text(obj.freq_axis, 0.02, 0.98, ...
                    'X[k] = (1/N)∑x[n]e^{-j2πkn/N}', ...
                    'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                    'FontName', obj.fonts.math, 'Color', obj.colors.secondary, ...
                    'BackgroundColor', 'white', 'EdgeColor', obj.colors.secondary, ...
                    'Interpreter', 'tex', 'VerticalAlignment', 'top');
            end
        end
        
        function addHarmonicsMathNotation(obj)
            % Add mathematical notation to harmonics plot
            if ~isempty(obj.harmonics)
                % Add synthesis equation
                text(obj.harmonics_axis, 0.02, 0.98, ...
                    'x[n] = ∑X[k]e^{j2πkn/N}', ...
                    'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                    'FontName', obj.fonts.math, 'Color', obj.colors.harmonic, ...
                    'BackgroundColor', 'white', 'EdgeColor', obj.colors.harmonic, ...
                    'Interpreter', 'tex', 'VerticalAlignment', 'top');
            end
        end
        
        function plotOrthogonalityDemo(obj)
            % Plot orthogonality demonstration
            if isempty(obj.fourier_math)
                return;
            end
            
            try
                % Get orthogonality demonstration data
                N = length(obj.original_signal);
                orthogonality_demo = obj.fourier_math.demonstrateOrthogonality(N);
                
                if ~isempty(orthogonality_demo.n)
                    % Plot the two complex exponentials
                    stem(obj.properties_axis, orthogonality_demo.n, real(orthogonality_demo.exp1), ...
                        'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', sprintf('e^{j2π(%d)n/N}', orthogonality_demo.k1));
                    
                    stem(obj.properties_axis, orthogonality_demo.n, real(orthogonality_demo.exp2), ...
                        'Color', obj.colors.secondary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', sprintf('e^{j2π(%d)n/N}', orthogonality_demo.k2));
                    
                    % Add orthogonality result
                    text(obj.properties_axis, 0.02, 0.98, ...
                        sprintf('Inner Product: %.2e', abs(orthogonality_demo.inner_product)), ...
                        'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                        'FontName', obj.fonts.math, 'Color', obj.colors.orthogonal, ...
                        'BackgroundColor', 'white', 'EdgeColor', obj.colors.orthogonal, ...
                        'Interpreter', 'none', 'VerticalAlignment', 'top');
                end
                
            catch ME
                fprintf('DT_FS_PlotManager: Orthogonality demo error: %s\n', ME.message);
            end
        end
        
        function plotConvergenceDemo(obj)
            % Plot convergence demonstration
            if isempty(obj.fourier_math) || isempty(obj.original_signal)
                return;
            end
            
            try
                % Get convergence analysis data
                N = length(obj.original_signal);
                n = (0:N-1)';
                max_harmonics = min(20, N);
                
                convergence_analysis = obj.fourier_math.analyzeConvergence(obj.original_signal, n, N, max_harmonics);
                
                if ~isempty(convergence_analysis.harmonic_counts)
                    % Plot MSE vs number of harmonics
                    plot(obj.properties_axis, convergence_analysis.harmonic_counts, convergence_analysis.mse_values, ...
                        'Color', obj.colors.convergence, 'LineWidth', obj.line_width+1, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', 'MSE vs Harmonics');
                    
                    xlabel(obj.properties_axis, 'Number of Harmonics', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
                    ylabel(obj.properties_axis, 'Mean Square Error', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
                    title(obj.properties_axis, 'DTFS Convergence Analysis', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
                    
                    % Add convergence equation
                    text(obj.properties_axis, 0.02, 0.98, ...
                        'Convergence: e[n] = x[n] - x̂[n]', ...
                        'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                        'FontName', obj.fonts.math, 'Color', obj.colors.convergence, ...
                        'BackgroundColor', 'white', 'EdgeColor', obj.colors.convergence, ...
                        'Interpreter', 'none', 'VerticalAlignment', 'top');
                end
                
            catch ME
                fprintf('DT_FS_PlotManager: Convergence demo error: %s\n', ME.message);
            end
        end
        
        function plotPropertiesDemo(obj)
            % Plot properties demonstration
            if isempty(obj.original_signal) || isempty(obj.sample_indices)
                return;
            end
            
            try
                % Show different properties based on settings
                if obj.time_shift
                    % Demonstrate time shifting property
                    shift_amount = round(length(obj.original_signal) / 4);
                    shifted_signal = circshift(obj.original_signal, shift_amount);
                    
                    stem(obj.properties_axis, obj.sample_indices, obj.original_signal, ...
                        'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', 'Original');
                    
                    stem(obj.properties_axis, obj.sample_indices, shifted_signal, ...
                        'Color', obj.colors.secondary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', 'Time Shifted');
                    
                    title(obj.properties_axis, 'Time Shifting Property', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
                    
                elseif obj.freq_shift
                    % Demonstrate frequency shifting property
                    if ~isempty(obj.coefficients)
                        % Shift coefficients in frequency domain
                        shifted_coeffs = circshift(obj.coefficients, 1);
                        
                        stem(obj.properties_axis, obj.frequencies, abs(obj.coefficients), ...
                            'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                            'MarkerSize', obj.marker_size, 'DisplayName', 'Original');
                        
                        stem(obj.properties_axis, obj.frequencies, abs(shifted_coeffs), ...
                            'Color', obj.colors.secondary, 'LineWidth', obj.line_width, ...
                            'MarkerSize', obj.marker_size, 'DisplayName', 'Freq Shifted');
                        
                        xlabel(obj.properties_axis, 'Frequency Index (k)', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
                        ylabel(obj.properties_axis, 'Magnitude', 'FontSize', obj.fonts.size, 'FontWeight', 'bold');
                        title(obj.properties_axis, 'Frequency Shifting Property', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
                    end
                    
                elseif obj.scaling
                    % Demonstrate scaling property
                    scaled_signal = 2 * obj.original_signal;
                    
                    stem(obj.properties_axis, obj.sample_indices, obj.original_signal, ...
                        'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', 'Original');
                    
                    stem(obj.properties_axis, obj.sample_indices, scaled_signal, ...
                        'Color', obj.colors.secondary, 'LineWidth', obj.line_width, ...
                        'MarkerSize', obj.marker_size, 'DisplayName', 'Scaled (×2)');
                    
                    title(obj.properties_axis, 'Scaling Property', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
                end
                
            catch ME
                fprintf('DT_FS_PlotManager: Properties demo error: %s\n', ME.message);
            end
        end
        
        function plotErrorAnalysis(obj)
            % Plot error analysis
            if isempty(obj.original_signal) || isempty(obj.fourier_signal)
                return;
            end
            
            try
                % Calculate and plot error signal
                error_signal = obj.original_signal - obj.fourier_signal;
                
                % Set small error values to zero to avoid visual clutter
                error_threshold = 1e-10;  % Threshold for small values
                error_signal(abs(error_signal) < error_threshold) = 0;
                
                stem(obj.properties_axis, obj.sample_indices, error_signal, ...
                    'Color', obj.colors.error, 'LineWidth', obj.line_width, ...
                    'MarkerSize', obj.marker_size, 'MarkerFaceColor', obj.colors.error, ...
                    'DisplayName', 'Error Signal');
                
                title(obj.properties_axis, 'Error Analysis', 'FontSize', obj.fonts.title, 'FontWeight', 'bold');
                
                % Add error statistics
                mse = mean(error_signal.^2);
                rmse = sqrt(mse);
                
                text(obj.properties_axis, 0.02, 0.98, ...
                    sprintf('MSE: %.4f\nRMSE: %.4f', mse, rmse), ...
                    'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                    'FontName', obj.fonts.math, 'Color', obj.colors.error, ...
                    'BackgroundColor', 'white', 'EdgeColor', obj.colors.error, ...
                    'Interpreter', 'none', 'VerticalAlignment', 'top');
                
            catch ME
                fprintf('DT_FS_PlotManager: Error analysis error: %s\n', ME.message);
            end
        end
    end
end
