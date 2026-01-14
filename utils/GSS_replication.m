function [Target, Path, rotated_loadings] = GSS_replication(X_raw)
    %% FUNCTION DESCRIPTION
    %  Replicates Gürkaynak et al. (2025) procedure to extract Target and
    %  Path factors from surprise changes in the Fed funds rate futures and
    %  Eurodollar futures. 
    % 
    % INPUT:
    %   - X_raw             : (T x 5) matrix containing [MP1, MP2, ED2, ED3, ED4]
    %                       (in THAT order). 
    %                       MP1 and MP2 are scaled surprises in Fed funds rate
    %                       futures (as described in the appendix of GSS 2005). 
    %                       They are already computed in US-MPD.
    % 
    % OUTPUTS:
    %   - Target and Path  : the two factors defined in GSS 2005.
    %   - rotated_loadings : (5 x 2) matrix of associated rotated loadings
    %% ====================================================================
    %% Principal component estimation
    X_norm = zscore(X_raw);
    [coeffs, scores] = pca(X_norm);
    
    % Take the 2 first principal components
    F1 = scores(:, 1);
    F2 = scores(:, 2);
    loadings_original = coeffs(:, 1:2);
    
    %% 2. Rotation (see Appendix of GSS 2005)
    % First condition: Z1 and Z2 have unit variance 
    F1 = zscore(F1);
    F2 = zscore(F2);

    % Second condition: Z1 and Z2 stay orthogonal (we will test this later)
    % Third condition: Z2 does not influence the current policy surprise
    mp1 = X_raw(:, 1); 
    
    % mp1 = c + gamma1*F1 + gamma2*F2 + error
    reg_mp1 = fitlm([F1, F2], mp1);
    gamma1 = reg_mp1.Coefficients.Estimate(2); 
    gamma2 = reg_mp1.Coefficients.Estimate(3); 
    
    % Rotation matrix U
    ratio = gamma1 / gamma2;
    alpha2 = sqrt(1 / (ratio^2 + 1));
    alpha1 = ratio * alpha2;
    
    % Orthogonality condition for beta
    beta2 = sqrt(1 / ((alpha2/alpha1)^2 + 1));
    beta1 = -(alpha2 * beta2) / alpha1;
    
    % U
    U = [alpha1, beta1; 
         alpha2, beta2];
     
    % Rotation
    Factors_Rotated = [F1, F2] * U;
    Z1_temp = Factors_Rotated(:, 1);
    Z2_temp = Factors_Rotated(:, 2);
    loadings_rotated_temp = loadings_original * U;

    %% 3. Scaling
    % GSS rescale the factors so that:
    %   - Z1 moves MP1 one for one
    %   - Z2 and Z1 have the same magnitude effect on ED4

    ed4 = X_raw(:, 5); 

    % First scale Z1
    reg_z1 = fitlm(Z1_temp, mp1, 'Intercept', false);
    scale_1 = reg_z1.Coefficients.Estimate(1);
    Z1 = Z1_temp * scale_1; 
    
    % Then scale Z2 wrt Z1
    reg_multivar = fitlm([Z1, Z2_temp], ed4); 
    
    beta_target_on_ed4 = reg_multivar.Coefficients.Estimate(2); % Coeff Z1
    beta_path_raw_on_ed4 = reg_multivar.Coefficients.Estimate(3); % Coeff Z2_temp
    
    if abs(beta_target_on_ed4) < 1e-10
        error('Path factor has a null effect on ED4. We cannot normalize Path with respect to it.');
    end
    
    scale_2 = beta_path_raw_on_ed4 / beta_target_on_ed4;
    Z2 = Z2_temp * scale_2;
    rotated_loadings = loadings_rotated_temp .* [scale_1, scale_2];
    
    %% 4. Output
    Target = Z1;
    Path = Z2;
    fprintf('Correlation between Target and Path: %.4f (Should be very close to 0)\n', corr(Target, Path));
end