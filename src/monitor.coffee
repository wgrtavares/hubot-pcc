class Executable
  constructor: ->
    return
  execute: (obj) ->
    return obj

class Buffer
  @maxLength_ = @executables = @queue = null
  constructor: (@maxLength_ = 10, @executables = []) ->
    @queue = []
    return
  put: (obj_) ->
    @queue.push(obj_)
    if @queue.length == @maxLength_ + 1
      @queue.shift()
    @execute_()
    return
  execute_: ->
    i = Math.floor(@queue.length/2)
    executable_.execute @queue[i] for executable_ in @executables
    return
  toString: ->
    str =+ executable+'\n' for executable in @executables
    return "[tamanho= #{maxLength_}\nmonitores=[\n#{str}\n]\n]"

class MonitorDeSala extends Executable
  @regexp = @salaMonitorada = @salaResposta = @autores = @excetoAutores = null
  constructor: (@buffers, @regexp, @salaMonitorada, @salaResposta, @autores = [],  @excetoAutores = []) ->
    return
  execute: (envelope) ->
    return if envelope.user in @excetoAutores
    if @autores.length?
      return unless envelope.user in @autores
    regexp_ = new RegExp @regexp, 'i'
    result_ = regexp_.exec(envelope.message.text)
    return unless result_[0]?
    str = ''
    for bufferedEnvelope_ in buffers[envelope.room].queue[..]
      str =+  bufferedEnvelope_.user + ': ' + bufferedEnvelope_.message.text + '\n'
    robot.messageRoom(@salaResposta, str)
    return
  toJSON: ->
    return {
    regexp: @regexp
    autores: @autores
    excetoAutores: @excetoAutores
    salaMonitorada: @salaMonitorada
    salaResposta: @salaResposta
    }
  toString: ->
    return "[regexp= #{@regexp}, salaMonitorada= #{@salaMonitorada}," +
    "salaResposta= #{@salaResposta}, autores= #{@autores}, excetoAutores= #{@excetoAutores}]"


f_ = (robot) ->

  bufferMaxLength = process.env.HUBOT_MONITOR_TAMANHO_CONTEXTO

  createBuffers_ = ->
    buffers_ = {}
    monitoresDados_ = robot.brain.get 'monitores'
    unless monitoresDados_?
      robot.logger.info 'Criando buffers: Não existem monitores guardados no cérebro.'
      return null
    indicePorChat = {}
    for monitorDado_ in monitoresDados_
      indicePorChat[monitorDado_.salaMonitorada] = [] unless indicePorChat[monitorDado_.salaMonitorada]?
      indicePorChat[monitorDado_.salaMonitorada].push new MonitorDeSala buffers_, monitorDado_.regexp,
        monitorDado_.salaMonitorada, monitorDado_.salaResposta, monitorDado_.autores, monitorDado_.excetoAutores
    for salaMonitorada_, monitoresDeSala_ of indicePorChat
      buffers_[salaMonitorada_] = new Buffer(bufferMaxLength, monitoresDeSala_)
    return buffers_

  getBuffers = ->
    buffers = createBuffers_() unless buffers?
    return buffers

  ### CONFIGURANDO ESCUTAS ###
  buffers = null
  robot.hear /.*/i, (response) ->
    getBuffers()[response.envelope.room].put response.envelope if getBuffers()?
    return

  robot.respond /monitore[^"]*"([^"]*)"[^a-z]*(.*)/i , (response) ->
    updateStr = (str, matchResult) ->
      return str.substring(str.indexOf(matchResult[0]), matchResult[0].length)

    salaResponsta_ = response.envelope.room

    regexp_ = response.match[1]
    str_ = response.match[2]

    findExcetoUsuarios = /exceto[ ]*usu.rio[s]{0,1}[^"]"([^"])"[ ]*/i
    result_ = findExcetoUsuarios.exec str
    exceto_ = result_[1].replace(' ', '').split(',')
    str_ = updateStr str_, result_

    findUsuarios = /usu.rio[s]{0,1}[^"]"([^"])"[ ]*/i
    result_ = findUsuarios.exec str
    usuarios_ = result_[1].replace(' ', '').split(',')
    str_ = updateStr str_, result_

    findSala = /na sala ([^ ]*)[ ]*/i
    result_ = findSala.exec str
    salaMonitorada_ = result_[1].replace(' ', '').split(',')

    monitor_ = new MonitorDeSala regexp_, salaMonitorada_, salaResponsta_, usuarios_, exceto_

    getBuffers[salaMonitorada_].executables.push(monitor_) if getBuffers[salaMonitorada_]? and getBuffers[salaMonitorada_].executables?

    return

  robot.respond /.*monitorando[^?]*[?]/i, (response) ->
    unless getBuffers()?
      response.send 'Não estou monitorando nada nesse momento'
    str = ''
    for room, buffer of getBuffers()
      str =+ ""

    return

  return


module.exports = {
  f_,
  Executable,
  MonitorDeSala,
  Buffer
}