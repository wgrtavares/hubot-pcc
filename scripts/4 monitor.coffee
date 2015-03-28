module.exports = (robot) ->

#  urlJsonMonitores = process.env.HUBOT_MONITOR_URL_JSON
#  isConsultaWebNaCarga = process.env.HUBOT_MONITOR_IS_CONSULTA_WEB_NA_CARGA
  bufferMaxLength = process.env.HUBOT_MONITOR_TAMANHO_CONTEXTO

  class Executable
    constructor: ->
      return
    execute: (obj) ->
      return obj

  class Buffer
    @maxLength_ = @executables_ = null
    constructor: (@maxLength_ = 10, @executables_ = []) ->
      @queue = []
    put: (obj_) ->
      @queue.push(obj_)
      if @queue.length == @maxLength_ + 1
        @queue.shift()
      @execute_()
      return
    execute_: ->
      i = Math.floor(@queue.length/2)
      executable_.execute @queue[i] for executable_ in @executables_
      return

  class MonitorDeSala extends Executable
    @regexp = @salaMonitorada = @salaResposta = @autores = @excetoAutores = null
    constructor: (@regexp, @salaMonitorada, @salaResposta, @autores = [],  @excetoAutores = []) ->
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

  createBuffers_ = ->
    buffers_ = {}
    monitoresDados_ = robot.brain.get 'monitores'
    unless monitoresDados_?
      robot.logger.error 'Não existem monitores guardados no cérebro.'
      return buffers_
    indicePorChat = {}
    for monitorDado_ in monitoresDados_
      indicePorChat[monitorDado_.salaMonitorada] = [] unless indicePorChat[monitorDado_.salaMonitorada]?
      indicePorChat[monitorDado_.salaMonitorada].push new MonitorDeSala monitorDado_.regexp,
        monitorDado_.salaMonitorada, monitorDado_.salaResposta, monitorDado_.autores, monitorDado_.excetoAutores
    for salaMonitorada_, monitoresDeSala_ of indicePorChat
      buffers_[salaMonitorada_] = new Buffer(bufferMaxLength, monitoresDeSala_)
    return buffers_


  ### CONFIGURANDO ESCUTAS ###
  buffers = null
  robot.hear /.*/i, (response) ->
    buffers = createBuffers_() unless buffers?
    buffers[response.envelope.room].put response.envelope
    return

  robot.respond /monitore "([^"]*)" na sala ([^ ]*) /i , (response) ->
    #TODO:
    return

  return





  ###getMonitores = (cbGetMonitores) ->

    getMonitoresFromWeb_ = (cbGetMonitoresWeb) ->
      req_ = require('https').request urlJsonMonitores, (res_) ->
        res_.on 'data', (data_) ->
          json_ = JSON.parse(data_);
          json_.monitores.versao = json_.versao
          cbGetMonitoresWeb json_.monitores
          return
        return
        res_.on 'error', (e) ->
          robot.logger.error(e)
          cbGetMonitoresWeb undefined
          return
      req_.end()
      return
    #fim getMonitoresFromWeb_

    getMonitoresFromBrain_ = ->
      json_ =  robot.brain.get 'json'
      if json_ && json_.monitores
        json_.monitores.versao = json_.versao
        return json_.monitores
      return undefined
    #fim getMonitoresFromBrain_

    getMaisRecente_ = (cbGetMaisRecente) ->
      monitoresFromBrain_ = getMonitoresFromBrain_
      if !monitores || (monitores && !isConsultaWebNaCarga)
        getMonitoresFromWeb_ (monitoresFromWeb_) ->
          if monitoresFromWeb_ && monitoresFromWeb_.versao && monitoresFromBrain_ && monitoresFromBrain_.versao
            monitores_ = if monitoresFromWeb_.versao >= monitoresFromBrain_.versao then monitoresFromWeb_ else monitoresFromBrain_
            robot.brain.set 'json', monitores_
            cbGetMaisRecente monitores_
          else if monitoresFromBrain_ && monitoresFromBrain_.versao
            cbGetMaisRecente monitoresFromBrain_
          else if monitoresFromWeb_ && monitoresFromWeb_.versao
            cbGetMaisRecente monitoresFromWeb_
          else
            robot.logger.error 'Não foi possível obter a coleção de monitores'
          return
        #fim declaração callback
      else if monitoresFromBrain_ && monitoresFromBrain_.versao
        cbGetMaisRecente monitoresFromBrain_
      else
        robot.logger.error 'Não foi possível obter a coleção de monitores'
      return
    #fim getMaisRecente_

    getMaisRecente_ cbGetMonitores

    return
  #fim getMonitores###