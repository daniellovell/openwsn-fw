% Clear any existing serial ports
delete(instrfindall)

if(exist('ser', 'var'))
    ser.delete();
    clear ser;
end

% Create serial object
ser = serialport('COM8', 921600, 'Timeout', 60);

% Set the expected packet length (number of bytes)
packet_length = 38; % 4 bytes for counter_val, 1 byte each for lqi and rssi, and 32 bytes for data

% Initialize time
last_print_time = tic;

% Create a structure to hold the data
data_struct = struct('time', [], 'counter_val', [], 'lqi', [], 'rssi', [], 'data', []);

% Define plot parameters
window_size = 1000; % Number of samples to display in the rolling window
update_interval = 0.1; % Update plot every 0.1 seconds
last_plot_time = tic;

% Initialize the plot
figure;
plot_handle = plot(NaN(1, window_size));
title('Live Data Plot');
xlabel('Sample');
ylabel('Value');
ylim([-10000, 10000]); % Adjust as needed based on your data range
grid on;

% Define sample rate and number of samples per packet
sps = 250;
Nsample = 8;

% Create a cleanup function
cleanupObj = onCleanup(@()cleanup(ser, data_struct));

err_ctr = 0;
pre_buff = '';

try
    while true
        
        % Read a full line from the serial port
        line = readline(ser);
        words = split(line, {' ', '\n'});
        words = words(~cellfun(@isempty,words));

        
        if(length(words) == 3)
            counter_val = str2double(words(1));

            lqi = str2double(words(2));
            rssi = str2double(words(3));
            data = zeros(1, Nsample);
            for i = 1:Nsample
                line = readline(ser);
%                 disp(line);
                words = split(line, {' ', '\n'});
                words = words(~cellfun(@isempty,words));
                if(length(words) > 1)
                    disp('Invalid ADC data line');
                end
                val = str2double(words(1));
                data(i) = val;
                if(abs(val) > 1e4)
                    err_ctr = err_ctr + 1;
                    err_rate = err_ctr / (length(data_struct) * 8);
                    disp(['Err Rate: ' num2str(err_rate)]);
               
                end
            end
            
        else
            continue;
        end

        % Store the receive time, counter value, LQI, RSSI, and data
        data_struct(end+1) = struct('time', datetime('now'), 'counter_val', counter_val, 'lqi', lqi, 'rssi', rssi, 'data', data);

        % Update the plot every update_interval seconds
        if toc(last_plot_time) >= update_interval
            % Get the last window_size samples
            plot_data = [data_struct(max(1, end-window_size+1):end).data];
            counter_vals = [data_struct(max(1, end-window_size+1):end).counter_val];
            
            % Calculate time vector
            tvec = (0:1/sps:(Nsample-1)/sps)';
            t = [];
            for i = 1:length(counter_vals)
                t = [t; tvec + (counter_vals(i) / 32.768e3)];
            end
            
            % Ensure plot_data and t have the same length
            twindow = min(numel(plot_data), window_size);
            plot_data = plot_data(end-twindow+1:end);
            t = t(end-twindow+1:end);
            
            % Update the plot
            set(plot_handle, 'YData', plot_data, 'XData', t);
            xlim([t(1), t(end)]); % Adjust x-axis limits
            drawnow;
            
            last_plot_time = tic;
        end


        % Print a message every second to indicate that data is being received
        if toc(last_print_time) >= 1
            fprintf('Receiving data...\n');
            last_print_time = tic;
        end
    end
catch ME
    disp('Caught in catch!');
    % Save the data
    save('data.mat', 'data_struct');

    % Close the serial port
    ser.delete();
    clear ser;
    rethrow(ME)
end

function cleanup(ser, data_struct)
    % Save the data
    save('data.mat', 'data_struct');

    % Close the serial port
    ser.delete();
    clear ser;
end
