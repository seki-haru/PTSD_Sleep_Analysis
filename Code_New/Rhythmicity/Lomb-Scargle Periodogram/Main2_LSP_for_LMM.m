% Run on the folder storing sleep stage files

clear all
stage = 4; % Choose the target stage (0==Wake, 1==N1, 2==N2, 3==N3, 4==REM, 5==NotScored)
T = 90; % target period in minutes 
w = 20; % half-window in minutes; rhythmicity window is [T-w, T+w]
T_weight = 90; % scaling window in minutes for night-level weights
epoch_minutes = 0.5; % 30 s epochs
useSplineDetrending = false; % false -> standard LSP (use plomb path), true -> extended LSP (use spline detrend)

% Compute rhythmicity features and build model tables
D_Healthy = make_rhythmicity_data('Healthy', 0, stage, T_weight, useSplineDetrending, 0, epoch_minutes, T, w);
patient_offset = numel(categories(D_Healthy.patient)); % Shift the starting index of participant ID
D_PTSD = make_rhythmicity_data('PTSD', 1, stage, T_weight, useSplineDetrending, patient_offset, epoch_minutes, T, w);
% input: Group(Healthy or PTSD), group_id(Healthy = 0, PTSD = 1), 
% the target stage, the scaling window, method, initial number of participant ID, epoch minutes, the target period, the half-window 
% output: Rhythmicity index, patient ID, night #, PTSD status, severity score, weights

% Run a linear mixed-effects model
run_mixed_effects_models(D_Healthy, D_PTSD);
% Check the results in command window


function run_mixed_effects_models(D_Healthy, D_PTSD)
% Run a linear mixed-effects model.
Data = [D_Healthy; D_PTSD];

% Full weighted ML model
lme_diag = fitlme(Data, 'Rhythmicity ~ PTSD + night + (night|patient)', ...
    'FitMethod', 'ML', 'CovariancePattern', 'Diagonal', 'Weights', Data.W);

% Simple weighted ML model
lme_simple = fitlme(Data, 'Rhythmicity ~ PTSD + (1|patient)', ...
    'FitMethod', 'ML', 'Weights', Data.W);

% Simple unweighted ML model
lme_simple_nw = fitlme(Data, 'Rhythmicity ~ PTSD + (1|patient)', ...
    'FitMethod', 'ML');

% Likelihood ratio test between models with/without night effects
cmp_night = compare(lme_simple, lme_diag);

% Final: full weighted REML model
lme_final = fitlme(Data, 'Rhythmicity ~ PTSD + (1|patient)', ...
    'FitMethod', 'REML', 'Weights', Data.W);
display(lme_final)

% Severity model for PTSD
lme_severity = fitlme(D_PTSD, 'Rhythmicity ~ severity + (1|patient)', ...
    'FitMethod', 'REML', 'Weights', D_PTSD.W);
display(lme_severity)

% Visualize relationship between rhythmicity and severity for PTSD
fit_line(D_PTSD)

% Print compact summaries for model selection (no full tables)
summarize_model_results(lme_simple, lme_simple_nw, cmp_night, lme_final, lme_severity);
end



function summarize_model_results(lme_simple, lme_simple_nw, cmp_night, lme_final, lme_severity)
% Print compact summaries for model selection (no full tables).

fprintf('\n========== Rhythmicity Summary ==========\n');

% 1) Night variable necessity
p_night = cmp_night(2, 8).pValue; % p-value of Likelihood ratio test  
fprintf('Night variable test (weighted ML simple vs night model): ');
if isnan(p_night)
    fprintf('p-value unavailable.\n');
elseif p_night >= 0.05
    fprintf('p=%.4g -> no meaningful difference, use simple model.\n', p_night);
else
    fprintf('p=%.4g -> models differ, night term may matter.\n', p_night);
end

% 2) Weighting effect on PTSD coefficient
% Return coefficient, p-value, and CI of PTSD fixed effect from weighted/unweighted models 
[b_w, p_w, ci_w] = get_fixed_effect_stats(lme_simple, 'PTSD');
[b_nw, p_nw, ci_nw] = get_fixed_effect_stats(lme_simple_nw, 'PTSD');
delta = b_nw - b_w; % difference of coefficients
fprintf('PTSD coefficient (simple ML, weighted): %.4f (95%% CI %.4f to %.4f), p=%.4g\n', ...
    b_w, ci_w(1), ci_w(2), p_w);
