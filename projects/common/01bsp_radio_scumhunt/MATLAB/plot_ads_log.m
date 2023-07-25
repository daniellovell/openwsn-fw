% Read the data from the file
data = readmatrix('data.txt');

% Create a new figure
figure;

% Plot the data
plot(data);

% Set the title and labels
title('Radio-Transmitted ADC Data');
xlabel('Index');
ylabel('Value');

% Add a grid
grid on;

% Enable minor grid lines
% ax = gca;
% ax.MinorGridLineStyle = ':';
% ax.MinorGridColor = 'k';
% ax.MinorGridAlpha = 0.5;

% Set the plot style
% set(gca, 'GridLineStyle', '-', 'GridColor', 'k', 'GridAlpha', 0.5);

% Show the plot
