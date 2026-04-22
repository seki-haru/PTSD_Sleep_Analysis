% Run on the folder storing sleep stage files

clear all
% Load all participants sleep data
[T,~]=load_patient_data_raw_withName('Healthy'); % 'Healthy' or 'PTSD'
% T: sleep stage data by numeric values
% one participant data in each cell> row: bin(30s), column: each night

% Exclude sleep latency
T_SL = exclude_SL(T);
% T_SL: sleep stage data starting with sleep stages

% Separate the target sleep stage from others
data = stage_replace(T_SL, 4); % 0==Wake, 1==N1, 2==N2, 3==N3, 4==REM, 5==NotScore
% data: 0/1 sleep stage data (1==chosen stage 0==other stages)

% Exclude latency of the target stage
[data,~] = remove_first_0(data);
% data: sleep stage data without latency
data_Healthy = data;

% Calculate interval durations across all nights
interval = get_interval_duration(data);
interval_Healthy = interval;

[T,~]=load_patient_data_raw_withName('PTSD');
T_SL = exclude_SL(T);
data = stage_replace(T_SL, 4);
[data,~] = remove_first_0(data);
data_PTSD = data;
interval = get_interval_duration(data);
interval_PTSD = interval;

% Integrate all interval durations across groups
y = [interval_Healthy; interval_PTSD];

%% Fit 2-component Gaussian mixture model (GMM) to log-transformed data

rng(2);
% Transform intervals to the log scale for Gaussian-like distribution
z = log(y);
% Fit 2-component GMM and plot histogram with Gaussian components
GMModel = plotGMM2(z, 0.05); % bin size: 0.05

% Because intervals are quantized in steps of 0.5 m,
% this often reveals visible discretization artifacts in the log-space.

%% Reduce discretization artifact by jittering data

rng(1);
% Add small random noise as standard dequantization / jittering step
% Since resolution is 0.5 m, noise is drawn from [-0.25, +0.25] m
b = (rand(numel(y),1) - 0.5)*0.5;
z = log(y + b);
GMModel = plotGMM2(z, 0.05);

%% Fit in the log-space, but plot fitted components back on the original scale

rng(1);
b = (rand(numel(y),1) - 0.5)*0.5;
% Fit model in the log-space and plot it on the original time scale (minutes) 
% to provide more interpretable representations
GMModel = plotGMM2_logfit(y + b, 1);
ylim([0 0.05])


%% Compute the maximum-likelihood threshold between the two fitted components
% Find point where the two weighted Gaussian densities are equal.

% Extract the final distribution components in the log-space
mu = GMModel.mu(:); % mean
sigma = sqrt(squeeze(GMModel.Sigma)); % SD
w = GMModel.ComponentProportion(:); % weight

% Sort components by log-space mean
[mu, idx] = sort(mu);
sigma = sigma(idx);
w = w(idx);

% Define difference between the two weighted Gaussian components
f = @(z) w(1)*normpdf(z, mu(1), sigma(1)) - ...
         w(2)*normpdf(z, mu(2), sigma(2));
% Find log-space point where difference is 0
zthr = fzero(f, [mu(1), mu(2)]);

% Combert the intersection to the original scale
ythr = exp(zthr);

fprintf('Threshold in log-space = %.4f\n', zthr);
fprintf('Threshold in original scale = %.4f m\n', ythr);


criteria_interval = 18.1;
% Calculate the SD of interval durations (> criteria) in each night
SD_Healthy = get_interval_SD(data_Healthy, criteria_interval);
SD_PTSD = get_interval_SD(data_PTSD, criteria_interval);

function interval = get_interval_duration(data)
% Calculate interval durations across all nights.

interval = [];

