function ci_vec = compute_ci(coef, se)
    %% FUNCTION DESCRIPTION
    % Function which computes the confidence intervals of a given coefficient
    % (1 and 2 standard errors confidence intervals)
    %
    % INPUTS:
    %   - coef      : coefficient for which we want to compute the CI
    %   - se        : its associated standard error
    % OUTPUT
    %   - ci_vec    : vector containing the CI bounds
    %% ====================================================================
    ci_vec = [coef + 2*se, coef + 1*se, coef, coef - 1*se, coef - 2*se];
end