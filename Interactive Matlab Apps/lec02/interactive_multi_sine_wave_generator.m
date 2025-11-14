function interactive_multi_sine_wave_generator
% INTERACTIVE MULTI-SINE WAVE GENERATOR
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app generates and combines multiple sine waves
% using mathematical operations (add, subtract, multiply). Users can
% visualize time domain and frequency domain representations while
% listening to the resulting audio signal.
% 
% FEATURES:
% - Generate 2-3 sine waves with adjustable frequencies and amplitudes
% - Combine waves using Add, Subtract, or Multiply operations
% - Real-time time domain and frequency domain visualization
% - Audio playback with export capabilities
% - Educational frequency analysis with FFT
% 
% EDUCATIONAL PURPOSE:
% - Understanding wave superposition and interference
% - Frequency domain analysis concepts
% - Signal operations and their effects on audio
% - Introduction to digital signal processing

% --- App State Initialization ---
state.numWaves        = 3;          % 2 or 3 waves
state.freq1           = 440;        % Base frequency in Hz
state.ratio2          = 1.5;        % Wave 2 ratio to wave 1
state.ratio3          = 2.0;        % Wave 3 ratio to wave 1
state.op12            = 'Add';      % Op between wave1 & wave2
state.op23            = 'Add';      % Op between wave2 & wave3
state.const1          = 1.0;        % Amplitude for wave1
state.const2          = 1.0;        % Amplitude for wave2
state.const3          = 1.0;        % Amplitude for wave3
state.duration        = 3;          % seconds
state.Fs              = 44100;      % Sampling rate

% View/behavior settings
state.viewMode        = 'N periods (Wave 1)';   % 'Full duration' | 'N periods (Wave 1)' | 'N periods (Fastest wave)'
state.periods         = 5;                 % Number of periods for period-based view
state.yScaleMode      = 'Auto';            % 'Auto' | 'Fixed [-1.2 1.2]'
state.autoUpdate      = true;              % Auto recompute plots on change
state.normalizeAudio  = true;              % Normalize audio on playback/export
state.showFreqAnalysis = false;            % Show frequency analysis

% --- UI Constants ---
uiColors.bg = [0.96 0.96 0.96];
uiColors.panel = [1 1 1];
uiColors.text = [0.1 0.1 0.1];
uiColors.primary = [0 0.4470 0.7410];
uiColors.highlight = [0.8500 0.3250 0.0980];
uiFonts.size = 12;
uiFonts.title = 14;
uiFonts.name = 'Helvetica Neue';

% --- UI Setup ---
fig = uifigure('Name','Interactive Multi-Sine Wave Generator','Position',[100 100 1200 760], 'Color', uiColors.bg);
fig.CloseRequestFcn = @(~,~) onClose();

mainGrid = uigridlayout(fig,[2 1]);
mainGrid.RowHeight = {'fit','1x'};
mainGrid.Padding = [16 14 16 14];
mainGrid.RowSpacing = 12;
mainGrid.ColumnSpacing = 12;

% Control Panel (top row)
ctrlPanel = uipanel(mainGrid,'Title','Controls','FontSize',uiFonts.title,'FontWeight','bold','BackgroundColor',uiColors.panel);
ctrlPanel.Layout.Row = 1;

ctrlGrid = uigridlayout(ctrlPanel,[2 3]);  % add a small row for equation
ctrlGrid.RowHeight = {'fit','fit'};
ctrlGrid.ColumnWidth = {'1x','1x','1.2x'};
ctrlGrid.Padding = [12 10 12 10];
ctrlGrid.RowSpacing = 10;
ctrlGrid.ColumnSpacing = 16;

% Sub-panels row
subGrid = uigridlayout(ctrlGrid,[1 4]);
subGrid.Layout.Row = 1; subGrid.Layout.Column = [1 4];
subGrid.ColumnWidth = {'1x','1x','1.2x','fit'};
subGrid.RowHeight = {'fit'};
subGrid.Padding = [0 0 0 0];
subGrid.ColumnSpacing = 16;

pSignal = uipanel(subGrid,'Title','Signal','FontWeight','bold'); pSignal.Layout.Column = 1;
pAmpDur = uipanel(subGrid,'Title','Amplitude & Timing','FontWeight','bold'); pAmpDur.Layout.Column = 2;
pViewPB = uipanel(subGrid,'Title','View & Playback','FontWeight','bold'); pViewPB.Layout.Column = 3;

% Help button
helpBtn = uibutton(subGrid, 'Text', '?', 'FontSize', 16, 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(~,~) showHelp());
helpBtn.Layout.Column = 4;

% Equation row (LaTeX label)
eqPanel = uipanel(ctrlGrid,'Title','Equation','FontWeight','bold');
eqPanel.Layout.Row = 2; eqPanel.Layout.Column = [1 3];
eqGrid = uigridlayout(eqPanel,[1 1]); eqGrid.Padding = [8 6 8 6];
lblEq = uilabel(eqGrid,'Text','', 'Interpreter','latex', 'WordWrap','on', 'FontSize',13);
lblEq.Layout.Row = 1; lblEq.Layout.Column = 1;

