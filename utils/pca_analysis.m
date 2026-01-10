function [loadings, score, latent, explained, mu] = pca_analysis(data, varargin)
    %% FUNCTION DESCRIPTION
    % Performs PCA analysis and creates visualization plots for explained
    % variance and component loadings.
    %
    % INPUTS:
    %   - data       : matrix (T x K) containing the variables for PCA
    %
    % NAME-VALUE PAIRS (optional):
    %   'Labels'     : cell array of variable names (default: {'Var1','Var2',...})
    %   'Title'      : main title for the figure (default: 'PCA Analysis')
    %   'NumPCs'     : number of PCs to show loadings for (default: 2)
    %   'Centered'   : boolean for centering data (default: true)
    %   'ShowPlot'   : boolean to display plots (default: true)
    %
    % OUTPUTS:
    %   - loadings   : principal component loadings
    %   - score      : principal component scores (factors)
    %   - latent     : eigenvalues
    %   - explained  : percentage of variance explained
    %   - mu         : mean of each variable
    %
    %% ====================================================================
    
    %% 1. Parse inputs
    p = inputParser;
    addRequired(p, 'data');
    addParameter(p, 'Labels', []);
    addParameter(p, 'Title', 'PCA Analysis');
    addParameter(p, 'NumPCs', 2);
    addParameter(p, 'Centered', true);
    addParameter(p, 'ShowPlot', true);
    parse(p, data, varargin{:});
    
    data = p.Results.data;
    titleStr = p.Results.Title;
    numPCs = p.Results.NumPCs;
    centered = p.Results.Centered;
    showPlot = p.Results.ShowPlot;
    
    % Default labels
    if isempty(p.Results.Labels)
        nVars = size(data, 2);
        labels = arrayfun(@(i) sprintf('Var%d', i), 1:nVars, 'UniformOutput', false);
    else
        labels = p.Results.Labels;
    end
    
    %% 2. Perform PCA
    [loadings, score, latent, ~, explained, mu] = pca(data, 'Centered', centered);
    
    %% 3. Display summary statistics
    fprintf('\n========================================\n');
    fprintf('%s\n', titleStr);
    fprintf('========================================\n');
    fprintf('\nVariance explained by first %d PCs:\n', numPCs);
    for i = 1:min(numPCs, length(explained))
        fprintf('  PC%d: %.2f%%\n', i, explained(i));
    end
    fprintf('  Cumulative: %.2f%%\n', sum(explained(1:min(numPCs, length(explained)))));
    fprintf('========================================\n\n');
    
    %% 4. Create visualization if requested
    if showPlot
        % Determine number of subplots needed
        nSubplots = 1 + numPCs; % 1 for variance explained + numPCs for loadings
        
        figure('Position', [100, 100, 900, 300*ceil(nSubplots/2)]);
        
        % Plot 1: Variance explained
        subplot(ceil(nSubplots/2), 2, 1);
        bar(explained, 'FaceColor', [0.2 0.4 0.8]);
        xlabel('Principal Component');
        ylabel('% Variance Explained');
        title('Variance Explained by Each PC');
        grid on;
        
        % Add cumulative variance line
        hold on;
        yyaxis right;
        plot(cumsum(explained), '-o', 'LineWidth', 2, 'MarkerSize', 6);
        ylabel('Cumulative %');
        ylim([0 105]);
        hold off;
        
        % Plots 2+: Loadings for each PC
        colors = lines(numPCs);
        for i = 1:min(numPCs, size(loadings, 2))
            subplot(ceil(nSubplots/2), 2, i+1);
            
            % Bar plot with colors
            b = bar(loadings(:, i), 'FaceColor', colors(i,:));
            
            % Customize
            set(gca, 'XTick', 1:length(labels), 'XTickLabel', labels);
            ylabel('Loading');
            title(sprintf('PC%d Loadings (%.1f%% variance)', i, explained(i)));
            grid on;
            
            % Add zero line
            hold on;
            yline(0, 'k--', 'LineWidth', 1);
            hold off;
            
            % Rotate x-labels if too many
            if length(labels) > 6
                xtickangle(45);
            end
        end
        
        % Super title
        sgtitle(titleStr, 'FontSize', 14, 'FontWeight', 'bold');
    end
end