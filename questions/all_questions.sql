/* ==============================================================
   Q01 – TOP 5 cursos com mais inscrições **ativas**
   Retorne: id_curso · nome · total_inscritos
=================================================================*/
-- SUA QUERY AQUI



/* ==============================================================
   Q02 – Taxa de conclusão por curso
   Para cada curso, calcule:
     • total_inscritos
     • total_concluidos   (status = 'concluída')
     • taxa_conclusao (%) = concluídos / inscritos * 100
   Ordene descendentemente pela taxa de conclusão.
=================================================================*/
-- SUA QUERY AQUI



/* ==============================================================
   Q03 – Tempo médio (dias) para concluir cada **nível** de curso
   Definições:
     • Início = data_insc   (tabela inscricoes)
     • Fim    = maior data em progresso onde porcentagem = 100
   Calcule a média de dias entre início e fim,
   agrupando por cursos.nivel (ex.: Básico, Avançado).
=================================================================*/
-- SUA QUERY AQUI

WITH conclusoes AS (
    SELECT
        i.id_aluno,
        i.id_curso,
        i.[data_inscricao] AS data_inscricao,
        MAX(p.data_ultima_atividade) AS data_conclusao
    FROM dbo.inscricoes i
    JOIN dbo.progresso p ON i.id_aluno = p.id_aluno
    WHERE p.percentual = 100
    GROUP BY i.id_aluno, i.id_curso, i.[data_inscricao]
),
duracoes AS (
    SELECT
        c.nivel,
        DATEDIFF(DAY, cns.data_inscricao, cns.data_conclusao) AS dias_para_concluir
    FROM conclusoes cns
    JOIN dbo.cursos c ON cns.id_curso = c.id_curso
)
SELECT
    nivel,
    AVG(CAST(dias_para_concluir AS FLOAT)) AS media_dias_conclusao
FROM duracoes
GROUP BY nivel;

/* ==============================================================
   Q04 – TOP 10 módulos com maior **taxa de abandono**
   - Considere abandono quando porcentagem < 20 %
   - Inclua apenas módulos com pelo menos 20 alunos
   Retorne: id_modulo · titulo · abandono_pct
   Ordene do maior para o menor.
=================================================================*/
-- SUA QUERY AQUI

SELECT TOP 10
    id_modulo,
    CAST(SUM(CASE WHEN percentual < 20 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT id_aluno) AS DECIMAL(5,2)) AS abandono_pct
FROM dbo.progresso
GROUP BY id_modulo
HAVING COUNT(DISTINCT id_aluno) >= 20
ORDER BY abandono_pct DESC;


/* ==============================================================
   Q05 – Crescimento de inscrições (janela móvel de 3 meses)
   1. Para cada mês calendário (YYYY-MM), conte inscrições.
   2. Calcule a soma móvel de 3 meses (mês atual + 2 anteriores) → rolling_3m.
   3. Calcule a variação % em relação à janela anterior.
   Retorne: ano_mes · inscricoes_mes · rolling_3m · variacao_pct
=================================================================*/
-- SUA QUERY AQUI
