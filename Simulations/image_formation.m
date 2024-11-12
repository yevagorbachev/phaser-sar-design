load("s_rx_Tt.mat");
noise = wgn(N_slow, n_fast, P_n_dBW, "complex");
s_rx_Tt_noisy = s_rx_Tt + noise;
s_rx_Tt_noisy = quantize(s_rx_Tt_noisy, sqrt(mag20(14.7-30)), 12);

figure(name = "Raw phase history");
phplot(real(s_rx_Tt_noisy), T_slow, t_fast, "Re(s_{rx}) [%sV]");

N_fft = n_fast;
s_tx_f = fft(conj(fliplr(s_tx_t)), N_fft) / N_fft;
s_rx_Tf = fft(s_rx_Tt_noisy, N_fft, 2) / N_fft;
s_rx_Tc = ifft(s_rx_Tf .* s_tx_f, N_fft, 2);

figure(name = "Processed phase history");
phplot(db20(s_rx_Tc), T_slow, t_fast, "|s_{rx}| [dBW]");

function data = quantize(data, fs, bits)
    lsb = fs / 2^bits;
    data = lsb*floor(data/lsb);
end
