% Save the data


% Close the serial port
if(exist('ser', 'var'))
    ser.delete();
    clear ser;
    save('data.mat', 'data_struct');
end
% Load the data
[filename, pathname] = uigetfile('*.mat', 'Select the data file');
if isequal(filename,0) || isequal(pathname,0)
   disp('User selected Cancel')
   return;
else
   fullpath = fullfile(pathname, filename);
   load(fullpath);
   disp(['User selected ', fullpath]);
end

% Get the number of data points
num_data_points = length(data_struct);

data = [];
voltages = [];
lqi = [];
rssi = [];
t = [];
sps = 1000;
Nsample = 8;
tvec = 0:1/sps:(0+(Nsample-1)/sps);

% Define ADC parameters
vref = 4.5;  % Reference voltage
gain = 8;   % PGA gain

% Check if we're dealing with old or new format data
is_old_format = ~isfield(data_struct, 'voltages');

% Extract the time, data, and LQI from the structure
for i = 2:num_data_points
    if is_old_format
        % Convert old format ADC codes to voltages
        raw_data = data_struct(i).data(:)';
        volt_data = zeros(size(raw_data));
        for j = 1:length(raw_data)
            volt_data(j) = ads1299_code_to_voltage(raw_data(j), vref, gain);
        end
        voltages = [voltages, volt_data];
        data = [data, raw_data];
    else
        % New format already has voltages
        voltages = [voltages, data_struct(i).voltages(:)'];
        data = [data, data_struct(i).data(:)'];
    end
    
    lqi = [lqi, repmat(data_struct(i).lqi, 1, Nsample)];
    rssi = [rssi, repmat(data_struct(i).rssi, 1, Nsample)];
    t = [t, tvec + (data_struct(i).counter_val / 32.768e3)];
end

% Shift time to start at 0
t = t - t(1);

% Design and apply high-pass filter
order = 4;  % 4th order Butterworth filter
cutoff_freq = 0.1;  % 1 Hz cutoff
nyquist_freq = sps/2;
[b, a] = butter(order, cutoff_freq/nyquist_freq, 'high');

% Apply zero-phase filtering to avoid phase distortion
voltages_filtered = filtfilt(b, a, voltages);

% Use filtered data for plotting
voltages_mv = voltages_filtered * 1000;
voltages = voltages_filtered;

% Normalize LQI to the range [0, 1]
idx = abs(lqi) > 0;
lqi(idx) = [];
voltages(idx) = [];
data(idx) = [];
rssi(idx) = [];
t(idx) = [];

% Create plots using voltages instead of raw data
f1 = figure;

% voltages_mv = voltages * 1000;

% Create a color map that goes from red to green
cmap = [linspace(1, 0, 256)', linspace(0, 1, 256)', zeros(256, 1)];

min_rssi = -127;
max_rssi = 4;
rssi_norm = rssi;

% Plot the voltages
length(t)
length(voltages_mv)
plot(t, voltages_mv, 'k');
hold on;
grid on;
clim([(min(rssi_norm)-5) (max(rssi_norm))+1]);
scatter(t, voltages_mv, 10, rssi_norm, 'filled');

% Set the color map
colormap(cmap);

% Add a color bar with a title
c = colorbar;
c.Label.String = 'RSSI (dBm)';

% Set the labels
xlabel('Time (s)');
ylabel('Voltage (mV)');
s = sprintf("ECG/EMG outside MRI\nVoltage vs. Time colored by RSSI");
title(s, 'FontSize', 40);

% Add text annotation with parameters
annotation_box = annotation('textbox', [0.005800388852884,0.78740157480315,0.212605314322748,0.207592800899908], ...  % [left bottom width height]
    'String', sprintf('Parameters:\nVREF: %.1f V\nGain: %d\nSample Rate: %d Hz', ...
    vref, gain, sps), ...
    'EdgeColor', 'black', ...
    'BackgroundColor', [1 1 1 0.7]);

% Hold off the plot
hold off;

% Set overall figure font size
fontsize(gca, 40, "points");
% Set annotation font size separately
set(annotation_box, 'FontSize', 24);

% Power Spectral Density Analysis
figure;

% Ensure voltages is a column vector
voltages = voltages(:);

% Calculate PSD using pwelch
[pxx, f] = pwelch(voltages, [], [], [], sps);

% Calculate SNR manually
signal_power = sum(pxx);
noise_power = var(voltages - mean(voltages));
snr_value = 20 * log10(signal_power / noise_power);

% Plot PSD
plot(f, 20*log10(pxx));
grid on;

% Set labels and title
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title(sprintf('Power Spectral Density (SNR: %.2f dB)', snr_value));

% Add text annotation with parameters
annotation_box2 = annotation('textbox', [0.691931775714199,0.706918677418853,0.212605314322748,0.207592800899908], ...
    'String', sprintf('Parameters:\nVREF: %.1f V\nGain: %d\nSample Rate: %d Hz\nSNR: %.2f dB', ...
    vref, gain, sps, snr_value), ...
    'EdgeColor', 'black', ...
    'BackgroundColor', [1 1 1 0.7]);

% Adjust font size
fontsize(gca, 40, "points");

% Set annotation font size separately
set(annotation_box2, 'FontSize', 24);

% %%
% figure;
% [Sxx, F] = periodogram(data,w,numel(data),Fs,'power');
% w = hann(numel(data));
% rbw = enbw(w, sps);
% snr(Sxx, F, rbw, 'power');

% ... (previous code)

% Prompt user for thresholds
prompt = {
    'Enter start time (s):', 
    'Enter end time (s):', 
    'Enter Missing Packet Threshold (s):', 
    'Enter Corruption Threshold (s):'
};
dlgtitle = 'Packet Drop Rate Analysis Parameters';
dims = [1 50];
definput = {'0', num2str(max(t)-0.1), '0.01', '0.02'};  % Default values
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('User canceled the input dialog.');
else
    t_start = str2double(answer{1});
    t_end = str2double(answer{2});
    missing_threshold = str2double(answer{3});
    corruption_threshold = str2double(answer{4});

    % Validate inputs
    if isnan(t_start) || isnan(t_end) || isnan(missing_threshold) || isnan(corruption_threshold) ...
            || t_start < 0 || t_end > max(t) || t_start >= t_end ...
            || missing_threshold <= 0 || corruption_threshold <= missing_threshold
        error('Invalid input parameters.');
    end

    % Filter data within the specified time range
    idx_range = t >= t_start & t <= t_end;
    t_range = t(idx_range);
    voltages_mv_range = voltages_mv(idx_range);

    % Find indices where each packet starts
    packet_indices = find(mod(1:length(t_range), Nsample) == 1);

    % Extract packet times
    packet_times = t_range(packet_indices);

    % Calculate time intervals between received packets
    packet_intervals = diff(packet_times);

    % Expected interval (median is more robust in presence of outliers)
    expected_interval = median(packet_intervals);

    % Classification of intervals
    % Regular intervals
    regular_intervals = find(abs(packet_intervals - expected_interval) <= missing_threshold);

    % Missing packets
    missing_intervals = find((packet_intervals > expected_interval + missing_threshold));

    % Corrupted packets
    corrupted_intervals = find((packet_intervals > expected_interval + corruption_threshold) | ...
                            (packet_intervals < expected_interval - corruption_threshold));


    % Initialize missing and corrupted packets lists
    missing_packets = [];
    corrupted_packets = [];

    % Handle missing packets
    for idx = missing_intervals'
        gap = packet_intervals(idx);
        num_missing = max(round(gap / expected_interval) - 1, 0);
        for k = 1:num_missing
            missing_time = packet_times(idx) + k * expected_interval;
            missing_packets = [missing_packets, missing_time];
        end
    end

    % Handle corrupted packets
    for idx = corrupted_intervals'
        if(isempty(corrupted_intervals))
            break;
        end

        if idx + 1 > length(packet_times)
            warning('Corrupted interval at index %d exceeds packet_times length. Skipping...', idx);
            continue;
        end
        corrupted_time = packet_times(idx + 1);  % The packet after the corrupted interval
        if isnan(corrupted_time) || ~isfinite(corrupted_time) || corrupted_time < 0
            warning('Invalid corrupted_time detected: %.4f. Skipping...', corrupted_time);
            continue;
        end
        corrupted_packets = [corrupted_packets, corrupted_time];
    end

    
    % Calculate total expected packets
    total_expected_packets = length(packet_times) + length(missing_packets);
    packet_drop_rate = (length(missing_packets) / total_expected_packets) * 100;
    corruption_rate = (length(corrupted_packets) / total_expected_packets) * 100;
    

    % Plot the packet intervals for visualization
    figure;
    plot(packet_times(1:end-1), packet_intervals, 'k', 'LineWidth', 2);  % Thicker lines
    hold on;
    grid on;

    % Plot the expected interval and thresholds with thicker lines
    plot(packet_times(1:end-1), expected_interval * ones(size(packet_intervals)), 'g', 'LineWidth', 2);
    plot(packet_times(1:end-1), (expected_interval + missing_threshold) * ones(size(packet_intervals)), 'r--', 'LineWidth', 1.5);  % Thicker dashed lines
    plot(packet_times(1:end-1), (expected_interval + corruption_threshold) * ones(size(packet_intervals)), 'm--', 'LineWidth', 1.5);
    plot(packet_times(1:end-1), (expected_interval - corruption_threshold) * ones(size(packet_intervals)), 'm--', 'LineWidth', 1.5);

    xlabel('Time (s)', 'FontSize', 36);  % Matched font size
    ylabel('Received packet interval (s)', 'FontSize', 36);
    title(sprintf('Ext. self-test, BOLD EPI (full)\nReceived packet intervals with expected interval and thresholds'), 'FontSize', 40);

    % Enhanced Legend with thicker lines and smaller font size
    legend_entries = {'Packet intervals', 'Expected interval', 'Missing threshold', 'Corruption thresholds'};
    legend(legend_entries, 'Location', 'best', 'FontSize', 24);  % Slightly smaller font size

    % Add annotation box with packet analysis report
    annotation_box3 = annotation('textbox', [0.15, 0.75, 0.3, 0.2], ...  % Adjust position as needed
        'String', sprintf(['Expected packets: %d\n' ...
                           'Received packets: %d\n' ...
                           'Missing packets: %d\n' ...
                           'Corrupted packets: %d\n' ...
                           'Packet drop rate: %.2f%%\n' ...
                           'Packet corruption rate: %.2f%%'], ...
                           total_expected_packets, length(packet_times), length(missing_packets), ...
                           length(corrupted_packets), packet_drop_rate, corruption_rate), ...
        'EdgeColor', 'black', ...
        'BackgroundColor', [1 1 1 0.8], ...
        'FontSize', 24);  % Slightly smaller font size than title/axes

    % Adjust overall figure font size if necessary
    set(gca, 'FontSize', 36);  % Matched font size for axes



    % Display results
    fprintf('Packet Analysis between %.2f s and %.2f s:\n', t_start, t_end);
    fprintf('Total Expected Packets: %d\n', total_expected_packets);
    fprintf('Total Received Packets: %d\n', length(packet_times));
    fprintf('Total Missing Packets: %d\n', length(missing_packets));
    fprintf('Total Corrupted Packets: %d\n', length(corrupted_packets));
    fprintf('Packet Drop Rate: %.2f%%\n', packet_drop_rate);
    fprintf('Packet Corruption Rate: %.2f%%\n', corruption_rate);

    % Debugging: Display contents of corrupted_packets
    disp('--- Debugging Information ---');
    disp('Corrupted Packets:');
    disp(corrupted_packets);
    disp('Length of corrupted_packets:');
    disp(length(corrupted_packets));

    % Ensure corrupted_packets contains valid data
    if any(~isfinite(corrupted_packets)) || any(corrupted_packets < 0)
        error('Corrupted packets contain invalid time values.');
    end

    % Clear any existing variable named 'line' to prevent function shadowing
    if exist('line', 'var')
        clear line
    end

    % Plotting missing and corrupted packets efficiently
    figure(f1);  % Use the existing figure
    hold on;
    grid on;

    y_limits = ylim;

    % Plot missing packets
    if ~isempty(missing_packets)
        x_coords_miss = [missing_packets; missing_packets];  % 2xN for vertical lines
        y_coords_miss = repmat(y_limits', 1, length(missing_packets));  % 2xN for y-coordinates
        line(x_coords_miss, y_coords_miss, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
    end

    % Plot corrupted packets
    if ~isempty(corrupted_packets)
        x_coords_corr = [corrupted_packets; corrupted_packets];  % 2xM for vertical lines
        y_coords_corr = repmat(y_limits', 1, length(corrupted_packets));  % 2xM for y-coordinates
        line(x_coords_corr, y_coords_corr, 'Color', 'm', 'LineStyle', '--', 'LineWidth', 1);
    end

    % Update legend
    legend_entries = {'Voltage (mV)', 'RSSI'};
    if ~isempty(missing_packets)
        legend_entries{end+1} = 'Missing Packets';
    end
    if ~isempty(corrupted_packets)
        legend_entries{end+1} = 'Corrupted Packets';
    end
    legend(legend_entries, 'Location', 'best', 'FontSize', 24);

    hold off;
end