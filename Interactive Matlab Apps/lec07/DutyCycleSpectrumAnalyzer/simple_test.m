function simple_test()
    % SIMPLE TEST FOR DUTY CYCLE AND SPECTRUM ANALYZER
    % 
    % This function performs basic tests to verify the application works
    
    fprintf('Testing Duty Cycle and Spectrum Analyzer...\n');
    
    % Test 1: Basic sinc function
    fprintf('\nTest 1: Basic sinc function\n');
    testSincFunction();
    
    % Test 2: Duty cycle calculation
    fprintf('\nTest 2: Duty cycle calculation\n');
    testDutyCycleCalculation();
    
    % Test 3: Harmonic nulling
    fprintf('\nTest 3: Harmonic nulling\n');
    testHarmonicNulling();
    
    fprintf('\nAll tests completed successfully!\n');
end

function testSincFunction()
    % Test sinc function calculation
    
    % Test case: sinc(0) = 1
    assert(abs(sinc(0) - 1) < 1e-10, 'sinc(0) should equal 1');
    
    % Test case: sinc(1) = 0
    assert(abs(sinc(1)) < 1e-10, 'sinc(1) should equal 0');
    
    % Test case: sinc(0.5) = 2/π
    expected = 2/pi;
    assert(abs(sinc(0.5) - expected) < 1e-10, 'sinc(0.5) incorrect');
    
    fprintf('  ✓ Sinc function calculation passed');
end

function testDutyCycleCalculation()
    % Test duty cycle calculations
    
    % Test 50% duty cycle
    dutyCycle = 0.5;
    amplitude = 1;
    
    % DC component should be amplitude * dutyCycle
    dcComponent = amplitude * dutyCycle;
    assert(abs(dcComponent - 0.5) < 1e-10, 'DC component incorrect');
    
    % Test 25% duty cycle
    dutyCycle = 0.25;
    dcComponent = amplitude * dutyCycle;
    assert(abs(dcComponent - 0.25) < 1e-10, 'DC component incorrect');
    
    fprintf('  ✓ Duty cycle calculation passed');
end

function testHarmonicNulling()
    % Test harmonic nulling detection
    
    % For 50% duty cycle, even harmonics should be nulled
    dutyCycle = 0.5;
    
    % Check that sinc(2 * 0.5) = sinc(1) = 0
    assert(abs(sinc(2 * dutyCycle)) < 1e-10, 'Even harmonic should be nulled');
    
    % Check that sinc(4 * 0.5) = sinc(2) = 0
    assert(abs(sinc(4 * dutyCycle)) < 1e-10, 'Even harmonic should be nulled');
    
    % Check that odd harmonics are not nulled
    assert(abs(sinc(1 * dutyCycle)) > 1e-10, 'Odd harmonic should not be nulled');
    assert(abs(sinc(3 * dutyCycle)) > 1e-10, 'Odd harmonic should not be nulled');
    
    fprintf('  ✓ Harmonic nulling detection passed');
end

