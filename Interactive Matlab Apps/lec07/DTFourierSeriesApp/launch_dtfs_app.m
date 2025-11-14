function launch_dtfs_app()
    % LAUNCH_DTFS_APP - Launch the DT Fourier Series App
    %
    % This function launches the DT Fourier Series Visualization App
    % with proper error handling and user feedback.
    
    fprintf('=== DT Fourier Series App Launcher ===\n\n');
    
    try
        % Check if we're in the right directory
        current_dir = pwd;
        if ~contains(current_dir, 'DTFourierSeriesApp')
            fprintf('Warning: Not in DTFourierSeriesApp directory\n');
            fprintf('Current directory: %s\n', current_dir);
            fprintf('Please navigate to the DTFourierSeriesApp directory\n');
            return;
        end
        
        % Check for required files
        required_files = {
            'DT_Fourier_Series_App.m',
            'DT_FS_Math.m',
            'DT_FS_PlotManager.m',
            'DT_FS_AnimationController.m',
            'DT_FS_Config.m'
        };
        
        missing_files = {};
        for i = 1:length(required_files)
            if ~exist(required_files{i}, 'file')
                missing_files{end+1} = required_files{i};
            end
        end
        
        if ~isempty(missing_files)
            fprintf('Error: Missing required files:\n');
            for i = 1:length(missing_files)
                fprintf('  - %s\n', missing_files{i});
            end
            fprintf('\nPlease ensure all files are present in the current directory.\n');
            return;
        end
        
        fprintf('✓ All required files found\n');
        fprintf('✓ Launching DT Fourier Series App...\n\n');
        
        % Launch the app
        DT_Fourier_Series_App();
        
        fprintf('✓ DT Fourier Series App launched successfully!\n');
        fprintf('\nApp Features:\n');
        fprintf('  - Interactive signal generation and analysis\n');
        fprintf('  - Real-time DTFS coefficient calculation\n');
        fprintf('  - Animated harmonic convergence\n');
        fprintf('  - Comprehensive error analysis\n');
        fprintf('  - Professional visualization\n');
        fprintf('\nFor help, click the "Help" button in the app.\n');
        
    catch ME
        fprintf('\n❌ LAUNCH FAILED!\n');
        fprintf('Error: %s\n', ME.message);
        
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        
        fprintf('\nTroubleshooting:\n');
        fprintf('1. Ensure you are in the DTFourierSeriesApp directory\n');
        fprintf('2. Check that all required files are present\n');
        fprintf('3. Verify MATLAB version compatibility (R2023b+)\n');
        fprintf('4. Run quick_test() to identify specific issues\n');
        fprintf('5. Run test_dtfs_app() for comprehensive testing\n');
    end
end

