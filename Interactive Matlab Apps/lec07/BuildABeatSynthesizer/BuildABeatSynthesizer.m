function BuildABeatSynthesizer()
    % BUILD-A-BEAT SYNTHESIZER
    % Interactive Fourier Series Synthesizer for creating musical tones
    % 
    % This app demonstrates additive synthesis using Fourier series
    % to create complex musical timbres by combining harmonics
    %
    % Features:
    % - Real-time harmonic amplitude control
    % - Musical note selection (C4, D4, E4, etc.)
    % - Waveform visualization
    % - Audio playback and export
    % - Educational challenges and presets
    % - Creative sound design tools
    
    % Create main figure
    fig = uifigure('Name', 'Build-A-Beat Synthesizer', ...
                 'Position', [50, 50, 1400, 900], ...
                 'Resize', 'on');
    
    % Initialize app data
    appData = initializeAppData();
    
    % Create UI components
    createUIComponents(fig, appData);
    
    % Set initial values
    updateDisplay(fig, appData);
    
    % Store app data in figure
    fig.UserData = appData;
    
    fprintf('Build-A-Beat Synthesizer launched!\n');
    fprintf('Adjust the harmonic sliders to create your own unique sounds!\n');
    fprintf('Try the educational challenges to learn about different waveforms!\n');
end

function appData = initializeAppData()
    % Initialize application data structure
    appData = struct();
    
    % Audio parameters
    appData.sampleRate = 44100;  % CD quality
    appData.duration = 2;         % seconds
    appData.amplitude = 0.5;     % Safe amplitude level
    
    % Musical parameters
    appData.fundamentalFreq = 261.63;  % C4
    appData.numHarmonics = 10;
    appData.harmonicAmplitudes = ones(1, appData.numHarmonics);  % All harmonics at full amplitude
    
    % Display parameters
    appData.timeRange = [0, 0.1];  % 100ms window
    appData.freqRange = [0, 2000]; % Up to 2kHz
    
    % UI handles (will be populated by createUIComponents)
    appData.handles = struct();
    
    % Audio player
    appData.audioPlayer = [];
end

