function [coef_table,r_2] = regression(y,X)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute robust to heteroskedasticity OLS
% using built-in packagre from Matlab

% Inputs:
% - X: matrix of regressors (without constant)
% - y: matrix of dependent variable

% Outputs:
% - coef_table: Table with coef, se, t-star, pvalue
% - r_2: R2 of the regression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Usual sanity check: length of the of matrix and presence of NaN
    if length(X) ~= length(y)
        error("Both series must have the same length to perform regression");
    end

    % Check if there are missing values in y
    if sum(sum(isnan(X))) ~= 0 || sum(sum(isnan(y))) ~= 0
        error("One of the serie contains missing values, check before continuing");
    end

    % Estimation from OLS
    Mdl = fitlm(X, y, 'Intercept', false);

    % We correct to account for heteroskedasticity in the model
    [~, se, beta] = hac(Mdl, "Type","HC", "Weights", "CLM");

    % Computation of tstats and pvalue
    tstats = beta./se;
    pval = 2*(1-normcdf(abs(tstats)));

    % Computation of the r_squared
    e = y-X*(beta);
    sse = sum(e.^2);
    sst = sum((y - mean(y)).^2);
    r_2 = 1 - sse/sst;

    % Store and retrieve the results
    coef_table = table(beta, se, tstats, pval, 'VariableNames',{'coef','se', ...
        'tstats','pval'});
end

