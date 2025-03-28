clear;
syms omega_c omega_if K_r t t_u t_grp pi
omega_cp = omega_c + omega_if;
t_tgt = t_u + t_grp;
s_tx_ang = omega_c * t + pi*K_r*t^2;
s_rx_ang = subs(s_tx_ang, t, t - t_tgt);
s_loc_ang = omega_cp * t + pi*K_r*t^2;
s_loc_ang = subs(s_loc_ang, t, t - t_grp);
s_if_hi = s_loc_ang + s_rx_ang;
s_if_lo = s_loc_ang - s_rx_ang;
expand(s_if_lo)
s_if_deriv = omega_if * t - omega_if * t_grp + t_u*(omega_c + 2*pi*K_r*(t - t_grp)) - pi*K_r*t_u^2;
expand(s_if_deriv)
simplify(s_if_deriv - s_if_lo)
