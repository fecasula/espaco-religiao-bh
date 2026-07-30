# Escopo espacial e roteiro de generalização

## Situação da versão 0.1.5

A análise espacial está homologada somente para **Belo Horizonte (MG), código IBGE 3106200**, com dados definitivos do Censo 2022. Esse escopo inclui:

- preparação da malha com atributos definitiva do IBGE;
- seleção e validação da população por setor;
- consolidação segura de setores multipartidos;
- seleção dos estabelecimentos religiosos;
- transformação para SIRGAS 2000 / UTM zona 23S;
- criação de buffers euclidianos;
- estimação da população coberta;
- cálculo do Índice de Cobertura Religiosa;
- mapas e painel Shiny.

A configuração municipal foi externalizada para facilitar a evolução do software, mas códigos diferentes de `3106200` são bloqueados. O bloqueio impede que dados de outra cidade sejam combinados com pontos religiosos, CRS métrico e parâmetros de mobilidade específicos de Belo Horizonte.

## Fonte censitária homologada

O pipeline acadêmico padrão utiliza o GeoPackage `MG_setores_CD2022.gpkg`, disponibilizado pelo IBGE na coleção definitiva de Agregados por Setores Censitários. Geometria e população são lidas do mesmo produto.

A combinação anterior entre a malha do `{geobr}` e os agregados preliminares do `{censobr}` permanece apenas como registro histórico. Ela não é utilizada por padrão porque as versões testadas apresentaram 330 geometrias sem população, 305 registros populacionais sem geometria e perda de 126.355 habitantes no cruzamento por código de setor.

A base definitiva de Belo Horizonte contém 5.167 feições e 5.166 códigos distintos. O setor `310620005670833` possui duas partes geométricas com a mesma população (171); o pipeline dissolve as duas feições e mantém a população uma vez, resultando em 5.166 setores e 2.315.560 habitantes.

## Versão multimunicipal em desenvolvimento

A próxima etapa deverá implementar:

1. obtenção e validação dos estabelecimentos religiosos do município selecionado;
2. classificação confessional com auditoria e relatório de incerteza;
3. seleção da UF, camada e população compatíveis;
4. escolha automática e validação de um CRS métrico apropriado;
5. parâmetros locais de velocidade e tempo de acesso;
6. testes de cobertura, população, geometrias e fronteiras municipais;
7. metadados e registros de proveniência por cidade;
8. interface de seleção municipal no Quarto/Shiny.

A liberação de outro município dependerá da aprovação desses controles, não apenas da possibilidade técnica de baixar sua malha censitária.

---

# Alcance espacial y hoja de ruta

La versión 0.1.5 está validada solamente para **Belo Horizonte (MG)** y utiliza la malla con atributos definitiva del Censo 2022. La versión multimunicipal está en desarrollo y requerirá establecimientos religiosos locales, población compatible, proyección métrica adecuada, parámetros de movilidad con evidencia local y pruebas específicas para cada ciudad.
