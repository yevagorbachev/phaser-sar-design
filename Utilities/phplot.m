function [im] = phplot(data, T_slow, t_fast, v_label)
    lay = tiledlayout(1,1);
    m_ax = axes(lay);
    colormap(m_ax, "jet");
    im = imagesc(m_ax, t_fast, T_slow, data);
    cb = colorbar(m_ax);
    siprefix("Cross-range [%ss]", m_ax, "YAxis", "YTickLabels");
    siprefix("Range [%ss]", m_ax, "XAxis", "XTickLabels");
    siprefix(v_label, cb, "Ruler", "TickLabels");
end

