function DutyCycleSpectrumAnalyzer()
    % DUTY CYCLE AND SPECTRUM ANALYZER
    % Interactive exploration of rectangular pulse trains and their frequency spectra
    % 
    % This app demonstrates the relationship between duty cycle and frequency spectrum
    % for rectangular pulse trains, showing how the sinc envelope affects harmonics
    %
    % Features:
    % - Real-time duty cycle adjustment (0% to 100%)
    % - Time domain visualization of rectangular pulses
    % - Frequency domain analysis with Fourier series coefficients
    % - Sinc envelope overlay
    % - Harmonic nulling visualization
    % - Educational presets and challenges
    
    % Create main figure
    fig = uifigure('Name', 'Duty Cycle and Spectrum Analyzer', ...
                   'Position', [100, 100, 1200, 800], ...
                   'Resize', 'on');
    
    % Initialize app data
    appData = initializeAppData();
    
    % Create UI components
    createUIComponents(fig, appData);
    
    % Set initial values
    updateDisplay(fig, appData);
    
    % Store app data in figure
    fig.UserData = appData;
    
    fprintf('Duty Cycle and Spectrum Analyzer launched!\n');
    fprintf('Adjust the duty cycle slider to see how pulse width affects the spectrum.\n');
    fprintf('Watch for harmonic nulling when the sinc envelope crosses zero!\n');
end

function appData = initializeAppData()
    % Initialize application data structure
    appData = struct();
    
    % Signal parameters
    appData.fundamentalFreq = 1;  % Hz
    appData.period = 1;           % seconds
    appData.sampleRate = 1000;     % Hz
    appData.timeVector = [];
    appData.frequencyVector = [];
    
    % Display parameters
    appData.numHarmonics = 20;
    appData.timeRange = [-0.5, 1.5];
    appData.freqRange = [0, 20];
    
    % Analysis parameters
    appData.dutyCycle = 0.5;  % 50% duty cycle
    appData.amplitude = 1;
    appData.offset = 0;
    
    % UI handles (will be populated by createUIComponents)
    appData.handles = struct();
end

