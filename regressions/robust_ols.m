function [beta_mat, se_mat, r2_vec, T_vec] = robust_ols(Y,X, intercept)
    %% FUNCTION DESCRIPTION
    % Runs a robust to heteroskedasticity OLS regression and returns the 
    % main results.
    %
    % INPUTS:
    %   - Y         : matrix (T x N) containing the values of endogenous 
    %                 variables
    %   - X         : matrix (T x K) containing the values of explicative 
    %                 variables
    %   - intercept : boolean, if true add a constant in explicative 
    %                 variables
    %
    % OUTPUTS:
    %   - beta_mat      : matrix (K (+1) x N) of coefficients (rows = 
    %                     intercept and explicative variables, 
    %                     columns = endogenous variables)
    %   - se_mat        : matrix (K (+1) x N) of standard errors (same
    %                     structure as beta_mat)
    %   - r2_vec        : vector containing the R-squared values of each
    %                     regression
    %   - T_vec         : number of observations of each regression
    %% ====================================================================
    
    %% 1. Basic checks
    [n_rows, n_assets] = size(Y);
        if size(X, 1) ~= n_rows
            error("Y and X must have same number of rows.");
        end
    if any(isnan(Y), 'all') || any(isnan(X), 'all')
        error('Missing values detected in the data. Cannot continue.')
    end
    
    %% 2. Regressions
    % Loop other the different assets (columns of Y)
    for i = 1:n_assets
        y = Y(:,i);
        Mdl = fitlm(X, y, 'Intercept', intercept);
        % We correct to account for heteroskedasticity in the model 
        [~, se, beta] = hac(Mdl, "Type","HC", "Weights", "HC0", "Display","off");
    
        % Matrix creations (when first loop)
        if i==1
            num_coeffs = length(beta);
            beta_mat = nan(num_coeffs, n_assets);
            se_mat   = nan(num_coeffs, n_assets);
            r2_vec   = nan(1, n_assets);
            n_obs_vec= nan(1, n_assets);
        end
    
        % Storage of the results
        beta_mat(:, i) = beta;
        se_mat(:, i)   = se;
        r2_vec(i)      = Mdl.Rsquared.Ordinary;
        T_vec(i)   = Mdl.NumObservations;
    end
end
