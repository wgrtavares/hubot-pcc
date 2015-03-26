module.exports = (robot) ->

  httpsConnectionData =
    readPath : process.env.HUBOT_REMOTE_JSON_READ_PATH
    hostname: process.env.HUBOT_REMOTE_JSON_HTTPS_HOSTNAME
    port: process.env.HUBOT_REMOTE_JSON_HTTPS_PORT
    path: process.env.HUBOT_REMOTE_JSON_HTTPS_PATH
    method: 'GET'
    headers:
      'Content-Type': 'application/json'

  robot.on 'queryHttpsConnectionData', (callback) ->
    callback httpsConnectionData
    return

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

  req = require('https').request httpsConnectionData, (res) ->
    res.on 'data', (data) ->
      json = null;

      localJson = robot.brain.get 'json'
      remoteJsonData = data
      if localJson && remoteJsonData
        remoteJson = JSON.parse(remoteJsonData)
        json = if localJson.versao > remoteJson.versao then localJson else remoteJson
      else if remoteJsonData
        json = JSON.parse(remoteJsonData)
      else
        robot.logger.error('Não foi possível carregar o JSON de conceitos.')
        return

      robot.brain.set 'json', json

      httpsConnectionData.method = 'PUT'
      req = require('https').request httpsConnectionData, (res) ->
        return
      req.write(JSON.stringify(json))
      req.end(null);

      registrarPerguntasERepostas(conceitoEspecifico, 'respond') for conceitoEspecifico in json.conceitosEspecificos
      registrarPerguntasERepostas(conceitoGeral, 'hear') for conceitoGeral in json.conceitosGerais

      return
    return
  req.end()