function createUIComponents(fig, appData)
    % Create main grid layout
    mainGrid = uigridlayout(fig, [1, 3]);
    mainGrid.ColumnWidth = {'1x', '2x', '1x'};
    
    % Left panel - Controls
    leftPanel = uipanel(mainGrid, 'Title', 'Control Panel');
    leftGrid = uigridlayout(leftPanel, [12, 1]);
    leftGrid.RowHeight = repmat({'fit'}, 1, 12);
    
    % Duty Cycle Control
    dutyCycleLabel = uilabel(leftGrid, 'Text', 'Duty Cycle: 50%', ...
                            'FontSize', 12, 'FontWeight', 'bold');
    appData.handles.dutyCycleLabel = dutyCycleLabel;
    
    dutyCycleSlider = uislider(leftGrid, 'Value', 0.5, ...
                              'Limits', [0.01, 0.99], ...
                              'ValueChangedFcn', @(src, event) updateDutyCycle(src, event, fig));
    appData.handles.dutyCycleSlider = dutyCycleSlider;
    
    % Amplitude Control
    amplitudeLabel = uilabel(leftGrid, 'Text', 'Amplitude: 1.0', ...
                            'FontSize', 10);
    appData.handles.amplitudeLabel = amplitudeLabel;
    
    amplitudeSlider = uislider(leftGrid, 'Value', 1, ...
                              'Limits', [0.1, 3], ...
                              'ValueChangedFcn', @(src, event) updateAmplitude(src, event, fig));
    appData.handles.amplitudeSlider = amplitudeSlider;
    
    % Fundamental Frequency Control
    freqLabel = uilabel(leftGrid, 'Text', 'Fundamental Freq (Hz): 1.0', ...
                       'FontSize', 10);
    appData.handles.freqLabel = freqLabel;
    
    freqSlider = uislider(leftGrid, 'Value', 1, ...
                         'Limits', [0.5, 5], ...
                         'ValueChangedFcn', @(src, event) updateFrequency(src, event, fig));
    appData.handles.freqSlider = freqSlider;
    
    % Number of Harmonics
    harmonicsLabel = uilabel(leftGrid, 'Text', 'Number of Harmonics: 20', ...
                           'FontSize', 10);
    appData.handles.harmonicsLabel = harmonicsLabel;
    
    harmonicsSlider = uislider(leftGrid, 'Value', 20, ...
                             'Limits', [5, 50], ...
                             'ValueChangedFcn', @(src, event) updateHarmonics(src, event, fig));
    appData.handles.harmonicsSlider = harmonicsSlider;
    
    % Preset Buttons
    presetLabel = uilabel(leftGrid, 'Text', 'Educational Presets:', ...
                        'FontSize', 12, 'FontWeight', 'bold');
    
    narrowPulseBtn = uibutton(leftGrid, 'Text', 'Narrow Pulse (10%)', ...
                             'ButtonPushedFcn', @(src, event) setPreset(src, event, fig, 0.1));
    
    widePulseBtn = uibutton(leftGrid, 'Text', 'Wide Pulse (90%)', ...
                           'ButtonPushedFcn', @(src, event) setPreset(src, event, fig, 0.9));
    
    squareWaveBtn = uibutton(leftGrid, 'Text', 'Square Wave (50%)', ...
                            'ButtonPushedFcn', @(src, event) setPreset(src, event, fig, 0.5));
    
    % Analysis Buttons
    analysisLabel = uilabel(leftGrid, 'Text', 'Analysis Tools:', ...
                          'FontSize', 12, 'FontWeight', 'bold');
    
    findNullsBtn = uibutton(leftGrid, 'Text', 'Find Harmonic Nulls', ...
                           'ButtonPushedFcn', @(src, event) findHarmonicNulls(src, event, fig));
    
    exportBtn = uibutton(leftGrid, 'Text', 'Export Data', ...
                        'ButtonPushedFcn', @(src, event) exportData(src, event, fig));
    
    % Center panel - Plots
    centerPanel = uipanel(mainGrid, 'Title', 'Analysis Display');
    centerGrid = uigridlayout(centerPanel, [2, 1]);
    centerGrid.RowHeight = {'1x', '1x'};
    
    % Time Domain Plot
    timeAxes = uiaxes(centerGrid, 'Title', 'Time Domain: Rectangular Pulse Train');
    timeAxes.XLabel.String = 'Time (seconds)';
    timeAxes.YLabel.String = 'Amplitude';
    timeAxes.Grid = 'on';
    appData.handles.timeAxes = timeAxes;
    
    % Frequency Domain Plot
    freqAxes = uiaxes(centerGrid, 'Title', 'Frequency Domain: Fourier Series Coefficients');
    freqAxes.XLabel.String = 'Harmonic Number (k)';
    freqAxes.YLabel.String = '|a_k|';
    freqAxes.Grid = 'on';
    appData.handles.freqAxes = freqAxes;
    
    % Right panel - Information and Help
    rightPanel = uipanel(mainGrid, 'Title', 'Information & Help');
    rightGrid = uigridlayout(rightPanel, [1, 1]);
    
    % Information text area
    infoText = uitextarea(rightGrid, 'Value', getInfoText(), ...
                         'Editable', 'off', 'FontSize', 10);
    appData.handles.infoText = infoText;
    
    % Store handles in app data
    appData.handles.mainGrid = mainGrid;
    appData.handles.leftPanel = leftPanel;
    appData.handles.centerPanel = centerPanel;
    appData.handles.rightPanel = rightPanel;
end

