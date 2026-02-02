function plot_ci(data)
    %% FUNCTION DESCRIPTION
    % Generates a figure similar to Figure 1 in Herbert et al. (2025).
    %
    % INPUT:
    %   - data: structure containing asset price changes and regressors
    %           (e.g. MPS_BS, MPS_GSS, Target, Path).
    %% ====================================================================

    labels_x = {'ED1', 'ED2', 'ED3', 'ED4'}; 
    x_idx = 1:length(labels_x);
    Y_mat = [data.ED1, data.ED2, data.ED3, data.ED4];

    % 1. Run regressions
    [b_GSS, se_GSS, r2_GSS] = robust_ols(Y_mat, data.MPS_GSS, true);
    [b_BS,  se_BS,  r2_BS]  = robust_ols(Y_mat, data.MPS_BS, true);
    [b_Tgt, se_Tgt, r2_Tgt] = robust_ols(Y_mat, data.Target, true);
    [b_Pat, se_Pat, r2_Pat] = robust_ols(Y_mat, data.Path, true);
    
    % Asset and model names for display
    AssetNames = {'ED1', 'ED2', 'ED3', 'ED4'}; 
    ModelNames = {'GSS'; 'BS'; 'Target'; 'Path'};
    
    % Loop over assets (columns of Y)
    for i = 1:4
        % Retrieve coefficients (row 2 = slope), SEs, and R2 for asset i
        Coeffs = [b_GSS(2,i);  b_BS(2,i);  b_Tgt(2,i);  b_Pat(2,i)];
        SEs    = [se_GSS(2,i); se_BS(2,i); se_Tgt(2,i); se_Pat(2,i)];
        R2s    = [r2_GSS(i);   r2_BS(i);   r2_Tgt(i);   r2_Pat(i)];
        
        if isrow(R2s), R2s = R2s'; end 
        
        % 2. Compute p-values
        Pvals = 2 * (1 - normcdf(abs(Coeffs ./ SEs)));
        
        % 3. Significance stars
        Stars = cell(4,1);
        for k = 1:4
            if Pvals(k) < 0.01
                Stars{k} = '***';
            elseif Pvals(k) < 0.05
                Stars{k} = '**';
            elseif Pvals(k) < 0.1
                Stars{k} = '*';
            else
                Stars{k} = '';
            end
        end
        
        % 4. Display results table for this asset
        T = table(ModelNames, Coeffs, SEs, Pvals, Stars, R2s, ...
            'VariableNames', {'Model', 'Coef', 'SE', 'P_Value', 'Sig', 'R2'});
        
        fprintf('\n=========================================\n');
        fprintf(' RESULTS FOR ASSET: %s\n', AssetNames{i});
        fprintf('=========================================\n');
        disp(T);
    end
    
    % Figure
    f = figure('Name', 'Figure 1: Policy Expectations', ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Units', 'normalized', 'Position', [0.2 0.2 0.6 0.5]); 
        
    t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    % Left panel: full monetary policy surprises
    nexttile;
    hold on;
    yline(0, 'k-', 'LineWidth', 1); 
    
    h1 = draw_coefs(x_idx, b_GSS(2,:), se_GSS(2,:), [0 0 1], -0.15);       
    h2 = draw_coefs(x_idx, b_BS(2,:),  se_BS(2,:),  [0.5 0.5 0.5], 0.15);

    format_panel('(a) Monetary policy surprises', labels_x);
    legend([h1, h2], {'GSS (2005)', 'BS (2023)'}, 'Location', 'northwest');

    % Right panel: decomposed monetary policy surprises
    nexttile;
    hold on;
    yline(0, 'k-', 'LineWidth', 1);

    h3 = draw_coefs(x_idx, b_Tgt(2,:), se_Tgt(2,:), [0.8 0.2 0.2], -0.15); 
    h4 = draw_coefs(x_idx, b_Pat(2,:), se_Pat(2,:), [0.2 0.6 0.2], 0.15);

    format_panel('(b) Target and Path surprises', labels_x);
    legend([h3, h4], {'Target', 'Path'}, 'Location', 'northwest');

    sgtitle('Correlation with policy expectations', 'FontWeight', 'bold');
end

%% LOCAL FUNCTIONS

function h_marker = draw_coefs(x_idx, betas, ses, col, offset)
    % Plot coefficient estimates with confidence intervals
    x_pos = x_idx + offset;
    light_col = col + 0.7 * ([1 1 1] - col);
    h_marker = [];
    
    for i = 1:length(betas)
        bounds = compute_ci(betas(i), ses(i));        
        xi = x_pos(i);
        
        % 95% confidence interval
        line([xi xi], [bounds(5) bounds(1)], ...
             'Color', light_col, 'LineWidth', 1.5);
         
        % 68% confidence interval
        line([xi xi], [bounds(4) bounds(2)], ...
             'Color', col, 'LineWidth', 8);
             
        % Point estimate
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
    xlim([0.5, length(labels) + 0.5]);
end
