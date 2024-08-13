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

% Extract the time, data, LQI, and RSSI from the structure
for i = 2:num_data_points
    data = [data, data_struct(i).data(:)'];
    lqi = [lqi, repmat(data_struct(i).lqi, 1, Nsample)];
    rssi = [rssi, repmat(data_struct(i).rssi, 1, Nsample)];
    t = [t, tvec + (data_struct(i).counter_val / 32.768e3)];
end

% Ask the user for the desired duration in seconds
N = input('Enter the desired duration in seconds: ');

% Calculate the total duration of the data
total_duration = t(end) - t(1);

% Check if the requested duration is longer than the available data
if N > total_duration
    warning('Requested duration is longer than the available data. Using all available data.');
    N = total_duration;
end

% Find the index corresponding to N seconds
end_index = find(t - t(1) <= N, 1, 'last');

% Truncate the data, LQI, RSSI, and time vectors
data = data(1:end_index);
lqi = lqi(1:end_index);
rssi = rssi(1:end_index);
t = t(1:end_index);

% Update num_data_points
num_data_points = ceil(end_index / Nsample);

fprintf('Data truncated to %.2f seconds\n', N);


% Calculate mean and standard deviation
mean_data = mean(data);
std_data = std(data);

% Define the threshold for outliers (3 standard deviations)
threshold = 1 * std_data;

% Find indices of non-outlier data points
inlier_indices = abs(data - mean_data) <= threshold;
t_old = t;
data_old = data;

% Remove outliers from the data, LQI, RSSI, and time
data = data(inlier_indices);
lqi = lqi(inlier_indices);
rssi = rssi(inlier_indices);
t = t(inlier_indices);

% Display information about removed outliers
num_outliers = sum(~inlier_indices);
percent_outliers = (num_outliers / numel(inlier_indices)) * 100;
fprintf('Removed %d outliers (%.2f%% of the data)\n', num_outliers, percent_outliers);

% Plot the data before and after outlier removal
figure;

% Original data
subplot(2,1,1);
plot(t_old, data_old, 'k-');
title('Original Data');
xlabel('Time (s)');
ylabel('Value');


data_struct_cleaned = struct('counter_val', {}, 'data', {}, 'lqi', {}, 'rssi', {});

for i = 2:num_data_points
    start_idx = (i-2)*Nsample + 1;
    end_idx = min(start_idx + Nsample - 1, length(inlier_indices));
    current_inliers = inlier_indices(start_idx:end_idx);
    
    data_struct_cleaned(i-1).counter_val = data_struct(i).counter_val;
    data_struct_cleaned(i-1).data = nan(size(data_struct(i).data));
    data_struct_cleaned(i-1).data(current_inliers) = data_struct(i).data(current_inliers);
    data_struct_cleaned(i-1).lqi = data_struct(i).lqi;
    data_struct_cleaned(i-1).rssi = data_struct(i).rssi;
end

% Plot the data after outlier removal
subplot(2,1,2);
plot(t, data, 'k-');
title('Data After Outlier Removal');
xlabel('Time (s)');
ylabel('Value');

% Adjust the layout
sgtitle('Data Before and After Outlier Removal');


% Replace the original data_struct with the cleaned version
data_struct = data_struct_cleaned;

% Update num_data_points
num_data_points = length(data_struct);

% Save the processed data
[~, name, ext] = fileparts(filename);
processed_filename = [name '_processed' ext];
processed_fullpath = fullfile(pathname, processed_filename);
save(processed_fullpath, 'data_struct');
fprintf('Processed data saved as: %s\n', processed_fullpath);
