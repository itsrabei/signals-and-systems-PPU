function quick_test()
    % QUICK_TEST - Quick test to verify DTFS app functionality
    %
    % This script performs a quick test of the DT Fourier Series app
    % to ensure all modules work correctly.
    
    fprintf('=== DT Fourier Series App - Quick Test ===\n\n');
    
    try
        % Test 1: Module initialization
        fprintf('Testing module initialization...\n');
        dt_fs_math = DT_FS_Math();
        animation_controller = DT_FS_AnimationController(dt_fs_math);
        plot_manager = DT_FS_PlotManager();
        fprintf('✓ All modules initialized successfully\n\n');
        
        % Test 2: Signal generation and DTFS calculation
        fprintf('Testing signal generation and DTFS calculation...\n');
        N = 20;
        n = (0:N-1)';
        square_wave = square(2*pi*(0:N-1)/N)';
        
        [coeffs, freqs, magnitude, phase] = dt_fs_math.calculateFourierCoefficients(square_wave, n, N);
        fprintf('✓ DTFS coefficients calculated successfully\n');
        fprintf('  - %d coefficients computed\n', length(coeffs));
        fprintf('  - Magnitude range: [%.4f, %.4f]\n', min(magnitude), max(magnitude));
        
        % Test 3: Signal synthesis
        fprintf('\nTesting signal synthesis...\n');
        % Synthesize using 5 harmonic pairs (DC + ±1..±5)
        [synthesized, harmonics] = dt_fs_math.synthesizeFourierSeries(coeffs, freqs, n, 5);
        fprintf('✓ Signal synthesis successful\n');
        fprintf('  - Synthesized signal length: %d samples\n', length(synthesized));
        
        % Test 4: Error metrics
        fprintf('\nTesting error metrics...\n');
        error_metrics = dt_fs_math.calculateErrorMetrics(square_wave, synthesized);
        fprintf('✓ Error metrics calculated\n');
        fprintf('  - MSE: %.6f\n', error_metrics.mse);
        fprintf('  - SNR: %.2f dB\n', error_metrics.snr_db);
        
        % Test 5: Configuration
        fprintf('\nTesting configuration...\n');
        config = DT_FS_Config.getDefaultConfig();
        colors = DT_FS_Config.getColorScheme();
        fprintf('✓ Configuration loaded successfully\n');
        fprintf('  - App name: %s\n', config.app_name);
        fprintf('  - Color scheme: %d colors\n', length(fieldnames(colors)));
        
        fprintf('\n=== Quick Test Results ===\n');
        fprintf('✅ ALL TESTS PASSED!\n');
        fprintf('✅ DT Fourier Series App is ready to use\n\n');
        fprintf('To launch the app, run: DT_Fourier_Series_App()\n');
        fprintf('For comprehensive testing, run: test_dtfs_app()\n');
        
    catch ME
        fprintf('\n❌ TEST FAILED!\n');
        fprintf('Error: %s\n', ME.message);
        fprintf('Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        fprintf('\nPlease check the error and try again.\n');
    end
end
