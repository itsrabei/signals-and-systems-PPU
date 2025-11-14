classdef CT_FS_PlotManager < handle
    % CT_FS_PLOT_MANAGER - Handles all plotting and visualization for CT Fourier Series
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 2.0
    %
    % This class manages all plotting functionality for the Continuous-Time Fourier
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
        time_vector = [];
        coefficients = [];
        frequencies = [];
        harmonics = [];
        
        % Display options
        show_gibbs = false;
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
        function obj = CT_FS_PlotManager()
            % Constructor - initialize plot manager
            obj.initializeColors();
            obj.initializeFonts();
        end
        
        function initializeColors(obj)
            % Initialize enhanced color scheme for CT Fourier Series
            obj.colors.bg = [0.96 0.96 0.96];
            obj.colors.panel = [1 1 1];
            obj.colors.text = [0.1 0.1 0.1];
            obj.colors.primary = [0 0.4470 0.7410];      % Blue
            obj.colors.highlight = [0.8500 0.3250 0.0980]; % Orange
            obj.colors.secondary = [0.4940 0.1840 0.5560]; % Purple
            obj.colors.harmonic = [0.2 0.8 0.2];          % Green
            obj.colors.gibbs = [0.8 0.2 0.2];             % Red
            obj.colors.orthogonal = [0.3 0.6 0.9];        % Light Blue
            obj.colors.error = [0.9 0.1 0.1];             % Dark Red
            obj.colors.convergence = [0.1 0.7 0.1];       % Dark Green
            obj.colors.ct_signal = [0.1 0.3 0.8];         % Dark Blue for CT
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
        
        function updateData(obj, original, fourier, t, coeffs, freqs, harmonics)
            % Update plot data
            obj.original_signal = original;
            obj.fourier_signal = fourier;
            obj.time_vector = t;
            obj.coefficients = coeffs;
            obj.frequencies = freqs;
            obj.harmonics = harmonics;
        end
        
        function setDisplayOptions(obj, gibbs, orthogonality, spectrum, properties, error, convergence)
            % Set display options
            if nargin >= 2, obj.show_gibbs = gibbs; end
            if nargin >= 3, obj.show_orthogonality = orthogonality; end
            if nargin >= 4, obj.show_spectrum = spectrum; end
            if nargin >= 5, obj.show_properties = properties; end
            if nargin >= 6, obj.show_error = error; end
            if nargin >= 7, obj.show_convergence = convergence; end
        end
        
        function setPropertyOptions(obj, time_shift, freq_shift, scaling)
            % Set property demonstration options
            if nargin >= 2, obj.time_shift = time_shift; end
            if nargin >= 3, obj.freq_shift = freq_shift; end
            if nargin >= 4, obj.scaling = scaling; end
        end
        
        function setPlotSettings(obj, line_width, marker_size, grid_alpha)
            % Set plot appearance settings
            if nargin >= 2, obj.line_width = line_width; end
            if nargin >= 3, obj.marker_size = marker_size; end
            if nargin >= 4, obj.grid_alpha = grid_alpha; end
        end
        
        function setMaxHarmonicsDisplay(obj, max_harmonics)
            % Set maximum number of harmonics to display
            obj.max_harmonics_display = max(1, min(max_harmonics, 20));
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
        
        function updateAllPlots(obj)
            % Update all plots with current data
            obj.updateTimeDomainPlot();
            obj.updateFrequencyDomainPlot();
            obj.updateHarmonicsPlot();
            obj.updatePropertiesPlot();
        end
        
        function updateTimeDomainPlot(obj)
            % Update time domain synthesis plot for CT signals
            try
                if isempty(obj.time_axis)
                    fprintf('CT_FS_PlotManager: Time axis not set\n');
                    return;
                end
                
                if isempty(obj.original_signal) || isempty(obj.time_vector)
                    fprintf('CT_FS_PlotManager: No signal data available\n');
                    % Clear axes to remove stale plots
                    cla(obj.time_axis);
                    text(obj.time_axis, 0.5, 0.5, 'No Signal Data Available', ...
                        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontName', 'Arial');
                    return;
                end
                
                % Validate data
                if length(obj.original_signal) ~= length(obj.time_vector)
                    fprintf('CT_FS_PlotManager: Signal and time vector length mismatch\n');
                    return;
                end
                
                cla(obj.time_axis);
                hold(obj.time_axis, 'on');
                
                % Plot original CT signal (if enabled)
                if obj.show_original_signal
                    plot(obj.time_axis, obj.time_vector, obj.original_signal, ...
                        'Color', obj.colors.ct_signal, 'LineWidth', obj.line_width, ...
                        'DisplayName', 'Original CT Signal');
                end
                
                % Plot Fourier series approximation (if enabled)
                if obj.show_fourier_signal
                    plot(obj.time_axis, obj.time_vector, obj.fourier_signal, ...
                        'Color', obj.colors.highlight, 'LineWidth', obj.line_width-0.5, ...
                        'DisplayName', 'CT Fourier Series');
                end
                
                % Highlight Gibbs phenomenon if enabled
                if obj.show_gibbs
                    error_signal = obj.original_signal - obj.fourier_signal;
                    try
                        [~, peaks] = findpeaks(abs(error_signal));
                        if ~isempty(peaks)
                            plot(obj.time_axis, obj.time_vector(peaks), obj.fourier_signal(peaks), ...
                                'ro', 'MarkerSize', obj.marker_size, 'MarkerFaceColor', obj.colors.gibbs, ...
                                'DisplayName', 'Gibbs Effect');
                        end
                    catch
                        % Skip Gibbs highlighting if findpeaks fails
                    end
                end
                
                % Show error signal if enabled
                if obj.show_error || obj.show_error_signal
                    error_signal = obj.original_signal - obj.fourier_signal;
                    plot(obj.time_axis, obj.time_vector, error_signal, ...
                        'Color', obj.colors.error, 'LineWidth', 1, 'LineStyle', '--', ...
                        'DisplayName', 'Approximation Error');
                    
                    % Add error equation
                    if obj.show_math_notation
                        text(obj.time_axis, 0.02, 0.02, ...
                            'Error: e(t) = x(t) - x_N(t)', ...
                            'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                            'FontName', obj.fonts.math, 'Color', obj.colors.error, ...
                            'BackgroundColor', 'white', 'EdgeColor', obj.colors.error, ...
                            'Interpreter', 'none', 'VerticalAlignment', 'bottom');
                    end
                end
                
                hold(obj.time_axis, 'off');
                
                % Show legend if enabled
                if obj.show_legend
                    legend(obj.time_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
                end
                
                % Set axis properties
                obj.setAxisProperties(obj.time_axis, 'CT Signal Synthesis & Fourier Approximation', ...
                    'Time (s)', 'Amplitude');
                
                % Show grid if enabled
                if obj.show_grid
                    grid(obj.time_axis, 'on');
                    obj.time_axis.GridAlpha = obj.grid_alpha;
                    obj.time_axis.GridColor = obj.colors.grid;
                else
                    grid(obj.time_axis, 'off');
                end
                
                % Enhanced dynamic limits with better scaling
                if ~isempty(obj.original_signal) && ~isempty(obj.fourier_signal)
                    y_max = max([max(abs(obj.original_signal)), max(abs(obj.fourier_signal))]) * 1.2;
                elseif ~isempty(obj.original_signal)
                    y_max = max(abs(obj.original_signal)) * 1.2;
                elseif ~isempty(obj.fourier_signal)
                    y_max = max(abs(obj.fourier_signal)) * 1.2;
                else
                    y_max = 1;
                end
                if y_max == 0, y_max = 1; end
                ylim(obj.time_axis, [-y_max, y_max]);
                
                % Dynamic xlim based on time vector
                if max(obj.time_vector) > 0
                    xlim(obj.time_axis, [0, max(obj.time_vector)]);
                else
                    xlim(obj.time_axis, [0, 1]);
                end
                
                % Add mathematical notation if enabled
                if obj.show_math_notation
                    % Use simplified mathematical notation to avoid TeX issues
                    math_text = 'x(t) = a_0 + sum[n=1 to N] [a_n*cos(n*omega_0*t) + b_n*sin(n*omega_0*t)]';
                    text(obj.time_axis, 0.02, 0.98, math_text, ...
                        'Units', 'normalized', 'FontSize', obj.fonts.size-2, 'FontName', obj.fonts.math, ...
                        'BackgroundColor', 'white', 'EdgeColor', 'black', 'Interpreter', 'none');
                end
            catch ME
                fprintf('Time domain plot error: %s\n', ME.message);
                % Display error message on plot
                cla(obj.time_axis);
                text(obj.time_axis, 0.5, 0.5, sprintf('Plot Error: %s', ME.message), ...
                    'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'red');
            end
        end
        
        function updateFrequencyDomainPlot(obj)
            % Update frequency domain spectrum plot for CT signals
            try
                if isempty(obj.freq_axis)
                    fprintf('CT_FS_PlotManager: Frequency axis not set\n');
                    return;
                end
                
                if isempty(obj.coefficients) || isempty(obj.frequencies)
                    fprintf('CT_FS_PlotManager: No frequency data available\n');
                    % Clear axes to remove stale plots
                    cla(obj.freq_axis);
                    text(obj.freq_axis, 0.5, 0.5, 'No Frequency Data Available', ...
                        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontName', 'Arial');
                    return;
                end
                
                if ~obj.show_spectrum
                    cla(obj.freq_axis);
                    text(obj.freq_axis, 0.5, 0.5, 'Spectrum Display Disabled', ...
                        'HorizontalAlignment', 'center', 'FontSize', 14, ...
                        'FontName', obj.fonts.name);
                    return;
                end
                
                % Validate data
                if length(obj.coefficients) ~= length(obj.frequencies)
                    fprintf('CT_FS_PlotManager: Coefficients and frequencies length mismatch\n');
                    return;
                end
            
                cla(obj.freq_axis);
                hold(obj.freq_axis, 'on');
                
                % Calculate magnitude spectrum properly using vectorized operations
                % This is more efficient than calculating magnitude for each coefficient individually
                magnitude = abs(obj.coefficients);
                
                % Plot magnitude spectrum with enhanced styling
                stem(obj.freq_axis, obj.frequencies, magnitude, ...
                    'Color', obj.colors.secondary, 'LineWidth', 2, ...
                    'MarkerSize', obj.marker_size, 'MarkerFaceColor', obj.colors.secondary, ...
                    'DisplayName', 'Magnitude Spectrum');
            
                % Find DC component (frequency = 0) and fundamental frequency
                dc_idx = find(obj.frequencies == 0, 1);
                fundamental_idx = find(obj.frequencies > 0, 1);
                
                % Highlight DC component
                if ~isempty(dc_idx)
                    plot(obj.freq_axis, obj.frequencies(dc_idx), magnitude(dc_idx), ...
                        'go', 'MarkerSize', obj.marker_size+2, 'MarkerFaceColor', obj.colors.primary, ...
                        'DisplayName', 'DC Component');
                end
                
                % Highlight fundamental frequency
                if ~isempty(fundamental_idx)
                    plot(obj.freq_axis, obj.frequencies(fundamental_idx), magnitude(fundamental_idx), ...
                        'ro', 'MarkerSize', obj.marker_size+2, 'MarkerFaceColor', obj.colors.highlight, ...
                        'DisplayName', 'Fundamental');
                end
                
                hold(obj.freq_axis, 'off');
                
                % Show legend if enabled
                if obj.show_legend
                    legend(obj.freq_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
                end
                
                % Set axis properties
                obj.setAxisProperties(obj.freq_axis, 'CT Fourier Series: Magnitude Spectrum', ...
                    'Frequency (Hz)', 'Magnitude');
                
            % Enhanced dynamic limits using vectorized operations
            max_magnitude = max(magnitude);
            if max_magnitude > 0
                ylim(obj.freq_axis, [0, max_magnitude*1.1]);
            else
                ylim(obj.freq_axis, [0, 1]);
            end
            
                % Dynamic xlim centered at zero frequency
                if max(obj.frequencies) > 0
                    % Find the range of frequencies (including negative frequencies)
                    min_freq = min(obj.frequencies);
                    max_freq = max(obj.frequencies);
                    
                    % Center the plot around zero
                    freq_range = max_freq - min_freq;
                    if freq_range > 0
                        xlim(obj.freq_axis, [min_freq - 0.1*freq_range, max_freq + 0.1*freq_range]);
                    else
                        xlim(obj.freq_axis, [-1, 1]);
                    end
                    
                    % Add frequency ticks for better readability with decimation
                    if max_freq > 0
                        fundamental_freq = obj.frequencies(find(obj.frequencies > 0, 1));  % First positive frequency
                        if ~isempty(fundamental_freq) && fundamental_freq > 0
                            % Set ticks at fundamental and its harmonics (including negative)
                            max_harmonic = floor(max_freq/fundamental_freq);
                            
                            % Decimate ticks to maintain readability (max ~15 tick labels)
                            if max_harmonic > 15
                                stride = ceil(max_harmonic / 15);
                                tick_freqs = fundamental_freq * (-max_harmonic:stride:max_harmonic);
                            else
                                tick_freqs = fundamental_freq * (-max_harmonic:max_harmonic);
                            end
                            
                            set(obj.freq_axis, 'XTick', tick_freqs);
                            % Format tick labels to show integer harmonics
                            tick_labels = cell(size(tick_freqs));
                            for k = 1:length(tick_freqs)
                                if tick_freqs(k) == 0
                                    tick_labels{k} = '0';
                                else
                                    harmonic_num = round(tick_freqs(k) / fundamental_freq);
                                    tick_labels{k} = sprintf('%d', harmonic_num);
                                end
                            end
                            set(obj.freq_axis, 'XTickLabel', tick_labels);
                        end
                    end
                else
                    xlim(obj.freq_axis, [-1, 1]);
                end
                
                % Add mathematical notation if enabled
                if obj.show_math_notation
                    math_text = '|X_n| = sqrt(a_n^2 + b_n^2)';
                    text(obj.freq_axis, 0.02, 0.98, math_text, ...
                        'Units', 'normalized', 'FontSize', obj.fonts.size-2, 'FontName', obj.fonts.math, ...
                        'BackgroundColor', 'white', 'EdgeColor', 'black', 'Interpreter', 'none');
                end
            catch ME
                fprintf('Frequency domain plot error: %s\n', ME.message);
                % Display error message on plot
                cla(obj.freq_axis);
                text(obj.freq_axis, 0.5, 0.5, sprintf('Spectrum Error: %s', ME.message), ...
                    'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'red');
            end
        end
        
        function updateHarmonicsPlot(obj)
            % Update individual harmonics plot for CT signals
            if isempty(obj.harmonics_axis) || isempty(obj.harmonics), return; end
            
            cla(obj.harmonics_axis);
            
            % Plot individual harmonics (limit based on max_harmonics_display setting)
            max_harmonics_to_show = min(obj.max_harmonics_display, size(obj.harmonics, 1));
            colors = lines(max_harmonics_to_show);
            
            for i = 1:max_harmonics_to_show
                harmonic_name = sprintf('Harmonic %d', i-1);
                if i == 1
                    harmonic_name = 'DC Component';
                end
                
                plot(obj.harmonics_axis, obj.time_vector, obj.harmonics(i,:), ...
                    'Color', colors(i,:), 'LineWidth', obj.line_width-0.5, ...
                    'DisplayName', harmonic_name);
                hold(obj.harmonics_axis, 'on');
            end
            
            hold(obj.harmonics_axis, 'off');
            legend(obj.harmonics_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
            
            % Set axis properties
            obj.setAxisProperties(obj.harmonics_axis, 'CT Fourier Series: Individual Harmonics', ...
                'Time (s)', 'Amplitude');
            
            % Enhanced dynamic limits
            y_max = max(abs(obj.harmonics(:))) * 1.1;
            if y_max == 0, y_max = 1; end
            ylim(obj.harmonics_axis, [-y_max, y_max]);
            
            % Dynamic xlim based on time vector
            if max(obj.time_vector) > 0
                xlim(obj.harmonics_axis, [0, max(obj.time_vector)]);
            else
                xlim(obj.harmonics_axis, [0, 1]);
            end
            
            % Add mathematical notation
            math_text = 'x_n(t) = a_n*cos(n*omega_0*t) + b_n*sin(n*omega_0*t)';
            text(obj.harmonics_axis, 0.02, 0.98, math_text, ...
                'Units', 'normalized', 'FontSize', obj.fonts.size-2, 'FontName', obj.fonts.math, ...
                'BackgroundColor', 'white', 'EdgeColor', 'black', 'Interpreter', 'none');
        end
        
        function updatePropertiesPlot(obj)
            % Update properties and analysis plot for CT signals
            if isempty(obj.properties_axis), return; end
            
            cla(obj.properties_axis);
            
            if obj.show_orthogonality
                obj.plotOrthogonalityDemo();
            elseif obj.show_convergence
                obj.plotConvergenceDemo();
            else
                obj.plotPropertiesDemo();
            end
        end
        
        function plotOrthogonalityDemo(obj)
            % Plot orthogonality demonstration for CT signals
            if isempty(obj.time_vector), return; end
            
            % Use fundamental frequency from coefficients
            f0 = 1;  % Default
            if ~isempty(obj.frequencies)
                positive_freqs = obj.frequencies(obj.frequencies > 0);
                if ~isempty(positive_freqs)
                    f0 = positive_freqs(1);  % First positive frequency
                end
            end
            
            % Create two different harmonics
            n1 = 1; n2 = 2;
            omega1 = 2*pi*n1*f0;
            omega2 = 2*pi*n2*f0;
            h1 = cos(omega1*obj.time_vector);
            h2 = cos(omega2*obj.time_vector);
            product = h1 .* h2;
            
            % Plot harmonics
            plot(obj.properties_axis, obj.time_vector, h1, ...
                'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                'DisplayName', sprintf('cos(%d\\omega_0t)', n1));
            hold(obj.properties_axis, 'on');
            
            plot(obj.properties_axis, obj.time_vector, h2, ...
                'Color', obj.colors.highlight, 'LineWidth', obj.line_width, ...
                'DisplayName', sprintf('cos(%d\\omega_0t)', n2));
            
            plot(obj.properties_axis, obj.time_vector, product, ...
                'Color', [1 0.5 0], 'LineWidth', obj.line_width+2, ...
                'DisplayName', 'Product (Orthogonal)');
            
            hold(obj.properties_axis, 'off');
            legend(obj.properties_axis, 'Location', 'best', 'FontSize', obj.fonts.size+2);
            
            obj.setAxisProperties(obj.properties_axis, ...
                'CT Orthogonality: cos(n_1*omega_0*t) perp cos(n_2*omega_0*t)', ...
                'Time (s)', 'Amplitude');
            
            % Dynamic ylim based on data content
            if ~isempty(h1) && ~isempty(h2) && ~isempty(product)
                y_max = max([max(abs(h1)), max(abs(h2)), max(abs(product))]) * 1.2;
            else
                y_max = 1.2;
            end
            ylim(obj.properties_axis, [-y_max, y_max]);
            
            % Dynamic xlim based on time vector
            if max(obj.time_vector) > 0
                xlim(obj.properties_axis, [0, max(obj.time_vector)]);
            else
                xlim(obj.properties_axis, [0, 1]);
            end
        end
        
        function plotConvergenceDemo(obj)
            % Plot convergence demonstration - MSE vs Number of Harmonics
            if isempty(obj.original_signal), return; end
            
            % Calculate convergence data for different numbers of harmonics
            max_harmonics = min(20, obj.max_harmonics_display * 2);
            N_values = 1:max_harmonics;
            mse_values = zeros(size(N_values));
            
            % Get fundamental frequency
            f0 = 1;  % Default
            if ~isempty(obj.frequencies)
                positive_freqs = obj.frequencies(obj.frequencies > 0);
                if ~isempty(positive_freqs)
                    f0 = positive_freqs(1);
                end
            end
            
            % Pre-calculate all coefficients for maximum efficiency
            try
                [all_coeffs, all_freqs] = obj.fourier_math.calculateFourierCoefficients(obj.original_signal, obj.time_vector, max_harmonics, f0);
                precomputed = true;
            catch
                precomputed = false;
            end
            
            % Calculate MSE for each number of harmonics using precomputed data
            % Vectorized approach for better performance
            for i = 1:length(N_values)
                try
                    if precomputed
                        % Use precomputed coefficients - much more efficient
                        fourier_signal = obj.fourier_math.synthesizeFourierSeries(obj.time_vector, all_coeffs, all_freqs, N_values(i));
                    else
                        % Fallback to individual calculation
                        [coeffs, freqs] = obj.fourier_math.calculateFourierCoefficients(obj.original_signal, obj.time_vector, N_values(i), f0);
                        fourier_signal = obj.fourier_math.synthesizeFourierSeries(obj.time_vector, coeffs, freqs, N_values(i));
                    end
                    
                    % Calculate MSE using vectorized operations
                    error_signal = obj.original_signal - fourier_signal;
                    mse_values(i) = mean(error_signal.^2);  % Vectorized mean and power operations
                catch
                    mse_values(i) = NaN;
                end
            end
            
            % Plot convergence curve
            plot(obj.properties_axis, N_values, mse_values, ...
                'Color', obj.colors.convergence, 'LineWidth', obj.line_width, ...
                'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', obj.colors.convergence, ...
                'DisplayName', 'MSE vs Harmonics');
            
            % Add convergence equation
            if obj.show_math_notation
                text(obj.properties_axis, 0.02, 0.98, ...
                    'Convergence: MSE(N) = E[|x(t) - x_N(t)|^2]', ...
                    'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                    'FontName', obj.fonts.math, 'Color', obj.colors.convergence, ...
                    'BackgroundColor', 'white', 'EdgeColor', obj.colors.convergence, ...
                    'Interpreter', 'none', 'VerticalAlignment', 'top');
            end
            
            obj.setAxisProperties(obj.properties_axis, ...
                'CT Fourier Series Convergence: MSE vs Number of Harmonics', ...
                'Number of Harmonics (N)', 'Mean Square Error');
            
            % Set appropriate limits with robustness
            finite_mse = mse_values(isfinite(mse_values));
            if ~isempty(finite_mse)
                ylim(obj.properties_axis, [0, max(finite_mse)*1.1]);
            else
                ylim(obj.properties_axis, [0, 1]);
            end
            xlim(obj.properties_axis, [1, max(N_values)]);
        end
        
        function plotPropertiesDemo(obj)
            % Plot properties demonstration for CT signals
            if isempty(obj.original_signal), return; end
            
            f0 = 1;  % Default frequency
            if ~isempty(obj.frequencies)
                positive_freqs = obj.frequencies(obj.frequencies > 0);
                if ~isempty(positive_freqs)
                    f0 = positive_freqs(1);  % First positive frequency
                end
            end
            
            T = 1/f0;
            
            if obj.time_shift
                % Time shifting demonstration
                shift = T/4;
                shifted_signal = interp1(obj.time_vector, obj.original_signal, ...
                    obj.time_vector - shift, 'linear', 'extrap');
                
                plot(obj.properties_axis, obj.time_vector, obj.original_signal, ...
                    'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                    'DisplayName', 'Original x(t)');
                hold(obj.properties_axis, 'on');
                plot(obj.properties_axis, obj.time_vector, shifted_signal, ...
                    'Color', obj.colors.highlight, 'LineWidth', obj.line_width, ...
                    'DisplayName', 'x(t-τ)');
                hold(obj.properties_axis, 'off');
                
                obj.setAxisProperties(obj.properties_axis, 'CT Time Shifting Property', ...
                    'Time (s)', 'Amplitude');
                
            elseif obj.freq_shift
                % Frequency shifting demonstration - proper Fourier Series property
                % Demonstrates x(t)e^(jωc*t) ↔ X(ω-ωc)
                f_shift = f0 * 0.5;  % Shift frequency
                omega_c = 2*pi*f_shift;
                
                % Create frequency-shifted signal: x(t) * e^(jωc*t)
                % For real signals, we use x(t) * cos(ωc*t) to show the effect
                freq_shifted = obj.original_signal .* cos(omega_c * obj.time_vector);
                
                plot(obj.properties_axis, obj.time_vector, obj.original_signal, ...
                    'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                    'DisplayName', 'Original x(t)');
                hold(obj.properties_axis, 'on');
                plot(obj.properties_axis, obj.time_vector, freq_shifted, ...
                    'Color', obj.colors.highlight, 'LineWidth', obj.line_width, ...
                    'DisplayName', 'x(t)cos(ω_c t)');
                
                % Add mathematical notation
                if obj.show_math_notation
                    text(obj.properties_axis, 0.02, 0.98, ...
                        'Frequency Shifting: x(t)*e^(j*omega_c*t) <-> X(omega-omega_c)', ...
                        'Units', 'normalized', 'FontSize', obj.fonts.size-2, ...
                        'FontName', obj.fonts.math, 'Color', obj.colors.highlight, ...
                        'BackgroundColor', 'white', 'EdgeColor', obj.colors.highlight, ...
                        'Interpreter', 'none', 'VerticalAlignment', 'top');
                end
                
                hold(obj.properties_axis, 'off');
                
                obj.setAxisProperties(obj.properties_axis, 'CT Frequency Shifting Property', ...
                    'Time (s)', 'Amplitude');
                
            elseif obj.scaling
                % Scaling demonstration
                scaled_signal = obj.original_signal * 2;
                
                plot(obj.properties_axis, obj.time_vector, obj.original_signal, ...
                    'Color', obj.colors.primary, 'LineWidth', obj.line_width, ...
                    'DisplayName', 'Original x(t)');
                hold(obj.properties_axis, 'on');
                plot(obj.properties_axis, obj.time_vector, scaled_signal, ...
                    'Color', obj.colors.highlight, 'LineWidth', obj.line_width, ...
                    'DisplayName', 'Scaled ax(t)');
                hold(obj.properties_axis, 'off');
                
                obj.setAxisProperties(obj.properties_axis, 'CT Scaling Property', ...
                    'Time (s)', 'Amplitude');
                
            else
                % Default: show approximation error
                error_signal = obj.original_signal - obj.fourier_signal;
                plot(obj.properties_axis, obj.time_vector, error_signal, ...
                    'Color', obj.colors.gibbs, 'LineWidth', obj.line_width-0.5, ...
                    'DisplayName', 'CT Approximation Error');
                
                obj.setAxisProperties(obj.properties_axis, ...
                    'CT Fourier Series Approximation Error (Gibbs Phenomenon)', ...
                    'Time (s)', 'Amplitude');
            end
            
            y_max = max(abs(obj.original_signal)) * 1.2;
            ylim(obj.properties_axis, [-y_max, y_max]);
            xlim(obj.properties_axis, [0, max(obj.time_vector)]);
        end
        
        function setAxisProperties(obj, axis_handle, title_text, xlabel_text, ylabel_text)
            % Set enhanced axis properties for CT signals
            title(axis_handle, title_text, 'FontSize', obj.fonts.title, 'FontWeight', 'bold', ...
                'FontName', obj.fonts.name);
            xlabel(axis_handle, xlabel_text, 'FontSize', obj.fonts.size, 'FontName', obj.fonts.name);
            ylabel(axis_handle, ylabel_text, 'FontSize', obj.fonts.size, 'FontName', obj.fonts.name);
            grid(axis_handle, 'on');
            axis_handle.FontSize = obj.fonts.size;
            axis_handle.FontName = obj.fonts.name;
            axis_handle.GridAlpha = obj.grid_alpha;
        end
        
        function exportPlots(obj, filename)
            % Export all plots to file with enhanced formatting
            if isempty(filename), return; end
            
            try
                % Create figure with subplots
                fig = figure('Visible', 'off', 'Position', [100 100 1400 900]);
                
                % Time domain
                subplot(2,2,1);
                if ~isempty(obj.time_axis) && isvalid(obj.time_axis)
                    obj.updateTimeDomainPlot();
                    if ~isempty(obj.time_axis.Children)
                        copyobj(obj.time_axis.Children, gca);
                    end
                end
                title('CT Signal Synthesis & Fourier Approximation');
                
                % Frequency domain
                subplot(2,2,2);
                if ~isempty(obj.freq_axis) && isvalid(obj.freq_axis)
                    obj.updateFrequencyDomainPlot();
                    if ~isempty(obj.freq_axis.Children)
                        copyobj(obj.freq_axis.Children, gca);
                    end
                end
                title('CT Fourier Series: Magnitude Spectrum');
                
                % Harmonics
                subplot(2,2,3);
                if ~isempty(obj.harmonics_axis) && isvalid(obj.harmonics_axis)
                    obj.updateHarmonicsPlot();
                    if ~isempty(obj.harmonics_axis.Children)
                        copyobj(obj.harmonics_axis.Children, gca);
                    end
                end
                title('CT Fourier Series: Individual Harmonics');
                
                % Properties
                subplot(2,2,4);
                if ~isempty(obj.properties_axis) && isvalid(obj.properties_axis)
                    obj.updatePropertiesPlot();
                    if ~isempty(obj.properties_axis.Children)
                        copyobj(obj.properties_axis.Children, gca);
                    end
                end
                title('CT Properties & Analysis');
                
                % Save figure in the requested format only
                [~, name, ext] = fileparts(filename);
                if isempty(ext)
                    % If no extension provided, default to PNG
                    saveas(fig, [filename '.png']);
                else
                    % Save in the requested format
                    saveas(fig, filename);
                end
                
                close(fig);
                
            catch ME
                fprintf('Export error: %s\n', ME.message);
            end
        end
        
        function exportData(obj, filename)
            % Export numerical data to file
            if isempty(filename), return; end
            
            try
                data = struct();
                data.time_vector = obj.time_vector;
                data.original_signal = obj.original_signal;
                data.fourier_signal = obj.fourier_signal;
                data.coefficients = obj.coefficients;
                data.frequencies = obj.frequencies;
                data.harmonics = obj.harmonics;
                
                save(filename, 'data');
                
            catch ME
                fprintf('Data export error: %s\n', ME.message);
            end
        end
        
    end
end
