classdef DT_plot_manager < handle
    % PlotManager - Visualization Management for Convolution Visualizer
    %
    % This class handles all plotting operations for the convolution visualizer.
    % It manages signal display, animation updates, and provides unified
    % visualization with proper scaling and responsive limits.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Features:
    % - Signal plotting with proper scaling
    % - Animation step visualization
    % - Unified x-axis limits for clear operation view
    % - Responsive plot updates
    % - Export functionality
    
    properties (Access = private)
        XAxes, HAxes, AnimationAxes, ProductAxes, OutputAxes
        XPlot, HPlot, AnimXPlot, AnimHPlot, ProductPlot, OutputPlot
        Colors = struct('x', [0 0.4470 0.7410], 'h', [0.8500 0.3250 0.0980], ...
            'prod', [0.9 0.6 0.0], 'out', [0.2 0.7 0.2], ...
            'active', [1.0 0.0 0.0], 'highlight', [0.0 0.0 1.0]);
        % NEW: Store master xlim for all animation plots
        MasterXLimits
        MasterYLimits
    end

    methods
        function initialize(obj, x_ax, h_ax, anim_ax, prod_ax, out_ax)
            try
                fprintf('PlotManager: Initializing with unified xlim support...\n');
                
                obj.XAxes = x_ax;
                obj.HAxes = h_ax;
                obj.AnimationAxes = anim_ax;
                obj.ProductAxes = prod_ax;
                obj.OutputAxes = out_ax;
                
                obj.configureAxesSafely();
                fprintf('PlotManager: Initialization successful!\n');
                
            catch ME
                fprintf('PlotManager initialization error: %s\n', ME.message);
                error('PlotManager:InitError', 'Failed to initialize PlotManager: %s', ME.message);
            end
        end

        function displayInitialSignals(obj, x_sig, h_sig, n_vec)
            obj.displayInitialSignalsWithCorrectLimits(x_sig, h_sig, n_vec);
        end

        function displayInitialSignalsWithCorrectLimits(obj, x_sig, h_sig, n_vec)
            % FIXED: Display with proper time vector response and dynamic limits
            try
                fprintf('PlotManager: Displaying signals with correct limits and time vector response...\n');
                
                obj.validatePlotInputsFixed(x_sig, h_sig, n_vec);
                obj.clearInitialPlotsSafely();

                % FIXED: Calculate master limits that respond to time vector changes
                obj.calculateMasterLimits(x_sig, h_sig, n_vec);

                % Create x[n] plot
                if obj.isValidAxes(obj.XAxes)
                    try
                        n_vec_plot = n_vec(:)';
                        x_sig_plot = x_sig(:)';
                        
                        % Ensure same size
                        min_len = min(numel(n_vec_plot), numel(x_sig_plot));
                        n_vec_plot = n_vec_plot(1:min_len);
                        x_sig_plot = x_sig_plot(1:min_len);
                        
                        obj.XPlot = stem(obj.XAxes, n_vec_plot, x_sig_plot, 'Color', obj.Colors.x, ...
                            'LineWidth', 2.5, 'MarkerFaceColor', obj.Colors.x, 'MarkerSize', 8);
                        
                        % FIXED: Apply responsive limits
                        obj.applyResponsiveXLimits(obj.XAxes, n_vec_plot);
                        obj.applyResponsiveYLimits(obj.XAxes, x_sig_plot);
                        
                        title(obj.XAxes, sprintf('x[n] | Range: [%.1f, %.1f] | Values: [%.3f, %.3f]', ...
                            min(n_vec_plot), max(n_vec_plot), min(x_sig_plot), max(x_sig_plot)), 'FontWeight', 'bold');
                        xlabel(obj.XAxes, 'n', 'FontWeight', 'bold');
                        ylabel(obj.XAxes, 'Amplitude', 'FontWeight', 'bold');
                        grid(obj.XAxes, 'on');
                        
                        fprintf('PlotManager: x[n] plot created with responsive limits\n');
                    catch ME
                        fprintf('Error plotting x signal: %s\n', ME.message);
                    end
                end
                
                % Create h[n] plot
                if obj.isValidAxes(obj.HAxes)
                    try
                        n_vec_plot = n_vec(:)';
                        h_sig_plot = h_sig(:)';
                        
                        min_len = min(numel(n_vec_plot), numel(h_sig_plot));
                        n_vec_plot = n_vec_plot(1:min_len);
                        h_sig_plot = h_sig_plot(1:min_len);
                        
                        obj.HPlot = stem(obj.HAxes, n_vec_plot, h_sig_plot, 'Color', obj.Colors.h, ...
                            'LineWidth', 2.5, 'MarkerFaceColor', obj.Colors.h, 'MarkerSize', 8);
                        
                        obj.applyResponsiveXLimits(obj.HAxes, n_vec_plot);
                        obj.applyResponsiveYLimits(obj.HAxes, h_sig_plot);
                        
                        title(obj.HAxes, sprintf('h[n] | Range: [%.1f, %.1f] | Values: [%.3f, %.3f]', ...
                            min(n_vec_plot), max(n_vec_plot), min(h_sig_plot), max(h_sig_plot)), 'FontWeight', 'bold');
                        xlabel(obj.HAxes, 'k', 'FontWeight', 'bold');
                        ylabel(obj.HAxes, 'Amplitude', 'FontWeight', 'bold');
                        grid(obj.HAxes, 'on');
                        
                        fprintf('PlotManager: h[n] plot created with responsive limits\n');
                    catch ME
                        fprintf('Error plotting h signal: %s\n', ME.message);
                    end
                end

                fprintf('PlotManager: Initial signals displayed with proper time vector response!\n');
                
            catch ME
                fprintf('PlotManager display error: %s\n', ME.message);
            end
        end

        function setupAnimationPlots(obj, x_sig, h_sig, n_vec, n_out)
            % FIXED: Setup with unified xlim for animation, product, and output
            try
                fprintf('PlotManager: Setting up animation plots with UNIFIED xlim...\n');
                
                obj.validatePlotInputsFixed(x_sig, h_sig, n_vec);
                obj.clearAnimationPlotsSafely();
                
                % Display initial signals first
                obj.displayInitialSignalsWithCorrectLimits(x_sig, h_sig, n_vec);

                % FIXED: Calculate unified xlim for all animation plots based on OUTPUT range
                if ~isempty(n_out)
                    output_min = min(n_out);
                    output_max = max(n_out);
                    output_range = output_max - output_min;
                    padding = max(output_range * 0.1, 0.5); % 10% padding minimum 0.5
                    obj.MasterXLimits = [output_min - padding, output_max + padding];
                    fprintf('Master xlim set to [%.2f, %.2f] based on output range\n', obj.MasterXLimits);
                else
                    % Fallback to input range
                    input_min = min(n_vec);
                    input_max = max(n_vec);
                    input_range = input_max - input_min;
                    padding = max(input_range * 0.15, 0.5);
                    obj.MasterXLimits = [input_min - padding, input_max + padding];
                end

                % Setup animation axes with UNIFIED xlim
                if obj.isValidAxes(obj.AnimationAxes)
                    try
                        n_vec_anim = n_vec(:)';
                        x_sig_anim = x_sig(:)';
                        
                        min_len = min(numel(n_vec_anim), numel(x_sig_anim));
                        n_vec_anim = n_vec_anim(1:min_len);
                        x_sig_anim = x_sig_anim(1:min_len);
                        
                        hold(obj.AnimationAxes, 'on');
                        obj.AnimXPlot = stem(obj.AnimationAxes, n_vec_anim, x_sig_anim, 'Color', obj.Colors.x, ...
                            'LineWidth', 2.5, 'DisplayName', 'x[k]', 'MarkerFaceColor', obj.Colors.x, 'MarkerSize', 8);
                        
                        obj.AnimHPlot = stem(obj.AnimationAxes, n_vec_anim, zeros(size(n_vec_anim)), ...
                            'Color', obj.Colors.h, 'LineWidth', 2.5, 'DisplayName', 'h[n-k]', ...
                            'MarkerFaceColor', obj.Colors.h, 'MarkerSize', 8);
                        hold(obj.AnimationAxes, 'off');
                        
                        legend(obj.AnimationAxes, 'Location', 'northeast', 'FontSize', 10);
                        
                        % UNIFIED xlim for animation
                        xlim(obj.AnimationAxes, obj.MasterXLimits);
                        obj.setSmartYLimitsForAnimation(obj.AnimationAxes, x_sig_anim, h_sig);
                        
                        title(obj.AnimationAxes, 'Animation: x[k] and h[n-k]', 'FontWeight', 'bold');
                        xlabel(obj.AnimationAxes, 'k', 'FontWeight', 'bold');
                        ylabel(obj.AnimationAxes, 'Amplitude', 'FontWeight', 'bold');
                        grid(obj.AnimationAxes, 'on');
                        
                        fprintf('Animation plot: UNIFIED xlim = [%.2f, %.2f]\n', obj.MasterXLimits);
                    catch ME
                        fprintf('Error setting up animation axes: %s\n', ME.message);
                    end
                end

                % Setup product plot with SAME xlim as animation
                if obj.isValidAxes(obj.ProductAxes)
                    try
                        n_vec_prod = n_vec(:)';
                        obj.ProductPlot = stem(obj.ProductAxes, n_vec_prod, zeros(size(n_vec_prod)), ...
                            'Color', obj.Colors.prod, 'LineWidth', 2.5, ...
                            'MarkerFaceColor', obj.Colors.prod, 'MarkerSize', 8);
                        
                        % UNIFIED xlim for product (same as animation)
                        xlim(obj.ProductAxes, obj.MasterXLimits);
                        obj.setSmartYLimitsForProduct(obj.ProductAxes, x_sig, h_sig);
                        
                        title(obj.ProductAxes, 'Product: x[k] × h[n-k]', 'FontWeight', 'bold');
                        xlabel(obj.ProductAxes, 'k', 'FontWeight', 'bold');
                        ylabel(obj.ProductAxes, 'Product', 'FontWeight', 'bold');
                        grid(obj.ProductAxes, 'on');
                        
                        fprintf('Product plot: UNIFIED xlim = [%.2f, %.2f]\n', obj.MasterXLimits);
                    catch ME
                        fprintf('Error setting up product axes: %s\n', ME.message);
                    end
                end

                % Setup output plot with MATCHED xlim
                if obj.isValidAxes(obj.OutputAxes) && ~isempty(n_out)
                    try
                        n_out_plot = n_out(:)';
                        obj.OutputPlot = stem(obj.OutputAxes, n_out_plot, nan(size(n_out_plot)), ...
                            'Color', obj.Colors.out, 'LineWidth', 2.5, ...
                            'MarkerFaceColor', obj.Colors.out, 'MarkerSize', 8);
                        
                        % MATCHED xlim for output (same range as animation for clarity)
                        xlim(obj.OutputAxes, obj.MasterXLimits);
                        obj.setSmartYLimitsForOutput(obj.OutputAxes, x_sig, h_sig);
                        
                        title(obj.OutputAxes, sprintf('Output y[n] - Range: [%.1f, %.1f]', min(n_out), max(n_out)), 'FontWeight', 'bold');
                        xlabel(obj.OutputAxes, 'n', 'FontWeight', 'bold');
                        ylabel(obj.OutputAxes, 'y[n]', 'FontWeight', 'bold');
                        grid(obj.OutputAxes, 'on');
                        
                        fprintf('Output plot: UNIFIED xlim = [%.2f, %.2f]\n', obj.MasterXLimits);
                    catch ME
                        fprintf('Error setting up output axes: %s\n', ME.message);
                    end
                end

                fprintf('PlotManager: Animation plots setup with UNIFIED xlim for clear operation visibility!\n');
                
            catch ME
                fprintf('PlotManager animation setup error: %s\n', ME.message);
            end
        end

        function updateAnimationStep(obj, h_shifted, product, current_y, ~, current_idx)
            % IMPROVED: Update animation step with better performance and visualization
            try
                % Update h[n-k] with improved performance
                if obj.isValidPlot(obj.AnimHPlot) && ~isempty(h_shifted)
                    try
                        % Ensure proper size matching
                        if numel(h_shifted) == numel(obj.AnimHPlot.YData)
                            obj.AnimHPlot.YData = h_shifted;
                        else
                            % Resize if needed
                            current_xdata = obj.AnimHPlot.XData;
                            h_shifted_resized = zeros(size(current_xdata));
                            copy_length = min(numel(h_shifted), numel(h_shifted_resized));
                            h_shifted_resized(1:copy_length) = h_shifted(1:copy_length);
                            obj.AnimHPlot.YData = h_shifted_resized;
                        end
                        
                        % Visual feedback for non-zero values
                        if sum(abs(h_shifted)) > 1e-10
                            obj.AnimHPlot.MarkerEdgeColor = [0.9 0.1 0.1];
                            obj.AnimHPlot.LineWidth = 3;
                            obj.AnimHPlot.MarkerSize = 10;
                            obj.updateYLimIfNeeded(obj.AnimationAxes, h_shifted);
                        else
                            obj.AnimHPlot.MarkerEdgeColor = obj.Colors.h;
                            obj.AnimHPlot.LineWidth = 2.5;
                            obj.AnimHPlot.MarkerSize = 8;
                        end
                    catch ME
                        fprintf('Error updating h_shifted plot: %s\n', ME.message);
                    end
                end

                % Update product with improved performance
                if obj.isValidPlot(obj.ProductPlot) && ~isempty(product)
                    try
                        % Ensure proper size matching
                        if numel(product) == numel(obj.ProductPlot.YData)
                            obj.ProductPlot.YData = product;
                        else
                            % Resize if needed
                            current_xdata = obj.ProductPlot.XData;
                            product_resized = zeros(size(current_xdata));
                            copy_length = min(numel(product), numel(product_resized));
                            product_resized(1:copy_length) = product(1:copy_length);
                            obj.ProductPlot.YData = product_resized;
                        end
                        
                        % Visual feedback for non-zero values
                        if sum(abs(product)) > 1e-10
                            obj.ProductPlot.MarkerEdgeColor = [0.1 0.9 0.1];
                            obj.ProductPlot.LineWidth = 3;
                            obj.ProductPlot.MarkerSize = 10;
                            obj.updateYLimIfNeeded(obj.ProductAxes, product);
                        else
                            obj.ProductPlot.MarkerEdgeColor = obj.Colors.prod;
                            obj.ProductPlot.LineWidth = 2.5;
                            obj.ProductPlot.MarkerSize = 8;
                        end
                        
                        % Update product title with current sum
                        product_sum = sum(product);
                        if obj.isValidAxes(obj.ProductAxes)
                            title(obj.ProductAxes, sprintf('Product: x[k] × h[n-k] (Sum: %.3f)', product_sum), 'FontWeight', 'bold');
                        end
                    catch ME
                        fprintf('Error updating product plot: %s\n', ME.message);
                    end
                end

                % Update output with improved performance
                if obj.isValidPlot(obj.OutputPlot)
                    try
                        if current_idx <= numel(obj.OutputPlot.YData)
                            obj.OutputPlot.YData(current_idx) = current_y;
                            
                            % Update y-limits if we have a valid value
                            if ~isnan(current_y) && isfinite(current_y)
                                obj.updateYLimForValue(obj.OutputAxes, current_y);
                                
                                % Visual feedback for new output value
                                obj.OutputPlot.MarkerEdgeColor = [0.1 0.1 0.9];
                                obj.OutputPlot.LineWidth = 3;
                                obj.OutputPlot.MarkerSize = 10;
                            else
                                % Reset visual feedback for cleared values
                                obj.OutputPlot.MarkerEdgeColor = obj.Colors.out;
                                obj.OutputPlot.LineWidth = 2.5;
                                obj.OutputPlot.MarkerSize = 8;
                            end
                        end
                    catch ME
                        fprintf('Error updating output plot: %s\n', ME.message);
                    end
                end

                % Improved drawing for better performance
                try
                    drawnow limitrate nocallbacks; % More efficient drawing
                catch ME
                    fprintf('Error in drawnow: %s\n', ME.message);
                end

            catch ME
                fprintf('PlotManager animation update error: %s\n', ME.message);
            end
        end

        function clearAllPlots(obj)
            obj.clearInitialPlotsSafely();
            obj.clearAnimationPlotsSafely();
        end

        function updateOutputPlot(obj, output_array)
            % Update the entire output plot with the given array
            if obj.isValidPlot(obj.OutputPlot) && ~isempty(output_array)
                try
                    % Ensure the array size matches the plot
                    if numel(output_array) == numel(obj.OutputPlot.YData)
                        obj.OutputPlot.YData = output_array;
                    else
                        % Resize if needed
                        current_xdata = obj.OutputPlot.XData;
                        output_resized = zeros(size(current_xdata));
                        copy_length = min(numel(output_array), numel(output_resized));
                        output_resized(1:copy_length) = output_array(1:copy_length);
                        obj.OutputPlot.YData = output_resized;
                    end
                    
                    % Update y-limits based on the array
                    obj.updateYLimIfNeeded(obj.OutputAxes, output_array);
                    
                catch ME
                    fprintf('Error updating output plot: %s\n', ME.message);
                end
            end
        end

        function displaySeparateSignals(obj, x_sig, h_sig, nx_vec, nh_vec)
            % FIXED: Display separate signals with proper time vector response
            try
                % Calculate responsive limits for separate signals
                x_range = max(nx_vec) - min(nx_vec);
                h_range = max(nh_vec) - min(nh_vec);
                
                if obj.isValidAxes(obj.XAxes)
                    cla(obj.XAxes);
                    stem(obj.XAxes, nx_vec, x_sig, 'Color', obj.Colors.x, ...
                        'LineWidth', 2.5, 'MarkerFaceColor', obj.Colors.x, 'MarkerSize', 8);
                    
                    % FIXED: Responsive xlim for separate x[n]
                    x_padding = max(x_range * 0.15, 0.5);
                    xlim(obj.XAxes, [min(nx_vec) - x_padding, max(nx_vec) + x_padding]);
                    obj.applyResponsiveYLimits(obj.XAxes, x_sig);
                    
                    title(obj.XAxes, sprintf('x[n] | nx: [%.1f:%.1f] | Values: [%.3f, %.3f]', ...
                        min(nx_vec), max(nx_vec), min(x_sig), max(x_sig)), 'FontWeight', 'bold');
                    xlabel(obj.XAxes, 'nx', 'FontWeight', 'bold');
                    ylabel(obj.XAxes, 'Amplitude', 'FontWeight', 'bold');
                    grid(obj.XAxes, 'on');
                end
                
                if obj.isValidAxes(obj.HAxes)
                    cla(obj.HAxes);
                    stem(obj.HAxes, nh_vec, h_sig, 'Color', obj.Colors.h, ...
                        'LineWidth', 2.5, 'MarkerFaceColor', obj.Colors.h, 'MarkerSize', 8);
                    
                    % FIXED: Responsive xlim for separate h[n]
                    h_padding = max(h_range * 0.15, 0.5);
                    xlim(obj.HAxes, [min(nh_vec) - h_padding, max(nh_vec) + h_padding]);
                    obj.applyResponsiveYLimits(obj.HAxes, h_sig);
                    
                    title(obj.HAxes, sprintf('h[n] | nh: [%.1f:%.1f] | Values: [%.3f, %.3f]', ...
                        min(nh_vec), max(nh_vec), min(h_sig), max(h_sig)), 'FontWeight', 'bold');
                    xlabel(obj.HAxes, 'nh', 'FontWeight', 'bold');
                    ylabel(obj.HAxes, 'Amplitude', 'FontWeight', 'bold');
                    grid(obj.HAxes, 'on');
                end
                
                fprintf('PlotManager: Separate signals displayed with responsive time vector limits\n');
                
            catch ME
                fprintf('Error displaying separate signals: %s\n', ME.message);
            end
        end

        % Include export functionality
        function exportPlots(obj, filename)
            fig = [];
            
            try
                fprintf('PlotManager: Exporting plots to %s...\n', filename);
                
                fig = figure('Visible', 'off', 'Position', [100, 100, 1400, 2000], ...
                    'Color', 'white', 'PaperPositionMode', 'auto');

                t = tiledlayout(fig, 5, 1, 'Padding', 'compact', 'TileSpacing', 'normal');

                axes_list = {obj.AnimationAxes, obj.ProductAxes, obj.OutputAxes, obj.XAxes, obj.HAxes};
                titles_list = {'Animation: x[k] and h[n-k] - UNIFIED xlim', ...
                              'Product: x[k] × h[n-k] - UNIFIED xlim', ...
                              'Output y[n] - UNIFIED xlim', ...
                              'Original Signal x[n] - Responsive xlim', ...
                              'Original Signal h[n] - Responsive xlim'};

                for i = 1:numel(axes_list)
                    try
                        ax = nexttile(t);
                        if obj.isValidAxes(axes_list{i})
                            obj.copyAxesContentSafely(axes_list{i}, ax);
                        end
                        title(ax, titles_list{i}, 'FontWeight', 'bold', 'FontSize', 14);
                    catch ME
                        fprintf('Error copying axes %d: %s\n', i, ME.message);
                    end
                end

                sgtitle(t, 'Corrected Convolution Visualizer - UNIFIED xlim & Time Vector Response', ...
                    'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);

                try
                    [~, ~, ext] = fileparts(filename);
                    if strcmpi(ext, '.pdf')
                        exportgraphics(t, filename, 'ContentType', 'vector', ...
                            'BackgroundColor', 'white', 'Resolution', 300);
                    else
                        exportgraphics(t, filename, 'Resolution', 300, ...
                            'BackgroundColor', 'white');
                    end
                    fprintf('PlotManager: Export successful!\n');
                catch ME
                    fprintf('Error during export: %s\n', ME.message);
                    error('PlotManager:ExportError', 'Failed to export: %s', ME.message);
                end

                delete(fig);

            catch ME
                if ~isempty(fig) && isvalid(fig)
                    delete(fig);
                end
                rethrow(ME);
            end
        end
    end

    methods (Access = public)
        function valid = isValidAxes(~, ax)
            valid = ~isempty(ax) && isvalid(ax) && isgraphics(ax);
        end

        function valid = isValidPlot(~, plot_obj)
            valid = ~isempty(plot_obj) && isvalid(plot_obj) && isgraphics(plot_obj);
        end
    end

    methods (Access = private)
        function calculateMasterLimits(obj, x_sig, h_sig, n_vec)
            % Calculate master limits that respond to time vector changes
            try
                % X limits responsive to time vector
                n_min = min(n_vec);
                n_max = max(n_vec);
                n_range = n_max - n_min;
                
                if n_range == 0
                    n_padding = 1;
                else
                    n_padding = max(n_range * 0.15, 0.5);
                end
                
                obj.MasterXLimits = [n_min - n_padding, n_max + n_padding];
                
                % Y limits based on signal amplitudes
                combined_signal = [x_sig(:); h_sig(:)];
                y_min = min(combined_signal);
                y_max = max(combined_signal);
                y_range = y_max - y_min;
                
                if y_range == 0
                    if abs(y_min) < 1e-10
                        obj.MasterYLimits = [-0.5, 0.5];
                    else
                        y_padding = max(abs(y_min) * 0.2, 0.1);
                        obj.MasterYLimits = [y_min - y_padding, y_max + y_padding];
                    end
                else
                    y_padding = max(y_range * 0.15, 0.05);
                    obj.MasterYLimits = [y_min - y_padding, y_max + y_padding];
                end
                
                fprintf('Master limits calculated: xlim=[%.2f, %.2f], ylim=[%.3f, %.3f]\n', ...
                    obj.MasterXLimits, obj.MasterYLimits);
                
            catch ME
                fprintf('Error calculating master limits: %s\n', ME.message);
                obj.MasterXLimits = [-5, 5];
                obj.MasterYLimits = [-1, 1];
            end
        end

        function applyResponsiveXLimits(obj, ax, n_vec)
            % FIXED: Apply xlim that responds to time vector changes
            try
                if ~obj.isValidAxes(ax) || isempty(n_vec)
                    return;
                end
                
                n_min = min(n_vec);
                n_max = max(n_vec);
                n_range = n_max - n_min;
                
                % Smart padding based on signal characteristics
                if length(n_vec) <= 3
                    padding_factor = 0.5; % More padding for very short signals
                elseif length(n_vec) <= 10
                    padding_factor = 0.3;
                else
                    padding_factor = 0.15;
                end
                
                padding = max(n_range * padding_factor, 0.5);
                x_limits = [n_min - padding, n_max + padding];
                
                if x_limits(1) < x_limits(2) && all(isfinite(x_limits))
                    xlim(ax, x_limits);
                    fprintf('Applied responsive xlim [%.2f, %.2f] to axes\n', x_limits);
                end
                
            catch ME
                fprintf('Error applying responsive x-limits: %s\n', ME.message);
            end
        end

        function applyResponsiveYLimits(obj, ax, signal)
            % Apply ylim that responds to signal amplitude changes
            try
                if ~obj.isValidAxes(ax) || isempty(signal)
                    return;
                end
                
                y_min = min(signal);
                y_max = max(signal);
                y_range = y_max - y_min;
                
                if y_range == 0
                    if abs(y_min) < 1e-10
                        y_limits = [-0.1, 0.1];
                    else
                        padding = max(abs(y_min) * 0.2, 0.05);
                        y_limits = [y_min - padding, y_max + padding];
                    end
                else
                    padding = max(y_range * 0.15, 0.05);
                    y_limits = [y_min - padding, y_max + padding];
                end
                
                if y_limits(1) < y_limits(2) && all(isfinite(y_limits))
                    ylim(ax, y_limits);
                end
                
            catch ME
                fprintf('Error applying responsive y-limits: %s\n', ME.message);
            end
        end

        function setSmartYLimitsForAnimation(obj, ax, x_sig, h_sig)
            try
                if ~obj.isValidAxes(ax)
                    return;
                end
                combined_signal = [x_sig(:); h_sig(:)];
                obj.applyResponsiveYLimits(ax, combined_signal);
            catch ME
                fprintf('Error setting animation y-limits: %s\n', ME.message);
            end
        end

        function setSmartYLimitsForProduct(obj, ax, x_sig, h_sig)
            try
                if ~obj.isValidAxes(ax)
                    return;
                end
                max_product = max(abs(x_sig)) * max(abs(h_sig));
                if max_product == 0
                    y_limits = [-0.1, 0.1];
                else
                    padding = max_product * 0.2;
                    y_limits = [-max_product - padding, max_product + padding];
                end
                
                if y_limits(1) < y_limits(2) && all(isfinite(y_limits))
                    ylim(ax, y_limits);
                end
            catch ME
                fprintf('Error setting product y-limits: %s\n', ME.message);
            end
        end

        function setSmartYLimitsForOutput(obj, ax, x_sig, h_sig)
            try
                if ~obj.isValidAxes(ax)
                    return;
                end
                try
                    y_conv = conv(x_sig, h_sig);
                    y_max = max(abs(y_conv));
                    if y_max == 0
                        y_limits = [-0.1, 0.1];
                    else
                        padding = y_max * 0.2;
                        y_limits = [-y_max - padding, y_max + padding];
                    end
                catch
                    max_estimate = sum(abs(x_sig)) * max(abs(h_sig));
                    padding = max_estimate * 0.2;
                    y_limits = [-max_estimate - padding, max_estimate + padding];
                end
                
                if y_limits(1) < y_limits(2) && all(isfinite(y_limits))
                    ylim(ax, y_limits);
                end
            catch ME
                fprintf('Error setting output y-limits: %s\n', ME.message);
            end
        end

        function updateYLimIfNeeded(obj, ax, new_signal)
            try
                if ~obj.isValidAxes(ax) || isempty(new_signal)
                    return;
                end
                
                current_lim = ylim(ax);
                new_min = min(new_signal);
                new_max = max(new_signal);
                
                expand_factor = 1.1;
                
                if new_max > current_lim(2)
                    new_upper = new_max * expand_factor;
                    if isfinite(new_upper)
                        ylim(ax, [current_lim(1), new_upper]);
                    end
                elseif new_min < current_lim(1)
                    new_lower = new_min * expand_factor;
                    if isfinite(new_lower)
                        ylim(ax, [new_lower, current_lim(2)]);
                    end
                end
            catch ME
                fprintf('Error updating y-limits: %s\n', ME.message);
            end
        end

        function updateYLimForValue(obj, ax, new_val)
            try
                if ~obj.isValidAxes(ax) || ~isfinite(new_val)
                    return;
                end
                obj.updateYLimIfNeeded(ax, [new_val]);
            catch ME
                fprintf('Error updating y-limits for value: %s\n', ME.message);
            end
        end

        function validatePlotInputsFixed(obj, x_sig, h_sig, n_vec)
            try
                if ~isnumeric(x_sig) || ~all(isfinite(x_sig)) || isempty(x_sig)
                    error('x_sig must be non-empty numeric with finite values');
                end
                
                if ~isnumeric(h_sig) || ~all(isfinite(h_sig)) || isempty(h_sig)
                    error('h_sig must be non-empty numeric with finite values');
                end
                
                if ~obj.isValidPlotVector(n_vec)
                    error('n_vec must be non-empty numeric with finite, strictly increasing values');
                end
            catch ME
                error('PlotManager:InvalidInputs', 'Input validation failed: %s', ME.message);
            end
        end

        function valid = isValidPlotVector(~, vec)
            valid = false;
            try
                if ~isnumeric(vec) || isempty(vec) || ~all(isfinite(vec))
                    return;
                end
                
                if numel(vec) > 1 && any(diff(vec) <= 0)
                    return;
                end
                
                valid = true;
            catch
                valid = false;
            end
        end

        function configureAxesSafely(obj)
            try
                all_axes = {obj.AnimationAxes, obj.ProductAxes, obj.OutputAxes, obj.XAxes, obj.HAxes};
                titles = {'Animation - UNIFIED xlim', 'Product - UNIFIED xlim', 'Output - UNIFIED xlim', ...
                    'x[n] - Responsive xlim', 'h[n] - Responsive xlim'};
                xlabels = {'k', 'k', 'n', 'n', 'n'};
                ylabels = {'Amplitude', 'Product', 'y[n]', 'Amplitude', 'Amplitude'};

                for i = 1:numel(all_axes)
                    if obj.isValidAxes(all_axes{i})
                        try
                            ax = all_axes{i};
                            title(ax, titles{i}, 'FontWeight', 'bold', 'FontSize', 11);
                            xlabel(ax, xlabels{i}, 'FontWeight', 'bold');
                            ylabel(ax, ylabels{i}, 'FontWeight', 'bold');
                            grid(ax, 'on');
                            ax.GridAlpha = 0.4;
                            ax.FontSize = 10;
                            ax.LineWidth = 1.2;
                        catch ME
                            fprintf('Error configuring axes %d: %s\n', i, ME.message);
                        end
                    end
                end
            catch ME
                fprintf('Error in axes configuration: %s\n', ME.message);
            end
        end

        function clearInitialPlotsSafely(obj)
            try
                if obj.isValidAxes(obj.XAxes)
                    cla(obj.XAxes);
                end
            catch, end
            
            try
                if obj.isValidAxes(obj.HAxes)
                    cla(obj.HAxes);
                end
            catch, end
        end

        function clearAnimationPlotsSafely(obj)
            axes_to_clear = {obj.AnimationAxes, obj.ProductAxes, obj.OutputAxes};

            for i = 1:numel(axes_to_clear)
                try
                    if obj.isValidAxes(axes_to_clear{i})
                        cla(axes_to_clear{i});
                    end
                catch, end
            end
        end

        function copyAxesContentSafely(obj, source_ax, target_ax)
            try
                if ~obj.isValidAxes(source_ax) || ~obj.isValidAxes(target_ax)
                    return;
                end

                children = source_ax.Children;
                for i = 1:numel(children)
                    try
                        if isvalid(children(i))
                            new_child = copyobj(children(i), target_ax);
                            if isprop(new_child, 'LineWidth')
                                new_child.LineWidth = max(new_child.LineWidth, 2);
                            end
                            if isprop(new_child, 'MarkerSize')
                                new_child.MarkerSize = max(new_child.MarkerSize, 8);
                            end
                        end
                    catch, end
                end

                try
                    xlim(target_ax, xlim(source_ax));
                    ylim(target_ax, ylim(source_ax));
                catch, end
                
                try
                    xlabel(target_ax, source_ax.XLabel.String, 'FontWeight', 'bold', 'FontSize', 12);
                    ylabel(target_ax, source_ax.YLabel.String, 'FontWeight', 'bold', 'FontSize', 12);
                catch, end
                
                try
                    grid(target_ax, 'on');
                    target_ax.GridAlpha = 0.4;
                    target_ax.FontSize = 11;
                    target_ax.LineWidth = 1.2;
                catch, end

                try
                    if ~isempty(source_ax.Legend) && isvalid(source_ax.Legend)
                        legend(target_ax, 'Location', source_ax.Legend.Location, ...
                            'FontSize', 11, 'FontWeight', 'bold');
                    end
                catch, end

            catch ME
                fprintf('Error in axes content copying: %s\n', ME.message);
            end
        end
    end
end