function updateDutyCycle(src, event, fig)
    % Update duty cycle and refresh display
    appData = fig.UserData;
    appData.dutyCycle = src.Value;
    
    % Update label
    appData.handles.dutyCycleLabel.Text = sprintf('Duty Cycle: %.1f%%', appData.dutyCycle * 100);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function updateAmplitude(src, event, fig)
    % Update amplitude and refresh display
    appData = fig.UserData;
    appData.amplitude = src.Value;
    
    % Update label
    appData.handles.amplitudeLabel.Text = sprintf('Amplitude: %.1f', appData.amplitude);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function updateFrequency(src, event, fig)
    % Update fundamental frequency and refresh display
    appData = fig.UserData;
    appData.fundamentalFreq = src.Value;
    appData.period = 1 / appData.fundamentalFreq;
    
    % Update label
    appData.handles.freqLabel.Text = sprintf('Fundamental Freq (Hz): %.1f', appData.fundamentalFreq);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function updateHarmonics(src, event, fig)
    % Update number of harmonics and refresh display
    appData = fig.UserData;
    appData.numHarmonics = round(src.Value);
    
    % Update label
    appData.handles.harmonicsLabel.Text = sprintf('Number of Harmonics: %d', appData.numHarmonics);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function setPreset(src, event, fig, dutyCycle)
    % Set preset duty cycle values
    appData = fig.UserData;
    appData.dutyCycle = dutyCycle;
    
    % Update slider and label
    appData.handles.dutyCycleSlider.Value = dutyCycle;
    appData.handles.dutyCycleLabel.Text = sprintf('Duty Cycle: %.1f%%', dutyCycle * 100);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function findHarmonicNulls(src, event, fig)
    % Find and highlight harmonic nulls
    appData = fig.UserData;
    
    % Calculate null frequencies
    D = appData.dutyCycle;
    nullHarmonics = [];
    
    for k = 1:appData.numHarmonics
        if abs(sinc(k * D)) < 0.01  % Threshold for null detection
            nullHarmonics = [nullHarmonics, k];
        end
    end
    
    % Display results
    if isempty(nullHarmonics)
        msgbox('No harmonic nulls found in the current range.', 'Harmonic Analysis');
    else
        msgbox(sprintf('Harmonic nulls found at k = %s', mat2str(nullHarmonics)), ...
               'Harmonic Analysis');
    end
end

function exportData(src, event, fig)
    % Export current analysis data
    appData = fig.UserData;
    
    % Generate data
    [timeData, freqData, harmonics] = generateAnalysisData(appData);
    
    % Create data structure
    exportData = struct();
    exportData.dutyCycle = appData.dutyCycle;
    exportData.amplitude = appData.amplitude;
    exportData.fundamentalFreq = appData.fundamentalFreq;
    exportData.timeData = timeData;
    exportData.frequencyData = freqData;
    exportData.harmonics = harmonics;
    exportData.sincEnvelope = appData.dutyCycle * sinc(harmonics * appData.dutyCycle);
    
    % Save to file
    [filename, pathname] = uiputfile('*.mat', 'Save Analysis Data');
    if filename ~= 0
        save(fullfile(pathname, filename), 'exportData');
        msgbox('Data exported successfully!', 'Export Complete');
    end
end

function updateDisplay(fig, appData)
    % Update all displays with current parameters
    updateTimeDomain(fig, appData);
    updateFrequencyDomain(fig, appData);
end

function updateTimeDomain(fig, appData)
    % Update time domain plot
    axes = appData.handles.timeAxes;
    
    % Generate time vector
    t = linspace(appData.timeRange(1), appData.timeRange(2), 1000);
    
    % Generate rectangular pulse train
    signal = generateRectangularPulseTrain(t, appData);
    
    % Plot
    cla(axes);
    plot(axes, t, signal, 'b-', 'LineWidth', 2);
    xlabel(axes, 'Time (seconds)');
    ylabel(axes, 'Amplitude');
    title(axes, sprintf('Rectangular Pulse Train (D = %.1f%%)', appData.dutyCycle * 100));
    grid(axes, 'on');
    
    % Add period markers
    hold(axes, 'on');
    for k = -2:2
        xline(axes, k * appData.period, 'r--', 'Alpha', 0.5);
    end
    hold(axes, 'off');