fprintf('PTSD coefficient (simple ML, unweighted): %.4f (95%% CI %.4f to %.4f), p=%.4g\n', ...
    b_nw, ci_nw(1), ci_nw(2), p_nw);
fprintf('Coefficient shift (unweighted - weighted): %.4f\n', delta);
if abs(b_w) < abs(b_nw)
    fprintf('Interpretation: weighting decreases coefficient magnitude.\n');
else
    fprintf('Interpretation: weighting does not decrease coefficient magnitude in this run.\n');
end

% 3) Final REML summary
% Return coefficient, p-value, and CI of PTSD fixed effect from final model
[b_final, p_final, ci_final] = get_fixed_effect_stats(lme_final, 'PTSD');
fprintf('Final model (REML, weighted, simple): Rhythmicity ~ PTSD + (1|patient)\n');
fprintf('Final PTSD effect: %.4f (95%% CI %.4f to %.4f), p=%.4g\n', ...
    b_final, ci_final(1), ci_final(2), p_final);

% 4) Severity relationship to rhythmicity
% Return coefficient, p-value, and CI of severity fixed effect from severity model
[b_sev, p_sev, ci_sev] = get_fixed_effect_stats(lme_severity, 'severity');
fprintf('Severity model: %.4f (95%% CI %.4f to %.4f), p=%.4g\n', ...
    b_sev, ci_sev(1), ci_sev(2), p_sev);
if isnan(p_sev)
    fprintf('Conclusion: severity effect could not be estimated from current model coding.\n');
elseif p_sev >= 0.05
    fprintf('Conclusion: severity does not relate to rhythmicity.\n');
else
    fprintf('Conclusion: severity shows a significant relation to rhythmicity.\n');
end

fprintf('=========================================\n\n');
end


function [beta, pval, ci] = get_fixed_effect_stats(lme, term)
% Return coefficient, p-value, and CI for a named fixed-effect term.

coef_tbl = lme.Coefficients; % table of fixed-effect estimates
names = string(coef_tbl.Name); % fixed-effect names list
idx = find(contains(names, term, 'IgnoreCase', true) & ~contains(names, ":"), 1, 'first'); % Find the target fixed-effect name
if isempty(idx)
    error('Could not find fixed-effect term containing "%s".', term);
end

beta = coef_tbl.Estimate(idx); % coefficient
pval = coef_tbl.pValue(idx); % p-value
ci = [coef_tbl.Lower(idx), coef_tbl.Upper(idx)]; % CI

end


function Data = make_rhythmicity_data(group, group_id, stage, T_scale_minutes, useSplineDetrending, patient_offset, epoch_minutes, T_target_minutes, w_minutes)
% Compute rhythmicity features and build model table.

if nargin < 4, T_scale_minutes = 90; end
if nargin < 5, useSplineDetrending = true; end
if nargin < 6, patient_offset = 0; end
if nargin < 7, epoch_minutes = 0.5; end
if nargin < 8, T_target_minutes = 90; end
if nargin < 9, w_minutes = 20; end

% Preprocess data
[hyp_h, ID] = load_and_clean_hypnograms(group, stage); % Load data and remove invalid nights
y = build_standardized_stage_series(hyp_h, stage); % Binarize by stage and apply Bernoulli standardization after first episode
W = compute_night_weights(y, T_scale_minutes, epoch_minutes); % Calculate night-level weights

% Calculate rhythmicity features
[periods, metric_matrix, metric_name, spectrum_title] = ...
    compute_rhythmicity_metric(y, useSplineDetrending, epoch_minutes); % Calculate rhythmicity metric
[Rhythmicity, lo, hi] = summarize_rhythmicity(metric_matrix, periods, T_target_minutes, w_minutes); % Extract rhythmicity index
plot_rhythmicity_figures(periods, lo, hi, metric_matrix, metric_name, spectrum_title, ...
    Rhythmicity, group, group_id, useSplineDetrending); % Plot summary periodograms and histograms

