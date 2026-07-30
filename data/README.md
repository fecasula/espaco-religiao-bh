# Política de dados

- `public/`: dados mínimos, desidentificados e aptos ao versionamento.
- `raw/census/`: arquivos oficiais grandes utilizados na preparação espacial; não versionar GeoPackages, Parquets ou arquivos temporários.
- `derived/`: tabelas, métricas, relatórios de auditoria e geometrias geradas pelo pipeline.
- `private/`: bases individuais e arquivos originais confidenciais; nunca versionar.
- `validation/`: reconciliações, controles de qualidade e decisões metodológicas.

A fonte espacial padrão é a malha com atributos definitiva do Censo 2022 do IBGE. A publicação dos dados públicos derivados não transfere direitos sobre as fontes originais. Verifique as condições do IBGE e o protocolo ético da pesquisa.
