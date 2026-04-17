function guard_band_samples = get_guard_band_samples(N_FFT, N_used)
%GET_GUARD_BAND_SAMPLES Guard-band indices in MATLAB FFT order (DC included)
%
% Assumptions:
%   - Spectrum is in MATLAB fft() order (DC at index 1).
%   - N_used includes DC and is odd (symmetric +/- around DC).
%   - Guard band is located near Nyquist + DC is nulled.

    validateattributes(N_FFT,  {'numeric'}, {'scalar','integer','positive'});
    validateattributes(N_used, {'numeric'}, {'scalar','integer','positive'});
    assert(N_used <= (N_FFT - 1), 'N_used must be <= N_FFT - 1; (-1) <- with DC');
    assert(mod(N_FFT,2)==0, 'N_FFT must be even (typical OFDM).');

    sz_start_used = floor(N_used / 2) + mod(N_used, 2);
    sz_end_used = floor(N_used / 2);

    % Used subcarriers (FFT order)
    used_idx = [ ...
        2:(1 + sz_start_used), ...                % positive low frequencies
        (N_FFT - sz_end_used + 1):N_FFT ...       % negative low frequencies
    ];

    % Guard band = everything else + DC
    guard_band_samples = setdiff(1:N_FFT, used_idx, 'stable');
end

