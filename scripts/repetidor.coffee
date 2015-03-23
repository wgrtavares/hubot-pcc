#noinspection JSUnresolvedVariable
module.exports = (robot) ->

  repeticoes = null
  repeticoesListadas = null
  salas = null

  robot.respond /repita[^0-9]*([0-9]{1,5})[ ]*(vezes|vez)[ ]*em[ ]*intervalos[^0-9]*([0-9]{1,5})[ ]*([a-z]*)(.*)/i, (response) ->
    grandeza = response.match[4]
    switch grandeza
      when 'minutos','minuto' then intervalo = 60*1000
      when 'segundos','segundo' then intervalo = 1000
      when 'horas','hora' then intervalo = 60*60*1000
      when 'dias', 'dia' then intervalo = 24*60*60*1000
      else
        response.send "opa, vc usou #{grandeza}. Tente novamente usando segundos, minutos, horas ou dias ;) "
        return

    qtdRepeticoes = response.match[1]
    intervalo *= response.match[3]
    timeout = intervalo * qtdRepeticoes
    texto = response.match[5]

    if !salas
      response.send "Configure quais as salas."
      return

    repeticao = new Repeticao qtdRepeticoes, intervalo, timeout, texto, salas

    if repeticoes.put repeticao
      repeticao.onStop = ->
        repeticoes.remove repeticao
        return
      repeticao.iniciar response
      persistir()
    else
      response.send "Esta repetição já existe."
      listarRepeticoes response
    return

  robot.respond /.*(repetindo)[^?]*(salas|sala)[^?][?]/i, (response) ->
    if salas
      response.send "As repetições inicadas agora serão realizadas nas salas #{salas}."
    else
      response.send "Não existem salas configuradas no momento."
    return

  robot.respond /.*(repetindo)[^?]*[?]/i, (response) ->
    listarRepeticoes response
    return

  robot.respond /.*repita.*(salas|sala)[ :](.*)/i, (response) ->
    if response.match[2]
      salas = response.match[2]
      response.send "Ok. As salas de repetição agora são: " + salas
    else
      response.send "Não entendí em quais salas você quer que eu repita."
    return

  robot.respond /.*(pare|cancele|parar|para).*(repetir|repeti..o)[^0-9]*([0-9]*)/i, (response) ->
    if !repeticoes.size()
      response.send "Não estou repetindo nada no momento."
      return
    i = response.match[3]
    if !i
      response.send "Tente novamente com um dos numeros abaixo."
      listarRepeticoes(response)
      return
    if repeticoes.remove(repeticoesListadas[i])
      switch response.match[1]
        when 'pare' then verbo = 'parei'
        when 'cancele' then verbo = 'cancelei'
        else
          return
      response.send "Pronto, #{verbo}"
    else
      response.send "Esta opção já era."
      listarRepeticoes(response)
    return

  class Repeticao

    constructor: (repeticoes, intervalo, timeout, texto, salas) ->
      @repeticoes = repeticoes
      @intervalo = intervalo
      @timeout = timeout
      @texto = texto
      @salas = salas
      @_construidoEm = new Date()
      @_iniciadoEm = 0
      @_paradoEm = 0
      @onStop = null
      return

    iniciar: (response) ->
      this.parar true #isChamadaInterna
      obj = this
      for sala in obj.salas.split(',')
        setTimeout () ->
          obj._iniciadoEm = new Date()
          robot.messageRoom sala, obj.texto

          obj.intervaloRepeticaoId = setInterval () ->
            for sala in obj.salas.split(',')
              robot.messageRoom sala, obj.texto
          , obj.intervalo

          obj.timeoutRepeticaoId = setTimeout () ->
            console.info(obj)
            clearInterval(obj.intervaloRepeticaoId)
            obj.intervaloRepeticaoId = null
            clearTimeout(obj.timeoutRepeticaoId)
            obj.timeoutRepeticaoId = null
            obj._paradoEm = new Date()
            if obj.onStop
              obj.onStop()
            return
          , obj.timeout
          return
        , 500
      setTimeout () ->
        response.send "Ok. Iniciando."
        return
      , 100
      return

    parar: (isChamadaInterna) ->
      if !isChamadaInterna
        @_paradoEm = new Date()

      if @intervaloRepeticaoId
        clearInterval(@intervaloRepeticaoId)
        @intervaloRepeticaoId = null
      if @timeout
        clearTimeout(@timeoutRepeticaoId)
        @timeoutRepeticaoId = null

      return

    _hash: (valArr) ->
      hash = 0
      for val in valArr
        do (val) ->
          _val = val + ""
          if (_val.length)
            for char in _val
              do (char) ->
                charCode = char.charCodeAt(0)
                hash  = ((hash << 5) - hash) + charCode
                hash |= 0 # Convert to 32bit integer
          return
      return hash;

    hash: ->
      return this._hash([
        @repeticoes,
        @intervalo,
        @timeout,
        @texto
      ])

    isRodando: ->
      return !@_paradoEm

    toString: ->
      return "[repeticões=#{@repeticoes}, intervalo=#{@intervalo} milisegundos, salas= #{@salas}, texto= '#{@texto}']"

  class RepeticaoSet
    @_hashSet
    @_keyList
    constructor: ->
      @_hashSet = {}
      @_keyList = []
    get: (hash) ->
      return @_hashSet[hash]
    put: (value) ->
      if (this.contains(value))
        return false
      key = value.hash()
      @_keyList.push(key)
      @_hashSet[key] = value
      return true
    remove: (value) ->
      if (!this.contains(value))
        return false
      key = value.hash()
      @_hashSet[key].parar()
      @_keyList.splice(@_keyList.indexOf(key), 1)
      @_hashSet[key] = undefined
      return true
    contains: (value) ->
      return !!@_hashSet[value.hash()]
    values: ->
      values = []
      for key, value of @_hashSet
        if (!key || !value)
          continue
        if value.isRodando()
          values.push(value)
        else
          this.remove value
      return values
    size: ->
      return @_keyList.length




  listarRepeticoes = (response) ->
    if !repeticoes.size()
      response.send "Não estou repetindo nada no momento."
      return

    setTimeout () ->
      response.send "Estou repetindo isto:"
      return
    , 250
    pilha = []
    for i, rep of repeticoes.values()
      chave = i*1+1
      pilha.push({chave:chave, texto: rep.toString()})
      repeticoesListadas[chave] = rep
    pilha = pilha.reverse()
    for i in [1..pilha.length]
      setTimeout ()->
        o = pilha.pop();
        response.send "#{o.chave}. #{o.texto}"
        return
      , i * 750
    return

  persistir = ->
    robot.brain.set 'repeticoes', repeticoes
    robot.brain.set 'repeticoesListadas', repeticoesListadas
    robot.brain.set 'salas', salas
    return

  carregar = ->
    repeticoes = robot.brain.get 'repeticoes'
    if !repeticoes
      repeticoes = new RepeticaoSet()
    repeticoesListadas = robot.brain.get 'repeticoesListadas'
    if !repeticoesListadas
      repeticoesListadas = {}
    #noinspection JSUnresolvedVariable
    if process.env.HUBOT_SALAS_PARA_REPETICAO
      salas = process.env.HUBOT_SALAS_PARA_REPETICAO
    else
      salas = robot.brain.get 'salas'
    return
    #TODO:break implementar carga no objeto repeticao

  carregar()