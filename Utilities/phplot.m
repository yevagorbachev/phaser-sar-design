function im = phplot(data_tT, T_slow, t_fast, v_label)
    lay = tiledlayout(1,1);
    m_ax = axes(lay);
    colormap(m_ax, "jet");
    im = imagesc(m_ax, T_slow, t_fast, data_tT);
    cb = colorbar(m_ax);
    siprefix("Cross-range [%ss]", m_ax, "XAxis", "XTickLabels");
    siprefix("Range [%ss]", m_ax, "YAxis", "YTickLabels");
    siprefix(v_label, cb, "Ruler", "TickLabels");
end

