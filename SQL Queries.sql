Drop table if exists msmefinancials;
CREATE table msmefinancials(
	Company_name varchar(100),
	Sector varchar(10) not null,
	Fiscal_year integer not null,
	Revenue NUMERIC,
	EBITDA NUMERIC,
	EBIT NUMERIC,
	PAT NUMERIC,
	Interest_expense NUMERIC,
	Total_assets NUMERIC,
	Total_equity NUMERIC,
	Total_debt NUMERIC,
	Current_assets NUMERIC,
	Current_liability NUMERIC,
	CFO NUMERIC,
	Debt_repayment NUMERIC,
	Market_cap NUMERIC,
	Retained_Earnings NUMERIC,
	Working_Capital NUMERIC
);
select * from msmefinancials;

-- Query 1: Credit ratios for all 6 companies FY2022 to FY2024
-- Shows how each company's financial health evolved over 3 years
SELECT
    company_name,
    fiscal_year,
    ROUND(CFO / (interest_expense + debt_repayment), 2)
        AS dscr,
    ROUND(total_debt / total_equity, 2)
        AS debt_to_equity,
    ROUND(ebit / interest_expense, 2)
        AS interest_coverage,
    ROUND(pat / revenue * 100, 1)
        AS pat_margin_pct,
    ROUND(ebitda / revenue * 100, 1)
        AS ebitda_margin_pct,
    ROUND(current_assets / current_liability, 2)
        AS current_ratio
FROM msmefinancials
ORDER BY company_name, fiscal_year;

select * from msmefinancials;

-- Query 2: Risk flags for all companies across all 3 years
-- Shows if risk is improving, stable, or worsening over time
SELECT
    company_name,
    fiscal_year,
    ROUND(cfo / (interest_expense + debt_repayment), 2)
        AS dscr,
    ROUND(total_debt / total_equity, 2)
        AS de_ratio,
    CASE
        WHEN cfo / (interest_expense + debt_repayment) < 1.0
            THEN 'HIGH RISK — DSCR Critical'
        WHEN cfo / (interest_expense + debt_repayment) < 1.25
            THEN 'CAUTION — DSCR Below Threshold'
        WHEN total_debt / total_equity > 2.0
            THEN 'WATCH — High Leverage'
        ELSE 'ACCEPTABLE — Within Limits'
    END AS risk_flag
FROM msmefinancials
ORDER BY company_name, fiscal_year;

select * from msmefinancials;

-- Query 3: Year-on-year revenue growth for all 6 companies
-- LAG() compares each year to prior year within same company
-- FY2022 will show NULL growth as no FY2021 data available
SELECT
    company_name,
    fiscal_year,
    revenue,
    LAG(revenue) OVER
        (PARTITION BY company_name
         ORDER BY fiscal_year)
        AS prior_year_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER
            (PARTITION BY company_name
             ORDER BY fiscal_year))
        / LAG(revenue) OVER
            (PARTITION BY company_name
             ORDER BY fiscal_year) * 100
    , 1) AS revenue_growth_pct
FROM msmefinancials
ORDER BY company_name, fiscal_year;

select * from msmefinancials;

-- Query 4: Rank companies by their 3-year average DSCR
-- Average is more meaningful than single year snapshot
-- Shows which company has been most consistently creditworthy
SELECT
    company_name,
    ROUND(AVG(cfo / (interest_expense + debt_repayment)), 2)
        AS avg_dscr_3yr,
    ROUND(MIN(cfo / (interest_expense + debt_repayment)), 2)
        AS worst_dscr,
    ROUND(MAX(cfo / (interest_expense + debt_repayment)), 2)
        AS best_dscr,
    ROUND(AVG(total_debt / total_equity), 2)
        AS avg_de_ratio_3yr,
    ROUND(AVG(ebitda / revenue * 100), 1)
        AS avg_ebitda_margin_pct,
    RANK() OVER
        (ORDER BY AVG(cfo /
            (interest_expense + debt_repayment)) DESC)
        AS creditworthiness_rank
FROM msmefinancials
GROUP BY company_name
ORDER BY avg_dscr_3yr DESC;

select * from msmefinancials;

-- Query 5: Altman Z-Score computed in SQL for all 6 companies
-- across all 3 years — shows Z-Score trajectory
-- Cross-validates the Z-Score trend from your Excel model
SELECT
    company_name,
    fiscal_year,
    ROUND(
        1.2 * (working_capital / total_assets) +
        1.4 * (retained_earnings / total_assets) +
        3.3 * (ebit / total_assets) +
        0.6 * (market_cap / (total_debt + current_liability)) +
        1.0 * (revenue / total_assets)
    , 2) AS altman_z_score,
    CASE
        WHEN (1.2*(working_capital/total_assets) +
              1.4*(retained_earnings/total_assets) +
              3.3*(ebit/total_assets) +
              0.6*(market_cap/(total_debt+current_liability)) +
              1.0*(revenue/total_assets)) > 2.99
            THEN 'Safe Zone'
        WHEN (1.2*(working_capital/total_assets) +
              1.4*(retained_earnings/total_assets) +
              3.3*(ebit/total_assets) +
              0.6*(market_cap/(total_debt+current_liability)) +
              1.0*(revenue/total_assets)) >= 1.81
            THEN 'Grey Zone'
        ELSE 'Distress Zone'
    END AS z_score_zone
FROM msmefinancials
ORDER BY company_name, fiscal_year;

select * from msmefinancials;

-- Bonus Query: DSCR trend direction for all companies
-- Is each company getting safer or riskier over time?
SELECT
    company_name,
    fiscal_year,
    ROUND(cfo / (interest_expense + debt_repayment), 2)
        AS dscr,
    ROUND(
        cfo / (interest_expense + debt_repayment) -
        LAG(cfo / (interest_expense + debt_repayment)) OVER
            (PARTITION BY company_name
             ORDER BY fiscal_year), 2)
        AS dscr_change_vs_prior_year,
    CASE
        WHEN cfo / (interest_expense + debt_repayment) >
             LAG(cfo / (interest_expense + debt_repayment)) OVER
                 (PARTITION BY company_name ORDER BY fiscal_year)
            THEN 'Improving'
        WHEN cfo / (interest_expense + debt_repayment) <
             LAG(cfo / (interest_expense + debt_repayment)) OVER
                 (PARTITION BY company_name ORDER BY fiscal_year)
            THEN 'Declining'
        ELSE 'Stable'
    END AS dscr_trend
FROM msmefinancials
ORDER BY company_name, fiscal_year;
