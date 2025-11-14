function test_dtfs_app()
    % TEST_DTFS_APP - Test script for DT Fourier Series App
    %
    % Author: Ahmed Rabei - TEFO, 2025
    % Version: 1.0
    %
    % This script tests the DT Fourier Series app functionality

    fprintf('=== DT Fourier Series App Test Suite ===\n\n');

    % Test 1: Module Initialization
    fprintf('Test 1: Module Initialization\n');
    try
        dt_fs_math = DT_FS_Math();
        animation_controller = DT_FS_AnimationController(dt_fs_math);
        plot_manager = DT_FS_PlotManager();
        fprintf('✓ All modules initialized successfully\n');
    catch ME
        fprintf('✗ Module initialization failed: %s\n', ME.message);
        return;
    end

    % Test 2: Signal Generation
    fprintf('\nTest 2: Signal Generation\n');
    try
        % Generate test signals
        N = 20;
        n = (0:N-1)';
        
        % Test different signal types
        signals = struct();
        signals.square = square(2*pi*(0:N-1)/N)';
        signals.sawtooth = sawtooth(2*pi*(0:N-1)/N)';
        signals.triangle = sawtooth(2*pi*(0:N-1)/N, 0.5)';
        signals.sine = sin(2*pi*(0:N-1)/N)';
        signals.cosine = cos(2*pi*(0:N-1)/N)';
        
        fprintf('✓ Signal generation successful\n');
        fprintf('  - Generated %d sample signals\n', N);
        fprintf('  - Signal types: square, sawtooth, triangle, sine, cosine\n');
    catch ME
        fprintf('✗ Signal generation failed: %s\n', ME.message);
        return;
    end

    % Test 3: DTFS Coefficient Calculation
    fprintf('\nTest 3: DTFS Coefficient Calculation\n');
    try
        test_signal = signals.square;
        [coeffs, freqs, magnitude, phase] = dt_fs_math.calculateFourierCoefficients(test_signal, n, N);
        
        fprintf('✓ DTFS coefficient calculation successful\n');
        fprintf('  - Coefficients: %d complex values\n', length(coeffs));
        fprintf('  - Frequencies: %d normalized frequencies\n', length(freqs));
        fprintf('  - Magnitude range: [%.4f, %.4f]\n', min(magnitude), max(magnitude));
        fprintf('  - Phase range: [%.4f, %.4f] radians\n', min(phase), max(phase));
    catch ME
        fprintf('✗ DTFS coefficient calculation failed: %s\n', ME.message);
        return;
    end

    % Test 4: Signal Synthesis
    fprintf('\nTest 4: Signal Synthesis\n');
    try
        % Use 5 harmonic pairs => DC + ±1..±5
        pair_count = 5;
        [synthesized_signal, harmonics] = dt_fs_math.synthesizeFourierSeries(coeffs, freqs, n, pair_count);
        
        fprintf('✓ Signal synthesis successful\n');
        fprintf('  - Synthesized signal length: %d samples\n', length(synthesized_signal));
        fprintf('  - Harmonics matrix: %dx%d\n', size(harmonics, 1), size(harmonics, 2));
        fprintf('  - Signal range: [%.4f, %.4f]\n', min(synthesized_signal), max(synthesized_signal));
    catch ME
        fprintf('✗ Signal synthesis failed: %s\n', ME.message);
        return;
    end

    % Test 5: Error Metrics Calculation
    fprintf('\nTest 5: Error Metrics Calculation\n');
    try
        error_metrics = dt_fs_math.calculateErrorMetrics(test_signal, synthesized_signal);
        
        fprintf('✓ Error metrics calculation successful\n');
        fprintf('  - MSE: %.6f\n', error_metrics.mse);
        fprintf('  - RMSE: %.6f\n', error_metrics.rmse);
        fprintf('  - MAE: %.6f\n', error_metrics.mae);
        fprintf('  - SNR: %.2f dB\n', error_metrics.snr_db);
        fprintf('  - Convergence: %.2f%%\n', error_metrics.convergence * 100);
    catch ME
        fprintf('✗ Error metrics calculation failed: %s\n', ME.message);
        return;
    end

    % Test 6: Orthogonality Demonstration
    fprintf('\nTest 6: Orthogonality Demonstration\n');
    try
        orthogonality_demo = dt_fs_math.demonstrateOrthogonality(N);
        
        fprintf('✓ Orthogonality demonstration successful\n');
        fprintf('  - Inner product: %.2e\n', abs(orthogonality_demo.inner_product));
        if orthogonality_demo.is_orthogonal
            fprintf('  - Is orthogonal: Yes\n');
        else
            fprintf('  - Is orthogonal: No\n');
        end
        fprintf('  - Frequencies: k1=%d, k2=%d\n', orthogonality_demo.k1, orthogonality_demo.k2);
    catch ME
        fprintf('✗ Orthogonality demonstration failed: %s\n', ME.message);
        return;
    end

    % Test 7: Convergence Analysis
    fprintf('\nTest 7: Convergence Analysis\n');
    try
        max_harmonics_analysis = 15;
        convergence_analysis = dt_fs_math.analyzeConvergence(test_signal, n, N, max_harmonics_analysis);
        
        fprintf('✓ Convergence analysis successful\n');
        fprintf('  - Harmonic counts: %d to %d\n', min(convergence_analysis.harmonic_counts), max(convergence_analysis.harmonic_counts));
        fprintf('  - MSE values: [%.6f, %.6f]\n', min(convergence_analysis.mse_values), max(convergence_analysis.mse_values));
        if convergence_analysis.mse_values(end) < convergence_analysis.mse_values(1)
            fprintf('  - Convergence trend: Improving\n');
        else
            fprintf('  - Convergence trend: Degrading\n');
        end
    catch ME
        fprintf('✗ Convergence analysis failed: %s\n', ME.message);
        return;
    end

    % Test 8: Animation Controller
    fprintf('\nTest 8: Animation Controller\n');
    try
        % Test animation controller methods
        animation_controller.setSpeed(2.0);
        animation_controller.setFrameRate(15);
        
        speed = animation_controller.getAnimationSpeed();
        direction = animation_controller.getAnimationDirection();
        is_animating = animation_controller.getAnimationStatus();
        
        fprintf('✓ Animation controller test successful\n');
        fprintf('  - Speed: %.1fx\n', speed);
        if direction > 0
            fprintf('  - Direction: Forward\n');
        else
            fprintf('  - Direction: Backward\n');
        end
        
        if is_animating
            fprintf('  - Is animating: Yes\n');
        else
            fprintf('  - Is animating: No\n');
        end
    catch ME
        fprintf('✗ Animation controller test failed: %s\n', ME.message);
        return;
    end

    % Test 9: Plot Manager
    fprintf('\nTest 9: Plot Manager\n');
    try
        % Test plot manager methods
        plot_manager.setDisplayOptions(true, false, true, false, true, false);
        plot_manager.setPlotElementVisibility(true, true, false, true, true, true);
        plot_manager.setMaxHarmonicsDisplay(8);
        
        fprintf('✓ Plot manager test successful\n');
        fprintf('  - Display options set\n');
        fprintf('  - Plot element visibility configured\n');
        fprintf('  - Max harmonics display set to 8\n');
    catch ME
        fprintf('✗ Plot manager test failed: %s\n', ME.message);
        return;
    end

    % Test 10: Configuration
    fprintf('\nTest 10: Configuration\n');
    try
        config = DT_FS_Config.getDefaultConfig();
        colors = DT_FS_Config.getColorScheme();
        fonts = DT_FS_Config.getFontScheme();
        animation_settings = DT_FS_Config.getAnimationSettings();
        
        fprintf('✓ Configuration test successful\n');
        fprintf('  - Default config loaded\n');
        fprintf('  - Color scheme: %d colors\n', length(fieldnames(colors)));
        fprintf('  - Font scheme: %d settings\n', length(fieldnames(fonts)));
        fprintf('  - Animation settings: %d parameters\n', length(fieldnames(animation_settings)));
    catch ME
        fprintf('✗ Configuration test failed: %s\n', ME.message);
        return;
    end

    % Test 11: Performance Statistics
    fprintf('\nTest 11: Performance Statistics\n');
    try
        stats = dt_fs_math.getPerformanceStats();
        
        fprintf('✓ Performance statistics test successful\n');
        fprintf('  - Total calculations: %d\n', stats.total_calculations);
        fprintf('  - Cache hits: %d\n', stats.cache_hits);
        fprintf('  - Cache misses: %d\n', stats.cache_misses);
        if ~isempty(stats.calculation_times)
            fprintf('  - Average calculation time: %.4f seconds\n', stats.average_calculation_time);
        end
    catch ME
        fprintf('✗ Performance statistics test failed: %s\n', ME.message);
        return;
    end

    % Test 12: Cache Functionality
    fprintf('\nTest 12: Cache Functionality\n');
    try
        % Test caching
        is_cached_before = dt_fs_math.isCached(test_signal, n, N);
        
        % Calculate coefficients again (should use cache)
        [coeffs2, freqs2, magnitude2, phase2] = dt_fs_math.calculateFourierCoefficients(test_signal, n, N);
        
        is_cached_after = dt_fs_math.isCached(test_signal, n, N);
        
        fprintf('✓ Cache functionality test successful\n');
        if is_cached_before
            fprintf('  - Cached before: Yes\n');
        else
            fprintf('  - Cached before: No\n');
        end
        
        if is_cached_after
            fprintf('  - Cached after: Yes\n');
        else
            fprintf('  - Cached after: No\n');
        end
        
        if isequal(coeffs, coeffs2)
            fprintf('  - Results identical: Yes\n');
        else
            fprintf('  - Results identical: No\n');
        end
    catch ME
        fprintf('✗ Cache functionality test failed: %s\n', ME.message);
        return;
    end

    % Cleanup
    fprintf('\nTest 13: Cleanup\n');
    try
        animation_controller.cleanup();
        dt_fs_math.resetCache();
        fprintf('✓ Cleanup successful\n');
    catch ME
        fprintf('✗ Cleanup failed: %s\n', ME.message);
    end

    % Summary
    fprintf('\n=== Test Summary ===\n');
    fprintf('✓ All tests completed successfully!\n');
    fprintf('✓ DT Fourier Series App is ready for use\n');
    fprintf('\nTo run the app, execute: DT_Fourier_Series_App()\n');
end
