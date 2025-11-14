classdef CT_plot_manager < handle
    % ContinuousPlotManager - Visualization Management for Continuous Convolution Visualizer
    %
    % This class handles all plotting operations for the continuous convolution visualizer.
    % It manages signal display, animation updates, and provides unified
    % visualization with proper scaling and responsive limits.
    %
    % Author: Ahmed Rabei - TEFO, 2025
    %
    % Features:
    % - Signal plotting with proper scaling
    % - Animation step visualization
    % - Dynamic axis limits for clear operation view
    % - Responsive plot updates
    % - Export functionality

    properties (Access = private)
        XAxes, HAxes, AnimationAxes, ProductAxes, OutputAxes
        Colors = struct('x', [0 0.4470 0.7410], 'h', [0.8500 0.3250 0.0980], ...
            'product', [0.9290 0.6940 0.1250], 'output', [0.4660 0.6740 0.1880], ...
            'overlap', [0.4940 0.1840 0.5560]);
        DynamicYlimEnabled logical = false
        HDynamicYlimEnabled logical = false
        XDynamicYlimEnabled logical = false
        ImpulseScalingEnabled logical = true
        MaxXValue double = 0
        MaxHValue double = 0
        MaxProductValue double = 0
    end
    
    methods
        function initialize(obj, x_ax, h_ax, anim_ax, prod_ax, out_ax)
            obj.XAxes=x_ax; obj.HAxes=h_ax; obj.AnimationAxes=anim_ax;
            obj.ProductAxes=prod_ax; obj.OutputAxes=out_ax;
            obj.configureAxes();
        end
        
        function plotSignals(obj, t_vec, x_vals, h_vals, h_t_vec)
            if nargin < 5
                % Use same time vector for both signals
                h_t_vec = t_vec;
            end
            
            obj.updateMaxValues(x_vals, h_vals); % Store max values for product plot scaling
            obj.plotSingleSignal(obj.XAxes, t_vec, x_vals, obj.Colors.x, 'x(t) - Input Signal');
            obj.plotSingleSignal(obj.HAxes, h_t_vec, h_vals, obj.Colors.h, 'h(t) - Impulse Response');
        end
        
        function updateAnimation(obj, tau_vec, x_vals, h_shifted, product, current_t)
            if ~obj.isValid(obj.AnimationAxes), return; end
            
            try
                cla(obj.AnimationAxes); hold(obj.AnimationAxes,'on');
                
                plot(obj.AnimationAxes,tau_vec,x_vals,'Color',obj.Colors.x,'LineWidth',1.5,'DisplayName','x(\tau)');
                plot(obj.AnimationAxes,tau_vec,h_shifted,'Color',obj.Colors.h,'LineWidth',1.5,'DisplayName',sprintf('h(%.1f-\\tau)',current_t));
                
                % Add area under product curve (simplified for performance)
                if length(tau_vec) > 10 % Only add area for detailed plots
            overlap_y = sign(product) .* min(abs(x_vals), abs(h_shifted));
                    obj.addArea(obj.AnimationAxes, tau_vec, overlap_y, obj.Colors.overlap, 0.3);
                end

            title(obj.AnimationAxes,sprintf('Animation at t = %.2f', current_t));
            xlabel(obj.AnimationAxes,'\tau'); 
            grid(obj.AnimationAxes,'on');
            obj.setDynamicLimits(obj.AnimationAxes, [x_vals, h_shifted]);
            hold(obj.AnimationAxes,'off');
                
                % Add legend after all plotting is complete with proper z-order
                try
                    legend(obj.AnimationAxes,'Location','best','AutoUpdate','off');
                    % Ensure legend is on top
                    legend_handle = legend(obj.AnimationAxes);
                    if ~isempty(legend_handle)
                        legend_handle.Box = 'on';
                        legend_handle.Color = 'white';
                    end
                catch
                    % Ignore legend warnings for compatibility
                end
            catch ME
                % Handle plotting errors gracefully
                fprintf('Animation plot error: %s\n', ME.message);
            end
            
            if ~obj.isValid(obj.ProductAxes), return; end
            
            try
            cla(obj.ProductAxes); hold(obj.ProductAxes,'on');
            plot(obj.ProductAxes,tau_vec,product,'Color',obj.Colors.product,'LineWidth',2);
            obj.addArea(obj.ProductAxes,tau_vec,product,obj.Colors.product,0.3);
            area_val=trapz(tau_vec,product);
            title(obj.ProductAxes,sprintf('Product x(\\tau)h(t-\\tau) -- Area = %.3f',area_val));
            xlabel(obj.ProductAxes,'\tau'); grid(obj.ProductAxes,'on');
            obj.setDynamicLimits(obj.ProductAxes, product);
            hold(obj.ProductAxes,'off');
            catch ME
                % Handle plotting errors gracefully
                fprintf('Product plot error: %s\n', ME.message);
            end
        end
        
        function updateOutput(obj, t_vals, y_vals, current_index)
            if ~obj.isValid(obj.OutputAxes), return; end
            cla(obj.OutputAxes); hold(obj.OutputAxes,'on');
            
            % Plot entire potential output signal faintly for context
            plot(obj.OutputAxes, t_vals, y_vals, 'Color', [obj.Colors.output 0.3], 'LineWidth', 1, 'LineStyle', '--');
            
            if current_index >= 1 && current_index <= length(t_vals)
                plot_end = current_index;
                t_plot = t_vals(1:plot_end);
                y_plot = y_vals(1:plot_end);
                % Plot computed portion brightly
                plot(obj.OutputAxes, t_plot, y_plot, 'Color', obj.Colors.output, 'LineWidth', 2.5);
                plot(obj.OutputAxes, t_plot(end), y_plot(end), 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
                obj.setDynamicLimits(obj.OutputAxes, y_vals(1:plot_end), t_vals(1:plot_end));
            end
            
            title(obj.OutputAxes, 'Output y(t) = x(t) * h(t)');
            xlabel(obj.OutputAxes, 't'); grid(obj.OutputAxes, 'on');
            hold(obj.OutputAxes, 'off');
        end
        
        function clearAll(obj)
            all_axes={obj.XAxes,obj.HAxes,obj.AnimationAxes,obj.ProductAxes,obj.OutputAxes};
            for i=1:length(all_axes)
                if obj.isValid(all_axes{i})
                    cla(all_axes{i}); title(all_axes{i},''); xlabel(all_axes{i},''); 
                    grid(all_axes{i}, 'off'); grid(all_axes{i}, 'on');
                end
            end
        end
        
        function setDynamicYlimEnabled(obj, enabled)
            obj.DynamicYlimEnabled = enabled;
        end
        
        function setHDynamicYlimEnabled(obj, enabled)
            obj.HDynamicYlimEnabled = enabled;
        end
        
        function setXDynamicYlimEnabled(obj, enabled)
            obj.XDynamicYlimEnabled = enabled;
        end
        
        function setImpulseScalingEnabled(obj, enabled)
            obj.ImpulseScalingEnabled = enabled;
        end
        
        function updateMaxValues(obj, x_vals, h_vals)
            obj.MaxXValue = max(abs(x_vals(:)));
            obj.MaxHValue = max(abs(h_vals(:)));
            obj.MaxProductValue = obj.MaxXValue * obj.MaxHValue;
        end
        
        function setDynamicLimits(obj, ax, y_data, x_data)
            y_min = min(y_data(:)); y_max = max(y_data(:));
            y_range = y_max - y_min;
            max_abs = max(abs(y_data(:)));
            
            % Dynamic impulse detection and scaling
            if length(y_data) > 1
                % Calculate signal characteristics
                non_zero_indices = find(abs(y_data) > max_abs * 0.01); % 1% threshold
                peak_count = sum(abs(y_data) > max_abs * 0.1); % 10% threshold
                signal_density = peak_count / length(y_data);
                
                % Determine if this is an impulse-like signal
                is_impulse = (max_abs > 5) && (signal_density < 0.05) && (length(non_zero_indices) < length(y_data) * 0.1);
                
                if is_impulse
                    % Dynamic impulse scaling - adapt to signal content
                    % Find the range of non-impulse values
                    non_impulse_values = y_data(abs(y_data) < max_abs * 0.1);
                    if ~isempty(non_impulse_values)
                        non_impulse_range = max(non_impulse_values) - min(non_impulse_values);
                        if non_impulse_range > 1e-6
                            % Scale to show both impulse and other signal content
                            impulse_scale = min(0.1, max(0.01, non_impulse_range / max_abs));
                            ylim(ax, [-max_abs * impulse_scale, max_abs * impulse_scale]);
                        else
                            % Pure impulse - use minimal scaling
                            ylim(ax, [-max_abs * 0.05, max_abs * 0.05]);
                        end
                    else
                        % Pure impulse - use minimal scaling
                        ylim(ax, [-max_abs * 0.05, max_abs * 0.05]);
                    end
                elseif y_range < 1e-6
                    % Near-zero signal
                    y_range = 1;
                    y_min = y_min - 0.5;
                    y_max = y_max + 0.5;
                    ylim(ax, [y_min - 0.1*y_range, y_max + 0.1*y_range]);
                else
                    % Normal signal scaling
                    ylim(ax, [y_min - 0.1*y_range, y_max + 0.1*y_range]);
                end
            else
                % Single point or empty
                ylim(ax, [-1, 1]);
            end
            
            % For product plots, use different scaling based on checkbox state
            if ax == obj.ProductAxes
                if obj.DynamicYlimEnabled
                    % Dynamic scaling based on current data
                    if max_abs < 1e-6, max_abs = 1; end
                    ylim(ax, [-max_abs*1.1, max_abs*1.1]);
                else
                    % Fixed scaling based on max(x) * max(h)
                    max_product = obj.MaxProductValue;
                    if max_product < 1e-6, max_product = 1; end
                    ylim(ax, [-max_product*1.1, max_product*1.1]);
                end
            end
            
            if nargin > 3 && ~isempty(x_data)
                xlim(ax, [min(x_data(:)), max(x_data(:))]);
            end
        end
    end

    methods (Access=private)
        function plotSingleSignal(obj,ax,t,y,color,ax_title)
            if obj.isValid(ax) && length(t)==length(y)
                cla(ax); hold(ax,'on'); 
                
                % Apply impulse scaling for visualization only if enabled
                y_plot = y;
                if obj.ImpulseScalingEnabled && (ax == obj.XAxes || ax == obj.HAxes)
                    y_plot = obj.applyVisualImpulseScaling(y, t);
                end
                
                plot(ax,t,y_plot,'Color',color,'LineWidth',2.5,'DisplayName',ax_title);
                obj.addArea(ax,t,y_plot,color,0.2); 
                title(ax,ax_title); xlabel(ax,'t'); 
                grid(ax,'on');
                
                % Apply dynamic y-limits based on plot type
                if ax == obj.XAxes && obj.XDynamicYlimEnabled
                    % Dynamic y-limits for x(t) plot
                    max_abs = max(abs(y(:)));
                    if max_abs < 1e-6, max_abs = 1; end
                    ylim(ax, [-max_abs*1.1, max_abs*1.1]);
                elseif ax == obj.HAxes && obj.HDynamicYlimEnabled
                    % Dynamic y-limits for h(t) plot
                    max_abs = max(abs(y(:)));
                    if max_abs < 1e-6, max_abs = 1; end
                    ylim(ax, [-max_abs*1.1, max_abs*1.1]);
                else
                    % Use standard dynamic limits
                    obj.setDynamicLimits(ax, y, t);
                end
                
                % Ensure proper axis orientation (removed redundant calls)
                
                hold(ax,'off');
                
                % Add legend after all plotting is complete with proper z-order
                try
                    legend(ax,'Location','best','AutoUpdate','off');
                    % Ensure legend is on top
                    legend_handle = legend(ax);
                    if ~isempty(legend_handle)
                        legend_handle.Box = 'on';
                        legend_handle.Color = 'white';
                    end
                catch
                    % Ignore legend warnings for compatibility
                end
            end
        end

        function addArea(~,ax,x,y,color,alpha)
            if length(x)<2,return;end
            valid_mask=isfinite(x)&isfinite(y); x=x(valid_mask);y=y(valid_mask);
            if length(x)<2,return;end
            fill(ax,[x(1) x x(end)],[0 y 0],color,'FaceAlpha',alpha,'EdgeColor','none');
        end
        function configureAxes(obj),all_axes={obj.XAxes,obj.HAxes,obj.AnimationAxes,obj.ProductAxes,obj.OutputAxes};
            for i=1:length(all_axes),if obj.isValid(all_axes{i}),ax=all_axes{i};ax.FontSize=9;ax.GridAlpha=.4;ax.Box='on';end,end,end
        function valid=isValid(~,ax),valid=~isempty(ax)&&isgraphics(ax)&&isvalid(ax);end
        
        function y_scaled = applyVisualImpulseScaling(obj, y, t)
            % Apply impulse scaling for visualization only
            % This doesn't affect the mathematical accuracy of the convolution
            y_scaled = y;
            
            if isempty(y) || length(y) < 3
                return;
            end
            
            % Detect impulses using simple peak detection
            [peaks, locs] = findpeaks(abs(y), 'MinPeakHeight', 0.1 * max(abs(y)));
            
            if isempty(peaks)
                return;
            end
            
            % Calculate the maximum non-impulse value for reference
            non_impulse_mask = true(size(y));
            for i = 1:length(locs)
                idx = locs(i);
                window_size = max(1, round(0.02 * length(y)));
                start_idx = max(1, idx - window_size);
                end_idx = min(length(y), idx + window_size);
                non_impulse_mask(start_idx:end_idx) = false;
            end
            
            non_impulse_vals = y(non_impulse_mask);
            max_non_impulse = max(abs(non_impulse_vals));
            if isempty(max_non_impulse) || max_non_impulse < 1e-10
                max_non_impulse = 1.0;
            end
            
            % Apply smart scaling to impulses for visualization
            for i = 1:length(locs)
                idx = locs(i);
                if abs(y(idx)) > max_non_impulse * 2
                    % This is likely an impulse, scale it for better visualization
                    scale_factor = min(3.0, max_non_impulse * 2.0 / abs(y(idx)));
                    y_scaled(idx) = y(idx) * scale_factor;
                end
            end
        end
    end
end