# analise-folha-pagamento-rh

**EN:** HR payroll analysis with advanced SQL (CTEs, window functions) on 100% synthetic data, using DuckDB, Pandas and Plotly.
**PT:** Análise de folha de pagamento de RH com SQL avançado (CTEs, window functions) em dados 100% sintéticos, com DuckDB, Pandas e Plotly.

## Questions answered / Perguntas respondidas
1. Monthly payroll cost per department (LAG, running total) / Custo mensal de folha por departamento (LAG, acumulado)
2. Top 3 salaries per department (DENSE_RANK) / Top 3 salários por departamento (DENSE_RANK)
3. Monthly turnover + 3-month moving average / Turnover mensal + média móvel de 3 meses
4. Employees 15%+ above their job average / Funcionários 15%+ acima da média do cargo

## How to run / Como executar
1. Open `analise_folha_pagamento_rh.ipynb` in Google Colab (free) / Abra no Google Colab (grátis)
2. Runtime > Run all / Ambiente de execução > Executar tudo
3. Download `output/resumo_dashboard.csv` and upload it to Looker Studio (free) / Baixe o CSV e envie ao Looker Studio (grátis)

## Stack
Python, SQL, DuckDB, Pandas, Plotly, Google Colab, Looker Studio

## Reproducibility / Reprodutibilidade
Fixed seed (`SEED = 42`): same data and results on every run / Seed fixa: mesmos dados e resultados a cada execução.

## Security / Segurança
- Synthetic data only: no names, CPF, e-mails or real salaries / Somente dados sintéticos
- No API keys, tokens or external connections / Sem chaves, tokens ou conexões externas
- In-memory database, nothing sensitive stored / Banco em memória

## Business conclusions / Conclusões de negócio
_Fill in after running / Preencha após executar._

## License / Licença
MIT