% Grids inside sub-panels
gSignal = uigridlayout(pSignal,[6 6]);
gSignal.RowHeight = repmat({'fit'},1,6);
gSignal.ColumnWidth = {'fit','1.1x','fit','1.1x','fit','fit'};
gSignal.Padding = [8 8 8 8];
gSignal.RowSpacing = 6;
gSignal.ColumnSpacing = 10;

gAmpDur = uigridlayout(pAmpDur,[5 4]);
gAmpDur.RowHeight = repmat({'fit'},1,5);
gAmpDur.ColumnWidth = {'fit','1x','fit','1x'};
gAmpDur.Padding = [8 8 8 8];
gAmpDur.RowSpacing = 6;
gAmpDur.ColumnSpacing = 10;

gViewPB = uigridlayout(pViewPB,[5 4]);
gViewPB.RowHeight = repmat({'fit'},1,5);
gViewPB.ColumnWidth = {'fit','1x','fit','1x'};
gViewPB.Padding = [8 8 8 8];
gViewPB.RowSpacing = 6;
gViewPB.ColumnSpacing = 10;

% --- Signal panel controls ---
lbl = uilabel(gSignal,'Text','Waves:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 1; lbl.Layout.Column = 1;
ddNumWaves = uidropdown(gSignal,'Items',{'2','3'},'Value','3','FontSize',12, ...
    'Tooltip','Select 2 or 3 active sine waves', ...
    'ValueChangedFcn', @(src,~) onNumWavesChanged(str2double(src.Value)));
ddNumWaves.Layout.Row = 1; ddNumWaves.Layout.Column = 2;

lbl = uilabel(gSignal,'Text','Freq 1 (Hz):','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 2; lbl.Layout.Column = 1;
efFreq1 = uieditfield(gSignal,'numeric','Value',state.freq1,'Limits',[0 Inf],'FontSize',12, ...
    'ValueDisplayFormat','%.0f', ...
    'Tooltip','Base frequency for Wave 1 in Hz', ...
    'ValueChangedFcn', @(src,~) setFreq1(src.Value));
efFreq1.Layout.Row = 2; efFreq1.Layout.Column = 2;

lblFreq1Val = uilabel(gSignal,'Text',sprintf('%.0f',state.freq1),'FontSize',12,'HorizontalAlignment','left');
lblFreq1Val.Layout.Row = 2; lblFreq1Val.Layout.Column = 3;

sldFreq1 = uislider(gSignal,'Limits',[20 4000],'Value',state.freq1, ...
    'MajorTicks',[], 'MinorTicks', [], 'FontSize',12, ...
    'Tooltip','Drag to adjust base frequency (20–4000 Hz)', ...
    'ValueChangingFcn', @(src,event) onFreq1Changing(event.Value));
sldFreq1.Layout.Row = 2; sldFreq1.Layout.Column = [4 6];

lbl = uilabel(gSignal,'Text','Ratio 2:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 3; lbl.Layout.Column = 1;
efRatio2 = uieditfield(gSignal,'numeric','Value',state.ratio2,'Limits',[0 Inf],'FontSize',12, ...
    'ValueDisplayFormat','%.2f', ...
    'Tooltip','Wave 2 frequency ratio relative to Wave 1', ...
    'ValueChangedFcn', @(src,~) setRatio2(src.Value));
efRatio2.Layout.Row = 3; efRatio2.Layout.Column = 2;

lblRatio2Val = uilabel(gSignal,'Text',sprintf('%.2f',state.ratio2),'FontSize',12,'HorizontalAlignment','left');
lblRatio2Val.Layout.Row = 3; lblRatio2Val.Layout.Column = 3;

sldRatio2 = uislider(gSignal,'Limits',[0 10],'Value',state.ratio2, ...
    'MajorTicks',[], 'MinorTicks', [], 'FontSize',12, ...
    'Tooltip','Drag to adjust Ratio 2 (0–10)', ...
    'ValueChangingFcn', @(src,event) onRatio2Changing(event.Value));
sldRatio2.Layout.Row = 3; sldRatio2.Layout.Column = [4 6];

lbl = uilabel(gSignal,'Text','Ratio 3:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 4; lbl.Layout.Column = 1;
efRatio3 = uieditfield(gSignal,'numeric','Value',state.ratio3,'Limits',[0 Inf],'FontSize',12, ...
    'ValueDisplayFormat','%.2f', ...
    'Tooltip','Wave 3 frequency ratio relative to Wave 1', ...
    'ValueChangedFcn', @(src,~) setRatio3(src.Value));
efRatio3.Layout.Row = 4; efRatio3.Layout.Column = 2;

lblRatio3Val = uilabel(gSignal,'Text',sprintf('%.2f',state.ratio3),'FontSize',12,'HorizontalAlignment','left');
lblRatio3Val.Layout.Row = 4; lblRatio3Val.Layout.Column = 3;

sldRatio3 = uislider(gSignal,'Limits',[0 10],'Value',state.ratio3, ...
    'MajorTicks',[], 'MinorTicks', [], 'FontSize',12, ...
    'Tooltip','Drag to adjust Ratio 3 (0–10)', ...
    'ValueChangingFcn', @(src,event) onRatio3Changing(event.Value));
sldRatio3.Layout.Row = 4; sldRatio3.Layout.Column = [4 6];

lbl = uilabel(gSignal,'Text','Op 1–2:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 5; lbl.Layout.Column = 1;
ddOp12 = uidropdown(gSignal,'Items',{'Add','Subtract','Multiply'},'Value',state.op12,'FontSize',12, ...
    'Tooltip','Operation between Wave 1 and Wave 2', ...
    'ValueChangedFcn', @(src,~) setOp12(src.Value));
ddOp12.Layout.Row = 5; ddOp12.Layout.Column = 2;

lbl = uilabel(gSignal,'Text','Op 2–3:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 5; lbl.Layout.Column = 3;
ddOp23 = uidropdown(gSignal,'Items',{'Add','Subtract','Multiply'},'Value',state.op23,'FontSize',12, ...
    'Tooltip','Operation between Wave 2 and Wave 3', ...
    'ValueChangedFcn', @(src,~) setOp23(src.Value));
ddOp23.Layout.Row = 5; ddOp23.Layout.Column = 4;

% --- Amplitude & Timing panel controls ---
lbl = uilabel(gAmpDur,'Text','Amp Wave 1:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 1; lbl.Layout.Column = 1;
efConst1 = uieditfield(gAmpDur,'numeric','Value',state.const1,'FontSize',12, ...
    'ValueDisplayFormat','%.2f', ...
    'Tooltip','Amplitude multiplier for Wave 1', ...
    'ValueChangedFcn', @(src,~) setConst1(src.Value));
efConst1.Layout.Row = 1; efConst1.Layout.Column = 2;

lbl = uilabel(gAmpDur,'Text','Amp Wave 2:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 2; lbl.Layout.Column = 1;
efConst2 = uieditfield(gAmpDur,'numeric','Value',state.const2,'FontSize',12, ...
    'ValueDisplayFormat','%.2f', ...
    'Tooltip','Amplitude multiplier for Wave 2', ...
    'ValueChangedFcn', @(src,~) setConst2(src.Value));
efConst2.Layout.Row = 2; efConst2.Layout.Column = 2;

lbl = uilabel(gAmpDur,'Text','Amp Wave 3:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 3; lbl.Layout.Column = 1;
efConst3 = uieditfield(gAmpDur,'numeric','Value',state.const3,'FontSize',12, ...
    'ValueDisplayFormat','%.2f', ...
    'Tooltip','Amplitude multiplier for Wave 3', ...
    'ValueChangedFcn', @(src,~) setConst3(src.Value));
efConst3.Layout.Row = 3; efConst3.Layout.Column = 2;

lbl = uilabel(gAmpDur,'Text','Duration (s):','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 4; lbl.Layout.Column = 1;
efDur = uieditfield(gAmpDur,'numeric','Value',state.duration,'Limits',[0.1 Inf],'FontSize',12, ...
    'ValueDisplayFormat','%.1f', ...
    'Tooltip','Signal length in seconds', ...
    'ValueChangedFcn', @(src,~) setDuration(src.Value));
efDur.Layout.Row = 4; efDur.Layout.Column = 2;

lbl = uilabel(gAmpDur,'Text','Fs (Hz):','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 5; lbl.Layout.Column = 1;
efFs = uieditfield(gAmpDur,'numeric','Value',state.Fs,'Limits',[8000 192000],'FontSize',12, ...
    'ValueDisplayFormat','%.0f', ...
    'Tooltip','Sampling rate (Hz): higher for higher frequencies', ...
    'ValueChangedFcn', @(src,~) setFs(src.Value));
efFs.Layout.Row = 5; efFs.Layout.Column = 2;

% --- View & Playback panel controls ---
lbl = uilabel(gViewPB,'Text','View:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 1; lbl.Layout.Column = 1;
ddView = uidropdown(gViewPB,'Items',{'Full duration','N periods (Wave 1)','N periods (Fastest wave)'}, ...
    'Value',state.viewMode,'FontSize',12, ...
    'Tooltip','Choose full-length view or period-based zoom', ...
    'ValueChangedFcn', @(src,~) setViewMode(src.Value));
ddView.Layout.Row = 1; ddView.Layout.Column = 2;

% Add frequency analysis checkbox
chkFreqAnalysis = uicheckbox(gViewPB,'Text','Show Frequency Analysis','Value',false,'FontSize',12, ...
    'Tooltip','Display FFT analysis of the resulting signal', ...
    'ValueChangedFcn', @(src,~) setFreqAnalysis(src.Value));
chkFreqAnalysis.Layout.Row = 1; chkFreqAnalysis.Layout.Column = 4;

lbl = uilabel(gViewPB,'Text','# Periods:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 1; lbl.Layout.Column = 3;
spnPeriods = uispinner(gViewPB,'Limits',[0.1 100],'Step',0.1,'Value',state.periods,'FontSize',12, ...
    'ValueDisplayFormat','%.1f', ...
    'Tooltip','Number of periods for period-based view', ...
    'ValueChangedFcn', @(src,~) setPeriods(src.Value));
spnPeriods.Layout.Row = 1; spnPeriods.Layout.Column = 3;

lbl = uilabel(gViewPB,'Text','Y Scale:','HorizontalAlignment','right','FontSize',12);
lbl.Layout.Row = 2; lbl.Layout.Column = 1;
ddYScale = uidropdown(gViewPB,'Items',{'Auto','Fixed [-1.2 1.2]'},'Value',state.yScaleMode,'FontSize',12, ...
    'Tooltip','Auto scales per plot or uses fixed range', ...
    'ValueChangedFcn', @(src,~) setYScaleMode(src.Value));
ddYScale.Layout.Row = 2; ddYScale.Layout.Column = 2;

chkAutoUpdate = uicheckbox(gViewPB,'Text','Auto Update','Value',state.autoUpdate,'FontSize',12, ...
    'Tooltip','Recompute plots immediately on change', ...
    'ValueChangedFcn', @(src,~) setAutoUpdate(src.Value));
chkAutoUpdate.Layout.Row = 2; chkAutoUpdate.Layout.Column = 4;


chkNormalize = uicheckbox(gViewPB,'Text','Normalize Audio','Value',state.normalizeAudio,'FontSize',12, ...
    'Tooltip','Normalize audio to avoid clipping on playback/export', ...
    'ValueChangedFcn', @(src,~) setNormalizeAudio(src.Value));
chkNormalize.Layout.Row = 3; chkNormalize.Layout.Column = 4;

btnPlay = uibutton(gViewPB,'Text','Generate & Play','FontSize',13,'ButtonPushedFcn', @(~,~) recompute(true));
btnPlay.Layout.Row = 4; btnPlay.Layout.Column = 2;

btnStop = uibutton(gViewPB,'Text','Stop','FontSize',13,'ButtonPushedFcn', @(~,~) stopAudio());
btnStop.Layout.Row = 4; btnStop.Layout.Column = 4;

btnExport = uibutton(gViewPB,'Text','Export WAV','FontSize',13,'ButtonPushedFcn', @(~,~) exportWav());
btnExport.Layout.Row = 5; btnExport.Layout.Column = [2 4];

% --- Axes layout (bottom row) ---
if state.showFreqAnalysis
    plotsGrid = uigridlayout(mainGrid,[2 3]);
    plotsGrid.Layout.Row = 2;
    plotsGrid.RowHeight = {'1x','1x'};
    plotsGrid.ColumnWidth = {'1x','1x','1.3x'};
    plotsGrid.ColumnSpacing = 16; plotsGrid.RowSpacing = 12; plotsGrid.Padding = [12 8 12 10];
    
    % Time domain plots
    axWave1 = uiaxes(plotsGrid); axWave1.Layout.Row = 1; axWave1.Layout.Column = 1;
    styleAxes(axWave1,'Wave 1');
    hW1 = plot(axWave1, NaN, NaN, 'r', 'LineWidth',1.6);

    axWave2 = uiaxes(plotsGrid); axWave2.Layout.Row = 1; axWave2.Layout.Column = 2;
    styleAxes(axWave2,'Wave 2 and Wave 3');
    hW2 = plot(axWave2, NaN, NaN, 'b', 'LineWidth',1.6); hold(axWave2,'on');
    hW3 = plot(axWave2, NaN, NaN, 'g--', 'LineWidth',1.3); hold(axWave2,'off');
    legW23 = legend(axWave2, {'Wave 2','Wave 3'}, 'Location','northeast'); legW23.Box = 'off'; legW23.AutoUpdate = 'off'; legW23.Visible = 'off';

    axResult = uiaxes(plotsGrid); axResult.Layout.Row = 1; axResult.Layout.Column = 3;
    styleAxes(axResult,'Resulting Signal');
    hRes = plot(axResult, NaN, NaN, 'k', 'LineWidth',2.0);
    
    % Frequency domain plots
    axFreq1 = uiaxes(plotsGrid); axFreq1.Layout.Row = 2; axFreq1.Layout.Column = 1;
    styleAxes(axFreq1,'Wave 1 Spectrum');
    hF1 = plot(axFreq1, NaN, NaN, 'r', 'LineWidth',1.6);

    axFreq2 = uiaxes(plotsGrid); axFreq2.Layout.Row = 2; axFreq2.Layout.Column = 2;
    styleAxes(axFreq2,'Wave 2 & 3 Spectrum');
    hF2 = plot(axFreq2, NaN, NaN, 'b', 'LineWidth',1.6); hold(axFreq2,'on');
    hF3 = plot(axFreq2, NaN, NaN, 'g--', 'LineWidth',1.3); hold(axFreq2,'off');

    axFreqRes = uiaxes(plotsGrid); axFreqRes.Layout.Row = 2; axFreqRes.Layout.Column = 3;
    styleAxes(axFreqRes,'Result Spectrum');
    hFRes = plot(axFreqRes, NaN, NaN, 'k', 'LineWidth',2.0);
else
    plotsGrid = uigridlayout(mainGrid,[1 3]);
    plotsGrid.Layout.Row = 2;
    plotsGrid.ColumnWidth = {'1x','1x','1.3x'};
    plotsGrid.ColumnSpacing = 16; plotsGrid.Padding = [12 8 12 10];

    axWave1 = uiaxes(plotsGrid); axWave1.Layout.Column = 1;
    styleAxes(axWave1,'Wave 1');
    hW1 = plot(axWave1, NaN, NaN, 'r', 'LineWidth',1.6);

    axWave2 = uiaxes(plotsGrid); axWave2.Layout.Column = 2;
    styleAxes(axWave2,'Wave 2 and Wave 3');
    hW2 = plot(axWave2, NaN, NaN, 'b', 'LineWidth',1.6); hold(axWave2,'on');
    hW3 = plot(axWave2, NaN, NaN, 'g--', 'LineWidth',1.3); hold(axWave2,'off');
    legW23 = legend(axWave2, {'Wave 2','Wave 3'}, 'Location','northeast'); legW23.Box = 'off'; legW23.AutoUpdate = 'off'; legW23.Visible = 'off';

    axResult = uiaxes(plotsGrid); axResult.Layout.Column = 3;
    styleAxes(axResult,'Resulting Signal');
    hRes = plot(axResult, NaN, NaN, 'k', 'LineWidth',2.0);
end

% Audio player
player = [];

% --- Callbacks & Helpers ---
function styleAxes(ax, ttl)
    ax.Color = [1 1 1];
    grid(ax,'on');
    xlabel(ax,'Time (s)','FontSize',12);
    ylabel(ax,'Amplitude','FontSize',12);
    title(ax, ttl, 'FontWeight','bold');
    ax.FontSize = 12;
    ax.TitleFontSizeMultiplier = 1.0;
end

function onNumWavesChanged(val)
    state.numWaves = val;
    tf = (val == 3);
    ddOp23.Enable = onOff(tf);
    efRatio3.Enable = onOff(tf);
    sldRatio3.Enable = onOff(tf);
    efConst3.Enable = onOff(tf);
    if tf
        legW23.Visible = 'on';
    else
        set(hW3,'XData',NaN,'YData',NaN);
        legW23.Visible = 'off';
    end
    maybeRecompute(false);
end

function setFreq1(val)
    state.freq1 = max(0,val);
    efFreq1.Value = state.freq1;
    sldFreq1.Value = clamp(state.freq1, sldFreq1.Limits);
    lblFreq1Val.Text = sprintf('%.0f',state.freq1);
    maybeRecompute(false);
end

function onFreq1Changing(val)
    state.freq1 = max(0,val);
    efFreq1.Value = state.freq1;
    lblFreq1Val.Text = sprintf('%.0f',state.freq1);
    maybeRecompute(false);
end

function setRatio2(val)
    state.ratio2 = max(0,val);
    efRatio2.Value = state.ratio2;
    sldRatio2.Value = clamp(state.ratio2, sldRatio2.Limits);
    lblRatio2Val.Text = sprintf('%.2f',state.ratio2);
    maybeRecompute(false);
end

function onRatio2Changing(val)
    state.ratio2 = max(0,val);
    efRatio2.Value = state.ratio2;
    lblRatio2Val.Text = sprintf('%.2f',state.ratio2);
    maybeRecompute(false);
end

function setRatio3(val)
    state.ratio3 = max(0,val);
    efRatio3.Value = state.ratio3;
    sldRatio3.Value = clamp(state.ratio3, sldRatio3.Limits);
    lblRatio3Val.Text = sprintf('%.2f',state.ratio3);
    maybeRecompute(false);
end

function onRatio3Changing(val)
    state.ratio3 = max(0,val);
    efRatio3.Value = state.ratio3;
    lblRatio3Val.Text = sprintf('%.2f',state.ratio3);
    maybeRecompute(false);
end

function setOp12(val)
    state.op12 = val; ddOp12.Value = val; maybeRecompute(false);
end

function setOp23(val)
    state.op23 = val; ddOp23.Value = val; maybeRecompute(false);
end

function setConst1(val)
    state.const1 = val; efConst1.Value = val; maybeRecompute(false);
end

function setConst2(val)
    state.const2 = val; efConst2.Value = val; maybeRecompute(false);
end

function setConst3(val)
    state.const3 = val; efConst3.Value = val; maybeRecompute(false);
end

function setDuration(val)
    state.duration = max(0.1,val); efDur.Value = state.duration; maybeRecompute(false);
end

function setFs(val)
    state.Fs = max(8000, min(192000, val)); efFs.Value = state.Fs; maybeRecompute(false);
end

function setViewMode(val)
    state.viewMode = val; ddView.Value = val; maybeRecompute(false);
end

function setPeriods(val)
    state.periods = max(0.1,val); spnPeriods.Value = state.periods; maybeRecompute(false);
end

function setYScaleMode(val)
    state.yScaleMode = val; ddYScale.Value = val; maybeRecompute(false);
end

function setAutoUpdate(val)
    state.autoUpdate = logical(val);
end


function setNormalizeAudio(val)
    state.normalizeAudio = logical(val);
end

function setFreqAnalysis(val)
    state.showFreqAnalysis = logical(val);
    maybeRecompute(false);
end

function maybeRecompute(forcePlay)
    if state.autoUpdate
        recompute(forcePlay);
    end
end

function recompute(doPlay)
    % Generate time base with adaptive sampling for smooth plots
    % Calculate required sampling rate based on highest frequency
    f1 = state.freq1; f2 = f1*state.ratio2; f3 = f1*state.ratio3;
    maxFreq = max([f1, f2, f3]);
    
    % Use at least 10 samples per period for smooth visualization
    minSamplesPerPeriod = 10;
    requiredFs = maxFreq * minSamplesPerPeriod;
    visFs = max([state.Fs, requiredFs, 22050]); % Reduced minimum for better performance
    
    N = max(1, round(state.duration*visFs));
    t = (0:N-1)/visFs;

    % Angular frequencies
    w1 = 2*pi*f1; w2 = 2*pi*f2; w3 = 2*pi*f3;

    % Waves
    wave1 = state.const1 * sin(w1 * t);
    wave2 = state.const2 * sin(w2 * t);

    switch state.op12
        case 'Add',      temp_res = wave1 + wave2;
        case 'Subtract', temp_res = wave1 - wave2;
        case 'Multiply', temp_res = wave1 .* wave2;
    end

    if state.numWaves == 3
        wave3 = state.const3 * sin(w3 * t);
        switch state.op23
            case 'Add',      result = temp_res + wave3;
            case 'Subtract', result = temp_res - wave3;
            case 'Multiply', result = temp_res .* wave3;
        end
    else
        wave3 = [];
        result = temp_res;
    end

    % Update plots
    updatePlot(axWave1, hW1, t, wave1);
    updatePlot(axWave2, hW2, t, wave2);
    if state.numWaves == 3
        updatePlot(axWave2, hW3, t, wave3);
        legW23.Visible = 'on';
    else
        set(hW3,'XData',NaN,'YData',NaN);
        legW23.Visible = 'off';
    end
    updatePlot(axResult, hRes, t, result);
    
    % Update frequency analysis if enabled
    if state.showFreqAnalysis
        updateFrequencyAnalysis(t, wave1, wave2, wave3, result, visFs);
    end

    % Harmonize X-limits across axes
    fActive = [max(f1,0), max(f2,0)];
    if state.numWaves == 3, fActive(end+1) = max(f3,0); end
    [x0,x1] = computeXWindow(t, fActive, state.viewMode, state.periods);
    set([axWave1,axWave2,axResult], 'XLim', [x0 x1]);

    % Y scaling
    applyYScale(axWave1, wave1, state.yScaleMode);
    applyYScale(axWave2, [wave2(:); wave3(:)], state.yScaleMode);
    applyYScale(axResult, result, state.yScaleMode);

    % Update equation label
    updateEquationLabel(f1, f2, f3);

    drawnow limitrate;
    if doPlay, playAudio(result); end
end

function [x0,x1] = computeXWindow(t, freqs, viewMode, periods)
    x0 = 0; x1 = t(end);
    switch viewMode
        case 'Full duration'
        case 'N periods (Wave 1)'
            fref = freqs(1);
            if fref > 0
                L = min(periods / fref, t(end));
                x1 = max(L, t(2));
            end
        case 'N periods (Fastest wave)'
            fref = max(freqs);
            if fref > 0
                L = min(periods / fref, t(end));
                x1 = max(L, t(2));
            end
    end
end

function updateEquationLabel(f1,f2,f3)
    op12sym = pickOpSymbol(state.op12);
    if state.numWaves == 3
        op23sym = pickOpSymbol(state.op23);
        eq = sprintf('$$y(t) = \\big(%.3g\\,\\sin(2\\pi\\,%.3g\\,t)\\ %s\\ %.3g\\,\\sin(2\\pi\\,%.3g\\,t)\\big)\\ %s\\ %.3g\\,\\sin(2\\pi\\,%.3g\\,t)$$' ...
            , state.const1, f1, op12sym, state.const2, f2, op23sym, state.const3, f3);
    else
        eq = sprintf('$$y(t) = %.3g\\,\\sin(2\\pi\\,%.3g\\,t)\\ %s\\ %.3g\\,\\sin(2\\pi\\,%.3g\\,t)$$' ...
            , state.const1, f1, op12sym, state.const2, f2);
    end
    lblEq.Text = eq; % LaTeX rendering
end

function s = pickOpSymbol(op)
    switch op
        case 'Add',      s = '+';
        case 'Subtract', s = '-';
        case 'Multiply', s = '\cdot';
    end
end

function updatePlot(~, hLine, t, y)
    hLine.XData = t;
    hLine.YData = y;
end

function updateFrequencyAnalysis(t, wave1, wave2, wave3, result, Fs)
    % Compute FFT for each signal
    N = length(t);
    freqs = (0:N-1) * Fs / N;
    freqs = freqs(1:floor(N/2)); % Only positive frequencies
    
    % Create Hann window (fallback for older MATLAB versions)
    if exist('hann', 'file')
        window = hann(N)';
    else
        % Manual Hann window implementation
        window = 0.5 * (1 - cos(2*pi*(0:N-1)/(N-1)));  % Row vector to match signal dimensions
    end
    
    % FFT of individual waves with proper windowing to reduce spectral leakage
    fft1 = abs(fft(wave1 .* window));
    fft1 = fft1(1:floor(N/2));
    
    fft2 = abs(fft(wave2 .* window));
    fft2 = fft2(1:floor(N/2));
    
    if state.numWaves == 3 && ~isempty(wave3)
        fft3 = abs(fft(wave3 .* window));
        fft3 = fft3(1:floor(N/2));
    else
        fft3 = zeros(size(fft1));
    end
    
    % FFT of result
    fftRes = abs(fft(result .* window));
    fftRes = fftRes(1:floor(N/2));
    
    % Update frequency plots with proper error checking
    if exist('hF1', 'var') && isvalid(hF1) && exist('axFreq1', 'var') && isvalid(axFreq1)
        updatePlot(axFreq1, hF1, freqs, fft1);
        xlabel(axFreq1, 'Frequency (Hz)');
        ylabel(axFreq1, 'Magnitude');
        title(axFreq1, 'Wave 1 Spectrum');
    end
    
    if exist('hF2', 'var') && isvalid(hF2) && exist('axFreq2', 'var') && isvalid(axFreq2)
        updatePlot(axFreq2, hF2, freqs, fft2);
        if state.numWaves == 3 && exist('hF3', 'var') && isvalid(hF3)
            updatePlot(axFreq2, hF3, freqs, fft3);
        end
        xlabel(axFreq2, 'Frequency (Hz)');
        ylabel(axFreq2, 'Magnitude');
        title(axFreq2, 'Wave 2 & 3 Spectrum');
    end
    
    if exist('hFRes', 'var') && isvalid(hFRes) && exist('axFreqRes', 'var') && isvalid(axFreqRes)
        updatePlot(axFreqRes, hFRes, freqs, fftRes);
        xlabel(axFreqRes, 'Frequency (Hz)');
        ylabel(axFreqRes, 'Magnitude');
        title(axFreqRes, 'Result Spectrum');
    end
end

function applyYScale(ax, y, mode)
    switch mode
        case 'Auto'
            if isempty(y) || all(isnan(y)) || all(isinf(y))
                yr = 1; % Default range for invalid data
            else
                yr = max(0.5, max(abs(y))+eps);
            end
            ylim(ax, 1.2*[-1 1]*yr);
        case 'Fixed [-1.2 1.2]'
            ylim(ax, [-1.2 1.2]);
    end
end

function playAudio(~)
    stopAudio();
    
    % Generate audio at correct sampling rate to match visualization
    % Calculate required sampling rate based on highest frequency
    f1 = state.freq1; f2 = f1*state.ratio2; f3 = f1*state.ratio3;
    maxFreq = max([f1, f2, f3]);
    
    % Use at least 10 samples per period for smooth audio
    minSamplesPerPeriod = 10;
    requiredFs = maxFreq * minSamplesPerPeriod;
    audioFs = max([state.Fs, requiredFs, 22050]);
    
    N_audio = max(1, round(state.duration*audioFs));
    t_audio = (0:N_audio-1)/audioFs;
    
    % Angular frequencies
    w1 = 2*pi*f1; w2 = 2*pi*f2; w3 = 2*pi*f1*state.ratio3;
    
    % Generate waves at audio sampling rate
    wave1_audio = state.const1 * sin(w1 * t_audio);
    wave2_audio = state.const2 * sin(w2 * t_audio);
    
    switch state.op12
        case 'Add',      temp_res = wave1_audio + wave2_audio;
        case 'Subtract', temp_res = wave1_audio - wave2_audio;
        case 'Multiply', temp_res = wave1_audio .* wave2_audio;
    end
    
    if state.numWaves == 3
        wave3_audio = state.const3 * sin(w3 * t_audio);
        switch state.op23
            case 'Add',      audioResult = temp_res + wave3_audio;
            case 'Subtract', audioResult = temp_res - wave3_audio;
            case 'Multiply', audioResult = temp_res .* wave3_audio;
        end
    else
        audioResult = temp_res;
    end
    
    sig = audioResult;
    if state.normalizeAudio
        m = max(abs(sig)); if m > 0, sig = sig / m; end
    end
    player = audioplayer(sig, audioFs);
    play(player);
end

function stopAudio()
    if ~isempty(player) && isplaying(player)
        stop(player);
    end
end

function exportWav()
    % Generate audio at correct sampling rate for export
    f1 = state.freq1; f2 = f1*state.ratio2; f3 = f1*state.ratio3;
    maxFreq = max([f1, f2, f3]);
    
    % Use at least 10 samples per period for smooth audio
    minSamplesPerPeriod = 10;
    requiredFs = maxFreq * minSamplesPerPeriod;
    exportFs = max([state.Fs, requiredFs, 22050]);
    
    N_export = max(1, round(state.duration*exportFs));
    t_export = (0:N_export-1)/exportFs;
    
    % Angular frequencies
    w1 = 2*pi*f1; w2 = 2*pi*f2; w3 = 2*pi*f1*state.ratio3;
    
    % Generate waves at export sampling rate
    wave1_export = state.const1 * sin(w1 * t_export);
    wave2_export = state.const2 * sin(w2 * t_export);
    
    switch state.op12
        case 'Add',      temp_res = wave1_export + wave2_export;
        case 'Subtract', temp_res = wave1_export - wave2_export;
        case 'Multiply', temp_res = wave1_export .* wave2_export;
    end
    
    if state.numWaves == 3
        wave3_export = state.const3 * sin(w3 * t_export);
        switch state.op23
            case 'Add',      y = temp_res + wave3_export;
            case 'Subtract', y = temp_res - wave3_export;
            case 'Multiply', y = temp_res .* wave3_export;
        end
    else
        y = temp_res;
    end
    
    if isempty(y) || all(~isfinite(y))
        try
            uialert(fig,'No audio to export.','Export WAV');
        catch
            fprintf('No audio to export.\n');
        end
        return;
    end
    
    % Validate data before export
    if any(~isfinite(y))
        y(~isfinite(y)) = 0;  % Replace NaN/Inf with zeros
    end
    
    if state.normalizeAudio
        m = max(abs(y)); 
        if m > 0, y = y/m; end
    end
    
    [fn,fp] = uiputfile('*.wav','Save audio as','multi_sine.wav');
    if isequal(fn,0), return; end
    
    try
        audiowrite(fullfile(fp,fn), y, exportFs);
    catch ME
        try
            uialert(fig, sprintf('Export failed: %s', ME.message), 'Export Error');
        catch
            fprintf('Export failed: %s\n', ME.message);
        end
    end
end

    function showHelp()
        helpText = ['HOW TO USE THIS APP:' newline newline ...
            '1. WAVE GENERATION:' newline ...
            '   • Select number of waves (2 or 3) using the dropdown' newline ...
            '   • Adjust frequencies using sliders or input fields' newline ...
            '   • Set amplitude ratios for each wave' newline ...
            '   • Choose operation: Add, Subtract, or Multiply' newline newline ...
            '2. VISUALIZATION:' newline ...
            '   • Time domain: See individual waves and combined result' newline ...
            '   • Frequency domain: Check "Show FFT" to see frequency content' newline ...
            '   • Zoom and pan to examine details' newline newline ...
            '3. AUDIO PLAYBACK:' newline ...
            '   • Click "Play" to hear the combined signal' newline ...
            '   • Use "Export" to save as WAV file' newline ...
            '   • Adjust duration and sample rate as needed' newline newline ...
            '4. EDUCATIONAL FEATURES:' newline ...
            '   • Observe wave interference patterns' newline ...
            '   • Study frequency domain representations' newline ...
            '   • Understand how operations affect the signal' newline ...
            '   • Learn about harmonic relationships'];
        
        % Create a figure with scrollable text
        helpFig = uifigure('Name', 'Help - Multi-Sine Wave Generator', 'Position', [300 300 500 400]);
        helpFig.CloseRequestFcn = @(~,~) delete(helpFig);
        
        % Create scrollable text area
        helpTextArea = uitextarea(helpFig, 'Value', helpText, 'Position', [10 10 480 380], ...
            'FontSize', 12, 'FontName', 'Consolas', 'Editable', 'off');
        
% Add scrollbar
if isprop(helpTextArea, 'Scrollable')
    helpTextArea.Scrollable = true;
end

    end

function onClose()
    try
        stopAudio();
    catch
        % Ignore errors during cleanup
    end
    try
        if isvalid(fig)
            delete(fig);
        end
    catch
        % Ignore errors during cleanup
    end
end

function out = onOff(tf)
    out = tern(tf,'on','off');
end

function y = tern(tf,a,b)
    if tf, y=a; else, y=b; end
end

function v = clamp(x, lims)
    v = min(max(x,lims(1)),lims(2));
end

% Initialize and first render
onNumWavesChanged(state.numWaves);
recompute(false);
end
