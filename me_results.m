function [me_table] = me_results(yvec, X, me_table, coefs)
% Small function to fill a table for ME coefficients (i.e. MPS|1^OPP = 1}
    for j =1:size(yvec,2)
        vec_me = compute_me(yvec(:,j), X, coefs);
        me_table{:,j} = round(vec_me', 3);
    end
end

function [avg_effect_vec] = compute_me(y,X, coefs)
% Small function to compute average marginal effect 
% when there is an interaction term, as well as standard error robust to 
% heteroskedasticity
% Inputs:
% - y: vector of dependent variable
% - X: matrix with regression variables
% - coefs: number of coefs to consider to compute the average effect
% Outputs:
% - me_vec: a vector containing the average effect and the associated SE
    
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
    [var_coef, ~, beta] = hac(Mdl, "Type","HC", "Weights", "CLM");

    % Compute the average effect
    average_effect = sum(beta(coefs,1));

    % Compute the associated SE
    var_effect = 0;
    for i=1:length(coefs)
        coef_var = coefs(i);
        % Add the variance term corresponding to each coef to keep
        var_effect = var_effect + var_coef(coef_var,coef_var);
           
        % Loop over the remaining term to add the covariance
        if i < length(coefs)
            for j = (i+1):length(coefs)
                coef_cov = coefs(j);
                var_effect = var_effect + 2 * var_coef(coef_var, coef_cov);
            end
        end
    end

    % Sanity check
    if var_effect < 0
        disp(var_effect);
        error("The variance of the marginal effect shouldn't be negative");
    end
    
    % Keep only the SE
    average_effect_se = sqrt(var_effect);
    avg_effect_vec = [average_effect average_effect_se];
end
