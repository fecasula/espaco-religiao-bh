# Publicação do website e da apresentação com GitHub Desktop e GitHub Web

Este guia assume que o painel Shiny já está no ar em:

<https://fecasula.shinyapps.io/religiao-mobilidade-bh/>

A estratégia adotada para o restante do projeto é simples e robusta: o Quarto renderiza o site localmente para `docs/`, o GitHub Desktop envia esses arquivos ao GitHub e o GitHub Pages publica a pasta `docs/`.

## 1. Aplicar este patch

Extraia o ZIP na raiz do projeto:

```text
C:/Users/felipe.casula/Documents/GitHub/Apresentacao_ALAS/Apresentação ALAS
```

Aceite substituir os arquivos existentes.

## 2. Conferir o nome do repositório

Os arquivos foram preparados para este endereço:

```text
https://github.com/fecasula/religiao-mobilidade-bh
```

Se o repositório for criado com outro nome, por exemplo `Apresentacao_ALAS`, altere antes de renderizar:

```yaml
website:
  site-url: "https://fecasula.github.io/NOME-DO-REPOSITORIO/"
  repo-url: "https://github.com/fecasula/NOME-DO-REPOSITORIO"
```

O arquivo a editar é `_quarto.yml`.

## 3. Renderizar o site localmente

No RStudio, reinicie a sessão e execute:

```r
source("scripts/04_render_site.R")
```

A saída esperada deve confirmar a criação destes arquivos:

```text
docs/index.html
docs/indice-cobertura.html
docs/apresentacao-pt.html
docs/es/presentacion-es.html
```

Abra `docs/index.html` no navegador e confira:

- página inicial;
- link para o painel Shiny;
- apresentação em português;
- apresentação em espanhol;
- referências;
- páginas de resultados.

## 4. Abrir o projeto no GitHub Desktop

No GitHub Desktop:

1. Clique em **File → Add local repository**.
2. Selecione a pasta do projeto.
3. Confirme que a lista de mudanças inclui `_quarto.yml`, os arquivos `.qmd`, `scripts/04_render_site.R`, `.gitignore`, `.nojekyll` e a pasta `docs/`.

## 5. Criar o repositório pelo GitHub Desktop

Se ainda não houver remoto no GitHub:

1. Clique em **Publish repository**.
2. Use o nome `religiao-mobilidade-bh`.
3. Desmarque **Keep this code private** se quiser que o site seja público.
4. Clique em **Publish Repository**.

Se o repositório já existir no GitHub, use apenas **Push origin**.

## 6. Fazer o commit pelo GitHub Desktop

No campo **Summary**, use:

```text
Publica website e apresentação ALAS
```

No campo **Description**, use:

```text
Renderiza site Quarto em docs, integra painel Shiny publicado e prepara GitHub Pages.
```

Clique em **Commit to main** e depois em **Push origin**.

## 7. Ativar o GitHub Pages pela interface web

No navegador:

1. Abra o repositório no GitHub.
2. Entre em **Settings**.
3. Abra **Pages**.
4. Em **Build and deployment**, escolha **Deploy from a branch**.
5. Em **Branch**, selecione `main`.
6. Em **Folder**, selecione `/docs`.
7. Clique em **Save**.

O site deve ficar disponível em:

```text
https://fecasula.github.io/religiao-mobilidade-bh/
```

A apresentação em português ficará em:

```text
https://fecasula.github.io/religiao-mobilidade-bh/apresentacao-pt.html
```

A apresentação em espanhol ficará em:

```text
https://fecasula.github.io/religiao-mobilidade-bh/es/presentacion-es.html
```

## 8. Teste final no navegador

Abra a URL do GitHub Pages e confira:

- menu superior;
- botão do painel Shiny;
- apresentação em tela cheia;
- versão em espanhol;
- links para referências e reprodutibilidade.

## 9. Atualizações futuras

Sempre que alterar texto, apresentação ou imagens:

```r
source("scripts/04_render_site.R")
```

Depois use GitHub Desktop:

1. revise as mudanças;
2. faça commit;
3. clique em **Push origin**.

O GitHub Pages atualizará o site a partir da pasta `docs/`.

## 10. Contingência para o congresso

Leve uma cópia da pasta `docs/` em pendrive. Para apresentar offline, abra:

```text
docs/apresentacao-pt.html
```

Também recomenda-se abrir a apresentação no navegador e exportar como PDF usando o modo de impressão do Reveal.js.
