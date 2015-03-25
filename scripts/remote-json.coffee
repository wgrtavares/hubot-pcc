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

  req = require('https').request options, (res) ->
    res.setEncoding 'utf8'
    res.on 'data', (data) ->
      json = null;

      localJson = robot.brain.get 'json'
      remoteJsonData = data
      if localJson && remoteJsonData
        remoteJson = JSON.parse(remoteJsonData.toString())
        json = if localJson.versao > remoteJson.versao then localJson else remoteJson
      else if remoteJsonData
        json = JSON.parse(remoteJsonData)
      else
        robot.logger.error('Não foi possível carregar o JSON de conceitos.')
        return

      robot.brain.set 'json', json

      options.method = 'PUT'
      req = require('https').request options, (res) ->
        return
      req.write(JSON.stringify(json))
      req.end(null);

      registrarPerguntasERepostas(conceitoEspecifico, 'respond') for conceitoEspecifico in json.conceitosEspecificos
      registrarPerguntasERepostas(conceitoGeral, 'hear') for conceitoGeral in json.conceitosGerais

      robot.respond /.*vers.o.*conceito.*[?]/i, (response) ->
        response.send json.versao
        return
      return
    return
  req.end()

