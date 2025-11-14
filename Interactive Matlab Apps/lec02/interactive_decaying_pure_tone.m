% INTERACTIVE EXPONENTIAL SIGNAL EXPLORER
% 
% Author: Ahmed Rabei - TEFO, 2025
% Version: 1.0
% 
% DESCRIPTION:
% This interactive MATLAB app demonstrates exponential signal concepts
% by allowing users to explore continuous-time and discrete-time exponential
% signals with real-time parameter control. Users can visualize the relationship
% between CT and DT exponential signals and hear the audio representation.
% 
% FEATURES:
% - Interactive parameter control for amplitude, rate, and frequency
% - Real-time visualization of CT and DT exponential signals
% - Audio playback with exponential envelope modulation
% - Mathematical analysis display (sampling period, time constant)
% - Visual comparison of continuous and discrete representations
% - Educational tooltips and parameter explanations
% 
% EDUCATIONAL PURPOSE:
% - Understanding exponential signal properties
% - CT/DT signal relationship and sampling concepts
% - Time constant and decay rate visualization
% - Audio signal processing with exponential envelopes
% - Interactive parameter exploration
% 
% Notes:
% - Supports both growing (α>0) and decaying (α<0) exponentials
% - Real-time audio generation with configurable sampling rate
% - Mathematical analysis includes time constant calculation
% - Visual comparison with optional DT sample connections

