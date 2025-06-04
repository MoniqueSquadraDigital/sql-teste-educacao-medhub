/* Tabelas Criadas:
 - medhub_aluno referente a alunos.csv
 - medhub_curso referente a cursos.csv
 - medhub_inscricao referente a inscricoes.csv
 - medhub_modulo referente a modulos.csv
 - medhub_progresso referente a progresso.csv
*/


/* ==============================================================
   Q01 – TOP 5 cursos com mais inscrições **ativas**
   Retorne: id_curso · nome · total_inscritos
=================================================================*/
select
mc.id_curso as id_curso
,mc.nome as nome
,count(id_inscricao) as total_inscritos
from medhub_curso mc
left join medhub_inscricao mi on mc.id_curso = mi.id_curso and mi.status = 'ativo'
group by mc.id_curso ,nome
order by total_inscritos desc
limit 5;


/* ==============================================================
   Q02 – Taxa de conclusão por curso
   Para cada curso, calcule:
     • total_inscritos
     • total_concluidos   (status = 'concluída')
     • taxa_conclusao (%) = concluídos / inscritos * 100
   Ordene descendentemente pela taxa de conclusão.
=================================================================*/
select 
mc.nome as nome
,count(id_inscricao) as total_inscritos
,count(*) FILTER (WHERE mi.status = 'concluido') AS total_concluido
,round(
    100.0 * COUNT(*) FILTER (WHERE mi.status = 'concluido') / nullif(COUNT(mi.id_inscricao), 0),
    2
  ) AS "taxa_conclusao (%)"
from medhub_curso mc 
left join medhub_inscricao mi on mc.id_curso = mi.id_curso 
group by mc.nome 
order by "taxa_conclusao (%)" desc;


/* ==============================================================
   Q03 – Tempo médio (dias) para concluir cada **nível** de curso
   Definições:
     • Início = data_insc   (tabela inscricoes)
     • Fim    = maior data em progresso onde porcentagem = 100
   Calcule a média de dias entre início e fim,
   agrupando por cursos.nivel (ex.: Básico, Avançado).
=================================================================*/
with progresso_finalizado as (
select 
p.id_aluno,
m.id_curso,
max(p.data_ultima_atividade) as data_final
from medhub_progresso p
join medhub_modulo m on p.id_modulo = m.id_modulo
where p.percentual >= 100
group by p.id_aluno, m.id_curso ),
dias_conclusao as (
select 
c.nivel,
i.id_inscricao,
i.data_inscricao,
pf.data_final,
date_part('day', pf.data_final::timestamp - i.data_inscricao::timestamp) AS dias
from medhub_inscricao i
left join medhub_curso c on i.id_curso = c.id_curso
left join progresso_finalizado pf on pf.id_aluno = i.id_aluno AND pf.id_curso = i.id_curso
where pf.data_final is not null and i.data_inscricao is not null
)
select 
nivel,
ROUND(AVG(dias)::numeric, 2) AS media_dias_conclusao
from dias_conclusao
GROUP BY nivel
ORDER BY media_dias_conclusao DESC;
 
 
/* ==============================================================
   Q04 – TOP 10 módulos com maior **taxa de abandono**
   - Considere abandono quando porcentagem < 20 %
   - Inclua apenas módulos com pelo menos 20 alunos
   Retorne: id_modulo · titulo · abandono_pct
   Ordene do maior para o menor.
=================================================================*/
select
mm.id_modulo,
mm.titulo,
round(100.0 * count(*) FILTER (WHERE mp.percentual < 20) / nullif(count(*), 0),2) 
as abandono_pct
from medhub_progresso mp
left join medhub_modulo mm ON mp.id_modulo = mm.id_modulo
group by mm.id_modulo, mm.titulo
having count(*) >= 20
order by abandono_pct desc
limit 10;


/* ==============================================================
   Q05 – Crescimento de inscrições (janela móvel de 3 meses)
   1. Para cada mês calendário (YYYY-MM), conte inscrições.
   2. Calcule a soma móvel de 3 meses (mês atual + 2 anteriores) → rolling_3m.
   3. Calcule a variação % em relação à janela anterior.
   Retorne: ano_mes · inscricoes_mes · rolling_3m · variacao_pct
=================================================================*/
select
to_char(data_mes, 'YYYY-MM') AS ano_mes,
inscricoes_mes,
rolling_3m,
round(100.0 * (rolling_3m - LAG(rolling_3m) OVER (ORDER BY data_mes)) /
nullif(lag(rolling_3m) OVER (ORDER BY data_mes), 0),2) AS variacao_pct
from (
  select
  date_trunc('month', data_inscricao) AS data_mes,
  count(id_inscricao) AS inscricoes_mes,
  sum(count(*)) over (
  order by DATE_TRUNC('month', data_inscricao)
  rows between 2 preceding and current row) AS rolling_3m
  from medhub_inscricao mi
  group by
    date_trunc('month', data_inscricao)) sub
order by
  data_mes;
