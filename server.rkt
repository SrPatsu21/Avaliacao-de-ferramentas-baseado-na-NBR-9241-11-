#lang racket

(require web-server/servlet
         web-server/servlet-env
         db/sqlite3)

;; ================================================
;; Conexão e configuração do banco de dados SQLite
;; ================================================

(define db-conn
  (sqlite3-connect #:database "avaliacoes.db"))

(define (create-db-tables!)
  (query-exec db-conn
    "CREATE TABLE IF NOT EXISTS avaliacoes (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       ferramenta TEXT,
       avaliacao INTEGER,
       comentario TEXT,
       data TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     )"))

(create-db-tables!)

;; ================================================
;; Funções de acesso ao banco de dados
;; ================================================

(define (insert-avaliacao ferramenta avaliacao comentario)
  (query-exec db-conn
    "INSERT INTO avaliacoes (ferramenta, avaliacao, comentario) VALUES (?, ?, ?)"
    ferramenta avaliacao comentario))

(define (get-avaliacoes)
  (query-rows db-conn "SELECT * FROM avaliacoes"))

;; ================================================
;; Servlet para lidar com as requisições HTTP
;; ================================================

(define (app req)
  (cond
    ;; POST: Processa envio do formulário
    [(eq? (request-method req) 'post)
     (define bindings (request-bindings req))
     (define ferramenta (hash-ref bindings 'ferramenta ""))
     (define avaliacao (string->number (hash-ref bindings 'avaliacao "0")))
     (define comentario (hash-ref bindings 'comentario ""))
     (insert-avaliacao ferramenta avaliacao comentario)
     (response/xexpr
      `(html
        (head (meta ([charset "utf-8"])) (title "Avaliação registrada"))
        (body
         (h1 "Avaliação registrada com sucesso!")
         (p "Obrigado por sua contribuição.")
         (p (a ([href "/"]) "Voltar para o formulário")))))]
    
    ;; GET: Mostra o formulário e avaliações
    [else
     (define avaliacoes (get-avaliacoes))
     (response/xexpr
      `(html
        (head
         (meta ([charset "utf-8"]))
         (title "Formulário de Avaliação")
         (style "body { font-family: Arial, sans-serif; margin: 20px; }
                 form p { margin: 10px 0; }"))
        (body
         (h1 "Avaliação de Ferramentas - Baseada na NBR‑9241‑11")
         (form ([method "post"] [action "/"])
           (p "Nome da Ferramenta: " (input ([type "text"] [name "ferramenta"])))
           (p "Avaliação (1 a 5): " (input ([type "number"] [min "1"] [max "5"] [name "avaliacao"])))
           (p "Comentário: " (textarea ([name "comentario"]) ""))
           (p (input ([type "submit"] [value "Enviar"]))))
         
         (h2 "Avaliações registradas")
         ,@(for/list ([linha avaliacoes])
             (let* (ferramenta (hash-ref linha 'ferramenta ""))
                    [nota (hash-ref linha 'avaliacao "")]
                    [comentario (hash-ref linha 'comentario "")]
                    [data (hash-ref linha 'data "Desconhecida")])
               `(div
                 (p (strong "Ferramenta: ") ,ferramenta)
                 (p (strong "Nota: ") ,(number->string nota))
                 (p (strong "Comentário: ") ,comentario)
                 (p (small "Data: " ,data))
                 (hr))))
         
         (h2 "Visualização Gráfica das Avaliações")
         (canvas ([id "avaliacoes-chart"] [width "400"] [height "200"]) "")
         
         ;; Script para renderizar o gráfico com dados fictícios
         (script "
           var ctx = document.getElementById('avaliacoes-chart').getContext('2d');
           var labels = ['Ferramenta A', 'Ferramenta B', 'Ferramenta C'];
           var data = [3, 5, 4];
           var chart = new Chart(ctx, {
               type: 'bar',
               data: {
                   labels: labels,
                   datasets: [{
                       label: 'Avaliações',
                       data: data,
                       backgroundColor: 'rgba(75, 192, 192, 0.2)',
                       borderColor: 'rgba(75, 192, 192, 1)',
                       borderWidth: 1
                   }]
               },
               options: {
                   scales: {
                       y: {
                           beginAtZero: true,
                           ticks: { stepSize: 1 }
                       }
                   }
               }
           });
         ")
         (script ([src "https://cdn.jsdelivr.net/npm/chart.js"]) "")))]))

;; ================================================
;; Inicialização do servidor Web
;; ================================================

(serve/servlet app
               #:servlet-path "/"
               #:port 8080
               #:listen-ip #f
               #:launch-browser? #t)
