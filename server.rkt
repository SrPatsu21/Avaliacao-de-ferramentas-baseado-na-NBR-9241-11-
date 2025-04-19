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
      (query-rows db-conn "SELECT * FROM avaliacoes ORDER BY avaliado_em DESC")
      (query-rows db-conn
            "SELECT * FROM avaliacoes WHERE site LIKE ? ORDER BY avaliado_em DESC"
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
       (if (and num (integer? num))
           num
           (error (format "Valor inválido em ~a: deve ser número inteiro" chave)))])))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementação do Servlet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (servlet request)
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
            (p "Site URL: " (input ([type "text"] [name "site"] [required "true"])))
            (p "Eficácia (0-10): " (input ([type "number"] [name "eficacia"] [min "0"] [max "10"] [required "true"])))
            (p "Eficiência (0-10): " (input ([type "number"] [name "eficiencia"] [min "0"] [max "10"] [required "true"])))
            (p "Satisfação (0-10): " (input ([type "number"] [name "satisfacao"] [min "0"] [max "10"] [required "true"])))
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
      (define site       (assoc-ref valores 'site))
      (define eficacia   (string->number (assoc-ref valores 'eficacia)))
      (define eficiencia (string->number (assoc-ref valores 'eficiencia)))
      (define satisfacao (string->number (assoc-ref valores 'satisfacao)))
      (define comentarios (assoc-ref valores 'comentarios))

      ;; Insere no banco
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
    [(string=? uri-path "/list")
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
    [(string=? uri-path "/search")
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
               #:port 8081
               #:launch-browser? #t)