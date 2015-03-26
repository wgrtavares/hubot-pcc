# Description:
#   <description of the scripts functionality>
#
# Dependencies:
#   "<module name>": "<module version>"
#
# Configuration:
#   HUBOT_GERENCIAMENTO_URL_JSON_CONCEITOS
#   HUBOT_SERVICE_NAME
#
# Commands:
#   hubot <trigger> - <what the respond trigger does>
#   <trigger> - <what the hear trigger does>
#
# Notes:
#
# Author:
#   wgrtavares
module.exports = (robot) ->

  url =  process.env.HUBOT_GERENCIAMENTO_URL_JSON_CONCEITOS
  serviceName = process.env.HUBOT_SERVICE_NAME

  respond = (regexp, callback) ->
    robot.respond regexp, (response) ->
      loadHttpsConnectionData(robot)
      callback(response)
      return
    return

  reiniciar = (robot, response) ->
    response.send 'Reiniciando.'

    setTimeout ->
      require('child_process')
      .exec "sudo service #{serviceName} restart", (err, stdout, stderr) ->
          if err
            robot.logger.error "Ao reiniciar: \n#{err}\n#{stderr}"
            response.send 'Ops, problemas com a reinicialização. Veja: \n#{err}\n#{stderr}'
          return
      return
    , 2000
    return

  respond /reinicie/i, (response) ->
    reiniciar robot, response
    return

  respond /carregue estes conceitos (.*)/i, (response) ->
    json = response.match[1]

    robot.http(url)
      .header('Content-Type', 'application/json')
      .put(json) (err, res, body) ->
        if err
          response.send "Ops, deu erro! #{err}"
        else
          response.send 'Carregado! =D'
          setTimeout ->
            reiniciar robot, response
            return
          , 1000
        return
    return

  respond /.*vers.o.*conceito.*[?]/i, (response) ->
    json = robot.brain.get 'json'
    if json
      response.send json.versao
    else
      response.send 'Não encontrei o json de conceitos no meu cérebro!'
    return

  respond /me mostre o json de conceitos/i, (response) ->
    response.send "#{httpsConnectionData.readPath}"
    return

  return