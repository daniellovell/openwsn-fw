% Clear any existing serial ports
delete(instrfindall)

if(exist('ser', 'var'))
    ser.delete();
    clear ser;
end

% Create serial object
ser = serialport('COM24', 1000000, 'Timeout', 60);

% Set the expected packet length (number of bytes)
packet_length = 38; % 4 bytes for counter_val, 1 byte each for lqi and rssi, and 32 bytes for data

% Initialize time
last_print_time = tic;

% Create a structure to hold the data
data_struct = struct('time', [], 'counter_val', [], 'lqi', [], 'rssi', [], 'data', []);

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
            data = zeros(1, 8);
            for i = 1:8
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
