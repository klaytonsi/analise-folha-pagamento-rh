-- =====================================================================
-- Análise de Folha de Pagamento de RH | HR Payroll Analysis
-- Consultas SQL (DuckDB) extraídas do notebook analise_folha_pagamento.ipynb
--
-- Pré-requisito: as tabelas departments, jobs e employees são geradas
-- (dados sintéticos, SEED = 42) no notebook e registradas no DuckDB.
-- Prerequisite: departments, jobs and employees are generated in the
-- notebook (synthetic data) and registered in DuckDB.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. View payroll: uma linha por funcionário por mês ativo (2023-2025)
--    One row per employee per active month
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW payroll AS
SELECT CAST(r.month_ts AS DATE) AS month_start,
       e.employee_id, e.department_id, e.salary
FROM range(DATE '2023-01-01', DATE '2026-01-01', INTERVAL 1 MONTH) AS r(month_ts)
JOIN employees e
  ON e.hire_date <= last_day(CAST(r.month_ts AS DATE))
 AND (e.termination_date IS NULL OR e.termination_date >= CAST(r.month_ts AS DATE));


-- ---------------------------------------------------------------------
-- 1. Custo mensal de folha por departamento (CTE + LAG + acumulado no ano)
--    Monthly payroll cost per department
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT p.month_start, d.department,
           COUNT(*) AS headcount,
           ROUND(SUM(p.salary), 2) AS payroll_cost
    FROM payroll p
    JOIN departments d ON d.department_id = p.department_id
    GROUP BY 1, 2
)
SELECT month_start, department, headcount, payroll_cost,
       ROUND(payroll_cost - LAG(payroll_cost) OVER (PARTITION BY department ORDER BY month_start), 2) AS mom_change,
       ROUND(SUM(payroll_cost) OVER (PARTITION BY department, YEAR(month_start) ORDER BY month_start), 2) AS ytd_cost
FROM monthly
ORDER BY department, month_start;


-- ---------------------------------------------------------------------
-- 2. Top 3 salários por departamento (DENSE_RANK, somente ativos)
--    Top 3 salaries per department (active employees only)
-- ---------------------------------------------------------------------
WITH active AS (
    SELECT e.employee_id, d.department, j.job_title, e.salary
    FROM employees e
    JOIN departments d ON d.department_id = e.department_id
    JOIN jobs j ON j.job_id = e.job_id
    WHERE e.termination_date IS NULL
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
    FROM active
)
SELECT * FROM ranked WHERE salary_rank <= 3 ORDER BY department, salary_rank;


-- ---------------------------------------------------------------------
-- 3. Turnover mensal (%) + média móvel de 3 meses
--    Monthly turnover (%) + 3-month moving average
-- ---------------------------------------------------------------------
WITH hc AS (
    SELECT month_start, COUNT(*) AS headcount FROM payroll GROUP BY 1
),
terms AS (
    SELECT CAST(DATE_TRUNC('month', termination_date) AS DATE) AS month_start, COUNT(*) AS terminations
    FROM employees WHERE termination_date IS NOT NULL GROUP BY 1
),
base AS (
    SELECT hc.month_start, hc.headcount,
           COALESCE(t.terminations, 0) AS terminations,
           ROUND(100.0 * COALESCE(t.terminations, 0) / hc.headcount, 2) AS turnover_pct
    FROM hc LEFT JOIN terms t USING (month_start)
)
SELECT *, ROUND(AVG(turnover_pct) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS turnover_ma3
FROM base ORDER BY month_start;


-- ---------------------------------------------------------------------
-- 4. Funcionários ativos 15%+ acima da média do cargo
--    Active employees 15%+ above their job average
--    (sem o LIMIT 15 do notebook, para contar todos os outliers / no LIMIT, to count all)
-- ---------------------------------------------------------------------
WITH active AS (
    SELECT e.employee_id, j.job_title, e.salary
    FROM employees e JOIN jobs j ON j.job_id = e.job_id
    WHERE e.termination_date IS NULL
),
stats AS (
    SELECT *, AVG(salary) OVER (PARTITION BY job_title) AS job_avg FROM active
)
SELECT employee_id, job_title, salary,
       ROUND(job_avg, 2) AS job_avg,
       ROUND(100.0 * (salary / job_avg - 1), 1) AS pct_above_avg
FROM stats
WHERE salary > job_avg * 1.15
ORDER BY pct_above_avg DESC;


-- ---------------------------------------------------------------------
-- 5. Tabela de resumo para o Looker Studio (mês × departamento)
--    Summary table for Looker Studio
-- ---------------------------------------------------------------------
WITH base AS (
    SELECT month_start, department_id, COUNT(*) AS headcount, SUM(salary) AS payroll_cost
    FROM payroll GROUP BY 1, 2
),
t AS (
    SELECT CAST(DATE_TRUNC('month', termination_date) AS DATE) AS month_start, department_id, COUNT(*) AS terminations
    FROM employees WHERE termination_date IS NOT NULL GROUP BY 1, 2
),
h AS (
    SELECT CAST(DATE_TRUNC('month', hire_date) AS DATE) AS month_start, department_id, COUNT(*) AS hires
    FROM employees GROUP BY 1, 2
)
SELECT b.month_start, d.department, b.headcount,
       ROUND(b.payroll_cost, 2) AS payroll_cost,
       COALESCE(h.hires, 0) AS hires,
       COALESCE(t.terminations, 0) AS terminations
FROM base b
JOIN departments d ON d.department_id = b.department_id
LEFT JOIN t ON t.month_start = b.month_start AND t.department_id = b.department_id
LEFT JOIN h ON h.month_start = b.month_start AND h.department_id = b.department_id
ORDER BY b.month_start, d.department;
