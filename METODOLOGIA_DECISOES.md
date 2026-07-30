# Registro de decisões metodológicas

| Data | Decisão | Justificativa | Consequência |
|---|---|---|---|
| 2026-07-29 | Adotar 646,67 m como perfil padrão | Resultado de 4 km/h × 9,7 min | O valor de 853,33 m permanece apenas como perfil histórico. |
| 2026-07-29 | Preservar tabela publicada e classificação atual | As distribuições por confissão divergem, mas o universo total coincide | Resultados recebem rótulo de versão. |
| 2026-07-29 | Publicar apenas OD desidentificada | Proteção dos participantes | Identificadores e bairros foram removidos. |
| 2026-07-29 | Wilson como IC padrão; Wald para reprodução | Melhor comportamento em pequenas frequências e compatibilidade histórica | Os dois intervalos são armazenados. |
| 2026-07-29 | ICR baseado na população total por setor | Compatibilidade com o cálculo publicado | A interpretação como acessibilidade de idosos é explicitamente qualificada. |

## Escopo espacial e parametrização municipal — versão 0.1.4

A versão atual permanece homologada exclusivamente para Belo Horizonte (MG). Embora município, ano e resolução geométrica tenham sido externalizados para `config/censo.yml`, a execução para outros municípios é interrompida de forma controlada. Essa decisão evita que a malha censitária de outra cidade seja combinada com pontos religiosos, CRS métrico e parâmetros de mobilidade específicos de Belo Horizonte.

O perfil `desenvolvimento` utiliza geometria simplificada para reduzir tempo de download, memória e renderização. O perfil `publicacao` deve empregar a geometria original na produção dos resultados acadêmicos finais. O GeoPackage foi mantido como formato oficial por reunir todos os componentes espaciais em um único arquivo.

A generalização futura deverá selecionar um CRS métrico apropriado, obter e validar estabelecimentos locais, usar população compatível e exigir parâmetros de mobilidade sustentados por evidência do município estudado.

## Base censitária definitiva — versão 0.1.5

A fonte espacial padrão passa a ser a malha com atributos definitiva do IBGE para o Censo 2022. Essa decisão elimina a necessidade de combinar uma geometria e uma tabela populacional publicadas em versões diferentes.

A auditoria do fluxo anterior encontrou 330 geometrias sem população, 305 registros populacionais sem geometria e perda de 126.355 habitantes no cruzamento entre a malha do `{geobr}` e os agregados preliminares do `{censobr}`. Por esse motivo, a combinação preliminar não é aceita no pipeline acadêmico padrão.

O produto oficial do IBGE contém 5.167 feições para Belo Horizonte e 5.166 códigos de setor distintos. O código `310620005670833` aparece em duas feições, ambas com população 171. As geometrias são dissolvidas e a população é preservada uma única vez, resultando em 5.166 setores e 2.315.560 habitantes.

O pipeline interrompe a execução quando a quantidade de setores, a população total, a integridade geométrica ou a unicidade dos códigos divergem da referência homologada. O arquivo estadual, o produto municipal e os relatórios de auditoria permanecem fora do Git e são reconstruídos a partir da fonte oficial.
