function [r2_vect] = subsample_r_squared(y,X,dummy)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Function to compute the R2 of a regression          %
%   over a subsample of observations for a given            %
%   number of dependent variables and a given criteria      %
%                                                           %
% Inputs:                                                   %
% - y: vector of dependent variables                        %
% - X: matrix of regressors                                 %
% - dummy: dummy variable to filter out the observations to %
% compute the regression                                    %
%                                                           %
% Outputs:                                                  %
% - r2_vec: vector containing the R2 for each regression    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % We only keep the observation associated with a given criteria
    y = y(dummy==1,:); X = X(dummy==1, :);

    % vector to stack the R2
    r2_vect = zeros(1,size(y,2));

    % Loop to make the regression and retrieve the R2 for each dependent
    % variable
    for j = 1:size(y,2)
        [~, r2] = regression(y(:,j),X);
        r2_vect(1,j) = r2;
    end
end