% Build model table
[nights_num, patient_id, night_id, PTSD] = build_index_vectors(hyp_h, group_id, patient_offset); % Build patient/night/group vectors for each night
severity = build_severity_vector(group_id, ID, nights_num, numel(Rhythmicity)); % Build severity vector for each night in PTSD

Data = table(Rhythmicity(:), categorical(patient_id), night_id - 1, categorical(PTSD), severity./100, W, ...
    'VariableNames', {'Rhythmicity', 'patient', 'night', 'PTSD', 'severity', 'W'}); % night # starts from 0

end


function [hyp_h, ID] = load_and_clean_hypnograms(group, stage)
% Load data and remove invalid nights.

% Load all participants sleep data
[T_raw, ID] = load_patient_data_raw_withName(group);
% T_raw: sleep stage data by numeric values
% one participant data in each cell> row: bin(30s), column: each night
% ID: subject IDs (column1) and their recording IDs (column2)

% Exclude sleep latency
hyp_h = exclude_SL(T_raw);
% hyp_h: sleep stage data starting with sleep stages

% Remove invalid nights
for p = 1:numel(hyp_h)
    Dp = hyp_h{p};
    if isempty(Dp), continue; end
    m_p = mean(double(Dp == stage), 'omitmissing'); % Calculate avrage probability of the target stage for each night
    % Exclude 0 variance nights
    kill = (m_p == 0 | m_p == 1);
    if any(kill)
        fprintf('  Patient %d in %s: removed %d zero-variance night(s).\n', p, group, sum(kill));
        hyp_h{p}(:, kill) = [];
    end
end

end


function y = build_standardized_stage_series(hyp_h, stage)
% Binarize with respect to the target stage and apply Bernoulli standardization after the first episode.

% Integrate all nights data
D = catpad(2, hyp_h{:});
% Binarize with respect to the target stage
X = double(D == stage);
X(isnan(D)) = NaN;

