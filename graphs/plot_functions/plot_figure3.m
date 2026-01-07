function plot_figure3(yields_table, mps_table, indic_hom)
    %% FUNCTION DESCRIPTION
    % Reproduces Figure 3 from Herbert et al. (2025).
    % Left: HOM statements, Right: other statements
    % Top: 5Y Treasury yield changes, Bottom: 10Y Treasury yield changes
    %
    % INPUTS:
    %   - yields_table  : table containing the daily changes in Treasury
    %                     yields
    %   - mps_table     : table containing the MPS
    %   - indic_hom     : indicator which tells if a statement is HOM or not.
    %% ====================================================================

    %% Basic checks when getting data
    % We check is MPS (Bauer & Swanson) are in. 
    if ismember('MPS_BS', mps_table.Properties.VariableNames)
        X_vec = mps_table.MPS_BS;
    elseif ismember('MPS', mps_table.Properties.VariableNames)
        X_vec = mps_table.MPS;
    else
        error('Column "MPS" or "MPS_BS" not found. Cannot continue.');
    end
    
    % For figure 3, we want changes in SVENY05 and SVENY10
    if ismember('SVENY05', yields_table.Properties.VariableNames) && ...
            ismember('SVENY10', yields_table.Properties.VariableNames)
        Y_5y  = yields_table.SVENY05;
        Y_10y = yields_table.SVENY10;
    else
        error('Colonnes SVENY05/SVENY10 ou Diff5y/Diff10y introuvables.');
    end

    %% Distinction between HOM and other
    idx_hom   = logical(indic_hom);
    idx_other = ~idx_hom; 

    %% Figure
    f = figure('Name', 'Figure 3: Long-term interest rates and monetary surprises', ...
               'Color', 'w', 'Units', 'normalized', 'Position', [0.2 0.1 0.5 0.7]);
    
    t = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    % TOP LEFT: 5y / HOM 
    nexttile;
    plot_scatter_fit(X_vec(idx_hom), Y_5y(idx_hom), [1 0.5 0], 'HOM statements');
    ylabel('5-year Treasury rates');

    % TOP RIGHT: 5y / Other
    nexttile;
    plot_scatter_fit(X_vec(idx_other), Y_5y(idx_other), [0.2 0.4 0.6], 'Other statements');
    ylabel('5-year Treasury rates');

    % BOTTOM LEFT: 10y / HOM 
    nexttile;
    plot_scatter_fit(X_vec(idx_hom), Y_10y(idx_hom), [1 0.5 0], 'HOM statements');
    ylabel('10-year Treasury rates');
    xlabel('MPS_t');

    % BOTTOM RIGHT: 10y / Other (Blue) 
    nexttile;
    plot_scatter_fit(X_vec(idx_other), Y_10y(idx_other), [0.2 0.4 0.6], 'Other statements');
    ylabel('10-year Treasury rates');
    xlabel('MPS_t');

    sgtitle('Long-term interest rates and monetary surprises', 'FontWeight', 'bold');
end

%% LOCAL FUNCTION 
function plot_scatter_fit(x, y, col, title_str)
    hold on;
    
    % 1. Scatter Plot 
    scatter(x, y, 30, col, 'LineWidth', 1.2); 
    
    % 2. Linear regression line (y = ax+b)
    if length(x) > 2
        p = polyfit(x, y, 1); 
        x_fit = linspace(min(x), max(x), 100);
        y_fit = polyval(p, x_fit);
        plot(x_fit, y_fit, '-', 'Color', col, 'LineWidth', 2);
    end
    
    % Formatting
    title(title_str, 'FontWeight', 'normal', 'Color', 'k'); 
    grid on; box on;
    
    ylim([-0.25 0.20]); 
    xlim([-0.15 0.15]);
    
    hold off;
end