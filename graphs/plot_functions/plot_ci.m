function plot_ci(data)
    %% FUNCTION DESCRIPTION
    % Generates a figure similar to the Figure 1 of Herbert et al. (2025) paper.
    % 
    % INPUT:
    %   - data: database containing asset price changes and the regressors (ex:
    %           MPS_BS, MPS_GUR, Path, Target).
    %% ====================================================================

    labels_x = {'ED1', 'ED2', 'ED3', 'ED4'}; 
    x_idx = 1:length(labels_x);
    Y_mat = [data.ED1, data.ED2, data.ED3, data.ED4];


    % 1. Exécution des régressions
    [b_GSS, se_GSS, r2_GSS] = robust_ols(Y_mat, data.MPS_GSS, true);
    [b_BS,  se_BS,  r2_BS]  = robust_ols(Y_mat, data.MPS_BS, true);
    [b_Tgt, se_Tgt, r2_Tgt] = robust_ols(Y_mat, data.Target, true);
    [b_Pat, se_Pat, r2_Pat] = robust_ols(Y_mat, data.Path, true);
    
        % Noms des actifs et des modèles pour l'affichage
    AssetNames = {'ED1', 'ED2', 'ED3', 'ED4'}; 
    ModelNames = {'GSS'; 'BS'; 'Target'; 'Path'};
    
    % On boucle sur les 4 actifs (les 4 colonnes de Y)
    for i = 1:4
        % 1. Récupération des Coefs (ligne 2 pour la pente), SE et R2 pour l'actif i
        Coeffs = [b_GSS(2,i);  b_BS(2,i);  b_Tgt(2,i);  b_Pat(2,i)];
        SEs    = [se_GSS(2,i); se_BS(2,i); se_Tgt(2,i); se_Pat(2,i)];
        R2s    = [r2_GSS(i);   r2_BS(i);   r2_Tgt(i);   r2_Pat(i)];
        
        % Pour R2, on s'assure que c'est une colonne
        if isrow(R2s), R2s = R2s'; end 
        
        % 2. Calcul des P-values
        Pvals = 2 * (1 - normcdf(abs(Coeffs ./ SEs)));
        
        % 3. Création des étoiles de significativité
        Stars = cell(4,1);
        for k = 1:4
            if Pvals(k) < 0.01,     Stars{k} = '***';
            elseif Pvals(k) < 0.05, Stars{k} = '**';
            elseif Pvals(k) < 0.1,  Stars{k} = '*';
            else,                   Stars{k} = '';
            end
        end
        
        % 4. Création et affichage du tableau pour cet actif
        T = table(ModelNames, Coeffs, SEs, Pvals, Stars, R2s, ...
            'VariableNames', {'Modele', 'Coef', 'SE', 'P_Value', 'Sig', 'R2'});
        
        fprintf('\n=========================================\n');
        fprintf(' RÉSULTATS POUR L''ACTIF : %s\n', AssetNames{i});
        fprintf('=========================================\n');
        disp(T);
    end
    
        f = figure('Name', 'Figure 1: Policy Expectations', ...
                   'NumberTitle', 'off', ...
                   'Color', 'w', ...
                   'Units', 'normalized', 'Position', [0.2 0.2 0.6 0.5]); 
        
        t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    % Left: full MPS
    nexttile;
    hold on;
    yline(0, 'k-', 'LineWidth', 1); 
    
    % GSS
    h1 = draw_coefs(x_idx, b_GSS(2,:), se_GSS(2,:), [0 0 1], -0.15);       
    % BS
    h2 = draw_coefs(x_idx, b_BS(2,:), se_BS(2,:), [0.5 0.5 0.5], 0.15);

    % Formatting
    format_panel('(a) MP surprises', labels_x);
    legend([h1, h2], {'GSS2005', 'BS2023'}, 'Location', 'northwest');

    % Right: Decomposed MPS 
    nexttile;
    hold on;
    yline(0, 'k-', 'LineWidth', 1);

    % Target 
    h3 = draw_coefs(x_idx, b_Tgt(2,:), se_Tgt(2,:), [0.8 0.2 0.2], -0.15); 
    % Path
    h4 = draw_coefs(x_idx, b_Pat(2,:), se_Pat(2,:), [0.2 0.6 0.2], 0.15);

    % Formatting
    format_panel('(b) Target and Path surprises', labels_x);
    legend([h3, h4], {'Target', 'Path'}, 'Location', 'northwest');

    sgtitle('Correlation with policy expectations', 'FontWeight', 'bold');
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