function [ci_vec] = compute_ic(coef,se, N)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute the IC at 1 and 2 standard deviations
% Inputs:
% - coef: the coef for which we compute the ci
% - se: the associated standard errors
% - N: length of the vector used in the linear reg
%
% Output:
% - ci_vec: vector containing the 1 and 2 se CI, as well as the parameter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Computation of the quantile (simple function, assume normal
    % distribution)
    quantile = norminv([0.9 0.95], 0, 1);

    % Computation of the desired quantities
    ci_vec = [coef + quantile(2)*se/sqrt(N) coef + quantile(1)*se/sqrt(N)...
        coef coef - quantile(1)*se/sqrt(N) coef - quantile(2)*se/sqrt(N)];
end

