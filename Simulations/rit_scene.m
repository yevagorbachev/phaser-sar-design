% Transmitting characteristics
radar.P_tx_dBW = -24;
radar.Rx_amp_dB = 92;
radar.f_c = 3.2e9;
radar.lambda = c / radar.f_c;
radar.tau = 150e-9;
radar.B = 200e6;
radar.f_s = 1.4*radar.B;
radar.F_prf = 100;

% Impairments
radar.B_N = radar.f_s;
radar.NF_dB = 41;
radar.L_dB = 6;
radar.T_0 = 310;

% Antenna characteristics
antenna.D_az = 0.1;
antenna.D_el = 0.1;
antenna.effc = 0.2;
antenna.lambda = radar.lambda;

% Aperture characteristics
aperture.h = 20;
aperture.L_0 = 75;
aperture.L_min = 50;
aperture.L_max = 100;
aperture.S_min = -5;
aperture.S_max = 5;
aperture.spd = 0.1;

% r - each column is a target's position
targets.r_grp_aN = [0 0 0; 
    -20 0 0]'; 
targets.rcs_dBsm = [5, 5];
