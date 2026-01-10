function mps_output = orthogonalize_mps_BS2023(mps_data, macro_data, varargin)
    %% FUNCTION DESCRIPTION
    % Orthogonalizes MPSs following Bauer & Swanson (2023)
    %
    % INPUTS:
    %   - mps_data      : Table with columns: Date (datetime), MPS or other named variable (numeric)
    %                     Duplicate dates are allowed and preserved
    %   - macro_data    : Struct with fields:
    %                   .nfp (table with Date, PAYEMS)
    %                   .sp500 (table with Date, GSPC_Close)
    %                   .yc_slope (table with Date, BETA1)
    %                   .bcom (table with Date or Dates, BCOMIndex)
    %                   .skew (table with Date, isk)
    %
    % Optional Name-Value Arguments:
    %   - 'Orthogonalize'   : Boolean, whether to orthogonalize (default: true)
    %   - 'Verbose'         : Boolean, display summary statistics (default: true)
    %   - 'MPSVarName'      : String, name of MPS variable in mps_data (default: 'MPS')
    %
    % OUTPUTS:
    %   - mps_output    : Table with columns:
    %                       Date, [original MPS variable], MPS_ORTH (orthogonalized or NaN if not requested),
    %                       NFP_YoY, SP500_3m, Slope_3m, BCOM_3m, Skew_Avg
    %% ====================================================================
    % Parse inputs
    p = inputParser;
    addRequired(p, 'mps_data', @istable);
    addRequired(p, 'macro_data', @(x) isstruct(x) && all(isfield(x, {'nfp', 'sp500', 'yc_slope', 'bcom', 'skew'})));
    addParameter(p, 'Orthogonalize', true, @islogical);
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'MPSVarName', 'MPS', @ischar);
    parse(p, mps_data, macro_data, varargin{:});
    
    do_orth = p.Results.Orthogonalize;
    verbose = p.Results.Verbose;
    mps_var_name = p.Results.MPSVarName;
    
    % Validate that Date and MPS variable exist
    if ~ismember('Date', mps_data.Properties.VariableNames)
        error('mps_data must contain a ''Date'' column');
    end
    if ~ismember(mps_var_name, mps_data.Properties.VariableNames)
        error('mps_data must contain a ''%s'' column', mps_var_name);
    end
    
    % ================================================
    % Prepare macro variables
    % ================================================
    
    % 1. Employment growth (YoY%, monthly data)
    nfp = macro_data.nfp;
    nfp.Date = datetime(nfp.Date);
    nfp.Growth_YoY = 100 * (log(nfp.PAYEMS) - log(lagmatrix(nfp.PAYEMS, 12)));
    
    % 2. S&P 500 (Log prices, daily data)
    sp500 = macro_data.sp500;
    sp500.Date = datetime(sp500.Date);
    sp500.LogPrice = log(sp500.GSPC_Close);
    
    % 3. Yield Curve Slope (daily data)
    yc_slope = macro_data.yc_slope;
    yc_slope.Date = datetime(yc_slope.Date);
    
    % 4. Commodities (log BCOM, daily data)
    bcom = macro_data.bcom;
    % Handle both 'Date' and 'Dates' column names
    if ismember('Date', bcom.Properties.VariableNames)
        bcom.Date = datetime(bcom.Date);
    elseif ismember('Dates', bcom.Properties.VariableNames)
        bcom.Date = datetime(bcom.Dates);
    else
        error('BCOM table must have a Date or Dates column');
    end
    bcom.LogPrice = log(bcom.BCOMIndex);
    
    % 5. Treasury Skewness (daily data)
    skew = macro_data.skew;
    skew.Date = datetime(skew.Date);
    
    % ================================================
    % Construct macro variables for each meeting
    % ================================================
    
    num_meetings = height(mps_data);
    X_macro = array2table(nan(num_meetings, 5), ...
        'VariableNames', {'NFP_YoY', 'SP500_3m', 'Slope_3m', 'BCOM_3m', 'Skew_Avg'});
    
    for i = 1:num_meetings
        fomc_date = mps_data.Date(i);
        
        % 1. Employment growth: Last release before the FOMC meeting
        idx_nfp = find(nfp.Date < fomc_date, 1, 'last');
        if ~isempty(idx_nfp)
            X_macro.NFP_YoY(i) = nfp.Growth_YoY(idx_nfp);
        end
        
        % 2. S&P 500: Log change over 65 trading days (~3 months)
        idx_sp_end = find(sp500.Date < fomc_date, 1, 'last');
        if ~isempty(idx_sp_end) && (idx_sp_end > 65)
            idx_sp_start = idx_sp_end - 65;
            X_macro.SP500_3m(i) = sp500.LogPrice(idx_sp_end) - sp500.LogPrice(idx_sp_start);
        end
        
        % 3. YC Slope: Change over 65 days
        idx_sl_end = find(yc_slope.Date < fomc_date, 1, 'last');
        if ~isempty(idx_sl_end) && (idx_sl_end > 65)
            idx_sl_start = idx_sl_end - 65;
            X_macro.Slope_3m(i) = yc_slope.BETA1(idx_sl_end) - yc_slope.BETA1(idx_sl_start);
        end
        
        % 4. BCOM: Log change over 65 days
        idx_bc_end = find(bcom.Date < fomc_date, 1, 'last');
        if ~isempty(idx_bc_end) && (idx_bc_end > 65)
            idx_bc_start = idx_bc_end - 65;
            X_macro.BCOM_3m(i) = bcom.LogPrice(idx_bc_end) - bcom.LogPrice(idx_bc_start);
        end
        
        % 5. Implied Skew: Average over the preceding month
        date_start_skew = fomc_date - 30;
        date_end_skew = fomc_date - 1;
        mask_skew = (skew.Date >= date_start_skew) & (skew.Date <= date_end_skew);
        vals_skew = skew.isk(mask_skew);
        if ~isempty(vals_skew)
            X_macro.Skew_Avg(i) = mean(vals_skew, 'omitnan');
        end
    end
    
    % ================================================
    % Perform orthogonalization
    % ================================================
    
    % Merge with original data
    mps_output = [mps_data, X_macro];
    
    if do_orth
        % Add row index to preserve original row order (bc of duplicate dates)
        mps_output.RowIdx = (1:num_meetings)';
        
        dataset_reg = mps_output(:, {'Date', 'RowIdx', mps_var_name, 'NFP_YoY', 'SP500_3m', 'Slope_3m', 'BCOM_3m', 'Skew_Avg'});
        dataset_reg_clean = rmmissing(dataset_reg);
        
        % Build formula dynamically
        formula_str = sprintf('%s ~ NFP_YoY + SP500_3m + Slope_3m + BCOM_3m + Skew_Avg', mps_var_name);
        
        % Run orthogonalization regression on cleaned data
        mdl = fitlm(dataset_reg_clean, formula_str);
        
        % Store orthogonalized MPS (residuals)
        mps_output.MPS_ORTH = nan(num_meetings, 1);
        mps_output.MPS_ORTH(dataset_reg_clean.RowIdx) = mdl.Residuals.Raw;
        
        % Remove temporary RowIdx column
        mps_output.RowIdx = [];
        
        rows_complete = ~isnan(mps_output.MPS_ORTH);
        
        % Display summary if verbose
        if verbose
            fprintf('\n=== Bauer & Swanson (2023) Orthogonalization ===\n');
            fprintf('MPS variable used: %s\n', mps_var_name);
            fprintf('Original sample size: %d\n', num_meetings);
            fprintf('Complete cases: %d (%.1f%%)\n', sum(rows_complete), 100*sum(rows_complete)/num_meetings);
            fprintf('Missing observations: %d\n', sum(~rows_complete));
            
            % Check for duplicate dates
            unique_dates = unique(mps_data.Date);
            if length(unique_dates) < num_meetings
                fprintf('Note: Dataset contains %d duplicate dates (%d unique dates)\n', ...
                    num_meetings - length(unique_dates), length(unique_dates));
            end
            
            fprintf('R² of MPS on macro variables: %.4f\n', mdl.Rsquared.Ordinary);
            fprintf('Adj. R²: %.4f\n', mdl.Rsquared.Adjusted);
            fprintf('\nRegression coefficients:\n');
            disp(mdl.Coefficients);
        end
    else
        % No orthogonalization: fill with NaN
        mps_output.MPS_ORTH = nan(num_meetings, 1);
        
        if verbose
            fprintf('\n=== Macro variables constructed (no orthogonalization) ===\n');
            fprintf('MPS variable: %s\n', mps_var_name);
            fprintf('Sample size: %d\n', num_meetings);
            
            % Check for duplicate dates
            unique_dates = unique(mps_data.Date);
            if length(unique_dates) < num_meetings
                fprintf('Note: Dataset contains %d duplicate dates (%d unique dates)\n', ...
                    num_meetings - length(unique_dates), length(unique_dates));
            end
            
            complete_macro = ~any(ismissing(X_macro), 2);
            fprintf('Observations with complete macro data: %d (%.1f%%)\n', ...
                sum(complete_macro), 100*sum(complete_macro)/num_meetings);
        end
    end
    
end