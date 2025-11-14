classdef DT_FS_Config < handle
    % DT_FS_CONFIG - Configuration and constants for DT Fourier Series App
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 1.0
    %
    % This class contains all configuration parameters, constants, and settings
    % for the Discrete-Time Fourier Series visualization app.
    
    properties (Constant)
        % === APPLICATION SETTINGS ===
        APP_NAME = 'Interactive Discrete-Time Fourier Series Visualization';
        APP_VERSION = '1.0';
        AUTHOR = 'Ahmed Rabei - TEFO, 2025';
        
        % === WINDOW SETTINGS ===
        WINDOW_WIDTH = 1400;
        WINDOW_HEIGHT = 900;
        WINDOW_POSITION = [100 100];
        
        % === ANIMATION SETTINGS ===
        DEFAULT_FRAME_RATE = 10;           % FPS
        MIN_FRAME_RATE = 1;
        MAX_FRAME_RATE = 30;
        
        DEFAULT_ANIMATION_SPEED = 1.0;     % Multiplier
        MIN_ANIMATION_SPEED = 0.1;
        MAX_ANIMATION_SPEED = 5.0;
        
        MIN_TIMER_PERIOD = 0.01;           % 10ms minimum
        MIN_STABLE_PERIOD = 0.01;          % 10ms minimum for stable animation
        
        % === SIGNAL SETTINGS ===
        DEFAULT_PERIOD = 20;               % Default signal period
        MIN_PERIOD = 4;
        MAX_PERIOD = 100;
        
        DEFAULT_HARMONICS = 10;            % Default number of harmonics
        MIN_HARMONICS = 1;
        MAX_HARMONICS = 50;
        
        DEFAULT_SIGNAL_TYPE = 'Square Wave';
        
        % === PLOT SETTINGS ===
        DEFAULT_LINE_WIDTH = 2;
        DEFAULT_MARKER_SIZE = 6;
        DEFAULT_GRID_ALPHA = 0.3;
        DEFAULT_MAX_HARMONICS_DISPLAY = 5;
        
        % === FONT SETTINGS ===
        DEFAULT_FONT_SIZE = 12;
        TITLE_FONT_SIZE = 14;
        MATH_FONT_SIZE = 11;
        FONT_NAME = 'Helvetica Neue';
        MATH_FONT_NAME = 'Times New Roman';
        
        % === COLOR SCHEME ===
        % Background colors
        BG_COLOR = [0.96 0.96 0.96];
        PANEL_COLOR = [1 1 1];
        TEXT_COLOR = [0.1 0.1 0.1];
        
        % Primary colors
        PRIMARY_COLOR = [0 0.4470 0.7410];      % Blue
        HIGHLIGHT_COLOR = [0.8500 0.3250 0.0980]; % Orange
        SECONDARY_COLOR = [0.4940 0.1840 0.5560]; % Purple
        
        % Signal colors
        DT_SIGNAL_COLOR = [0.8 0.2 0.6];        % Magenta for DT signals
        FOURIER_SIGNAL_COLOR = [0 0.4470 0.7410]; % Blue for Fourier approximation
        ERROR_SIGNAL_COLOR = [0.9 0.1 0.1];     % Red for error
        
        % Analysis colors
        HARMONIC_COLOR = [0.2 0.8 0.2];         % Green for harmonics
        ORTHOGONAL_COLOR = [0.3 0.6 0.9];       % Light Blue for orthogonality
        CONVERGENCE_COLOR = [0.1 0.7 0.1];      % Dark Green for convergence
        GRID_COLOR = [0.8 0.8 0.8];             % Light Gray for grid
        
        % === MATHEMATICAL CONSTANTS ===
        PI = pi;
        TWO_PI = 2*pi;
        EPSILON = 1e-10;
        
        % === SIGNAL GENERATION SETTINGS ===
        DEFAULT_AMPLITUDE = 1.0;
        MIN_AMPLITUDE = 0.1;
        MAX_AMPLITUDE = 10.0;
        
        % === ERROR TOLERANCE SETTINGS ===
        CACHE_TOLERANCE = 1e-10;
        NUMERICAL_TOLERANCE = 1e-12;
        DISPLAY_TOLERANCE = 1e-6;
        
        % === EXPORT SETTINGS ===
        DEFAULT_EXPORT_FORMAT = 'png';
        SUPPORTED_EXPORT_FORMATS = {'fig', 'png', 'pdf'};
        EXPORT_RESOLUTION = 300;  % DPI
        
        % === PERFORMANCE SETTINGS ===
        MAX_CACHE_SIZE = 100;     % Maximum number of cached calculations
        PERFORMANCE_MONITORING = true;
        
        % === UI LAYOUT SETTINGS ===
        CONTROL_PANEL_HEIGHT = 200;
        STATUS_PANEL_HEIGHT = 100;
        PLOT_AREA_HEIGHT = 600;
        
        GRID_PADDING = 10;
        GRID_SPACING = 5;
        
        % === VALIDATION SETTINGS ===
        MIN_SIGNAL_LENGTH = 4;
        MAX_SIGNAL_LENGTH = 1000;
        
        % === ANIMATION CONTROL SETTINGS ===
        SMOOTH_TRANSITIONS = true;
        PAUSE_BETWEEN_HARMONICS = false;
        AUTO_REVERSE = true;
        
        % === PLOT ELEMENT SETTINGS ===
        SHOW_GRID_BY_DEFAULT = true;
        SHOW_LEGEND_BY_DEFAULT = true;
        SHOW_MATH_NOTATION_BY_DEFAULT = true;
        
        % === ERROR HANDLING SETTINGS ===
        MAX_ERROR_RETRIES = 3;
        ERROR_RECOVERY_ENABLED = true;
        VERBOSE_ERROR_MESSAGES = true;
        
        % === CACHING SETTINGS ===
        ENABLE_CACHING = true;
        CACHE_CLEANUP_INTERVAL = 100;  % Cleanup every 100 operations
        MAX_CACHE_AGE = 3600;          % 1 hour in seconds
    end
    
    methods (Static)
        function config = getDefaultConfig()
            % Get default configuration structure
            config = struct();
            
            % Application settings
            config.app_name = DT_FS_Config.APP_NAME;
            config.app_version = DT_FS_Config.APP_VERSION;
            config.author = DT_FS_Config.AUTHOR;
            
            % Window settings
            config.window_width = DT_FS_Config.WINDOW_WIDTH;
            config.window_height = DT_FS_Config.WINDOW_HEIGHT;
            config.window_position = DT_FS_Config.WINDOW_POSITION;
            
            % Animation settings
            config.frame_rate = DT_FS_Config.DEFAULT_FRAME_RATE;
            config.animation_speed = DT_FS_Config.DEFAULT_ANIMATION_SPEED;
            config.min_timer_period = DT_FS_Config.MIN_TIMER_PERIOD;
            
            % Signal settings
            config.period = DT_FS_Config.DEFAULT_PERIOD;
            config.harmonics = DT_FS_Config.DEFAULT_HARMONICS;
            config.signal_type = DT_FS_Config.DEFAULT_SIGNAL_TYPE;
            
            % Plot settings
            config.line_width = DT_FS_Config.DEFAULT_LINE_WIDTH;
            config.marker_size = DT_FS_Config.DEFAULT_MARKER_SIZE;
            config.grid_alpha = DT_FS_Config.DEFAULT_GRID_ALPHA;
            config.max_harmonics_display = DT_FS_Config.DEFAULT_MAX_HARMONICS_DISPLAY;
            
            % Font settings
            config.font_size = DT_FS_Config.DEFAULT_FONT_SIZE;
            config.title_font_size = DT_FS_Config.TITLE_FONT_SIZE;
            config.math_font_size = DT_FS_Config.MATH_FONT_SIZE;
            config.font_name = DT_FS_Config.FONT_NAME;
            config.math_font_name = DT_FS_Config.MATH_FONT_NAME;
            
            % Color settings
            config.bg_color = DT_FS_Config.BG_COLOR;
            config.panel_color = DT_FS_Config.PANEL_COLOR;
            config.text_color = DT_FS_Config.TEXT_COLOR;
            config.primary_color = DT_FS_Config.PRIMARY_COLOR;
            config.highlight_color = DT_FS_Config.HIGHLIGHT_COLOR;
            config.secondary_color = DT_FS_Config.SECONDARY_COLOR;
            config.dt_signal_color = DT_FS_Config.DT_SIGNAL_COLOR;
            config.fourier_signal_color = DT_FS_Config.FOURIER_SIGNAL_COLOR;
            config.error_signal_color = DT_FS_Config.ERROR_SIGNAL_COLOR;
            config.harmonic_color = DT_FS_Config.HARMONIC_COLOR;
            config.orthogonal_color = DT_FS_Config.ORTHOGONAL_COLOR;
            config.convergence_color = DT_FS_Config.CONVERGENCE_COLOR;
            config.grid_color = DT_FS_Config.GRID_COLOR;
            
            % Performance settings
            config.enable_caching = DT_FS_Config.ENABLE_CACHING;
            config.performance_monitoring = DT_FS_Config.PERFORMANCE_MONITORING;
            config.max_cache_size = DT_FS_Config.MAX_CACHE_SIZE;
            
            % Error handling settings
            config.error_recovery_enabled = DT_FS_Config.ERROR_RECOVERY_ENABLED;
            config.verbose_error_messages = DT_FS_Config.VERBOSE_ERROR_MESSAGES;
            config.max_error_retries = DT_FS_Config.MAX_ERROR_RETRIES;
        end
        
        function colors = getColorScheme()
            % Get color scheme structure
            colors = struct();
            colors.bg = DT_FS_Config.BG_COLOR;
            colors.panel = DT_FS_Config.PANEL_COLOR;
            colors.text = DT_FS_Config.TEXT_COLOR;
            colors.primary = DT_FS_Config.PRIMARY_COLOR;
            colors.highlight = DT_FS_Config.HIGHLIGHT_COLOR;
            colors.secondary = DT_FS_Config.SECONDARY_COLOR;
            colors.dt_signal = DT_FS_Config.DT_SIGNAL_COLOR;
            colors.fourier_signal = DT_FS_Config.FOURIER_SIGNAL_COLOR;
            colors.error = DT_FS_Config.ERROR_SIGNAL_COLOR;
            colors.harmonic = DT_FS_Config.HARMONIC_COLOR;
            colors.orthogonal = DT_FS_Config.ORTHOGONAL_COLOR;
            colors.convergence = DT_FS_Config.CONVERGENCE_COLOR;
            colors.grid = DT_FS_Config.GRID_COLOR;
        end
        
        function fonts = getFontScheme()
            % Get font scheme structure
            fonts = struct();
            fonts.size = DT_FS_Config.DEFAULT_FONT_SIZE;
            fonts.title = DT_FS_Config.TITLE_FONT_SIZE;
            fonts.math = DT_FS_Config.MATH_FONT_SIZE;
            fonts.name = DT_FS_Config.FONT_NAME;
            fonts.math_name = DT_FS_Config.MATH_FONT_NAME;
        end
        
        function settings = getAnimationSettings()
            % Get animation settings structure
            settings = struct();
            settings.frame_rate = DT_FS_Config.DEFAULT_FRAME_RATE;
            settings.min_frame_rate = DT_FS_Config.MIN_FRAME_RATE;
            settings.max_frame_rate = DT_FS_Config.MAX_FRAME_RATE;
            settings.animation_speed = DT_FS_Config.DEFAULT_ANIMATION_SPEED;
            settings.min_animation_speed = DT_FS_Config.MIN_ANIMATION_SPEED;
            settings.max_animation_speed = DT_FS_Config.MAX_ANIMATION_SPEED;
            settings.min_timer_period = DT_FS_Config.MIN_TIMER_PERIOD;
            settings.min_stable_period = DT_FS_Config.MIN_STABLE_PERIOD;
            settings.smooth_transitions = DT_FS_Config.SMOOTH_TRANSITIONS;
            settings.pause_between_harmonics = DT_FS_Config.PAUSE_BETWEEN_HARMONICS;
            settings.auto_reverse = DT_FS_Config.AUTO_REVERSE;
        end
        
        function settings = getSignalSettings()
            % Get signal settings structure
            settings = struct();
            settings.period = DT_FS_Config.DEFAULT_PERIOD;
            settings.min_period = DT_FS_Config.MIN_PERIOD;
            settings.max_period = DT_FS_Config.MAX_PERIOD;
            settings.harmonics = DT_FS_Config.DEFAULT_HARMONICS;
            settings.min_harmonics = DT_FS_Config.MIN_HARMONICS;
            settings.max_harmonics = DT_FS_Config.MAX_HARMONICS;
            settings.signal_type = DT_FS_Config.DEFAULT_SIGNAL_TYPE;
            settings.amplitude = DT_FS_Config.DEFAULT_AMPLITUDE;
            settings.min_amplitude = DT_FS_Config.MIN_AMPLITUDE;
            settings.max_amplitude = DT_FS_Config.MAX_AMPLITUDE;
        end
        
        function settings = getPlotSettings()
            % Get plot settings structure
            settings = struct();
            settings.line_width = DT_FS_Config.DEFAULT_LINE_WIDTH;
            settings.marker_size = DT_FS_Config.DEFAULT_MARKER_SIZE;
            settings.grid_alpha = DT_FS_Config.DEFAULT_GRID_ALPHA;
            settings.max_harmonics_display = DT_FS_Config.DEFAULT_MAX_HARMONICS_DISPLAY;
            settings.show_grid_by_default = DT_FS_Config.SHOW_GRID_BY_DEFAULT;
            settings.show_legend_by_default = DT_FS_Config.SHOW_LEGEND_BY_DEFAULT;
            settings.show_math_notation_by_default = DT_FS_Config.SHOW_MATH_NOTATION_BY_DEFAULT;
        end
        
        function settings = getExportSettings()
            % Get export settings structure
            settings = struct();
            settings.default_format = DT_FS_Config.DEFAULT_EXPORT_FORMAT;
            settings.supported_formats = DT_FS_Config.SUPPORTED_EXPORT_FORMATS;
            settings.resolution = DT_FS_Config.EXPORT_RESOLUTION;
        end
        
        function settings = getValidationSettings()
            % Get validation settings structure
            settings = struct();
            settings.min_signal_length = DT_FS_Config.MIN_SIGNAL_LENGTH;
            settings.max_signal_length = DT_FS_Config.MAX_SIGNAL_LENGTH;
            settings.cache_tolerance = DT_FS_Config.CACHE_TOLERANCE;
            settings.numerical_tolerance = DT_FS_Config.NUMERICAL_TOLERANCE;
            settings.display_tolerance = DT_FS_Config.DISPLAY_TOLERANCE;
        end
        
        function settings = getPerformanceSettings()
            % Get performance settings structure
            settings = struct();
            settings.enable_caching = DT_FS_Config.ENABLE_CACHING;
            settings.performance_monitoring = DT_FS_Config.PERFORMANCE_MONITORING;
            settings.max_cache_size = DT_FS_Config.MAX_CACHE_SIZE;
            settings.cache_cleanup_interval = DT_FS_Config.CACHE_CLEANUP_INTERVAL;
            settings.max_cache_age = DT_FS_Config.MAX_CACHE_AGE;
        end
        
        function settings = getErrorHandlingSettings()
            % Get error handling settings structure
            settings = struct();
            settings.error_recovery_enabled = DT_FS_Config.ERROR_RECOVERY_ENABLED;
            settings.verbose_error_messages = DT_FS_Config.VERBOSE_ERROR_MESSAGES;
            settings.max_error_retries = DT_FS_Config.MAX_ERROR_RETRIES;
        end
        
        function info = getAppInfo()
            % Get application information
            info = struct();
            info.name = DT_FS_Config.APP_NAME;
            info.version = DT_FS_Config.APP_VERSION;
            info.author = DT_FS_Config.AUTHOR;
            info.description = 'Interactive Discrete-Time Fourier Series Visualization Tool';
            info.purpose = 'Educational tool for understanding DTFS concepts and properties';
            info.features = {
                'Interactive signal generation and analysis';
                'Real-time DTFS coefficient calculation';
                'Animated harmonic synthesis';
                'Comprehensive error analysis';
                'Orthogonality demonstrations';
                'Convergence analysis';
                'Export capabilities';
                'Professional visualization'
            };
        end
        
        function config = validateConfig(config)
            % Validate configuration parameters and return corrected config
            try
                % Validate window settings
                if config.window_width < 800 || config.window_width > 2000
                    warning('DT_FS_Config: Invalid window width, using default');
                    config.window_width = DT_FS_Config.WINDOW_WIDTH;
                end
                
                if config.window_height < 600 || config.window_height > 1200
                    warning('DT_FS_Config: Invalid window height, using default');
                    config.window_height = DT_FS_Config.WINDOW_HEIGHT;
                end
                
                % Validate animation settings
                if config.frame_rate < DT_FS_Config.MIN_FRAME_RATE || config.frame_rate > DT_FS_Config.MAX_FRAME_RATE
                    warning('DT_FS_Config: Invalid frame rate, using default');
                    config.frame_rate = DT_FS_Config.DEFAULT_FRAME_RATE;
                end
                
                if config.animation_speed < DT_FS_Config.MIN_ANIMATION_SPEED || config.animation_speed > DT_FS_Config.MAX_ANIMATION_SPEED
                    warning('DT_FS_Config: Invalid animation speed, using default');
                    config.animation_speed = DT_FS_Config.DEFAULT_ANIMATION_SPEED;
                end
                
                % Validate signal settings
                if config.period < DT_FS_Config.MIN_PERIOD || config.period > DT_FS_Config.MAX_PERIOD
                    warning('DT_FS_Config: Invalid period, using default');
                    config.period = DT_FS_Config.DEFAULT_PERIOD;
                end
                
                if config.harmonics < DT_FS_Config.MIN_HARMONICS || config.harmonics > DT_FS_Config.MAX_HARMONICS
                    warning('DT_FS_Config: Invalid harmonics, using default');
                    config.harmonics = DT_FS_Config.DEFAULT_HARMONICS;
                end
                
                fprintf('DT_FS_Config: Configuration validation completed\n');
                
            catch ME
                fprintf('DT_FS_Config: Configuration validation error: %s\n', ME.message);
            end
        end
    end
end
