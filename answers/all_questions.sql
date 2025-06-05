/* ==============================================================
   Q01 – TOP 5 cursos com mais inscrições **ativas**
   Retorne: id_curso · nome · total_inscritos
=================================================================*/
-- SUA QUERY AQUI
SELECT
	z.id_curso
	,z.nome
	,z.total_inscritos
FROM(
	SELECT
		c.id_curso
		,c.nome
		,COUNT(i.id_inscricao) AS total_inscritos
		,RANK() OVER(ORDER BY COUNT(i.id_inscricao) DESC) AS RANKING
	FROM inscricoes i
		LEFT JOIN cursos c ON c.id_curso = i.id_curso
	WHERE
		i.status = 'ativo'
	GROUP BY
		c.id_curso
		,c.nome
	ORDER BY
		3 DESC
) z
WHERE
	z.ranking <= 5 
	
/* ==============================================================
   Q02 – Taxa de conclusão por curso
   Para cada curso, calcule:
     • total_inscritos
     • total_concluidos   (status = 'concluída')
     • taxa_conclusao (%) = concluídos / inscritos * 100
   Ordene descendentemente pela taxa de conclusão.
=================================================================*/
-- SUA QUERY AQUI
SELECT
	c.nome
	,COUNT(i.id_inscricao) AS total_inscritos
	,SUM(
		CASE
			WHEN i.status = 'concluido' THEN 1
			ELSE 0
		END
	) AS total_concluidos
	,ROUND(
			SUM(
				CASE
					WHEN i.status = 'concluido' THEN 1
					ELSE 0
				END
				) * 100 / COUNT(i.id_inscricao)
		, 1) AS taxa_conclusao
FROM inscricoes i
	LEFT JOIN cursos c ON c.id_curso = i.id_curso
GROUP BY
	c.nome
ORDER BY
	4 DESC

/* ==============================================================
   Q03 – Tempo médio (dias) para concluir cada **nível** de curso
   Definições:
     • Início = data_insc   (tabela inscricoes)
     • Fim    = maior data em progresso onde porcentagem = 100
   Calcule a média de dias entre início e fim,
   agrupando por cursos.nivel (ex.: Básico, Avançado).
=================================================================*/
-- SUA QUERY AQUI

-- CTE pra trazer a maior data em progresso da tabela "progresso" onde porcentagem = 100
WITH maior_progresso_cte AS (
	SELECT
		p.id_aluno
		,MAX(p.data_ultima_atividade) AS data_ultima_atividade  -- maior data em progresso
	FROM
		progresso p
	WHERE
	p.percentual = 100
	GROUP BY
		p.id_aluno
)
-- Pela base, até o momento, nenhum aluno dentro da tabela "progresso" chegou ao valor '100' na coluna de porcentagem (percentual).
SELECT
	c.nivel
	,AVG(p.data_ultima_atividade - i.data_inscricao) AS Tempo     
FROM inscricoes i
	LEFT JOIN cursos c ON c.id_curso = i.id_curso
	LEFT JOIN maior_progresso_cte p ON p.id_aluno = i.id_aluno
GROUP BY
	c.nivel;


/* ==============================================================
   Q04 – TOP 10 módulos com maior **taxa de abandono**
   - Considere abandono quando porcentagem < 20 %
   - Inclua apenas módulos com pelo menos 20 alunos
   Retorne: id_modulo · titulo · abandono_pct
   Ordene do maior para o menor.
=================================================================*/
-- SUA QUERY AQUI

-- entende-se que essa porcentagem vem da tabela de progresso, na coluna "percentual"
SELECT
	m.id_modulo
	,m.titulo
	,MIN(p.percentual) AS abandono_pct		-- O uso do MIN() se justifica pois, busca-se a taxas menores de 20%.
FROM progresso p		-- a tabela de progresso não trás uma coluna de ID que identifique o curso, ou seja, o mesmo ID_MODULO pode ser de cursos diferentes
	JOIN modulos m ON m.id_modulo = p.id_modulo
WHERE
	p.percentual < 20
GROUP BY
	m.id_modulo
	,m.titulo
HAVING
	COUNT(p.id_aluno) >= 20
ORDER BY
	3 DESC;


/* ==============================================================
   Q05 – Crescimento de inscrições (janela móvel de 3 meses)
   1. Para cada mês calendário (YYYY-MM), conte inscrições.
   2. Calcule a soma móvel de 3 meses (mês atual + 2 anteriores) → rolling_3m.
   3. Calcule a variação % em relação à janela anterior.
   Retorne: ano_mes · inscricoes_mes · rolling_3m · variacao_pct
=================================================================*/
-- SUA QUERY AQUI

-- entende-se aqui que a coluna "inscricoes_mes" é a coluna de qtd de inscrições contadas por "ano-mês".

WITH rolling_data AS (		-- essa CTE serve para calcular a soma dos ultimos 03 meses a nível de linha e acumula naquele ano-mês.
    SELECT 
        dk.ano_mes,
        dk.inscricoes_mes,
        SUM(dk.inscricoes_mes) OVER (
            ORDER BY dk.ano_mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3m
    FROM dashboard_kpis dk
)
, variacao_calculo AS (		/* já aqui eu to pegando o valor do "rolling_3m", trazendo o valor anterior a ela no ano-mês seguinte e
							e calculando a variação em (%), usando o valor atual lá versus o anterior no mesmo contexto de linha */
	SELECT
		ano_mes,
		inscricoes_mes,
		rolling_3m,
		LAG(rolling_3m) OVER (ORDER BY ano_mes) AS rolling_3m_anterior,
		CASE
			WHEN LAG(rolling_3m) OVER (ORDER BY ano_mes) IS NULL THEN NULL
			ELSE ROUND((rolling_3m - LAG(rolling_3m) OVER (ORDER BY ano_mes)) * 100.0 
						/ LAG(rolling_3m) OVER (ORDER BY ano_mes), 2)
		END AS variacao_pct
	FROM rolling_data
)

SELECT 
    ano_mes,
    inscricoes_mes,
    rolling_3m,
    variacao_pct
FROM variacao_calculo;

/* Só perceber uma coisa obvia, mas que deve ser explicada quando for analisar os números:
No primeiro mês vai vir sempre "null" pois não existe ano-mês anterior ao primeiro */