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

## Artigo 

Este presente artigo visa realizar a análise do software **DrRacket** levando em conta sua utilização para desenvolvedores de código, o público que irá ser analisado será justamente programadores. 

### Resumo


### Introdução
Este artigo visa mostrar um estudo de usabilidade usando as normas da NBR 9241 para análisar o software DrRacket.
DrRacket é um ambiente gráfico para desenvolvimento de programas para linguagens Racket e suas derivações. NBR 9241 é uma adaptação da norma ISO 9241 para o contexto do Brasil, que define o que é Usabilidade e como deve ocorrer a interação humano-máquina, sendo que a norma brasileira tem como algumas adições a medição da eficácia e eficiência segundo os usuários em um determinado contexto, entre outras.

### Fundamentação teórica
Usabilidade neste conceito se refere à medida do quanto os usuários conseguem utilizar o sistema de forma eficiente. Ela pode ser melhorada utilizando algumas caracteristicas e conceitos que beneficiem a utilização por parte dos usuários, para tal é importante conhecer qual o público alvo pois essas características são diferentes em determinados contextos.

### Análise de usabilidade
A análise foi conduzida por um usuário que simulou a utilização do software DrRacket como sendo um desenvolvedor ativo que tem por experiência a utilização do software Visual Studio Code, portanto ele está habituado a utilização de uma interface intuitíva e com atalhos.

Para cada parâmetro foi dado uma nota de 0 à 10, como apenas uma pessoa avaliou então será utilizado a nota bruta, no software apresentado neste repositório há a avaliação por completo. Os parâmetros que foram analisados e suas respectivas notas foram os seguintes:

| Parâmetro                                      | Nota |
|------------------------------------------------|------|
| Adequação ao uso                               | 10   |
| Auto descrição                                 | 9    |
| Controle explícito                             | 6    |
| Consistência                                   | 4    |
| Prevenção de erros                             | 3    |
| Tolerância a falhas                            | 7    |
| Flexibilidade e eficiência de uso              | 8    |
| Estética e design minimalista                  | 9    |
| Compatibilidade com a expectativa dos usuários | 5    |
| Conformidade com as normas e convenções        | 4    |

O software apresentado neste repositório ainda permite alguns comentários extra para repassar algumas outras anotações.

### Resultado
A utilização do software requer certa prática e um tempo de adequação pois ele não tem compatibilidade com o que o usuário desenvolvedor espera e com algumas normas e convenções que novamente entram no espectro que era esperado mas que não se cumpriu, principalemnte com atalhos pois a utilização do DrRacket é puramente voltada para a programação, e a carência de atalhos indica que ele não foi criado para a utilização de forma eficiente.

### Conclusão
O Software tem muito a melhorar principalmente no parâmetro "espectativa do usuário" pois muitas funcionalidades, principalmente atalhos, não funcionam, e isto para o público alvo do DrRacket que são os desenvolvedores é extremamente essêncial, sendo poucos os que poderiam utiliza-lo de forma eficiente.

### Referências
<https://fundamentosdeux.com/post/nbr-9241-11-requisitos-ergonomicos-para-trabalho-de-escritorios-com-computadores-418.htm> 
NBR. NBR 9241-11 - Requisitos Ergonômicos para trabalho de escritórios com computadoresNBR, , 2002. Disponível em: <http://www.inf.ufsc.br/~edla.ramos/ine5624/_Walter/Normas/Parte%2011/iso9241-11F2.pdf>. Acesso em: 26 jan. 2021