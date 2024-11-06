% Clear any existing serial ports
delete(instrfindall)

if(exist('ser', 'var'))
    ser.delete();
    clear ser;
end

avdd = 5.0;      % Positive supply voltage
avss = 0;     % Negative supply voltage
gain = 8;       % PGA gain
vmax_diff = 300e-3; % Maximum differential input voltage
vref = 4.5;  % Reference voltage
% Define sample rate and number of samples per packet
sps = 1000;
Nsample = 8;

[cm_min, cm_max] = ads1299_common_mode_range(avdd, avss, gain, vmax_diff);

full_scale = ads1299_differential_range(vref, gain);

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
title('Live ADC Voltage');
xlabel('Time (s)');
ylabel('Voltage (mV)');
ylim([-300, 300]); % Adjusted for typical voltage range in mV with gain=2
grid on;



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

        if length(words) == 3
            % Parse counter, LQI, and RSSI as before
            counter_val = str2double(words(1));
            lqi = str2double(words(2));
            rssi = str2double(words(3));

            % Read ADC data
            data = zeros(1, Nsample);
            voltages = zeros(1, Nsample);  % Add array for voltage values
            adc_line = readline(ser);
            adc_line = regexprep(adc_line, '[^a-zA-Z0-9]', '');
            adc_hex = reshape(adc_line{:}, 8, []); % 8 characters per sample (4 bytes)
            for i = 1:Nsample
                sample_hex = adc_hex(:, i)';
                sample_bytes = hex2dec(reshape(sample_hex, 2, [])');
                sample_bytes = flip(sample_bytes);
                sample_value = typecast(uint8(sample_bytes), 'int32');
                data(i) = double(sample_value);
                
                % Convert to voltage using the dedicated function
                voltages(i) = ads1299_code_to_voltage(data(i), vref, gain);
                % [voltages(i), filter_states] = filter(b_notch, a_notch, voltages(i), filter_states);
            end

            % Error checking (using voltages)
            if any(abs(voltages) > 1)  % Check for voltages > 1V
                err_ctr = err_ctr + 1;
                err_rate = err_ctr / (length(data_struct) * Nsample);
                disp(['Err Rate: ' num2str(err_rate)]);
            end
        else
            disp('Invalid packet structure');
            continue;
        end

        % Store the receive time, counter value, LQI, RSSI, and data
        data_struct(end+1) = struct('time', datetime('now'), 'counter_val', counter_val, 'lqi', lqi, 'rssi', rssi, 'data', data);

        % Update the plot every update_interval seconds
        if toc(last_plot_time) >= update_interval
            % Get the last window_size samples
            plot_data = [data_struct(max(1, end-window_size+1):end).data];
            counter_vals = [data_struct(max(1, end-window_size+1):end).counter_val];
            
            % Convert ADC codes to voltage (mV)
            plot_data_voltage = ads1299_code_to_voltage(plot_data, vref, gain) * 1000;
            
            % Calculate time vector
            tvec = (0:1/sps:(Nsample-1)/sps)';
            t = [];
            for i = 1:length(counter_vals)
                t = [t; tvec + (counter_vals(i) / 32.768e3)];
            end
            
            % Ensure plot_data and t have the same length
            twindow = min(numel(plot_data_voltage), window_size);
            plot_data_voltage = plot_data_voltage(end-twindow+1:end);
            t = t(end-twindow+1:end);
            
            % Update the plot
            set(plot_handle, 'YData', plot_data_voltage, 'XData', t);
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
function [b, a] = designNotchFilter(notch_freq, Q, fs)
    w0 = notch_freq/(fs/2);  % Normalized frequency
    bw = w0/Q;               % Bandwidth
    
    % Compute filter coefficients
    alpha = sin(pi*w0)/(2*Q);
    cosw0 = cos(pi*w0);
    
    b = [1, -2*cosw0, 1];
    a = [1+alpha, -2*cosw0, 1-alpha];
end