#lang racket

(require web-server/servlet
         web-server/servlet-env
         db/base
         db/sqlite3
         )  ; Importa as funções do módulo db, incluindo query-exec

;; Definição de assoc-ref para trabalhar com association lists
(define (assoc-ref alist key [default #f])
  (let ([pair (assoc key alist)])
    (if pair (cdr pair) default)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Configuração e inicialização do banco de dados SQLite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define db-path "avaliacoes.db")
;; Estabelece conexão com o banco de dados SQLite (cria o arquivo se necessário)
(define db-conn (sqlite3-connect #:database db-path))

;; Criação da tabela "avaliacoes" (se ela ainda não existir)
(query-exec db-conn
            "CREATE TABLE IF NOT EXISTS avaliacoes (
               id INTEGER PRIMARY KEY,
               site TEXT NOT NULL,
               url TEXT NOT NULL,
               tipo_usuario TEXT NOT NULL,
               componente_avaliado TEXT NOT NULL,
               adequacao INTEGER,
               descricao INTEGER,
               explicito INTEGER,
               consistencia INTEGER,
               prevencao_erros INTEGER,
               tolerancia_falhas INTEGER,
               flexibilidade_eficiencia INTEGER,
               estetica_design INTEGER,
               expectativa INTEGER,
               normas_convencao INTEGER,
               comentarios TEXT,
               avaliado_em DATETIME DEFAULT CURRENT_TIMESTAMP
            );")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Funções de Acesso ao Banco
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Insere uma nova avaliação no banco de dados
(define (inserir-avaliacao site url tipo_usuario componente_avaliado adequacao descricao explicito consistencia prevencao_erros tolerancia_falhas flexibilidade_eficiencia estetica_design expectativa normas_convencao comentarios)
  (query-exec db-conn
              "INSERT INTO avaliacoes (site, url, tipo_usuario, componente_avaliado, adequacao, descricao, explicito, consistencia, prevencao_erros, tolerancia_falhas, flexibilidade_eficiencia, estetica_design, expectativa, normas_convencao, comentarios)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
              site url tipo_usuario componente_avaliado adequacao descricao explicito consistencia prevencao_erros tolerancia_falhas flexibilidade_eficiencia estetica_design expectativa normas_convencao comentarios))

;; Retorna as avaliações, opcionalmente filtrando por uma string no campo 'site'
(define (buscar-avaliacoes [criterio ""])
  (if (or (not criterio) (string=? criterio ""))
      (begin
        ;;(displayln "Executando SQL: SELECT * FROM avaliacoes ORDER BY avaliado_em DESC")
        (query-rows db-conn "SELECT * FROM avaliacoes ORDER BY avaliado_em DESC"))
      (begin
        ;;(printf (~a "SELECT * FROM avaliacoes WHERE site LIKE ? ORDER BY avaliado_em DESC" (string-append "%" criterio "%")))
        (query-rows db-conn
                    "SELECT * FROM avaliacoes WHERE site LIKE ? ORDER BY avaliado_em DESC"
                    (string-append "%" criterio "%")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Função para gerar linhas da tabela HTML (usada nas páginas de listagem/pesquisa)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gerar-linhas avaliacao-list)
  (for/list ([reg avaliacao-list])
    (define id                        (vector-ref reg 0))
    (define site                      (vector-ref reg 1))
    (define url                       (vector-ref reg 2))
    (define tipo_usuario              (vector-ref reg 3))
    (define componente_avaliado       (vector-ref reg 4))
    (define adequacao                 (vector-ref reg 5))
    (define descricao                 (vector-ref reg 6))
    (define explicito                 (vector-ref reg 7))
    (define consistencia              (vector-ref reg 8))
    (define prevencao_erros           (vector-ref reg 9))
    (define tolerancia_falhas         (vector-ref reg 10))
    (define flexibilidade_eficiencia  (vector-ref reg 11))
    (define estetica_design           (vector-ref reg 12))
    (define expectativa               (vector-ref reg 13))  
    (define normas_convencao          (vector-ref reg 14))
    (define comentarios               (vector-ref reg 15))
    (define avaliado-em               (vector-ref reg 16))
    `(tr
      (td ,(number->string id))
      (td ,site)
      (td ,url)
      (td ,tipo_usuario)
      (td ,componente_avaliado)
      (td ,(number->string adequacao))
      (td ,(number->string descricao))
      (td ,(number->string explicito))
      (td ,(number->string consistencia))
      (td ,(number->string prevencao_erros))
      (td ,(number->string tolerancia_falhas))
      (td ,(number->string flexibilidade_eficiencia))
      (td ,(number->string estetica_design))
      (td ,(number->string expectativa))
      (td ,(number->string normas_convencao))
      (td ,comentarios)
      (td ,avaliado-em))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utilitarios
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (obter-e-validar-numero valores chave)
  (let* ([str (assoc-ref valores chave)])
    (cond
      [(not str)
       (error (format "Campo obrigatório ausente: ~a" chave))]
      [(not (string? str))
       (error (format "Valor inválido em ~a: não é string" chave))]
      [else
       (define num (string->number str))
       (if (and (and num (integer? num) (and (> num -1) (< num 11))))
           num
           (error (format "Valor inválido em ~a: deve ser número inteiro entre 0 e 10" chave)))])))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementação do Servlet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (servlet request)
  ;; (print (request-method request))        ; mostra 'get ou 'post
  ;; (displayln (request-uri request))           ; mostra a URL
  ;; (displayln (request-bindings request))      ; mostra os campos do formulário


  (define valores (request-bindings request))
  (define uri-path
    (string-append "/" (string-join (map path/param-path (url-path (request-uri request))) "/")))
  (cond
    ;; Página principal: formulário para cadastrar avaliação
    [(string=? uri-path "/")
     (response/xexpr
      `(html
        (head (title "Avaliação de Sites - NBR 9241-11"))
        (body
          (h1 "Avaliação de Sites - NBR 9241-11")
          (form ([action "/submit"] [method "post"])
            (p "Site: " (input ([type "text"] [name "site"] [required "true"])))
            (p "URL: " (input ([type "text"] [name "url"] [required "true"])))
            (p "Tipo de usuários tester's: " (input ([type "text"] [name "tipo_usuario"] [required "true"])))
            (p "Componentes testados: " (input ([type "text"] [name "componente_avaliado"] [required "true"])))
            (p "Adequação ao uso (0-10): " (input ([type "number"] [name "adequacao"] [min "0"] [max "10"] [required "true"])))
            (p "Auto descrição (0-10): " (input ([type "number"] [name "descricao"] [min "0"] [max "10"] [required "true"])))
            (p "Controle explícito (0-10): " (input ([type "number"] [name "explicito"] [min "0"] [max "10"] [required "true"])))
            (p "Consistência (0-10): " (input ([type "number"] [name "consistencia"] [min "0"] [max "10"] [required "true"])))
            (p "Prevenção de erros (0-10): " (input ([type "number"] [name "prevencao_erros"] [min "0"] [max "10"] [required "true"])))
            (p "Tolerância a falhas (0-10): " (input ([type "number"] [name "tolerancia_falhas"] [min "0"] [max "10"] [required "true"])))
            (p "Flexibilidade e eficiência de uso (0-10): " (input ([type "number"] [name "flexibilidade_eficiencia"] [min "0"] [max "10"] [required "true"])))
            (p "Estética e design minimalista (0-10): " (input ([type "number"] [name "estetica_design"] [min "0"] [max "10"] [required "true"])))
            (p "Compatibilidade com a expectativa dos usuários (0-10): " (input ([type "number"] [name "expectativa"] [min "0"] [max "10"] [required "true"])))
            (p "Conformidade com as normas e convenções (0-10): " (input ([type "number"] [name "normas_convencao"] [min "0"] [max "10"] [required "true"])))
            (p "Comentários: " (textarea ([name "comentarios"] [required "true"])))
            (p (input ([type "submit"] [value "Enviar Avaliação"])))
          )
          (hr)
          (p (a ([href "/list"]) "Listar Avaliações"))
          (p (a ([href "/search"]) "Pesquisar Avaliações"))
        )))]

    ;; Processa o formulário e salva os dados no SQLite
    [(string=? uri-path "/submit")
    ;; (displayln ">>>> VALORES RECEBIDOS:")
    ;; (for-each (λ (x)
    ;;            (print (car x))
    ;;            (display " => ")
    ;;            (print (cdr x))
    ;;            (display "\n")
    ;;            )
    ;;          valores)

      ;; Converte para string e número
      (define site                      (assoc-ref valores 'site))
      (define url                       (assoc-ref valores 'url))
      (define tipo_usuario              (assoc-ref valores 'tipo_usuario))
      (define componente_avaliado       (assoc-ref valores 'componente_avaliado))
      (define adequacao                 (string->number (assoc-ref valores 'adequacao)))
      (define descricao                 (string->number (assoc-ref valores 'descricao)))
      (define explicito                 (string->number (assoc-ref valores 'explicito)))
      (define consistencia              (string->number (assoc-ref valores 'consistencia)))
      (define prevencao_erros           (string->number (assoc-ref valores 'prevencao_erros)))
      (define tolerancia_falhas         (string->number (assoc-ref valores 'tolerancia_falhas)))
      (define flexibilidade_eficiencia  (string->number (assoc-ref valores 'flexibilidade_eficiencia)))
      (define estetica_design           (string->number (assoc-ref valores 'estetica_design)))
      (define expectativa               (string->number (assoc-ref valores 'expectativa)))
      (define normas_convencao          (string->number (assoc-ref valores 'normas_convencao)))
      (define comentarios (assoc-ref valores 'comentarios))

      ;; Insere no banco
      (inserir-avaliacao site url tipo_usuario componente_avaliado adequacao descricao explicito consistencia prevencao_erros tolerancia_falhas flexibilidade_eficiencia estetica_design expectativa normas_convencao comentarios)

      (response/xexpr
        `(html
          (head (title "Avaliação Registrada"))
          (body
            (h1 "Avaliação Registrada com Sucesso!")
            (p "A avaliação para o site " ,site " foi registrada.")
            (p (a ([href "/"]) "Voltar para o formulário"))
            (p (a ([href "/list"]) "Listar Todas as Avaliações"))
          )))]

    ;; Página para listar todas as avaliações registradas
    [(string=? uri-path "/list")
     (define avaliacoes (buscar-avaliacoes))
     (response/xexpr
      `(html
        (head (title "Lista de Avaliações"))
        (body
          (h1 "Avaliações Registradas")
          (table ([border "1"])
            (tr
              (th "ID") (th "Site") (th "Url") (th "Tipo de usuario") (th "Componente avaliado") (th "Adequação ao uso") (th "Auto descrição") (th "Controle explícito") (th "Consistência") (th "Prevenção de erros") (th "Tolerância a falhas") (th "Flexibilidade") (th "Estética") (th "Compatibilidade e expectativa") (th "Normas e convenções") (th "Comentarios extra") (th "Data"))
            ,@(gerar-linhas avaliacoes))
          (p (a ([href "/"]) "Voltar ao formulário"))
        )))]

    ;; Página de pesquisa: exibe formulário e, quando submetido, resultados filtrados
    [(string=? uri-path "/search")
     (cond
       [(equal? (request-method request) #"POST")
        (define criterio (assoc-ref valores 'criterio))
        (define avaliacoes (buscar-avaliacoes criterio))
        (response/xexpr
         `(html
           (head (title "Resultados da Pesquisa"))
           (body
             (h1 "Resultados da Pesquisa")
             (table ([border "1"])
               (tr
                 (th "ID") (th "Site") (th "Url") (th "Tipo de usuario") (th "Componente avaliado") (th "Adequação ao uso") (th "Auto descrição") (th "Controle explícito") (th "Consistência") (th "Prevenção de erros") (th "Tolerância a falhas") (th "Flexibilidade") (th "Estética") (th "Compatibilidade e expectativa") (th "Normas e convenções") (th "Comentarios extra") (th "Data"))
               ,@(gerar-linhas avaliacoes))
             (p (a ([href "/"]) "Voltar ao formulário"))
           )))
       ]
       [else
        (response/xexpr
         `(html
           (head (title "Pesquisar Avaliações"))
           (body
             (h1 "Pesquisar Avaliações")
             (form ([action "/search"] [method "post"])
               (p "Pesquisar por Site: " (input ([type "text"] [name "criterio"])))
               (p (input ([type "submit"] [value "Pesquisar"])))
             )
             (p (a ([href "/"]) "Voltar ao formulário"))
           )))
        ])]

    ;; Página padrão - rota não encontrada
    [else
     (response/xexpr
      `(html
        (head (title "Página não encontrada"))
        (body
          (h1 "404 - Página não encontrada")
          (p "A página solicitada não foi encontrada.")
          (p (a ([href "/"]) "Voltar"))
        )))])
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Iniciar o servidor com o servlet definido
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(serve/servlet servlet
               #:servlet-regexp #rx".*"
               #:servlet-path "/"
               #:port 8080
               #:launch-browser? #t)