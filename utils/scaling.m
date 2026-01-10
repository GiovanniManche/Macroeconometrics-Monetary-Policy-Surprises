function [scaled_loadings, scaled_factor] = scaling(loadings, factor, on_what_to_scale)
    %% FUNCTION DESCRIPTION
    % Scales loadings and principal component to be economically
    % interpretable.
    %  X = score * loadings' = (Score * lambda) * (Loadings' / lambda)
    % Loadings = 5*1 matrix, each row = loadings to MP1, MP2, ED2,...
    %% ====================================================================
    mdl_scale = fitlm(factor, on_what_to_scale);
    lambda = mdl_scale.Coefficients.Estimate(2);
    scaled_loadings = loadings / lambda;
    scaled_factor = factor * lambda;
end