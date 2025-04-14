#lang racket

(require web-server/servlet
         web-server/servlet-env
         db/base
         db/sqlite3
         )  ; Importa as funções do módulo db, incluindo query-exec

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
               eficacia INTEGER,
               eficiencia INTEGER,
               satisfacao INTEGER,
               comentarios TEXT,
               avaliado_em DATETIME DEFAULT CURRENT_TIMESTAMP
            );")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Funções de Acesso ao Banco
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Insere uma nova avaliação no banco de dados
(define (inserir-avaliacao site eficacia eficiencia satisfacao comentarios)
  (query-exec db-conn
              "INSERT INTO avaliacoes (site, eficacia, eficiencia, satisfacao, comentarios)
               VALUES (?, ?, ?, ?, ?)"
              site eficacia eficiencia satisfacao comentarios))

;; Retorna as avaliações, opcionalmente filtrando por uma string no campo 'site'
(define (buscar-avaliacoes [criterio ""])
  (if (or (not criterio) (string=? criterio ""))
      (query-list db-conn "SELECT * FROM avaliacoes ORDER BY avaliado_em DESC")
      (query-list db-conn "SELECT * FROM avaliacoes WHERE site LIKE ? ORDER BY avaliado_em DESC"
                  (string-append "%" criterio "%"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Função para gerar linhas da tabela HTML (usada nas páginas de listagem/pesquisa)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gerar-linhas avaliacao-list)
  (for/list ([reg avaliacao-list])
    (define id           (vector-ref reg 0))
    (define site         (vector-ref reg 1))
    (define eficacia     (vector-ref reg 2))
    (define eficiencia   (vector-ref reg 3))
    (define satisfacao   (vector-ref reg 4))
    (define comentarios  (vector-ref reg 5))
    (define avaliado-em  (vector-ref reg 6))
    `(tr
      (td ,(number->string id))
      (td ,site)
      (td ,(number->string eficacia))
      (td ,(number->string eficiencia))
      (td ,(number->string satisfacao))
      (td ,comentarios)
      (td ,avaliado-em))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementação do Servlet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (servlet request)
  (define valores (request-bindings request))
  (define uri (request-uri request))
  (cond
    ;; Página principal: formulário para cadastrar avaliação
    [(string=? uri "/")
     (response/xexpr
      `(html
        (head (title "Avaliação de Sites - NBR 9241-11"))
        (body
          (h1 "Avaliação de Sites - NBR 9241-11")
          (form ([action "/submit"] [method "post"])
            (p "Site URL: " (input ([type "text"] [name "site"])))
            (p "Eficácia (0-10): " (input ([type "number"] [name "eficacia"] [min "0"] [max "10"])))
            (p "Eficiência (0-10): " (input ([type "number"] [name "eficiencia"] [min "0"] [max "10"])))
            (p "Satisfação (0-10): " (input ([type "number"] [name "satisfacao"] [min "0"] [max "10"])))
            (p "Comentários: " (textarea ([name "comentarios"])))
            (p (input ([type "submit"] [value "Enviar Avaliação"])))
          )
          (hr)
          (p (a ([href "/list"]) "Listar Avaliações"))
          (p (a ([href "/search"]) "Pesquisar Avaliações"))
        )))]

    ;; Processa o formulário e salva os dados no SQLite
    [(string=? uri "/submit")
     (define site       (assoc-ref valores "site"))
     (define eficacia   (string->number (assoc-ref valores "eficacia")))
     (define eficiencia (string->number (assoc-ref valores "eficiencia")))
     (define satisfacao (string->number (assoc-ref valores "satisfacao")))
     (define comentarios (assoc-ref valores "comentarios"))
     (inserir-avaliacao site eficacia eficiencia satisfacao comentarios)
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
    [(string=? uri "/list")
     (define avaliacoes (buscar-avaliacoes))
     (response/xexpr
      `(html
        (head (title "Lista de Avaliações"))
        (body
          (h1 "Avaliações Registradas")
          (table ([border "1"])
            (tr
              (th "ID") (th "Site") (th "Eficácia") (th "Eficiência")
              (th "Satisfação") (th "Comentários") (th "Data"))
            ,@(gerar-linhas avaliacoes))
          (p (a ([href "/"]) "Voltar ao formulário"))
        )))]

    ;; Página de pesquisa: exibe formulário e, quando submetido, resultados filtrados
    [(string=? uri "/search")
     (cond
       [(eq? (request-method request) 'post)
        (define criterio (assoc-ref valores "criterio"))
        (define avaliacoes (buscar-avaliacoes criterio))
        (response/xexpr
         `(html
           (head (title "Resultados da Pesquisa"))
           (body
             (h1 "Resultados da Pesquisa")
             (table ([border "1"])
               (tr
                 (th "ID") (th "Site") (th "Eficácia") (th "Eficiência")
                 (th "Satisfação") (th "Comentários") (th "Data"))
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
    
    ;; Página padrão – rota não encontrada
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
               #:servlet-path "/"
               #:port 8080
               #:launch-browser? #t)