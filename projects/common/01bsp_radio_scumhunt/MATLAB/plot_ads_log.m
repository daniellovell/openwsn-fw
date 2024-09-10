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
lqi = [];
rssi = [];
t = [];
sps = 250;
Nsample = 8;
tvec = 0:1/sps:(0+(Nsample-1)/sps);
% Extract the time, data, and LQI from the structure
for i = 2:num_data_points
    data = [data, data_struct(i).data(:)'];
    lqi = [lqi, repmat(data_struct(i).lqi, 1, Nsample)];
    rssi = [rssi, repmat(data_struct(i).rssi, 1, Nsample)];
    t = [t, tvec + (data_struct(i).counter_val / 32.768e3)];
end

% Shift time to start at 0
t = t - t(1);


% Normalize LQI to the range [0, 1]
idx = abs(lqi) > 0;
lqi(idx) = [];
data(idx) = [];
rssi(idx) = [];
t(idx) = [];
median(data);

f = figure;

% plot(t, data, '.-');


% Create a color map that goes from red to green
cmap = [linspace(1, 0, 256)', linspace(0, 1, 256)', zeros(256, 1)];

% Create a new figure
%figure;

min_rssi = -127;
max_rssi = 4;
% rssi_norm = (rssi - min_rssi);
% rssi_norm = round(rssi_norm * (255 / max_rssi));
% Dont normalize the RSSI
rssi_norm = rssi;

% Plot the data
plot(t, data, 'k-');
hold on;
grid on;
clim([(min(rssi_norm)-5) (max(rssi_norm))+1]);
scatter(t, data, 10, rssi_norm, 'filled');

% Set the color map
colormap(cmap);


% Add a color bar
colorbar;
% Add a color bar with a title
c = colorbar;
c.Label.String = 'RSSI (dBm)';

% Set the labels
xlabel('Time (s)');
ylabel('ADC Data');
s = sprintf("B0 field only baseline\nData Received vs. Time colored by RSSI");
title(s);

% Hold off the plot
hold off;
fontsize(gcf, 40, "points");

% Power Spectral Density Analysis
figure;

% Ensure data is a column vector
data = data(:);

% Calculate PSD using pwelch
[pxx, f] = pwelch(data, [], [], [], sps);

% Calculate SNR manually
signal_power = sum(pxx);
noise_power = var(data - mean(data));
snr_value = 20 * log10(signal_power / noise_power);

% Plot PSD
plot(f, 20*log10(pxx));
grid on;

% Set labels and title
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title(sprintf('Power Spectral Density (SNR: %.2f dB)', snr_value));

% Adjust font size
fontsize(gcf, 40, "points");

% %%
% figure;
% [Sxx, F] = periodogram(data,w,numel(data),Fs,'power');
% w = hann(numel(data));
% rbw = enbw(w, sps);
% snr(Sxx, F, rbw, 'power');