function createUIComponents(fig, appData)
    % Create main grid layout
    mainGrid = uigridlayout(fig, [1, 3]);
    mainGrid.ColumnWidth = {'1x', '2x', '1x'};
    
    % Left panel - Harmonic Controls
    leftPanel = uipanel(mainGrid, 'Title', 'Harmonic Mixer');
    leftGrid = uigridlayout(leftPanel, [15, 1]);
    leftGrid.RowHeight = repmat({'fit'}, 1, 15);
    
    % Fundamental frequency control
    freqLabel = uilabel(leftGrid, 'Text', 'Fundamental Frequency:', ...
                       'FontSize', 12, 'FontWeight', 'bold');
    
    noteDropdown = uidropdown(leftGrid, 'Items', {'C4 (261.6 Hz)', 'D4 (293.7 Hz)', 'E4 (329.6 Hz)', ...
                                                 'F4 (349.2 Hz)', 'G4 (392.0 Hz)', 'A4 (440.0 Hz)', ...
                                                 'B4 (493.9 Hz)', 'C5 (523.3 Hz)'}, ...
                             'ValueChangedFcn', @(src, event) updateFundamentalFreq(src, event, fig));
    appData.handles.noteDropdown = noteDropdown;
    
    % Harmonic amplitude controls
    harmonicLabel = uilabel(leftGrid, 'Text', 'Harmonic Amplitudes:', ...
                           'FontSize', 12, 'FontWeight', 'bold');
    
    % Create harmonic sliders
    appData.handles.harmonicSliders = [];
    appData.handles.harmonicLabels = [];
    
    for k = 1:appData.numHarmonics
        % Harmonic label
        label = uilabel(leftGrid, 'Text', sprintf('Harmonic %d:', k), ...
                       'FontSize', 10);
        appData.handles.harmonicLabels(k) = label;
        
        % Harmonic slider
        slider = uislider(leftGrid, 'Value', 1, 'Limits', [0, 1], ...
                         'ValueChangedFcn', @(src, event) updateHarmonicAmplitude(src, event, fig, k));
        appData.handles.harmonicSliders(k) = slider;
    end
    
    % Master controls
    masterLabel = uilabel(leftGrid, 'Text', 'Master Controls:', ...
                         'FontSize', 12, 'FontWeight', 'bold');
    
    % Master amplitude
    masterAmpLabel = uilabel(leftGrid, 'Text', 'Master Amplitude: 0.5', ...
                            'FontSize', 10);
    appData.handles.masterAmpLabel = masterAmpLabel;
    
    masterAmpSlider = uislider(leftGrid, 'Value', 0.5, 'Limits', [0, 1], ...
                              'ValueChangedFcn', @(src, event) updateMasterAmplitude(src, event, fig));
    appData.handles.masterAmpSlider = masterAmpSlider;
    
    % Center panel - Visualization and Controls
    centerPanel = uipanel(mainGrid, 'Title', 'Synthesizer Display');
    centerGrid = uigridlayout(centerPanel, [3, 1]);
    centerGrid.RowHeight = {'1x', '1x', 'fit'};
    
    % Waveform plot
    waveformAxes = uiaxes(centerGrid, 'Title', 'Generated Waveform');
    waveformAxes.XLabel.String = 'Time (seconds)';
    waveformAxes.YLabel.String = 'Amplitude';
    waveformAxes.Grid = 'on';
    appData.handles.waveformAxes = waveformAxes;
    
    % Frequency spectrum plot
    spectrumAxes = uiaxes(centerGrid, 'Title', 'Frequency Spectrum');
    spectrumAxes.XLabel.String = 'Frequency (Hz)';
    spectrumAxes.YLabel.String = 'Magnitude';
    spectrumAxes.Grid = 'on';
    appData.handles.spectrumAxes = spectrumAxes;
    
    % Control buttons
    buttonGrid = uigridlayout(centerGrid, [1, 4]);
    buttonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
    
    playBtn = uibutton(buttonGrid, 'Text', 'Play Sound', ...
                      'ButtonPushedFcn', @(src, event) playSound(src, event, fig), ...
                      'FontSize', 12, 'FontWeight', 'bold');
    appData.handles.playBtn = playBtn;
    
    stopBtn = uibutton(buttonGrid, 'Text', 'Stop', ...
                      'ButtonPushedFcn', @(src, event) stopSound(src, event, fig), ...
                      'FontSize', 12);
    appData.handles.stopBtn = stopBtn;
    
    exportBtn = uibutton(buttonGrid, 'Text', 'Export Audio', ...
                        'ButtonPushedFcn', @(src, event) exportAudio(src, event, fig), ...
                        'FontSize', 12);
    appData.handles.exportBtn = exportBtn;
    
    resetBtn = uibutton(buttonGrid, 'Text', 'Reset', ...
                       'ButtonPushedFcn', @(src, event) resetHarmonics(src, event, fig), ...
                       'FontSize', 12);
    appData.handles.resetBtn = resetBtn;
    
    % Right panel - Presets and Challenges
    rightPanel = uipanel(mainGrid, 'Title', 'Presets & Challenges');
    rightGrid = uigridlayout(rightPanel, [1, 1]);
    
    % Preset buttons
    presetLabel = uilabel(rightGrid, 'Text', 'Educational Presets:', ...
                         'FontSize', 12, 'FontWeight', 'bold');
    
    squareWaveBtn = uibutton(rightGrid, 'Text', 'Square Wave', ...
                            'ButtonPushedFcn', @(src, event) setSquareWave(src, event, fig), ...
                            'FontSize', 11);
    
    sawtoothBtn = uibutton(rightGrid, 'Text', 'Sawtooth Wave', ...
                          'ButtonPushedFcn', @(src, event) setSawtoothWave(src, event, fig), ...
                          'FontSize', 11);
    
    triangleBtn = uibutton(rightGrid, 'Text', 'Triangle Wave', ...
                          'ButtonPushedFcn', @(src, event) setTriangleWave(src, event, fig), ...
                          'FontSize', 11);
    
    sineBtn = uibutton(rightGrid, 'Text', 'Pure Sine Wave', ...
                      'ButtonPushedFcn', @(src, event) setSineWave(src, event, fig), ...
                      'FontSize', 11);
    
    % Challenge buttons
    challengeLabel = uilabel(rightGrid, 'Text', 'Creative Challenges:', ...
                           'FontSize', 12, 'FontWeight', 'bold');
    
    challenge1Btn = uibutton(rightGrid, 'Text', 'Challenge 1: Recreate Square Wave', ...
                           'ButtonPushedFcn', @(src, event) showChallenge1(src, event, fig), ...
                           'FontSize', 10);
    
    challenge2Btn = uibutton(rightGrid, 'Text', 'Challenge 2: Create Sawtooth', ...
                           'ButtonPushedFcn', @(src, event) showChallenge2(src, event, fig), ...
                           'FontSize', 10);
    
    challenge3Btn = uibutton(rightGrid, 'Text', 'Challenge 3: Design Your Instrument', ...
                           'ButtonPushedFcn', @(src, event) showChallenge3(src, event, fig), ...
                           'FontSize', 10);
    
    % Information text area
    infoText = uitextarea(rightGrid, 'Value', getInfoText(), ...
                         'Editable', 'off', 'FontSize', 9);
    appData.handles.infoText = infoText;
    
    % Store handles in app data
    appData.handles.mainGrid = mainGrid;
    appData.handles.leftPanel = leftPanel;
    appData.handles.centerPanel = centerPanel;
    appData.handles.rightPanel = rightPanel;
