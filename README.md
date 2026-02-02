# Monetary Policy Surprises, Higher-Order Moments, and the Yield Curve

Replication and extension of Herbert, Hubert, and Lé (2025)

### Giovanni Manche & Timothée Dangleterre

> **Main takeaway:** Monetary policy transmission to long-term yields is highly heterogeneous and is largely driven by higher-order moment announcements operating primarily through the real rate and term premium channels.

![Console Output](graphs/teaser_hom_vs_nonhom_1999_2025.png)

*Figure summarizing Table 3 (1999–2025): yield responses to monetary policy surprises are substantially larger during higher-order moment (HOM) events than during non-HOM events.*

---
This repository provides replication and extension code for Sylvérie Herbert, Paul Hubert, and Mathias Lé (2025),
[_When does Monetary Policy Matter? Policy Stance vs. Term Premium News_](https://www.banque-france.fr/en/publications-and-statistics/publications/when-does-monetary-policy-matter-policy-stance-vs-term-premium-news),
Working Paper No. 1017, Banque de France.

 
More precisely, the repository replicates their baseline results and extends the analysis using the extended [U.S. Monetary Policy Event-Study Database](https://www.frbsf.org/research-and-insights/data-and-indicators/us-monetary-policy-event-study-database/).

We rely on high-frequency identification methods, following the literature on monetary policy surprises, to study the effects of monetary policy news on asset prices (especially long-term interest rates) as well as on macroeconomic variables using local projections.

## Project Overview
The main objective is to exploit the interplay between the well-known **Target** and **Path** monetary policy surprises to identify **"higher-order moment (HOM) statements"**, defined as events in which the Path surprise is larger in absolute value than the Target surprise and both have opposite signs. 

We analyse monetary policy surprises around not only FOMC statements, but also around Press Conferences, "Monetary Events" and Minutes, following the steps below:
- **Target and Path monetary policy surprises**, constructed following the methodology of Gürkaynak, Sack and Swanson (2005), which consists of rotating the first two principal components of high-frequency changes in Fed Funds and Eurodollar futures;
- **Orthogonalized monetary policy surprises**, constructed following the methodology of Bauer and Swanson (2023), which consists of regressing the first principal component of high-frequency changes in Eurodollar futures on a selected set of publicly available macroeconomic data in order to purge predictable components;
- **Heterogeneous transmission of monetary policy along the yield curve**: using event-study methods, we show that most of the transmission of monetary policy to the long-end of the yield curve is driven by HOM events. This finding helps explain the well-known puzzle whereby variations in long-term interest rates are concentrated around FOMC announcement windows, even though FOMC announcements account for only a small fraction of the daily variance of long-term yields;
- **Robustness checks** including controls for asymmetric effects, quantitative easing announcements, euro-area evidence, and subsample analyses;
- **Local Projection with external instruments** used to assess the macroeconomic effects of monetary policy surprises.

## Key findings
Our results are consistent with those of Herbert et al. (2025), even when using an extended database. In particular:
- Monetary policy surprises (Bauer and Swanson-like) have a statistically significant effect on asset prices and yields, yet their overall explanatory power is limited, in line with the aforementioned puzzle;
- Announcements conveying  HOM signals have a highly
significant positive impact on daily changes in bond yields (2Y, 5Y, 10Y). This holds **even when distinguishing across event types**, suggesting that HOM-related effects are broadly shared across communication formats;
- Using the decomposition of zero-coupon yields between a real rate component and an inflation compensation component, we find that HOM events primarily affect 2Y, 5Y and 10Y yields **through the real interest rate**;
- Using the decomposition of ZC yields between an expectations component and a term premium, we find that HOM events primarily affect 2Y, 5Y and 10Y ZC **through the term premium**;
- HOM events have a strong effect on uncertainty measures, consistent with the interpretation of HOM as conveying information about uncertainty surrounding the future monetary policy stance.

These results are robust to a wide range of controls and hold across subsamples.


## Project Structure

```
main.mlx                          # Main analysis script (MATLAB Live Script)
data/                             # Raw data files
├── USMPD.xlsx                    # US Monetary Policy Database
├── Dataset_EA-MPD.xlsx           # Euro Area Monetary Policy Database
├── FOMC_surprises_Bauer_Swanson.xlsx # Initial series constructed by Bauer and Swanson around FOMC statements
├── ABJ_2024_Path_Target.xlsx    # Target and Path factors around FOMC statements 
├── FED_rates.xlsx               # Federal Reserve interest rates
├── GSW_feds200628.xlsx          # Gürkaynak-Sack-Wright yield curve data
├── ACMTermPremium.xls           # ZC decomposition 
├── risk_indicators.xlsx         # Uncertainty and risk measures
├── sp500_daily.xlsx             # S&P 500 daily prices
└── Base Macro News.xlsx         # Macroeconomic news to orthogonalize MPS
utils/                           # Utility functions
├── GSS_replication.m            # Target and Path extraction following Gürkaynak et al. (2005) 
├── orthogonalize_mps_BS2023.m   # Bauer & Swanson (2023) orthogonalization
├── pca_analysis.m               # PCA with visualization
├── classifier_mp_events.m       # Classify MP events (HOM/Attenuation) using Target and Path
└── scaling.m                    # Factor scaling
regressions/                     # Regression analysis functions
├── robust_ols.m                 # Heteroskedasticity-robust OLS
├── display_regression_results.m # Formatted regression output
├── compute_ci.m                 # Confidence interval computation
└── me_results.m                 # Marginal effects 
graphs/                          # Output visualizations
├── plot_functions/              # Plotting utilities
│   ├── plot_ci.m                # Confidence interval plots
│   ├── plot_figure2.m          
│   └── plot_figure3.m
└── [Various .pdf and .png outputs]
└── Report_Macroeconometrics_Project.pdf  # Final report
```

## Key Features

### 1. **Target and Path Factor Extraction** (`GSS_replication.m`)
Implements the Gürkaynak, Sack, and Swanson (2005) methodology to decompose monetary policy surprises into:
- **Target factor**: Current policy rate expectations
- **Path factor**: Future policy path expectations

**Method:**
- Principal Component Analysis on Fed funds futures (MP1, MP2) and Eurodollar futures (ED2, ED3, ED4)
- Specific rotation to ensure Path factor doesn't affect current policy and to give both factors economic meaning (cf GSS 2005 Appendix)
- Scaling so Target moves MP1 one-for-one and both factors have equal magnitude effects on ED4

### 2. **Orthogonalization** (`orthogonalize_mps_BS2023.m`)
Follows Bauer & Swanson (2023) to purge monetary policy surprises of predictable components using:
- **Employment growth** (NFP, year-over-year)
- **S&P 500 returns** (3-month log changes)
- **Yield curve slope** (3-month changes)
- **Commodity prices** (BCOM index, 3-month log changes)
- **Treasury skewness** (1-month average)

**Output:** Orthogonalized MPS that isolates truly exogenous monetary policy shocks

### 3. **Event Classification** (`classifier_mp_events.m`)
Categorizes FOMC announcements into:
- **Opposite signs**: Target and Path have different signs
- **Attenuation**: |Target| > |Path| with opposite signs
- **HOM (Hike-Or-More)**: |Path| ≥ |Target| with opposite signs

### 4. **Robust Regression Analysis** (`robust_ols.m`)
- Heteroskedasticity-robust standard errors
- Supports multiple dependent variables

### 5. **PCA Analysis** (`pca_analysis.m`)
Flexible PCA implementation with:
- Automatic variance explained visualization
- Component loadings plots
- Customizable number of components
- Optional centering

## Data Sources

### Primary Datasets
1. **US-MPD** (US Monetary Policy Database): High-frequency surprises in Fed funds and Eurodollar futures around FOMC announcements
2. **EA-MPD** (Euro Area Monetary Policy Database): Similar data for ECB announcements
3. **Bauer & Swanson (2023)**: Pre-computed orthogonalized surprises
4. **GSW Yield Curves**: Daily zero-coupon yield curve estimates from Gürkaynak, Sack, and Wright

### Macroeconomic Controls
- **Employment**: Non-farm payrolls 
- **Equity markets**: S&P 500 daily closing prices
- **Commodities**: Bloomberg Commodity Index (BCOM)
- **Risk indicators**: Treasury skewness, term premiums

## Usage

### Running the Main Analysis
Open and run `main.mlx` in MATLAB. This live script contains:
1. Data loading and preprocessing
2. Factor extraction
3. Orthogonalization
4. Regression analysis
5. Visualization of results

### Using Individual Functions

#### Extract Target and Path Factors
```matlab
% Load data with MP1, MP2, ED2, ED3, ED4
X_raw = [MP1, MP2, ED2, ED3, ED4];
[Target, Path, loadings] = GSS_replication(X_raw);
```

#### Orthogonalize MPS
```matlab
% Prepare macro data structure
macro_data.nfp = nfp_table;          % Columns: Date, PAYEMS
macro_data.sp500 = sp500_table;      % Columns: Date, GSPC_Close
macro_data.yc_slope = slope_table;   % Columns: Date, BETA1
macro_data.bcom = bcom_table;        % Columns: Date, BCOMIndex
macro_data.skew = skew_table;        % Columns: Date, isk

% Orthogonalize
mps_orth = orthogonalize_mps_BS2023(mps_data, macro_data, ...
    'MPSVarName', 'MPS', 'Orthogonalize', true);
```

#### Run PCA
```matlab
[loadings, scores, latent, explained, mu] = pca_analysis(data, ...
    'Labels', var_names, ...
    'Title', 'Yield Curve PCA', ...
    'NumPCs', 3);
```

#### Robust OLS Regression
```matlab
% Y: T×N matrix of dependent variables
% X: T×K matrix of regressors
[beta, se, r2, n_obs] = robust_ols(Y, X, true);  % true = include intercept
```

## Outputs

The analysis produces several key outputs (see `graphs/` folder):

1. **Factor Analysis**
   - `factors.pdf`: Time series of Target and Path factors
   - `loadings_target_path_by_event.png`: Factor loadings visualization
   - Correlation between Target and Path ≈ 0 (confirms orthogonality)

2. **Comparison with Alternative Measures**
   - `BS_MPS_vs_reconstructed.pdf`: Bauer-Swanson MPS vs. reconstructed
   - `Target_Path_ABJ_vs_reconstructed.pdf`: Comparison with ABJ (2024)

3. **Impulse Responses**
   - `LP-IV 1.png`: Local projection impulse responses
   - `LP-IV HOM.png`: Responses conditional on HOM events
   - `changes_in_ZC_yields.pdf`: Yield curve responses

4. **Asset Price Responses**
   - `SP500.pdf`: S&P 500 response to monetary policy shocks
   - `Figure1.png`, `Figure2.png`, `Figure3.png`: Main regression results

## Requirements

- **MATLAB** R2020a or later
- **Toolboxes:**
  - Statistics and Machine Learning Toolbox (for `pca`, `fitlm`, `hac`)
  - Econometrics Toolbox (for time series analysis)

## Notes

- The main analysis script (`main.mlx`) is a MATLAB Live Script that cannot be directly viewed as text. Open it in MATLAB for the complete analysis workflow.
- All regression results use heteroskedasticity-robust standard errors (HC0).
- The project preserves duplicate FOMC dates when multiple announcements occur on the same day.

## Authors

Giovanni Manche & Timothée Dangleterre  
Master in Quantitative Methods for Economic Decision | ENSAE Paris 
Macroeconometrics: Advanced Time-Series Analysis course
January 2026

## License

This project is for academic purposes only.
