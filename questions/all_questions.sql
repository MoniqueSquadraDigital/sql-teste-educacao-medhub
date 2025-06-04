/* ==============================================================
   Q01 – TOP 5 cursos com mais inscrições **ativas**
   Retorne: id_curso · nome · total_inscritos
=================================================================*/
-- SUA QUERY AQUI

SELECT TOP 5
    c.id_curso,
    c.nome,
    COUNT(i.id_aluno) AS total_inscritos
FROM dbo.cursos c
INNER JOIN dbo.id_inscricao i ON c.id_curso = i.id_curso
WHERE i.status = 'ativo'  -- Assumindo que 'ativo' é o valor para inscrições ativas
GROUP BY c.id_curso, c.nome
ORDER BY COUNT(i.id_aluno) DESC;

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
    c.id_curso,
    c.nome,
    COUNT(i.id_aluno) AS total_inscritos,
    COUNT(CASE WHEN i.status = 'concluido' THEN 1 END) AS total_concluidos,
    CAST(ROUND((COUNT(CASE WHEN i.status = 'concluido' THEN 1 END) * 100.0) / COUNT(i.id_aluno), 2) AS DECIMAL(5,2)) AS taxa_conclusao_pct
FROM dbo.cursos c
INNER JOIN dbo.inscricoes i ON c.id_curso = i.id_curso  -- Ajuste o nome conforme necessário
GROUP BY c.id_curso, c.nome
ORDER BY taxa_conclusao_pct DESC;

/* ==============================================================
   Q03 – Tempo médio (dias) para concluir cada **nível** de curso
   Definições:
     • Início = data_insc   (tabela inscricoes)
     • Fim    = maior data em progresso onde porcentagem = 100
   Calcule a média de dias entre início e fim,
   agrupando por cursos.nivel (ex.: Básico, Avançado).
=================================================================*/
-- SUA QUERY AQUI



/* ==============================================================
   Q04 – TOP 10 módulos com maior **taxa de abandono**
   - Considere abandono quando porcentagem < 20 %
   - Inclua apenas módulos com pelo menos 20 alunos
   Retorne: id_modulo · titulo · abandono_pct
   Ordene do maior para o menor.
=================================================================*/
-- SUA QUERY AQUI



/* ==============================================================
   Q05 – Crescimento de inscrições (janela móvel de 3 meses)
   1. Para cada mês calendário (YYYY-MM), conte inscrições.
   2. Calcule a soma móvel de 3 meses (mês atual + 2 anteriores) → rolling_3m.
   3. Calcule a variação % em relação à janela anterior.
   Retorne: ano_mes · inscricoes_mes · rolling_3m · variacao_pct
=================================================================*/
-- SUA QUERY AQUI

WITH inscricoes_mensais AS (
    SELECT
        FORMAT(data_inscricao, 'yyyy-MM') AS ano_mes,
        COUNT(*) AS inscricoes_mes
    FROM dbo.inscricoes
    GROUP BY FORMAT(data_inscricao, 'yyyy-MM')
),
inscricoes_com_rolling AS (
    SELECT
        ano_mes,
        inscricoes_mes,
        SUM(inscricoes_mes) OVER (
            ORDER BY ano_mes
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3m
    FROM inscricoes_mensais
),
com_variacao AS (
    SELECT
        ano_mes,
        inscricoes_mes,
        rolling_3m,
        LAG(rolling_3m) OVER (ORDER BY ano_mes) AS rolling_3m_anterior
    FROM inscricoes_com_rolling
)
SELECT
    ano_mes,
    inscricoes_mes,
    rolling_3m,
    CASE 
        WHEN rolling_3m_anterior IS NULL THEN NULL
        WHEN rolling_3m_anterior = 0 THEN NULL
        ELSE CAST(ROUND(((rolling_3m - rolling_3m_anterior) * 100.0) / rolling_3m_anterior, 2) AS DECIMAL(10,2))
    END AS variacao_pct
FROM com_variacao
ORDER BY ano_mes;