end

function updateFundamentalFreq(src, event, fig)
    % Update fundamental frequency based on note selection
    appData = fig.UserData;
    
    % Note frequencies (Hz)
    noteFreqs = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25];
    appData.fundamentalFreq = noteFreqs(src.Value);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function updateHarmonicAmplitude(src, event, fig, harmonicNum)
    % Update specific harmonic amplitude
    appData = fig.UserData;
    appData.harmonicAmplitudes(harmonicNum) = src.Value;
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function updateMasterAmplitude(src, event, fig)
    % Update master amplitude
    appData = fig.UserData;
    appData.amplitude = src.Value;
    
    % Update label
    appData.handles.masterAmpLabel.Text = sprintf('Master Amplitude: %.2f', appData.amplitude);
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function setSquareWave(src, event, fig)
    % Set harmonic amplitudes for square wave
    appData = fig.UserData;
    
    % Square wave: only odd harmonics with amplitudes 1/k
    for k = 1:appData.numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            appData.harmonicAmplitudes(k) = 1 / k;
        else  % Even harmonics
            appData.harmonicAmplitudes(k) = 0;
        end
        
        % Update slider
        appData.handles.harmonicSliders(k).Value = appData.harmonicAmplitudes(k);
    end
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function setSawtoothWave(src, event, fig)
    % Set harmonic amplitudes for sawtooth wave
    appData = fig.UserData;
    
    % Sawtooth wave: all harmonics with amplitudes 1/k
    for k = 1:appData.numHarmonics
        appData.harmonicAmplitudes(k) = 1 / k;
        
        % Update slider
        appData.handles.harmonicSliders(k).Value = appData.harmonicAmplitudes(k);
    end
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function setTriangleWave(src, event, fig)
    % Set harmonic amplitudes for triangle wave
    appData = fig.UserData;
    
    % Triangle wave: only odd harmonics with amplitudes 1/k^2
    for k = 1:appData.numHarmonics
        if mod(k, 2) == 1  % Odd harmonics
            appData.harmonicAmplitudes(k) = 1 / (k^2);
        else  % Even harmonics
            appData.harmonicAmplitudes(k) = 0;
        end
        
        % Update slider
        appData.handles.harmonicSliders(k).Value = appData.harmonicAmplitudes(k);
    end
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function setSineWave(src, event, fig)
    % Set harmonic amplitudes for pure sine wave
    appData = fig.UserData;
    
    % Pure sine: only fundamental harmonic
    appData.harmonicAmplitudes(1) = 1;
    for k = 2:appData.numHarmonics
        appData.harmonicAmplitudes(k) = 0;
    end
    
    % Update sliders
    for k = 1:appData.numHarmonics
        appData.handles.harmonicSliders(k).Value = appData.harmonicAmplitudes(k);
    end
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function showChallenge1(src, event, fig)
    % Show Challenge 1: Recreate Square Wave
    msgbox({
        'Challenge 1: Recreate a Square Wave';
        '';
        'A square wave is made of only odd harmonics';
        'with amplitudes that decay as 1/k.';
        '';
        'Try to recreate it by setting:';
        '• Harmonic 1: 1.0';
        '• Harmonic 3: 0.33';
        '• Harmonic 5: 0.20';
        '• Harmonic 7: 0.14';
        '• All even harmonics: 0.0';
        '';
        'This creates the characteristic "hollow"';
        'sound used in classic video games!'
    }, 'Challenge 1: Square Wave');
