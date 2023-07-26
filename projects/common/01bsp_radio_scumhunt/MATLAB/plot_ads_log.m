% Save the data
save('data.mat', 'data_struct');

% Close the serial port
if(exist('ser', 'var'))
    ser.delete();
    clear ser;
end
% Load the data
load('data.mat');

% Get the number of data points
num_data_points = length(data_struct);

data = [];
lqi = [];
% Extract the time, data, and LQI from the structure
for i = 2:num_data_points
    data = [data, data_struct(i).data(:)'];
    lqi = [lqi, repmat(data_struct(i).lqi, 1, 8)];
end

% Normalize LQI to the range [0, 1]
lqi = lqi / 255;

% Create a color map that goes from red to green
cmap = [linspace(1, 0, 256)', linspace(0, 1, 256)', zeros(256, 1)];

% Create a new figure
figure;

% Plot the data
cmap(round(lqi*255)+1, :);
scatter(1:length(data), data, 10, cmap(round(lqi*255)+1, :), 'filled');
hold on;

% Set the color map
colormap(cmap);

% Add a color bar
colorbar;

% Set the labels
xlabel('Time (s)');
ylabel('Data');
title('Data vs. Time colored by LQI');

% Hold off the plot
hold off;
