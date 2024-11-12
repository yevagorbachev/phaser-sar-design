%% Phase History Simulation
% P22714 Multifrequency SAR
% Yevgeniy Gorbachev
% November 2024

clear; close all;

%% Conventions
% NOTE All values are in M-K-S units, unless otherwise specified.
% NOTE All log-scale variables are indicated as such
% NOTE X is cross-range, Y is range, Z is altitude
% NOTE Matrices (and some vectors) are suffixed with the quantity indexed into
%       T: slow-time
%       t: fast-time
%       N: target index
%       a: axis (x, y, or z for vectors)
%       1: singleton dimension for broadcasting operations
% Examples: 
%       Tt, for example, is (Slow-time index, fast-time index)
%       TN is (Slow-time index, target index)
%       a1T is (axis, singleton, slow-time);
%       aNT is (axis, target index, slow-time)

%% Constants and simulation parameters
c = 299792458;
k = 1.3806e-23;

rit_scene;

%% Derived variables
struct2wkspace(radar);
struct2wkspace(aperture);

targets.r_aN = [0; aperture.L_0; 0] + targets.r_grp_aN;
grazing = atan(h / L_0);
R_0 = sqrt(h^2 + L_0^2);
R_min = sqrt(h^2 + L_min^2);
R_max = sqrt(h^2 + L_max^2);

t_min = 2*R_min/c - tau;
t_max = 2*R_max/c + tau;
t_fast = t_min:(1/f_s):t_max;
n_fast = length(t_fast);

T_min = S_min / spd;
T_max = S_max / spd;
T_slow = T_min:(1/F_prf):T_max;
N_slow = length(T_slow);

look = [1 0 0;
    0 cos(grazing) -sin(grazing); 
    0 sin(grazing) cos(grazing)];

% Create aperture
v_rdr = [spd; 0; 0];
x_rdr_aT = [spd*T_slow; zeros(1, N_slow); repmat(h, 1, N_slow)];

N_targets = size(targets.r_aN, 2);

%% Plot scene
figure(name = "Target view");
for ti = 1:N_targets
    plot(targets.r_aN(1, ti), targets.r_aN(2, ti), ...
        "+", LineWidth = 2, DisplayName = sprintf("Target %d", ti));
end
plot(0, 0, "+k", LineWidth = 3, HandleVisibility = "off");

xlabel("Coss-range [m]");
ylabel("Range [m]");
legend;
% xlim([S_min S_max]);
% ylim([L_min L_max]);

figure(name = "3D view");
for ti = 1:N_targets
    plot3(targets.r_aN(1, ti), targets.r_aN(2, ti), targets.r_aN(3, ti), ...
        "+", LineWidth = 2, DisplayName = sprintf("Target %d", ti));
end
plot3(x_rdr_aT(1, :), x_rdr_aT(2, :), x_rdr_aT(3, :), "-k", DisplayName = "Aperture");
ground_area_vis = [S_min S_min S_max S_max S_min; 
    L_min L_max L_max L_min L_min; 
    0 0 0 0 0];
plot([S_min S_min S_max S_max S_min], ...
    [L_min L_max L_max L_min L_min], ...
    "--k", HandleVisibility = "off");

xlabel("Coss-range [m]");
ylabel("Range [m]");
zlabel("Altitude [m]");
legend;
view([45 20]);

%% Generate signals

P_n_dBW = db10(B_N * T_0 * k) + NF_dB;
gain = antenna_ptn(antenna, eye(3), [0; 1; 0]);
SNR = P_tx_dBW + db10(gain^2 * lambda^2 / ((4*pi)^3 * R_0^4)) - P_n_dBW;

K_r = B / tau;
t_tx = 0:(1/f_s):tau;
s_tx_t = exp(1i*K_r*t_tx.^2);
s_rx_tT = zeros(N_slow, n_fast);

x_rdr_a1T = permute(x_rdr_aT, [1 3 2]);
r_tgt_aNT = x_rdr_a1T - targets.r_aN;
R_tgt_1NT = vecnorm(r_tgt_aNT, 2, 1);
u_tgt_aNT = r_tgt_aNT ./ R_tgt_1NT;

t_tgt_1NT = 2*R_tgt_1NT/c;
F_dop_1NT = 2/lambda * pagemtimes(v_rdr', u_tgt_aNT);

phi_shift_tNT = exp(-2i*pi*(f_c * t_tgt_1NT + permute(t_tx, [2 1]) .* F_dop_1NT));
phi_rx_tNT = permute(s_tx_t, [2 1]) .* phi_shift_tNT;

rcs_1N = targets.rcs_dBsm;
P_rx_1NT = antenna_ptn(antenna, look, u_tgt_aNT) .*...
    (lambda^2 / (4*pi)^3) ./ R_tgt_1NT.^4 .* ...
    mag10(P_tx_dBW + Rx_amp_dB + rcs_1N - L_dB);

s_rx_tNT = phi_rx_tNT .* sqrt(P_rx_1NT);
i_tgt_1NT = floor((t_tgt_1NT - t_min) * f_s);
i_tgt_eNT = cat(1, i_tgt_1NT, i_tgt_1NT + length(s_tx_t) - 1);

% return;
wb = waitbar(0, "Creating phase history");

for slow_i = 1:N_slow
    for tar_i = 1:N_targets
        slc = i_tgt_eNT(1, tar_i, slow_i):i_tgt_eNT(2, tar_i, slow_i);
        s_rx_tT(slc, slow_i) = s_rx_tT(slc, slow_i) + s_rx_tNT(:, tar_i, slow_i);
    end

    if mod(slow_i, 50) == 0
        waitbar(slow_i / N_slow, wb, sprintf("Slow-time index %d of %d", slow_i, N_slow));
    end
end

waitbar(1, wb, "Done");
close(wb);

save("s_rx_tT.mat", "s_rx_tT");

function gain = antenna_ptn(ant, drc, u_tgt)
    arguments
        ant (1,1) struct; % antenna parameter structure
        drc (3,3) double; % direction cosine matrix
        u_tgt (3,:,:) double; % unit column-vector(s) pointing at target
    end
    A_e = ant.D_az * ant.D_el * ant.effc;
    G = 4*pi*A_e/ant.lambda^2;

    u_ant_aNT = pagemtimes(drc, u_tgt);
    % u_ant_aNT = drc * u_tgt;
    sin_az = u_ant_aNT(1, :, :);
    sin_el = u_ant_aNT(3, :, :);
    gain = G * (sinc(ant.D_az / ant.lambda * sin_az) .* ...
        sinc(ant.D_el / ant.lambda * sin_el)) .^ 2;
end

% Create target modulation constants
% Create per-target data matrix
% Insert per-target data matrix
