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

midterm_scene;

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
s_rx_Tt = zeros(N_slow, n_fast);

x_rdr_a1T = permute(x_rdr_aT, [1 3 2]);
r_tgt_aNT = x_rdr_a1T - targets.r_aN;
R_tgt_1NT = vecnorm(r_tgt_aNT, 2, 1);
u_tgt_aNT = r_tgt_aNT ./ R_tgt_1NT;

t_tgt_1NT = 2*R_tgt_1NT/c;
F_dop_1NT = 2/lambda * pagemtimes(v_rdr', u_tgt_aNT);
phi_shift_tNT = exp(-2i*pi*(f_c * t_tgt_1NT + t_tx' .* F_dop_1NT ));

G_tgt_1NT = antenna_ptn(antenna, look, u_tgt_aNT);

return;
wb = waitbar(0, "Creating phase history");

% required quantities,  TN:
%   modulation phase
%   modulation frequency
%   antenna gain

% In turn, requiring
%   Unit vector
%   Range
%   Range rate

profile on;
for slow_i = 1:N_slow
    x_rdr = x_rdr_aT(:, slow_i);
    for tar_i = 1:N_targets
        x_tgt = targets.r_aN(:, tar_i);
        r_tgt = x_tgt - x_rdr;
        R = norm(r_tgt);
        u_tgt = r_tgt / R;
        t_tgt = 2*R/c;

        i_fast_start = floor((t_tgt - t_min)*f_s);
        i_fast_end = i_fast_start + length(s_tx_t) - 1;

        phi_shift = f_c*t_tgt;
        F_dop = 2/lambda * v_rdr' * u_tgt;
        P_rx = mag10(P_tx_dBW + Rx_amp_dB + targets.rcs_dBsm(tar_i) - L_dB) * ...
            (antenna_ptn(antenna, look, u_tgt)^2 * lambda^2) / ((4*pi)^3 * R^4);

        modul = sqrt(P_rx) * exp(-2i*pi*(phi_shift + t_tx * F_dop));
        % TODO propogation, scattering, antenna pattern

        s_rx_Tt(slow_i, i_fast_start:i_fast_end) = ...
            s_rx_Tt(slow_i, i_fast_start:i_fast_end) ...
            + s_tx_t .* modul;
    end

    if mod(slow_i, 50) == 0
        waitbar(slow_i / N_slow, wb, sprintf("Slow-time index %d of %d", slow_i, N_slow));
    end
end
profile viewer;

waitbar(1, wb, "Done");
close(wb);

save("s_rx_Tt.mat", "s_rx_Tt");

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
