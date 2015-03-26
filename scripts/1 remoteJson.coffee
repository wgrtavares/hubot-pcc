# Description:
#   Lê arquivo JSON de conceitos na núvem e carrega no cérebro. Isso facilita a atualização de perguntas e respostas.
#   Veja um exemplo de JSON de conceito em https://api.myjson.com/bins/4qtiv.
#
# Dependencies:
#   "redis-brain": "1.x"
#
# Configuration:
#   HUBOT_REMOTE_JSON_HTTPS_HOSTNAME
#     Ex: 'api.myjson.com'
#   HUBOT_REMOTE_JSON_HTTPS_PORT
#     Ex: '443'
#   HUBOT_REMOTE_JSON_HTTPS_PATH
#     Ex: '/bins/4qtiv'
#
# Commands:
#   Os comandos variam de acordo com a configuração do JSON de conceitos.
#
# Notes:
#   Todas as perguntas e respostas devem estar no JSON de conceitos da núvem.
#
# Author:
#   wgrtavares
module.exports = (robot) ->

  httpsConnectionData =
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

