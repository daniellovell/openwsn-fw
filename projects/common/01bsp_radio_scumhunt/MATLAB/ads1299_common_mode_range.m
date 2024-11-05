function [cm_min, cm_max] = ads1299_common_mode_range(avdd, avss, gain, vmax_diff)
    % Calculates the input common mode range for ADS1299
    %
    % Inputs:
    %   avdd      - Positive analog supply voltage (V)
    %   avss      - Negative analog supply voltage (V)
    %   gain      - PGA gain setting
    %   vmax_diff - Maximum differential input voltage (V)
    %
    % Outputs:
    %   cm_min    - Minimum allowed common mode voltage (V)
    %   cm_max    - Maximum allowed common mode voltage (V)
    
    % Calculate the terms
    gain_term = (gain * vmax_diff) / 2;
    
    % Calculate min and max common mode voltages
    cm_min = avdd - 0.2 - gain_term;
    cm_max = avss + 0.2 + gain_term;
    
    % Display the results
    fprintf('Input Common Mode Range:\n');
    fprintf('CM must be between %.3f V and %.3f V\n', cm_min, cm_max);
    fprintf('Given these parameters:\n');
    fprintf('AVDD: %.2f V\n', avdd);
    fprintf('AVSS: %.2f V\n', avss);
    fprintf('Gain: %d\n', gain);
    fprintf('Vmax_diff: %.3f V\n', vmax_diff);
end