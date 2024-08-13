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

figure;
% plot(t, data, '.-');


% Create a color map that goes from red to green
cmap = [linspace(1, 0, 256)', linspace(0, 1, 256)', zeros(256, 1)];

% Create a new figure
figure;

rssi_norm = (rssi - min(rssi));
rssi_norm = round(rssi_norm * (255 / max(rssi_norm)));

% Plot the data
plot(t, data, 'k-');
hold on;
grid on;
scatter(t, data, 10, cmap(rssi_norm+1, :), 'filled');


% Set the color map
colormap(cmap);


% Add a color bar
colorbar;
% Add a color bar with a title
c = colorbar;
c.Label.String = 'Locally Normalized RSSI';

% Set the labels
xlabel('Time (s)');
ylabel('ADC Data');
s = sprintf("Gradient Only (w/ RFE Protection)\nData Received vs. Time colored by RSSI");
title(s);

% Hold off the plot
hold off;