% Exclude latency to the first episode
X2 = [];
for i = 1:size(X,2)

    temp = X(:,i);
    temp(isnan(temp)) = [];

    % Segment the binary (0/1) data into episodes based on consecutive values
    [s,ix] = get_segment(temp);
    % s: data segments of 0/1 episodes, ix: sleep stage for each episode (0 or 1)

    % Discard data until the first episode
    if ix(1) == 0
        s(1) = [];
    end

    % Integrate data again after the first epiosode
    X2=catpad(2,X2,segment2vector(s)');

end

% Bernoulli standardization
m = mean(X2, 'omitmissing');
y = (X2 - m) ./ (sqrt(m .* (1 - m)) + 1e-4);

end

function W = compute_night_weights(y, T_scale_minutes, epoch_minutes)
% Calculate night-level weights.

% epoch numbers of the scaling window
% T_scale_epochs = T_scale_minutes / epoch_minutes
T_scale_epochs = T_scale_minutes / epoch_minutes;
if T_scale_epochs <= 0
    error('T_scale_minutes must be positive.');
end

% weight = the number of epochs / T_scale_epochs
W = [];
for p = 1:size(y,2)
    Dp = y(:,p);
    W = [W; sum(~isnan(Dp), 1) ./ T_scale_epochs];
end
end

function [periods, metric_matrix, metric_name, spectrum_title] = compute_rhythmicity_metric(y, useSplineDetrending, epoch_minutes)
% Calculate rhythmicity metric by mode:
% - false (standard LSP): normalized plomb power
% - true (extended LSP) : F-statistics with spline detrending

if ~useSplineDetrending
    periods = (200:-1:1)'; % the candidate periods (minutes)
    fgrid = 1 ./ periods;  % corresponding frequencies
    Fs = 1 / epoch_minutes; % sampling frequency
    % Perform LSP to each night
    [metric_matrix, ~] = plomb(y, Fs, fgrid, 'normalized');
    % Store metric type and mode
    metric_name = 'Normalized PSD';
    spectrum_title = 'Normalized Lomb-Scargle Periodogram';
else
    periods = (1:1:200)'; % the candidate periods (minutes)
    % Perform extended LSP to each night
    metric_matrix = compute_extended_periodogram(y, epoch_minutes, periods);
    % Store metric type and mode
    metric_name = 'F statistics';
    spectrum_title = 'Extended Lomb-Scargle Periodogram';
end
end


function Fstat_all = compute_extended_periodogram(y, epoch_minutes, periods)
% Calculate F-statistics with spline detrending.

Fstat_all = [];

for n = 1:size(y, 2)
    night = y(:, n);
    night(isnan(night)) = [];
    % Build spline trend basis
    t = 0:epoch_minutes:size(night,1)/2-epoch_minutes;
    G = build_trend_basis(t);
    % Calculate F statistics
    Fstat = compute_night_fstat(night, t, G, periods);
    Fstat_all = catpad(2, Fstat_all, Fstat);
end
end


function G = build_trend_basis(t)
% Build spline trend basis.

knots = (t(1):180:t(end))'; % knots every 180 minutes
if numel(knots) < 2
    tc = t(:) - mean(t);
    G = tc; % linear trend when number of knots < 2
else
    G = spline(knots, eye(numel(knots)), t)'; % spline basis at each point
end
end


function Fstat = compute_night_fstat(night, t, G, periods)
% Compute F-statistics by comparing trend-only and sinusoidal models.

Fstat = zeros(size(periods));

% loop over candidate periods
for k = 1:numel(periods)
    w = 2 * pi / periods(k); % angular frequency for the candidate period

    % Design matrix including only trend
    X1 = G;
    b1 = X1 \ night;
    RSS1 = sum((night - X1 * b1) .^ 2); % residual sum of squares for trend-only model

    % Design matrix including trend and sinusoidal components (cos/sin)
    X2 = [G, cos(w * t)', sin(w * t)'];
    if rank(X2) < size(X2, 2)
        Fstat(k) = NaN; % Skip if matrix is rank-deficient
        continue
    end

    b2 = X2 \ night;
    RSS2 = sum((night - X2 * b2) .^ 2);  % residual sum of squares for model with sinusoidal components

    % Calculate F-statistics
    df = 2; % degrees of freedom for added sinusoidal terms
    dfr = numel(night) - rank(X2); % residual degrees of freedom of full model
    Fstat(k) = ((RSS1 - RSS2) / df) / (RSS2 / dfr); % F-statistics comparing models
end
end


function [Rhythmicity, lo, hi] = summarize_rhythmicity(metric_matrix, periods, T_target_minutes, w_minutes)
% Extract rhythmicity index as max value inside rhythmicity window.

% Difine rhythmicity window
lo = T_target_minutes - w_minutes;
hi = T_target_minutes + w_minutes;
in_band = (periods >= lo) & (periods <= hi);
if ~any(in_band)
    error('No period bins found in [%g, %g] minutes. Adjust T or w.', lo, hi);
end

% Extract data corresponding to the rhythmicity window
band_metric = metric_matrix(in_band, :); % rhythmicity metric
[Rhythmicity, ~] = max(band_metric, [], 1); % maximum rhythmicity metric during the rhythmicity window

end


function plot_rhythmicity_figures(periods, lo, hi, metric_matrix, metric_name, spectrum_title, ...
    Rhythmicity, group, group_id, useSplineDetrending)
% Plot summary periodograms and histograms.

figure('Name', 'Rhythmicity', 'Color', 'w');

% 1) Periodogram across all nights
subplot(2,1,1);
plot(periods, metric_matrix, 'Color', [0.6 0.6 0.6]);
hold on;
if group_id == 0
    plot(periods, mean(metric_matrix, 2), '-b', 'LineWidth', 2); % mean periodogram
else
    plot(periods, mean(metric_matrix, 2), '-r', 'LineWidth', 2);
end
xlabel('Period [m]');
ylabel(metric_name);
if useSplineDetrending
    mode_label = 'spline detrending ON';
else
    mode_label = 'spline detrending OFF (plomb)';
