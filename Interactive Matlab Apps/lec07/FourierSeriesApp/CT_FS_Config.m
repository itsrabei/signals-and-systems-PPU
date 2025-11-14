classdef CT_FS_Config
    % CT_FS_CONFIG - Configuration constants for CT Fourier Series App
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 2.1
    %
    % This class contains all configuration constants used throughout the
    % CT Fourier Series application for better maintainability.
    
    properties (Constant)
        % Performance settings
        MAX_HARMONICS = 100;
        MIN_HARMONICS = 1;
        DEFAULT_HARMONICS = 10;
        MAX_FREQUENCY = 10;
        MIN_FREQUENCY = 0.1;
        DEFAULT_FREQUENCY = 1;
        
        % Animation settings
        DEFAULT_FRAME_RATE = 10;
        MIN_FRAME_RATE = 1;
        MAX_FRAME_RATE = 30;  % Conservative limit to prevent system overload
        % Discrete animation speed levels to prevent stuck animation
        ANIMATION_SPEEDS = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];  % Discrete speed levels
        MIN_ANIMATION_SPEED = 0.5;  % Minimum discrete speed
        MAX_ANIMATION_SPEED = 3.0;  % Maximum discrete speed
        DEFAULT_ANIMATION_SPEED = 1;
        MIN_TIMER_PERIOD = 0.001;  % 1ms minimum - prevents MATLAB timer precision warnings
        MIN_STABLE_PERIOD = 0.01;  % 10ms minimum for stable animation
        
        % UI settings
        DEFAULT_FONT_SIZE = 12;
        TITLE_FONT_SIZE = 14;
        DEFAULT_LINE_WIDTH = 2;
        DEFAULT_MARKER_SIZE = 6;
        DEFAULT_GRID_ALPHA = 0.3;
        
        % Mathematical constants
        TOLERANCE = 1e-10;
        NUMERICAL_TOLERANCE = 1e-12;
        MAX_SAMPLES = 10000;
        MIN_SAMPLES = 300;
        
        % Signal generation
        DEFAULT_TIME_PERIODS = 3;  % Number of periods to show
        SAMPLES_PER_PERIOD = 1000;
        
        % Color scheme
        COLORS = struct(...
            'bg', [0.96 0.96 0.96], ...
            'panel', [1 1 1], ...
            'text', [0.1 0.1 0.1], ...
            'primary', [0 0.4470 0.7410], ...
            'highlight', [0.8500 0.3250 0.0980], ...
            'secondary', [0.4940 0.1840 0.5560], ...
            'harmonic', [0.2 0.8 0.2], ...
            'gibbs', [0.8 0.2 0.2], ...
            'orthogonal', [0.3 0.6 0.9], ...
            'error', [0.9 0.1 0.1], ...
            'convergence', [0.1 0.7 0.1], ...
            'ct_signal', [0.1 0.3 0.8], ...
            'grid', [0.8 0.8 0.8] ...
        );
        
        % Font settings
        FONTS = struct(...
            'size', 12, ...
            'title', 14, ...
            'name', 'Helvetica Neue', ...
            'math', 'Times New Roman' ...
        );
    end
    
    methods (Static)
        function validateHarmonics(N)
            % Validate harmonic count
            if N < CT_FS_Config.MIN_HARMONICS || N > CT_FS_Config.MAX_HARMONICS
                error('CT_FS_Config:InvalidHarmonics', ...
                    'Harmonics must be between %d and %d', ...
                    CT_FS_Config.MIN_HARMONICS, CT_FS_Config.MAX_HARMONICS);
            end
        end
        
        function validateFrequency(f0)
            % Validate frequency
            if f0 < CT_FS_Config.MIN_FREQUENCY || f0 > CT_FS_Config.MAX_FREQUENCY
                error('CT_FS_Config:InvalidFrequency', ...
                    'Frequency must be between %.1f and %.1f Hz', ...
                    CT_FS_Config.MIN_FREQUENCY, CT_FS_Config.MAX_FREQUENCY);
            end
        end
        
        function validateAnimationSpeed(speed)
            % Validate animation speed
            if speed < CT_FS_Config.MIN_ANIMATION_SPEED || speed > CT_FS_Config.MAX_ANIMATION_SPEED
                error('CT_FS_Config:InvalidAnimationSpeed', ...
                    'Animation speed must be between %.1f and %.1f', ...
                    CT_FS_Config.MIN_ANIMATION_SPEED, CT_FS_Config.MAX_ANIMATION_SPEED);
            end
        end
        
        function validateFrameRate(fps)
            % Validate frame rate
            if fps < CT_FS_Config.MIN_FRAME_RATE || fps > CT_FS_Config.MAX_FRAME_RATE
                error('CT_FS_Config:InvalidFrameRate', ...
                    'Frame rate must be between %d and %d FPS', ...
                    CT_FS_Config.MIN_FRAME_RATE, CT_FS_Config.MAX_FRAME_RATE);
            end
        end
        
        function clamped_N = clampHarmonics(N)
            % Clamp harmonics to valid range
            clamped_N = max(CT_FS_Config.MIN_HARMONICS, min(N, CT_FS_Config.MAX_HARMONICS));
        end
        
        function clamped_f0 = clampFrequency(f0)
            % Clamp frequency to valid range
            clamped_f0 = max(CT_FS_Config.MIN_FREQUENCY, min(f0, CT_FS_Config.MAX_FREQUENCY));
        end
        
        function clamped_speed = clampAnimationSpeed(speed)
            % Clamp animation speed to valid range
            clamped_speed = max(CT_FS_Config.MIN_ANIMATION_SPEED, min(speed, CT_FS_Config.MAX_ANIMATION_SPEED));
        end
        
        function clamped_fps = clampFrameRate(fps)
            % Clamp frame rate to valid range
            clamped_fps = max(CT_FS_Config.MIN_FRAME_RATE, min(fps, CT_FS_Config.MAX_FRAME_RATE));
        end
    end
end
