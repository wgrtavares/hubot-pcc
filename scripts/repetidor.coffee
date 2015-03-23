#noinspection JSUnresolvedVariable
module.exports = (robot) ->

  repeticoes = null
  repeticoesListadas = null
  salas = null

  respond = (regexp, callback) ->
    robot.respond regexp, (response) ->
      carregar()
      callback(response)
      persistir()
      return
    return

  respond /repita[^0-9]*([0-9]{1,5})[ ]*(vezes|vez)[ ]*em[ ]*intervalos[^0-9]*([0-9]{1,5})[ ]*([a-z]*)(.*)/i, (response) ->
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
      repeticao.iniciar response, robot.messageRoom
    else
      response.send "Esta repetição já existe."
      listarRepeticoes response
    return

  respond /.*(repetindo)[^?]*(salas|sala)[^?][?]/i, (response) ->
    if salas
      response.send "As repetições inicadas agora serão realizadas nas salas #{salas}."
    else
      response.send "Não existem salas configuradas no momento."
    return

  respond /.*(repetindo)[^?]*[?]/i, (response) ->
    listarRepeticoes response
    return

  respond /.*repita.*(salas|sala)[ :](.*)/i, (response) ->
    if response.match[2]
      salas = response.match[2]
      response.send "Ok. As salas de repetição agora são: " + salas
    else
      response.send "Não entendí em quais salas você quer que eu repita."
    return

  respond /.*(pare|cancele|parar|para).*(repetir|repeti..o)[^0-9]*([0-9]*)/i, (response) ->
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

  respond /qual o id dessa sala?/i, (response) ->
    response.send response.envelope.room
    return

  class Repeticao

    constructor: (repeticoes, intervalo, timeout, texto, salas) ->
      @repeticoes = repeticoes
      @intervalo = intervalo
      @timeout = timeout
      @texto = texto
      @salas = salas
      @_construidoEm = (new Date()).getTime()
      @_iniciadoEm = 0
      @_paradoEm = 0
      @onStop = null
      return

    iniciar: (response) ->

      @_iniciadoEm = (new Date()).getTime()
      this.parar true #isChamadaInterna

      if (!response)
        return

      setTimeout () ->
        response.send "Ok. Iniciando."
        return
      , 100

      obj = this
      _sala = @salas
#      for _sala in _salas
      setTimeout () ->
        obj._iniciadoEm = new Date()
        console.log(JSON.stringify(response.envelope))
        response.envelope = {room: _sala.toString()}
        response.send obj.texto

        obj.intervaloRepeticaoId = setInterval () ->
          console.log(obj.texto)
          response.send obj.texto
          return
        , obj.intervalo

        obj.timeoutRepeticaoId = setTimeout () ->
          clearInterval(obj.intervaloRepeticaoId)
          obj.intervaloRepeticaoId = null
          clearTimeout(obj.timeoutRepeticaoId)
          obj.timeoutRepeticaoId = null
          obj._paradoEm = (new Date()).getTime()
          if obj.onStop
            obj.onStop()
          return
        , obj.timeout
        return
      , 500
      return

    reiniciar: (response) ->
      @timeout = @_iniciadoEm + @timeout - (new Date()).getTime();
      if @timeout <= 0
        @timeout = 0
        return
      console.log("@timeout #{@timeout} / @intervalo #{@intervalo} / @_iniciadoEm #{@_iniciadoEm}")
      @repeticoes = Math.floor(@timeout / @intervalo)
      this.iniciar(response)
      return

    parar: (isChamadaInterna) ->
      if !isChamadaInterna
        @_paradoEm = (new Date()).getTime()

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
        @texto,
        @salas
      ])

    isRodando: ->
      return @timeout && !@_paradoEm

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

    fetch = (arrRepeticao) ->
      ret = []
      for repeticao in arrRepeticao
        ret.push(
          {
            repeticoes : repeticao.repeticoes,
            intervalo : repeticao.intervalo,
            timeout : repeticao.timeout,
            texto : repeticao.texto,
            salas : repeticao.salas,
            _construidoEm : repeticao._construidoEm,
            _iniciadoEm : repeticao._iniciadoEm,
            _paradoEm : repeticao._paradoEm
          }
        )
      ret
    robot.brain.set 'repeticoes', fetch repeticoes.values()
    robot.brain.set 'repeticoesListadas', fetch (
      for i, rep of repeticoesListadas
        rep.i = i
        rep
    )
    robot.brain.set 'salas', salas

    return

  isCarregado = false;

  carregar = (response) ->

#    robot.brain.set 'repeticoes', undefined
#    robot.brain.set 'repeticoesListadas', undefined
#    robot.brain.set 'salas', undefined

    if isCarregado
      return

    fetch = (arr, f) ->
      if !arr || arr.length == 0
        return
      for dado in arr
        if (!dado.timeout)
          continue
        rep = new Repeticao dado.repeticoes,
          dado.intervalo,
          dado.timeout,
          dado.texto,
          dado.salas
        rep._construidoEm = dado._construidoEm
        rep._iniciadoEm = dado._iniciadoEm
        rep._paradoEm = dado._paradoEm
        f rep
      return

    repeticoes = new RepeticaoSet
    fetch robot.brain.get('repeticoes'), (rep) ->
      rep.reiniciar(response)
      repeticoes.put(rep)
      return

    repeticoesListadas = {}
    fetch robot.brain.get('repeticoesListadas'), (rep) ->
      repeticoesListadas[rep.i] = rep
      return

    if process.env.HUBOT_SALAS_PARA_REPETICAO
      salas = process.env.HUBOT_SALAS_PARA_REPETICAO
    else
      salas = robot.brain.get 'salas'

    isCarregado = true
    return

