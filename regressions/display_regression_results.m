function display_regression_results(Y, X, varargin)
    %% FUNCTION DESCRIPTION
    % Display multiple regression results in a standardized table. Can handle
    % several regressions at the same time.
    %
    % INPUTS:
    %   - Y : Matrix (T x N) of endogenous variables
    %   - X : Matrix (T x K) of regressors. 
    %   To handle several regression: {X1, X2}.
    % OPTIONAL NAME-VALUE PAIRS:
    %   'YNames'     : Column names (usually the endogenous variables)
    %   'XNames'     : Row names (usually the regressors)
    %   'SpecNames'  : Specification name (ex: "MPS", "Target+Path")
    %   'Intercept'  : boolean to include a constant (default: true)
    %   'Title'      : table title(default: 'Regression Results')
    %% ====================================================================
    
    %% 1. Parse inputs
    p = inputParser;
    addRequired(p,'Y');
    addRequired(p,'X');
    addParameter(p,'YNames', []);
    addParameter(p,'XNames', []);
    addParameter(p,'SpecNames', []);
    addParameter(p,'Intercept', true);
    addParameter(p,'Title', 'Regression Results');
    addParameter(p,'Digits', 3);
    parse(p, Y, X, varargin{:});
    
    Y = p.Results.Y;
    X = p.Results.X;
    intercept = p.Results.Intercept;
    
    %% 2. Basic checks and handling
    % Convert X to cell if needed 
    if ~iscell(X)
        X = {X};
    end
    nSpecs = length(X);
    
    % Number of endogenous variables (= number of regressions = number of 
    % columns in the table)
    [Tn, nY] = size(Y);
    
    % Default names
    if isempty(p.Results.YNames)
        YNames = arrayfun(@(i) sprintf('Y%d', i), 1:nY, 'UniformOutput', false);
    else
        YNames = p.Results.YNames;
    end
    
    if isempty(p.Results.SpecNames)
        SpecNames = arrayfun(@(i) sprintf('Spec%d', i), 1:nSpecs, 'UniformOutput', false);
    else
        SpecNames = p.Results.SpecNames;
    end
    
    % Handle XNames
    if isempty(p.Results.XNames)
        XNames = cell(nSpecs, 1);
        for s = 1:nSpecs
            nX = size(X{s}, 2);
            XNames{s} = arrayfun(@(i) sprintf('X%d', i), 1:nX, 'UniformOutput', false);
        end
    else
        XNames = p.Results.XNames;
        if ~iscell(XNames{1})
            XNames = {XNames};
        end
    end
    
    %% 3. Run regressions for each specification
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('%s\n', p.Results.Title);
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    for s = 1:nSpecs
        fprintf('======= %s ======= \n\n', SpecNames{s});
        
        % Run regression
        [b, se, r2, n] = robust_ols(Y, X{s}, intercept);
        
        % Determine indices (we won't show intercept because we don't care)
        if intercept
            coef_idx = 2:size(b, 1);
            var_names = XNames{s};
        else
            coef_idx = 1:size(b, 1);
            var_names = XNames{s};
        end
        
        % Build results matrix
        nVars = length(coef_idx);
        nRows = nVars * 2 + 2;  % coef + se for each var + R2 + Obs
        results_matrix = nan(nRows, nY);
        rowNames = cell(nRows, 1);
        
        % We fill with coefficients and se
        row = 1;
        for v = 1:nVars
            results_matrix(row, :) = b(coef_idx(v), :);
            rowNames{row} = var_names{v};
            row = row + 1;
            
            results_matrix(row, :) = se(coef_idx(v), :);
            rowNames{row} = ['se_' var_names{v}];
            row = row + 1;
        end
        
        % We add R2 and observations
        results_matrix(row, :) = r2;
        rowNames{row} = 'R2';
        row = row + 1;
        
        results_matrix(row, :) = n;
        rowNames{row} = 'Obs';
        
        % We display coefficients table
        T = array2table(results_matrix, 'RowNames', rowNames, 'VariableNames', YNames);
        disp(T);
        
        % We compute and display p-values
        fprintf('\nP-values:\n');
        pval_matrix = nan(nVars, nY);
        pval_rowNames = cell(nVars, 1);
        
        for v = 1:nVars
            coef_row = (v-1)*2 + 1;
            se_row = coef_row + 1;
            
            t_stat = results_matrix(coef_row, :) ./ results_matrix(se_row, :);
            pval_matrix(v, :) = 2 * (1 - normcdf(abs(t_stat)));
            pval_rowNames{v} = ['pval_' var_names{v}];
        end
        
        T_pval = array2table(pval_matrix, 'RowNames', pval_rowNames, 'VariableNames', YNames);
        disp(T_pval);
    end

end