end

function showChallenge2(src, event, fig)
    % Show Challenge 2: Create Sawtooth
    msgbox({
        'Challenge 2: Create a Sawtooth Wave';
        '';
        'A sawtooth wave contains all harmonics';
        'with amplitudes that decay as 1/k.';
        '';
        'Try to recreate it by setting:';
        '• Harmonic 1: 1.0';
        '• Harmonic 2: 0.5';
        '• Harmonic 3: 0.33';
        '• Harmonic 4: 0.25';
        '• And so on...';
        '';
        'This creates a much "brighter" or';
        '"buzzier" sound common in synthesizers!'
    }, 'Challenge 2: Sawtooth Wave');
end

function showChallenge3(src, event, fig)
    % Show Challenge 3: Design Your Instrument
    msgbox({
        'Challenge 3: Design Your Own Instrument';
        '';
        'Experiment with different combinations';
        'of harmonics to create a unique sound!';
        '';
        'Try these creative approaches:';
        '• Emphasize certain harmonics';
        '• Create harmonic "gaps"';
        '• Experiment with different decay rates';
        '• Combine multiple frequency ranges';
        '';
        'This is how real synthesizers work -';
        'by creatively combining harmonics to';
        'create new and unique timbres!'
    }, 'Challenge 3: Creative Design');
end

function playSound(src, event, fig)
    % Play the generated sound
    appData = fig.UserData;
    
    % Stop any currently playing audio
    if ~isempty(appData.audioPlayer) && isplaying(appData.audioPlayer)
        stop(appData.audioPlayer);
    end
    
    % Generate audio signal
    audioSignal = generateAudioSignal(appData);
    
    % Play audio
    appData.audioPlayer = audioplayer(audioSignal, appData.sampleRate);
    play(appData.audioPlayer);
    
    fig.UserData = appData;
end

function stopSound(src, event, fig)
    % Stop the currently playing sound
    appData = fig.UserData;
    
    if ~isempty(appData.audioPlayer) && isplaying(appData.audioPlayer)
        stop(appData.audioPlayer);
    end
end

function exportAudio(src, event, fig)
    % Export the generated audio
    appData = fig.UserData;
    
    % Generate audio signal
    audioSignal = generateAudioSignal(appData);
    
    % Save to file
    [filename, pathname] = uiputfile('*.wav', 'Save Audio File');
    if filename ~= 0
        audiowrite(fullfile(pathname, filename), audioSignal, appData.sampleRate);
        msgbox('Audio exported successfully!', 'Export Complete');
    end
end

function resetHarmonics(src, event, fig)
    % Reset all harmonic amplitudes to default
    appData = fig.UserData;
    
    % Reset amplitudes
    appData.harmonicAmplitudes = ones(1, appData.numHarmonics);
    
    % Reset sliders
    for k = 1:appData.numHarmonics
        appData.handles.harmonicSliders(k).Value = 1;
    end
    
    % Update display
    updateDisplay(fig, appData);
    fig.UserData = appData;
