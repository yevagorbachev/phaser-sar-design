% Transmitting characteristics
radar.P_tx_dBW = 60;
radar.Rx_amp_dB = 0;
radar.f_c = 10e9;
radar.lambda = c / radar.f_c;
radar.tau = 10e-6;
radar.B = 150e6;
radar.f_s = 1.4*radar.B;
radar.F_prf = 500;

% Impairments
radar.B_N = radar.f_s;
radar.NF_dB = 3.2;
radar.L_dB = 2;
radar.T_0 = 310;

% Antenna characteristics
antenna.D_az = 1.62;
antenna.D_el = 254e-3;
antenna.effc = 0.7;
antenna.lambda = radar.lambda;

% Aperture characteristics
aperture.h = 7620;
aperture.L_0 = 13e3;
aperture.L_min = aperture.L_0 - 100;
aperture.L_max = aperture.L_0 + 100;
aperture.S_min = -1e3;
aperture.S_max = 1e3;
aperture.spd = 140;

% r - each column is a target's position
targets.r_grp_aN = [-50 -50 0 50; 50 -50 0 50; 0 0 0 0];
targets.rcs_dBsm = [0, 0, 0, 0];
% targets.r_grp_aN = [0; 0; 0];
% targets.rcs_dBsm = [0];
