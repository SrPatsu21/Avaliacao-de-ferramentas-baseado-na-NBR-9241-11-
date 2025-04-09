# Avaliacao-de-ferramentas-baseado-na-NBR-9241-11-

Usar a NBR 9241-11 como parametro para avaliar ferramentas

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