end

function updateDisplay(fig, appData)
    % Update all displays with current parameters
    updateWaveform(fig, appData);
    updateSpectrum(fig, appData);
end

function updateWaveform(fig, appData)
    % Update waveform plot
    axes = appData.handles.waveformAxes;
    
    % Generate time vector
    t = linspace(0, appData.duration, appData.sampleRate * appData.duration);
    
    % Generate waveform
    waveform = generateWaveform(t, appData);
    
    % Plot
    cla(axes);
    plot(axes, t, waveform, 'b-', 'LineWidth', 1.5);
    xlabel(axes, 'Time (seconds)');
    ylabel(axes, 'Amplitude');
    title(axes, 'Generated Waveform');
    grid(axes, 'on');
    
    % Limit x-axis to first 100ms for detail
    xlim(axes, [0, 0.1]);
end

function updateSpectrum(fig, appData)
    % Update frequency spectrum plot
    axes = appData.handles.spectrumAxes;
    
    % Generate frequency data
    [frequencies, magnitudes] = generateSpectrumData(appData);
    
    % Plot
    cla(axes);
    stem(axes, frequencies, magnitudes, 'b', 'LineWidth', 1.5, 'MarkerSize', 6);
    xlabel(axes, 'Frequency (Hz)');
    ylabel(axes, 'Magnitude');
    title(axes, 'Frequency Spectrum');
    grid(axes, 'on');
    
    % Limit x-axis to reasonable range
    xlim(axes, [0, 2000]);
end

function waveform = generateWaveform(t, appData)
    % Generate waveform using Fourier series synthesis
    f0 = appData.fundamentalFreq;
    A = appData.amplitude;
    
    % Initialize waveform
    waveform = zeros(size(t));
    
    % Add each harmonic
    for k = 1:appData.numHarmonics
        if appData.harmonicAmplitudes(k) > 0
            harmonic = appData.harmonicAmplitudes(k) * sin(2 * pi * k * f0 * t);
            waveform = waveform + harmonic;
        end
    end
    
    % Apply master amplitude
    waveform = A * waveform;
end

function [frequencies, magnitudes] = generateSpectrumData(appData)
    % Generate frequency spectrum data
    f0 = appData.fundamentalFreq;
    
    % Frequency vector
    frequencies = f0 * (1:appData.numHarmonics);
    
    % Magnitude vector
    magnitudes = appData.amplitude * appData.harmonicAmplitudes;
end

function audioSignal = generateAudioSignal(appData)
    % Generate audio signal for playback
    t = linspace(0, appData.duration, appData.sampleRate * appData.duration);
    audioSignal = generateWaveform(t, appData);
end

function infoText = getInfoText()
    % Get information text for the help panel
    infoText = {
        'BUILD-A-BEAT SYNTHESIZER';
        '';
        'This synthesizer uses Fourier series';
        'to create musical tones by combining';
        'harmonics. This is called additive';
        'synthesis!';
        '';
        'Key Concepts:';
        '• Harmonics: Integer multiples of';
        '  the fundamental frequency';
        '• Additive Synthesis: Combining';
        '  harmonics to create timbre';
        '• Timbre: The unique character of';
        '  a sound';
        '';
        'Educational Challenges:';
        '1. Recreate a Square Wave';
        '2. Create a Sawtooth Wave';
        '3. Design Your Own Instrument';
        '';
        'Controls:';
        '• Harmonic Sliders: Adjust';
        '  individual harmonic amplitudes';
        '• Note Selection: Choose';
        '  fundamental frequency';
        '• Master Amplitude: Overall';
        '  volume control';
        '';
        'Presets:';
        '• Square Wave: Odd harmonics only';
        '• Sawtooth Wave: All harmonics';
        '• Triangle Wave: Odd harmonics,';
        '  1/k² decay';
        '• Sine Wave: Pure fundamental';
        '';
        'This is how real synthesizers work!';
        'Experiment and create your own';
        'unique sounds!'
    };
end