% Loop over all nights
for k=1:size(data,1)
    M=data{k};

    for i =1:size(M,2)
        temp=M(:,i);
        temp(isnan(temp))=[];

        % Segment the binary (0/1) data into episodes based on consecutive values
        [s,ix] = get_segment(temp);
        % s: data segments of 0/1 episodes, ix: sleep stage for each episode (0 or 1)
        d = cellfun(@(x) size(x,1)*0.5,s); % Convert segments duration from seconds to minutes
        DIX=[ix;d];

        % Exclude data after the last episode of the target stage
        if DIX(1, end) == 0
            DIX(:, end) = [];
        end
        % Exclude episodes and left their intervals
        DIX(:,DIX(1,:)==1)=[]; 

        % Store all interval durations
        interval  = [interval; DIX(2,:)']; 
    end
end

end

function GMModel = plotGMM2(y, bin_sz)
% Fit 2-component GMM and plot histogram with Gaussian components.

    y = y(:);
    y = y(isfinite(y));

    % Fit GMM
    GMModel = fitgmdist(y, 2,'Replicates',10);

    % Extract distribution components
    mu = GMModel.mu; % mean
    sigma = sqrt(squeeze(GMModel.Sigma)); % SD
    w = GMModel.ComponentProportion; % weight

    % Sort components by mean
    [mu, idx] = sort(mu);
    sigma = sigma(idx);
    w = w(idx);

    % Histogram
    edges = min(y):bin_sz:max(y);
    figure;
    histogram(y, edges, 'Normalization', 'pdf', ...
        'FaceColor', [0.75 0.75 0.75], ...
        'EdgeColor', 'k');
    hold on

    % Plot Gaussian components
    xx = linspace(min(y), max(y), 1000); % x grid
    g1 = w(1) * normpdf(xx, mu(1), sigma(1));
    g2 = w(2) * normpdf(xx, mu(2), sigma(2));
    gmix = g1 + g2;

    plot(xx, g1, 'b', 'LineWidth', 3);
    plot(xx, g2, 'r', 'LineWidth', 3);
    plot(xx, gmix, 'k--', 'LineWidth', 2);

    xlabel('Data');
    ylabel('Probability density');
    title('2-Component Gaussian Mixture Fit');

    legend({'Data', 'Gaussian 1', 'Gaussian 2', 'Mixture'}, ...
        'Location', 'best');

    box off
    set(gca, 'LineWidth', 1.2, 'FontSize', 12);
end

function GMModel = plotGMM2_logfit(y, bin_sz)
% Fit model in the log-space and plot it on the original time scale (minutes) 
% to provide more interpretable representations.

    y = y(:);
    y = y(isfinite(y) & y > 0); 

    % Fit GMM in the log-space
    z = log(y);
    GMModel = fitgmdist(z, 2, 'Replicates',10);

    % Extract distribution components
    mu = GMModel.mu; % mean
    sigma = sqrt(squeeze(GMModel.Sigma)); % SD
    w = GMModel.ComponentProportion; % weight

    % Sort components by log-space mean
    [mu, idx] = sort(mu);
    sigma = sigma(idx);
    w = w(idx);

    % Histogram on the original scale
    edges = min(y):bin_sz:max(y);

    figure;
    histogram(y, edges, 'Normalization', 'pdf', ...
        'FaceColor', [0.75 0.75 0.75], ...
        'EdgeColor', 'k');
    hold on



    % Plot Gaussian components on the original scale
    % If log(Y) ~ N(mu, sigma^2), then Y ~ Lognormal(mu, sigma)
    xx = linspace(min(y), max(y), 2000); % x grid on the original scale
    xx(xx <= 0) = eps;
    g1 = w(1) * lognpdf(xx, mu(1), sigma(1));
    g2 = w(2) * lognpdf(xx, mu(2), sigma(2));
    gmix = g1 + g2;


    plot(xx, g1, 'b', 'LineWidth', 3);
    plot(xx, g2, 'r', 'LineWidth', 3);
    plot(xx, gmix, 'k--', 'LineWidth', 2);

    xlabel('Data');
    ylabel('Probability density');
    title('2-Component GMM fit in log-space, shown on original scale');

    legend({'Data', 'Component 1', 'Component 2', 'Mixture'}, ...
        'Location', 'best');

    box off
    set(gca, 'LineWidth', 1.2, 'FontSize', 12);

    % Optional: print component summaries on the original scale
    mean_orig = exp(mu + 0.5*sigma.^2); % mean of lognormal distribution (original scale)
    fprintf('Log-space means:      %.3f, %.3f\n', mu(1), mu(2));
    fprintf('Log-space SDs:        %.3f, %.3f\n', sigma(1), sigma(2));
    fprintf('Original-scale means: %.3f, %.3f\n', mean_orig(1), mean_orig(2));
    fprintf('Weights:              %.3f, %.3f\n', w(1), w(2));
end

function SD = get_interval_SD(data, criteria)
% Calculate SD of interval durations (> criteria) in each night.

SD = [];

% Loop over all nights
for k = 1:size(data,1)
    M = data{k}; 

    for i =1:size(M,2)
        temp=M(:,i); 
        temp(isnan(temp))=[];

        % Segment the binary (0/1) data into episodes based on consecutive values
        [s,ix] = get_segment(temp);
        % s: data segments of 0/1 episodes, ix: sleep stage for each episode (0 or 1)
        d = cellfun(@(x) size(x,1)*0.5,s); % Convert segments duration from seconds to minutes
        DIX=[ix;d];

        % Exclude data after the last episode of the target stage
        if DIX(1, end) == 0
            DIX(:, end) = [];
        end

        % Exclude episodes and left their intervals
        DIX(:,DIX(1,:)==1)=[]; 

        % Exclude episode intervals shorter than the criteria
        DIX(:,DIX(2,:)<=criteria)=[];

        % Calculate SD of intervals
        if size(DIX,2) >= 2
            SD(end+1,1) = std(DIX(2,:));
        end
    end
end
end