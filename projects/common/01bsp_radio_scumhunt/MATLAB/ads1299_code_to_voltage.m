function voltage = ads1299_code_to_voltage(code, vref, gain)
    % Converts ADS1299 24-bit output codes to input voltage
    %
    % Inputs:
    %   code - 24-bit hex code from ADS1299 (string or integer)
    %   vref - Reference voltage (V)
    %   gain - PGA gain setting
    %
    % Output:
    %   voltage - Corresponding input voltage (V)
    
    % Convert hex string to number if needed
    if ischar(code) || isstring(code)
        code = hex2dec(code);
    end
    
    % Convert to signed 24-bit
    if code > hex2dec('7FFFFF')
        code = code - hex2dec('1000000');
    end
    
    % Calculate LSB size using equation 8
    lsb = (2 * vref / gain) / (2^24);
    
    % Convert code to voltage
    voltage = code * lsb;
end