% Clear any existing serial ports
delete(instrfindall)

% Create serial object
ser = serialport('COM17', 1000000, 'Timeout', 60);

% Create a file
fid = fopen('data.txt', 'w');

% Initialize time
last_print_time = tic;

try
    while true
        % Read a line from the serial port
        line = readline(ser);

        % Remove NUL characters
        line = erase(line, char(0));

        % Split the line into words using space or newline as the separator
        words = split(line, {' ', '\n'});

        % Remove any empty strings resulting from the split operation
        words = words(~cellfun(@isempty,words));

        % Save the cleaned-up words to the file
        fprintf(fid, '%s\n', words{:});

        % Print a message every second to indicate that data is being received
        if toc(last_print_time) >= 1
            fprintf('Receiving data...\n');
            last_print_time = tic;
        end
    end
catch ME
    % If an error occurs (or the script is terminated with Ctrl+C), close the serial port
    ser.delete();
    clear ser;
    fclose(fid);
    rethrow(ME)
end