end

function updateFrequencyDomain(fig, appData)
    % Update frequency domain plot
    axes = appData.handles.freqAxes;
    
    % Generate harmonic data
    [harmonics, coefficients, sincEnvelope] = generateFrequencyData(appData);
    
    % Plot
    cla(axes);
    stem(axes, harmonics, abs(coefficients), 'b', 'LineWidth', 1.5, 'MarkerSize', 6);
    hold(axes, 'on');
    plot(axes, harmonics, sincEnvelope, 'r-', 'LineWidth', 2);
    xlabel(axes, 'Harmonic Number (k)');
    ylabel(axes, '|a_k|');
    title(axes, sprintf('Fourier Series Coefficients (D = %.1f%%)', appData.dutyCycle * 100));
    legend(axes, 'Coefficients', 'Sinc Envelope', 'Location', 'best');
    grid(axes, 'on');
    hold(axes, 'off');
end

function signal = generateRectangularPulseTrain(t, appData)
    % Generate rectangular pulse train
    D = appData.dutyCycle;
    T0 = appData.period;
    A = appData.amplitude;
    
    % Create pulse train
    signal = zeros(size(t));
    for i = 1:length(t)
        % Normalize time to period
        t_norm = mod(t(i), T0) / T0;
        
        % Check if within pulse
        if t_norm <= D
            signal(i) = A;
        else
            signal(i) = 0;
        end
    end
end

function [harmonics, coefficients, sincEnvelope] = generateFrequencyData(appData)
    % Generate frequency domain data
    D = appData.dutyCycle;
    A = appData.amplitude;
    
    % Harmonic numbers
    harmonics = 0:appData.numHarmonics;
    
    % Fourier series coefficients
    coefficients = zeros(size(harmonics));
    coefficients(1) = A * D;  % DC component
    
    for k = 2:length(harmonics)
        if harmonics(k) ~= 0
            coefficients(k) = A * D * sinc(harmonics(k) * D);
        end
    end
    
    % Sinc envelope
    sincEnvelope = A * D * abs(sinc(harmonics * D));
end

function [timeData, freqData, harmonics] = generateAnalysisData(appData)
    % Generate comprehensive analysis data
    t = linspace(appData.timeRange(1), appData.timeRange(2), 1000);
    timeData = generateRectangularPulseTrain(t, appData);
    
    [harmonics, coefficients, ~] = generateFrequencyData(appData);
    freqData = abs(coefficients);
end

function infoText = getInfoText()
    % Get information text for the help panel
    infoText = {
        'DUTY CYCLE & SPECTRUM ANALYZER';
        '';
        'This app demonstrates the relationship between';
        'duty cycle and frequency spectrum for';
        'rectangular pulse trains.';
        '';
        'Key Concepts:';
        '• Duty Cycle (D): Ratio of pulse width to period';
        '• Sinc Function: sinc(x) = sin(πx)/(πx)';
        '• Harmonic Nulling: When sinc(kD) = 0';
        '';
        'Educational Challenges:';
        '1. Find the duty cycle that nulls the 3rd harmonic';
        '2. Compare narrow vs wide pulse spectra';
        '3. Observe the inverse relationship between';
        '   time and frequency domains';
        '';
        'Controls:';
        '• Duty Cycle: Adjust pulse width';
        '• Amplitude: Change signal strength';
        '• Frequency: Set fundamental frequency';
        '• Harmonics: Number of coefficients to display';
        '';
        'Presets:';
        '• Narrow Pulse: Wide spectrum';
        '• Wide Pulse: Narrow spectrum';
        '• Square Wave: Classic 50% duty cycle';
        '';
        'Analysis Tools:';
        '• Find Harmonic Nulls: Locate zero crossings';
        '• Export Data: Save analysis results';
        '';
        'Watch for the sinc envelope and how it';
        'affects the harmonic amplitudes!'
    };
end
