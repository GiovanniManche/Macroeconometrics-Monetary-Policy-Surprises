function plot_figure2(data, indicator)
    %% FUNCTION DESCRIPTION
    % Generates a figure similar to the Figure 2 of Herbert et al. (2025) paper.
    % The function basically follows the same structure as in "plot_ci".
    % 
    % INPUT:
    %   - data: database containing asset price changes and the regressors.
    %   - indicator: dummy variable used to split the sample (ex: Opposite signs).
    %% ====================================================================
    labels_x = {'ED1', 'ED2', 'ED3', 'ED4'}; 
    x_idx = 1:length(labels_x);
    Y_mat = [data.ED1, data.ED2, data.ED3, data.ED4];
    
    % Regressions
    % We regress on the subset where indicator is 0 (Same sign)
    [b_Same, se_Same] = robust_ols(Y_mat(~indicator, :), data.MPS_BS(~indicator), true);
    % We regress on the subset where indicator is 1 (Opposite signs)
    [b_Opp,  se_Opp]  = robust_ols(Y_mat(indicator, :), data.MPS_BS(indicator), true);
    
    f = figure('Name', 'Figure 2: Term structure of policy expectations', ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Units', 'normalized', 'Position', [0.2 0.2 0.6 0.5]); 
    
    t = tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Term structure of policy expectation adjustments
    nexttile;
    hold on;
    yline(0, 'k-', 'LineWidth', 1); 
    
    % Same sign (Indicator == 0)
    h1 = draw_coefs(x_idx, b_Same(2,:), se_Same(2,:), [0.2 0.2 0.2], -0.1);       
    % Opposite signs (Indicator == 1)
    h2 = draw_coefs(x_idx, b_Opp(2,:), se_Opp(2,:), [1 0.5 0], 0.1);
    
    % Formatting
    format_panel('Term structure of policy expectation adjustments', labels_x);
    legend([h1, h2], {'Same sign', 'Opposite signs'}, 'Location', 'northwest');
end
%% LOCAL FUNCTIONS
function h_marker = draw_coefs(x_idx, betas, ses, col, offset)
    % Plot the boxplots for a given series 
    x_pos = x_idx + offset;
    light_col = col + 0.7 * ([1 1 1] - col);
    h_marker = [];
    for i = 1:length(betas)
        bounds = compute_ci(betas(i), ses(i));        
        xi = x_pos(i);
        
        % 95%  intervals
        line([xi xi], [bounds(5) bounds(1)], ...
             'Color', light_col, 'LineWidth', 1.5);
         
        % 68% intervals
        line([xi xi], [bounds(4) bounds(2)], ...
             'Color', col, 'LineWidth', 8);
             
        % 3. Point Estimate 
        h = plot(xi, bounds(3), 's', 'MarkerFaceColor', col, ...
             'MarkerEdgeColor', 'k', 'MarkerSize', 6);
        if i == 1
            h_marker = h;
        end
    end
    
end
function format_panel(title_str, labels)
    xticks(1:length(labels));
    xticklabels(labels);
    ylabel('Coefficient');
    title(title_str, 'FontWeight', 'bold');
    grid on; box on;
    xlim([0.5, length(labels)+0.5]);
end