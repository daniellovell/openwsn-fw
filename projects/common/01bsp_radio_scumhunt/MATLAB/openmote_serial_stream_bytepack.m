% Clear any existing serial ports
delete(instrfindall)

if(exist('ser', 'var'))
    ser.delete();
    clear ser;
end

% Create serial object
ser = serialport('COM24', 115200, 'Timeout', 60);

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
        while(~strcmp(pre_buff, 'UCB'))
            pre_buff = char(read(ser, 3, 'uint8'));
        end
        pre_buff = '';
        % Read a full packet from the serial port
        packet = read(ser, packet_length, "uint8");
        packet = double(packet);
        if(length(packet) < packet_length)
            disp('Short packet');
            continue;

        end

        % Unpack counter_val manually
        counter_val = packet(1) + packet(2)*256 + packet(3)*65536 + packet(4)*16777216;

        lqi = packet(5);
        rssi = packet(6);

        % Unpack data manually and handle two's complement
        data = zeros(1, 8);
        for i = 1:8
            idx = 7 + (i-1)*4;
            val = packet(idx) + packet(idx+1)*256 + packet(idx+2)*65536 + packet(idx+3)*16777216;
            if val >= 2^31 % check if the value is greater or equal to 2^31
                val = val - 2^32; % two's complement
            end
            data(i) = val;
            if(abs(val) > 1e4)
                err_ctr = err_ctr + 1;
                err_rate = err_ctr / (length(data_struct) * 8);
                disp(['Err Rate: ' num2str(err_rate)]);
%                 disp(['Byte Idx: ' num2str(i)])
                
            end
%             char(packet)
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
