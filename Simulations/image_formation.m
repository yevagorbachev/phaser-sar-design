load("s_rx_tT.mat");
wgnm = memoize(@wgn);
noise = wgnm(n_fast, N_slow, P_n_dBW, "complex");
s_rx_tT_noisy = s_rx_tT + noise;
% s_rx_tT_noisy = quantize(s_rx_tT_noisy, sqrt(mag20(14.7-30)), 12);

figure(name = "Raw phase history");
phplot(real(s_rx_tT_noisy), T_slow, t_fast, "Re(s_{rx}) [%sV]");

N_fft = n_fast;
s_tx_f = fft(conj(flip(s_tx_t, 1)), N_fft) / N_fft;
s_rx_fT = fft(s_rx_tT_noisy, N_fft, 1) / N_fft;
s_rx_Tc = ifft(s_rx_fT .* s_tx_f, N_fft, 1);

figure(name = "Processed phase history");
phplot(db20(s_rx_Tc), T_slow, t_fast, "|s_{rx}| [dBW]");

function data = quantize(data, fs, bits)
    lsb = fs / 2^bits;
    data = lsb*floor(data/lsb);
end
