function [result_table] = table_results(yvec,X, result_table, vect_coef)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generic functions to compute the table results %
%       of the regression over several assets    %
%
% Inputs:
% - yvec: vector containing each assets on which the regression should be
% performed
% - X: matrix containing the regressors
% - result_table: the empty table to fill with the results
% Outputs:
% - result_table: the filled table with the results
% - vect_coef: vector containing the coeff to retrieve from the regression
%%%%%%%%%%%
% Loop for the regression
for j = 1:size(yvec,2)

    % Regression
    [coef_reg, r_2] = regression(yvec(:,j),X);

    % Retrieve the results from the regression
    results = get_coef_reg(coef_reg, r_2, vect_coef);

    % Compute average effects eventually
    result_table{:,j} = round(results', 3);
end
end


function [vect_result] = get_coef_reg(coef_reg_table, r_2, vect_coef)
% Small function to loop over the elements of the coefficient table
% to build the vector that will be reported in the result table
    
    vect_result = [];
    for i = 1:size(vect_coef,2)
        % Number of coef to retrieve
        coef_num = vect_coef(1,i);
        vect_result = [vect_result table2array(coef_reg_table(coef_num,1:2))]; 
    end
    vect_result(end+1) = r_2;
end
