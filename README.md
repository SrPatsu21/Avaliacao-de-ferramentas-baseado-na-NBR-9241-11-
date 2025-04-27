# Avaliacao-de-ferramentas-baseado-na-NBR-9241-11-

Usar a NBR 9241-11 como parametro para avaliar ferramentas

Programa/aplicação web em racket que permite: avaliar por meio de um formulario se um site cumpre os parametro da NBR 9241-11; guardar as avaliaçôes em um banco de dados SQLite; permitir a visualizacao e pesquisa dessas avaliacoes.

## Explicação Geral

- Banco de Dados
  - O trecho inicia conectando (ou criando) o arquivo avaliacoes.db.
    - A tabela avaliacoes é criada com os campos: id, site, eficacia, eficiencia, satisfacao, comentarios e o timestamp avaliado_em.

  - Funções de Acesso

    - inserir-avaliacao: Insere os dados da avaliação no banco de dados.

    - buscar-avaliacoes: Retorna uma lista de avaliações. Aceita opcionalmente um critério de pesquisa (usado na página de busca).

  - Servlet

    - A função servlet examina a URI da requisição e direciona a resposta:

        - "/": Apresenta o formulário de avaliação.

        - "/submit": Processa a submissão do formulário (método POST) e insere os dados no banco.

        - "/list": Lista todas as avaliações registradas, exibindo-as em uma tabela HTML.

        - "/search": Exibe um formulário para inserir o critério de pesquisa (site) e, após o POST, retorna os resultados filtrados.

  - Servidor

  - A chamada à função serve/servlet inicia o servidor na porta 8080 e tenta abrir o navegador.

## Instalar

Voce pode instalar pacote por pacote
```sh
sudo apt install libsqlite3-dev
```
```sh
raco pkg install web-server
```
```sh
raco pkg install db
```
```sh
raco pkg install db-lib
```
```sh
raco pkg install libsqlite3
```
ou tudo junto
```sh
sudo apt install libsqlite3-dev
raco pkg install web-server db db-lib libsqlite3
```

## Rodar

```sh
racket server.rkt
```