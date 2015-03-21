module.exports = (robot) ->

  options =
    hostname: 'api.myjson.com'
    port: 443
    path: '/bins/4qtiv'
    method: 'GET'
    headers:
      'Content-Type': 'application/json'

  registrarPerguntasERepostas = (conceito, tipoEscuta) ->
    regexp = new RegExp conceito.pergunta.regex, conceito.pergunta.modificador
    robot[tipoEscuta] regexp, (msg) ->
      if conceito.respostasAleatorias
        setTimeout () ->
          msg.send msg.random conceito.respostasAleatorias
        , 500
      if conceito.respostas
        setTimeout () ->
          msg.send conceito.respostas
        , 1000
      return
    return

  https = require 'https'

  req = https.request options, (res) ->
    res.setEncoding 'utf8'
    res.on 'data', (data) ->
      dataJson = JSON.parse(data)
      registrarPerguntasERepostas(conceitoEspecifico, 'respond') for conceitoEspecifico in dataJson.conceitosEspecificos
      registrarPerguntasERepostas(conceitoGeral, 'hear') for conceitoGeral in dataJson.conceitosGerais
      return
    return
  req.end()