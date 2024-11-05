function [full_scale_range] = ads1299_differential_range(vref, gain)
    % Calculates the input differential dynamic range for ADS1299
    %
    % Inputs:
    %   vref - Reference voltage (V)
    %   gain - PGA gain setting
    %
    % Outputs:
    %   full_scale_range - Full-scale input range (Vp-p)
    
    % Calculate full-scale range
    full_scale_range = (2 * vref) / gain;
    
    % Display the results
    fprintf('Input Differential Dynamic Range:\n');
    fprintf('Full-scale range: %.3f Vp-p\n', full_scale_range);
    fprintf('Given these parameters:\n');
    fprintf('VREF: %.3f V\n', vref);
    fprintf('Gain: %d\n', gain);
end