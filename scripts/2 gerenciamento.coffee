# Description:
#   Permite algumas funções de auto gerenciamento para evitar o uso do terminal linux.
#
# Dependencies:
#   "redis-brain": "1.x"
#
# Configuration:
#   HUBOT_GERENCIAMENTO_URL_JSON_CONCEITOS
#   HUBOT_SERVICE_NAME
#
# Commands:
#   jarvis reinicie - Faz com que o serviço hubot+tg seja reiniciado.
#   jarvis carregue estes conceitos <json> - Faz com que o jarvis execute uma requisição https do tipo PUT para o
# endereço contido em HUBOT_GERENCIAMENTO_URL_JSON_CONCEITOS. Após isto ele atualiza seu próprio JSON de conceitos e se
# reinicia (como no comando acima).
#   jarvis qual a versão atual do seu conceito? - Retorna o valor da chave "versão" do JSON de conceitos.
#   jarvis me mostre o json de conceitos - Retorna o JSON de conceitos atual.
#
# Notes:
#   Não há
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