function interactive_pure_tone
    defaults.A = 1.0;
    defaults.alpha = -1.5;
    defaults.duration = 10;
    defaults.N = 11;
    defaults.playFreq = 390;
    defaults.normalizeAudio = true;
    defaults.connectDT = false;
    defaults.dashedCurve = 'DT';
    state = defaults;
    state.Fs = 44100;
    state.wasAliasing = false;
    state.suppressAlert = false;

    colors.CT = [0.90 0.20 0.20];
    colors.DT = [0.10 0.40 0.80];
    colors.Tau = [0.40 0.40 0.40];

    fig = uifigure('Name','Advanced Exponential Explorer','Position',[200 200 1000 820], 'Color',[1 1 1]);
    fig.CloseRequestFcn = @(~,~) onClose();
    mainGrid = uigridlayout(fig,[2 1]);
    mainGrid.RowHeight = {'fit','1x'};
    mainGrid.Padding = [15 15 15 15];
    mainGrid.RowSpacing = 12;

    pCtrl = uipanel(mainGrid,'Title','Controls','FontSize',15,'FontWeight','bold');
    pCtrl.Layout.Row = 1;

    ctrlGrid = uigridlayout(pCtrl,[1 4]);
    ctrlGrid.ColumnWidth = {'1x','1x','0.7x','0.7x'};
    ctrlGrid.Padding = [10 10 10 10];
    ctrlGrid.ColumnSpacing = 15;

    pSignal   = uipanel(ctrlGrid,'Title','Signal Parameters','FontWeight','bold'); pSignal.Layout.Column = 1;
    pSample   = uipanel(ctrlGrid,'Title','Sampling & Visualization','FontWeight','bold'); pSample.Layout.Column = 2;
    pAnalysis = uipanel(ctrlGrid,'Title','Analysis','FontWeight','bold'); pAnalysis.Layout.Column = 3;
    pActions  = uipanel(ctrlGrid,'Title','Actions','FontWeight','bold'); pActions.Layout.Column = 4;

    gSignal = uigridlayout(pSignal,[3 3]);
    gSignal.ColumnWidth = {'fit','1x','fit'};
    gSignal.RowHeight = {'fit','fit','fit'};
    gSignal.Padding = [8 8 8 8]; gSignal.RowSpacing = 8; gSignal.ColumnSpacing = 8;

    gSample = uigridlayout(pSample,[3 3]);
    gSample.ColumnWidth = {'fit','1x','fit'};
    gSample.RowHeight = {'fit','fit','fit'};
    gSample.Padding = [8 8 8 8]; gSample.RowSpacing = 8; gSample.ColumnSpacing = 8;

    gAnalysis = uigridlayout(pAnalysis,[3 1]);
    gAnalysis.RowHeight = {'fit','fit','fit'};
    gAnalysis.Padding = [15 10 15 10]; gAnalysis.RowSpacing = 10;

    gActions = uigridlayout(pActions,[4 1]);
    gActions.RowHeight = repmat({'fit'}, 1, 4);
    gActions.Padding = [10 15 10 15]; gActions.RowSpacing = 8;

    [sldA, edtA]         = addLabelSlider(gSignal,  'Amplitude A:',       1, [0 5],    state.A,          @onA, ...
                                                    'Initial amplitude of the signal.');
    [sldAlpha, edtAlpha] = addLabelSlider(gSignal,  'Rate  alpha:',       2, [-2 2],   state.alpha,      @onAlpha, ...
                                                    'Growth (>0) or decay (<0) rate per second.');
    [sldFreq, edtFreq]   = addLabelSlider(gSignal,  'Carrier Freq (Hz):', 3, [20 25000], state.playFreq, @onFreq, ...
                                                    'Sine carrier frequency for the heard signal. Values above 22050 Hz will cause aliasing.');

    [sldN, edtN]         = addLabelSlider(gSample,  'DT Samples N:',      1, [5 200],  state.N,          @onN, ...
                                                    'Number of discrete samples across the duration.');
    [sldDur, edtDur]     = addLabelSlider(gSample,  'Duration (s):',      2, [0.5 10], state.duration,   @onDur, ...
                                                    'Total continuous-time window for plotting and playback.');

    lblDash = uilabel(gSample,'Text','Dashed Curve:','HorizontalAlignment','right','FontSize',12, ...
                      'Tooltip','Choose which curve is dashed.');
    lblDash.Layout.Row = 3; lblDash.Layout.Column = 1;

    ddDashed = uidropdown(gSample,'Items',{'DT','CT'},'Value',state.dashedCurve, ...
                          'ValueChangedFcn',@(src,~) setParam('dashedCurve',src.Value), ...
                          'Tooltip','Choose which curve is dashed.');
    ddDashed.Layout.Row = 3; ddDashed.Layout.Column = 2;

    chkConnect = uicheckbox(gSample,'Text','Connect DT Samples','Value',state.connectDT,'FontSize',12, ...
                            'ValueChangedFcn',@(s,~) setParam('connectDT',logical(s.Value)), ...
                            'Tooltip','Draw lines connecting the DT samples.');
    chkConnect.Layout.Row = 3; chkConnect.Layout.Column = 3;

    lblT       = uilabel(gAnalysis,'Text','Sampling Period (T): - s','FontSize',13,'Interpreter','latex');
    lblTau     = uilabel(gAnalysis,'Text','Time Constant (\tau): - s','FontSize',13,'Interpreter','latex');
    lblAlphaDT = uilabel(gAnalysis,'Text','DT Base (\alpha): -','FontSize',13,'Interpreter','latex');

    btnPlay   = uibutton(gActions,'Text','▶ Play Audio','FontSize',14,'FontWeight','bold','ButtonPushedFcn',@(~,~) playTone(), ...
                         'Tooltip','Play a tone modulated by the CT exponential envelope.');
    btnPlay.Layout.Row = 1;

    btnStop   = uibutton(gActions,'Text','■ Stop','FontSize',14,'ButtonPushedFcn',@(~,~) stopAudio(), ...
                         'Tooltip','Stop audio playback.','Enable','off');
    btnStop.Layout.Row = 2;

    chkNorm   = uicheckbox(gActions,'Text','Normalize Audio','Value',state.normalizeAudio,'FontSize',12, ...
                           'ValueChangedFcn',@(s,~) setParam('normalizeAudio',logical(s.Value)), ...
                           'Tooltip','Scale audio to full range if nonzero.');
    chkNorm.Layout.Row = 3;

    btnReset  = uibutton(gActions,'Text','Reset','FontSize',14,'ButtonPushedFcn',@(~,~) resetParams(), ...
                         'Tooltip','Reset all parameters to defaults.');
    btnReset.Layout.Row = 4;

    plotPanel = uipanel(mainGrid); plotPanel.Layout.Row = 2;

    plotGrid = uigridlayout(plotPanel,[4 1]);
    plotGrid.RowHeight = {'1x','fit','fit','0.8x'};
    plotGrid.Padding = [10 5 10 10];

    ax = uiaxes(plotGrid);
    ax.Layout.Row = 1;
    ax.XLabel.String = 'Time (t)';
    ax.YLabel.String = 'Amplitude';
    ax.FontSize = 12;
    grid(ax,'on');

    lblEq  = uilabel(plotGrid,'Interpreter','latex','FontSize',16,'HorizontalAlignment','center');
    lblEq.Layout.Row = 2;

    infoTx = uilabel(plotGrid,'FontSize',13,'HorizontalAlignment','center');
    infoTx.Layout.Row = 3;

    axAudio = uiaxes(plotGrid);
    axAudio.Layout.Row = 4;
    axAudio.XLabel.String = 'Time (t)';
    axAudio.YLabel.String = 'Audio amplitude';
    axAudio.FontSize = 12;
    grid(axAudio,'on');
    axAudio.Title.String = 'Heard Signal';
    axAudio.Title.FontWeight = 'bold';

    hold(ax,'on');
    hCT  = plot(ax,NaN,NaN,'-','Color',colors.CT,'LineWidth',2.0, ...
               'DisplayName','$y(t) = A e^{\alpha t}$');

    hDT = stem(ax,NaN,NaN,'filled','Color',colors.DT, ...
               'MarkerFaceColor',colors.DT,'MarkerEdgeColor','k', ...
               'LineWidth',1.2,'DisplayName','$y[n] = y(nT)$');
    hDT.BaseValue = 0;

    hDTconn = plot(ax,NaN,NaN,'-','Color',min(colors.DT*1.1,1), ...
                   'LineWidth',1.0,'HandleVisibility','off','Visible','off');

    legend(ax,'Location','best','FontSize',12,'Interpreter','latex');
    hold(ax,'off');

    hAudio = plot(axAudio,NaN,NaN,'-','Color',[0.15 0.15 0.15],'LineWidth',1.2, ...
                  'DisplayName','x(t) = \sin(2\pi f t)\, A e^{\alpha t}');

    player = [];

    updateAll();

    function [sld, edt] = addLabelSlider(parent, txt, r, lims, val, cb, tip)
        lbl = uilabel(parent,'Text',txt,'HorizontalAlignment','right','FontSize',12,'Tooltip',tip);
        lbl.Layout.Row = r; lbl.Layout.Column = 1;

        sld = uislider(parent,'Limits',lims,'Value',val,'Tooltip',tip);
        sld.Layout.Row = r; sld.Layout.Column = 2;

        edt = uieditfield(parent,'numeric','Value',val,'Tooltip',tip);
        edt.Layout.Row = r; edt.Layout.Column = 3;

        sld.ValueChangingFcn = @(~,evt) cb(evt.Value);
        sld.ValueChangedFcn  = @(src,~) cb(src.Value);
        edt.ValueChangedFcn  = @(src,~) cb(src.Value);
    end

    function onA(val)
        state.A = clamp(val, sldA.Limits);
        sldA.Value = state.A; edtA.Value = state.A;
        updateAll();
    end

    function onAlpha(val)
        state.alpha = clamp(val, sldAlpha.Limits);
        sldAlpha.Value = state.alpha; edtAlpha.Value = state.alpha;
        updateAll();
    end

    function onFreq(val)
        v = clamp(val, sldFreq.Limits);
        state.playFreq = v;
        sldFreq.Value = state.playFreq; edtFreq.Value = state.playFreq;
        updateAll();
    end

    function onN(val)
        state.N = max(2, round(clamp(val, sldN.Limits)));
        sldN.Value = state.N; edtN.Value = state.N;
        updateAll();
    end

    function onDur(val)
        state.duration = clamp(val, sldDur.Limits);
        sldDur.Value = state.duration; edtDur.Value = state.duration;
        updateAll();
    end

    function setParam(field, val)
        state.(field) = val;
        updateAll();
    end

    function [t, env, tone] = getAudio()
        t = (0:1/state.Fs:state.duration).';
        env = state.A * exp(state.alpha * t);
        env(env < 0) = 0;
        
        tone = sin(2*pi*state.playFreq*t) .* env;
    end

    function updateAll()
        T = state.duration / (state.N - 1);

        n    = 0:(state.N-1);
        t_dt = n * T;
        t_ct = linspace(0, t_dt(end), 1000);

        dt_vals = state.A * exp(state.alpha * t_dt);
        ct_vals = state.A * exp(state.alpha * t_ct);

        hCT.XData = t_ct; hCT.YData = ct_vals;
        set(hDT,'XData',t_dt,'YData',dt_vals);

        if state.connectDT
            set(hDTconn,'XData',t_dt,'YData',dt_vals,'Visible','on');
        else
            set(hDTconn,'Visible','off');
        end

        if strcmp(state.dashedCurve,'DT')
            hDT.LineStyle = '--';
            hCT.LineStyle = '-';
            if strcmp(hDTconn.Visible,'on'), hDTconn.LineStyle = '--'; end
        else
            hDT.LineStyle = '-';
            hCT.LineStyle = '--';
            if strcmp(hDTconn.Visible,'on'), hDTconn.LineStyle = '-'; end
        end

        xlim(ax,[0, max(0.01, t_dt(end))*1.02]);
        allv = [ct_vals(:); dt_vals(:)];
        ymin = min([0; allv]); ymax = max([0; allv]);
        yrng = max(ymax - ymin, 0.1);
        ylim(ax,[ymin - 0.1*yrng, ymax + 0.1*yrng]);

        alpha_dt = exp(state.alpha * T);
        lblT.Text       = sprintf('Sampling Period (T): %.4f s', T);
        lblAlphaDT.Text = sprintf('DT Base (\\alpha): %.4f', alpha_dt);
        if state.alpha < -1e-6
            tau = -1/state.alpha;
            lblTau.Text = sprintf('Time Constant (\\tau): %.4f s', tau);
            lblTau.Visible = 'on';
        else
            lblTau.Visible = 'off';
        end

        ax.Title.Interpreter = 'latex';
        ax.Title.String = sprintf('Exponential Signal: $A=%.2f$, $\\alpha=%.2f$', state.A, state.alpha);
        lblEq.Text = sprintf('$$ y(t) = %.2f\\, e^{%.2f t} \\;\\Rightarrow\\; y[n] = %.2f\\,(%.3f)^n $$', ...
                             state.A, state.alpha, state.A, alpha_dt);

        if abs(alpha_dt - 1) < 1e-6
            infoTx.Text = 'Constant Signal: |α| = 1';
        elseif abs(alpha_dt) < 1
            infoTx.Text = 'Decaying Signal: |α| < 1';
        else
            infoTx.Text = 'Growing Signal: |α| > 1';
        end

        [t, ~, tone] = getAudio();

        maxPts = 4000;
        step = max(1, floor(numel(t)/maxPts));
        td = t(1:step:end);
        xd = tone(1:step:end);
        
        set(hAudio,'XData',td,'YData',xd);

        xlim(axAudio,[0, max(0.01, t(end))*1.02]);
        yA = max(1e-6, max(abs(xd)));
        ylim(axAudio, 1.1*[-yA yA]);

        drawnow limitrate
    end

    function playTone()
        stopAudio();
        [~, ~, tone] = getAudio();
        if state.normalizeAudio && max(abs(tone)) > 0
            tone = tone / max(abs(tone));
        end
        player = audioplayer(tone, state.Fs);
        player.StopFcn = @(~,~) onPlaybackStopped();
        btnPlay.Enable = 'off';
        btnPlay.Text   = 'Playing...';
        btnStop.Enable = 'on';
        play(player);
    end

    function onPlaybackStopped()
        btnPlay.Enable = 'on';
        btnPlay.Text   = '▶ Play Audio';
        btnStop.Enable = 'off';
    end

    function stopAudio()
        if ~isempty(player) && isvalid(player) && isplaying(player)
            stop(player);
        end
    end

    function resetParams()
        stopAudio();
        state = defaults;
        state.Fs = 44100;
        state.wasAliasing   = false;
        state.suppressAlert = true;

        sldA.Value       = state.A;        edtA.Value       = state.A;
        sldAlpha.Value   = state.alpha;    edtAlpha.Value   = state.alpha;
        sldN.Value       = state.N;        edtN.Value       = state.N;
        sldDur.Value     = state.duration; edtDur.Value     = state.duration;
        sldFreq.Value    = state.playFreq; edtFreq.Value    = state.playFreq;
        ddDashed.Value   = state.dashedCurve;
        chkConnect.Value = state.connectDT;
        chkNorm.Value    = state.normalizeAudio;

        updateAll();
        state.suppressAlert = false;
    end

    function onClose()
        stopAudio();
        delete(fig);
    end

    function v = clamp(x, lims)
        v = max(lims(1), min(lims(2), x));
    end
    
end
