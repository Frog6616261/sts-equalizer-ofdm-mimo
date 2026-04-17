function output_signal = MIMO_convolution(input_signal, h, N_FFT, cp_length)
%MIMO_CONVOLUTION MIMO linear convolution, trimmed to one OFDM symbol length
%
% Inputs:
%   input_signal : (Nt x N_sym) time-domain TX signals, N_sym = N_FFT + cp_length
%   h            : (Nr x Nt x N_h) channel impulse responses (tap 1 = delay 0)
%   N_FFT        : FFT size
%   cp_length    : cyclic prefix length
%
% Output:
%   output_signal: (Nr x N_sym) received time-domain signal (ready for RX)

    validateattributes(input_signal, {'numeric'}, {'2d','nonempty'}, mfilename, 'input_signal');
    validateattributes(h, {'numeric'}, {'3d','nonempty'}, mfilename, 'h');
    validateattributes(N_FFT, {'numeric'}, {'scalar','integer','positive'}, mfilename, 'N_FFT');
    validateattributes(cp_length, {'numeric'}, {'scalar','integer','nonnegative'}, mfilename, 'cp_length');

    [Nt_sym, N_sym] = size(input_signal);
    [Nr, Nt, N_h] = size(h);

    expected_len = N_FFT + cp_length;

    assert(N_sym == expected_len, ...
        'Length mismatch: size(input_signal,2)=%d, but N_FFT+cp_length=%d.', N_sym, expected_len);

    assert(Nt_sym == Nt, ...
        'Antenna mismatch: input_signal has Nt=%d, but h has Nt=%d (3rd dim).', Nt_sym, N_h);

    assert(N_h >= 1, 'Channel length N_h must be >= 1.');

    % ---- Channel start tap check ----
    h_abs = abs(h);
    max_h = max(h_abs(:));
    if max_h > 0
        tol = 1e-12 * max_h;
        lin = find(h_abs > tol, 1, 'first');
        [tapIdx, ~, ~] = ind2sub(size(h), lin);
        if tapIdx ~= 1
            warning(['Channel impulse response does not start at tap 1 (delay 0). ', ...
                     'First significant tap is at index %d. ', ...
                     'You may need timing alignment (shift) before CP removal/FFT.'], tapIdx);
        end
    else
        warning('Channel impulse response h is all zeros.');
    end

    % ---- Allocate output (type-safe, without incompatible addition) ----
    output_signal = zeros(Nr, expected_len, 'like', input_signal);

    % If either input is complex, ensure complex output
    if ~isreal(input_signal) || ~isreal(h)
        output_signal = complex(output_signal);
    end

    % ---- Convolution + trimming ----
    for id_r = 1:Nr
        y_r = zeros(1, expected_len, 'like', output_signal);

        for id_t = 1:Nt_sym
            x  = input_signal(id_t, :);
            ht = squeeze(h(id_r, id_t, :));    
            ht = ht(:).';

            y_full = conv(x, ht, 'full');   % (N_sym + N_h - 1 x 1)

            L = min(expected_len, numel(y_full));
            y_r(1:L) = y_r(1:L) + y_full(1:L);
        end

        output_signal(id_r, :) = y_r;
    end
end