end
title([spectrum_title 'across all nights - ' group ' (' mode_label ')']);
xlim([1 max(periods)]);
% lower and upper bounds of the rhythmicity window
xline(lo, 'k', 'LineWidth', 1); 
xline(hi, 'k', 'LineWidth', 1);

% 2) Heatmap of periodogram for each night
subplot(2,1,2);
imagesc(periods, 1:size(metric_matrix,2), flipud(metric_matrix'));
set(gca, 'YDir', 'normal');
xlabel('Period [m]');
ylabel('Night #');
title(['Per-Night ' spectrum_title ' - ' group]);
colormap(turbo);
colorbar;
% lower and upper bounds of the rhythmicity window
xline(lo, 'r', 'LineWidth', 2);
xline(hi, 'r', 'LineWidth', 2);

% 3) Histogram of rhythmicity index
m1 = median(Rhythmicity); % median of rhythmicity index
figure;
h1 = histogram(Rhythmicity, 'Normalization', 'probability');
if group_id == 0
    h1.FaceColor = [0.0745 0.6235 1.0000];
else
    h1.FaceColor = [1.0000 0.3882 0.3882];
end
h1.BinWidth = 25;
xline(m1, 'r', 'LineWidth', 2);
xlabel(['Maximum ' metric_name ' - ' group]);
ylabel('Frequency');
title(['Rhythmicity index - ' group]);

end


function [nights_num, patient_id, night_id, PTSD] = build_index_vectors(hyp_h, group_id, patient_offset)
% Build patient/night/group vectors for each night.

nights_num = cellfun(@(x) size(x,2), hyp_h); % night number of each participant
patient_id = repelem((1:numel(nights_num))', nights_num) + patient_offset; % participant ID
night_id = cell2mat(arrayfun(@(n) (1:n)', nights_num, 'UniformOutput', false)); % night ID
PTSD = zeros(sum(nights_num), 1) + group_id; % PTSD status (Healthy=0, PTSD=1)
end


function severity = build_severity_vector(group_id, ID, nights_num, nRows)
% Build severity vector for each night in PTSD.

severity = zeros(nRows, 1);
if group_id ~= 1
    return
end

% Load PDS-IV file
severity = nan(nRows, 1);
filepath = resolve_pds_file(); % Resolve PDS-IV file path in current workspace
if ~isfile(filepath)
    warning('PDS-IV file not found. PTSD severity remains NaN.');
    return
end
PDS = readcell(filepath);
PDS = PDS(2:end, :);

% Find patient ID in PDS-IV file
subj_id = strtrim(string(ID(:,1)));
pds_id = strtrim(string(PDS(:,1)));
[tf, loc] = ismember(subj_id, pds_id);

% Extract corresponding severity score from PDS-IV file
subj_severity = nan(numel(nights_num), 1);
for iSub = 1:numel(nights_num)
    if ~tf(iSub), continue; end
    v = PDS{loc(iSub), 2};
    if isnumeric(v) && isscalar(v)
        subj_severity(iSub) = v;
    else
        nv = str2double(string(v));
        if ~isnan(nv), subj_severity(iSub) = nv; end
    end
end

if any(~tf)
    warning('Some PTSD subject IDs were not found in PDS-IV. Their severity remains NaN.');
end

% Build severity vector
severity = repelem(subj_severity, nights_num);
end


function filepath = resolve_pds_file()
% Resolve PDS-IV file path in current workspace.

currentDir = pwd;
filepath = fullfile(currentDir, "PDS-IV.xlsx");
if ~isfile(filepath)
    filepath = fullfile(currentDir, "PDS-IV");
end
end


function fit_line(Data)
% Visualize relationship between rhythmicity and severity for PTSD.

x = Data.severity;
y = Data.Rhythmicity;

% Scatter plot of severity and rhythmicity
figure;
scatter(x, y, 40, 'filled');
hold on;

% Plot linear model
p = polyfit(x, y, 1); % first-order (linear) fit
xfit = linspace(min(x), max(x), 100);
yfit = polyval(p, xfit);
plot(xfit, yfit, 'r', 'LineWidth', 2);

xlabel('Severity');
ylabel('Rhythmicity');
title('Severity vs Rhythmicity');
grid on;

end
