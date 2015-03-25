module.exports = (robot) ->

  repeticoes = null
  repeticoesListadas = null

  respond = (regexp, callback) ->
    robot.respond regexp, (response) ->
      carregar(response)
      callback(response)
      persistir()
      return
    return


  internalRespondIntervalo = (tipoInicio, response, opcoes) ->
    intervalo = 0
    grandeza = response.match[4]
    switch grandeza
      when 'minutos','minuto' then intervalo = 60*1000
      when 'segundos','segundo' then intervalo = 1000
      when 'horas','hora' then intervalo = 60*60*1000
      when 'dias', 'dia' then intervalo = 24*60*60*1000
      else
        response.send "opa, vc usou #{grandeza}. Tente novamente usando segundos, minutos, horas ou dias ;) "
        return

    opcoes['intervalo'] = intervalo * Number(response.match[3])
    if opcoes['repeticoes']
      opcoes['timeout'] = Number(opcoes['intervalo']) * Number(opcoes['repeticoes'])
    opcoes['texto'] = response.match[5]

    findSala = new RegExp('[ ]*na[ ]*sala[ ]*([^ ]*)[ ]*(.*)')
    result = findSala.exec(opcoes['texto'])
    if result
      opcoes['sala'] = result[1]
      opcoes['texto'] = result[2]
    else
      opcoes['sala'] = response.envelope.room

    repeticao = new Repeticao opcoes

    if repeticoes.put repeticao
      repeticao.onStop = ->
        repeticoes.remove repeticao
        return
      repeticao[tipoInicio] false, response
    else
      response.send "Esta repetição já existe."
      listarRepeticoes response
    return

    return

  respond /.*id.*sala[^?]*[?]/i, (response) ->
    response.send response.envelope.room
    return

  respond /repita[ ]*entre[ ]*([0-9]{1,2}:[0-9]{1,2})[ ]*e[ ]*([0-9]{1,2}:[0-9]{1,2})[ ]*em[ ]*intervalos[^0-9]*([0-9]{1,5})[ ]*([a-z]*)(.*)/i, (response) ->

    obj =
      periodo : new Periodo(response.match[1], response.match[2])

    internalRespondIntervalo('iniciarPorPeriodo', response, obj)

    return


  respond /repita[^0-9]*([0-9]{1,5})[ ]*(vezes|vez)[ ]*em[ ]*intervalos[^0-9]*([0-9]{1,5})[ ]*([a-z]*)(.*)/i, (response) ->

    qtdRepeticoes = response.match[1]
#    if qtdRepeticoes > 1
#      qtdRepeticoes--

    obj =
      repeticoes: qtdRepeticoes

    internalRespondIntervalo('iniciarPorIntervalo', response, obj)

    return


  respond /.*(repetindo)[^?]*[?]/i, (response) ->
    listarRepeticoes response
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


  class Periodo

    constructor: (horaInicioStr, horaFimStr) ->
      @dateTimeInicio = if horaInicioStr instanceof Date then horaInicioStr else @_parseDate horaInicioStr.split(':')
      @dateTimeFim = if horaFimStr instanceof Date then horaFimStr else @_parseDate horaFimStr.split(':')
      return

    _parseDate: (arr) ->
      return new Date(71, 1, 1, arr[0], arr[1], 0, 0)

    isDentroPeriodo: (date) ->
      if !date
        date = new Date()
      agora = @_parseDate([date.getHours(), date.getMinutes()])
      return @dateTimeInicio.getTime() <= agora.getTime() && agora.getTime() < @dateTimeFim.getTime()

    toString: ->
      return "[inicio= #{@dateTimeInicio.toTimeString()}, fim= #{@dateTimeFim.toTimeString()}]"

    toJSON: ->
      return {dateTimeInicio:@dateTimeInicio.toJSON(), dateTimeFim:@dateTimeFim.toJSON()}


  class Repeticao

    @_iniciadoEm = 0
    @_paradoEm = 0
    @onStop = null

    constructor: (options) ->
      @repeticoes = options['repeticoes']
      @intervalo = options['intervalo']
      @timeout = options['timeout']
      @texto = options['texto']
      @sala = options['sala']
      @periodo = options['periodo']
      @_construidoEm = (new Date()).getTime()
      return


    iniciarPorPeriodo:(isReinicio, response) ->

      @_iniciadoEm = (new Date()).getTime()
      @.parar true #isChamadaInterna

      _this = @
      setTimeout () ->

        # Primeiro envio de confirmação para o usuário
        if isReinicio != true
          if (response && response.envelope.room == _this.sala &&_this.periodo.isDentroPeriodo()) ||
              (response && response.envelope.room != _this.sala)
            if response
              response.send 'Certo.'
            else
              robot.messageRoom _this.sala, _this.texto

        _this.intervaloRepeticaoId = setInterval () ->
          if _this.periodo.isDentroPeriodo()
            robot.messageRoom _this.sala, _this.texto
          return
        , _this.intervalo
      , 500

      return


    iniciarPorIntervalo: (isReinicio) ->

      @_iniciadoEm = (new Date()).getTime()
      @.parar true #isChamadaInterna

      _this = @
      setTimeout () ->

        if isReinicio != true
          robot.messageRoom _this.sala, _this.texto

        _this.intervaloRepeticaoId = setInterval () ->
          robot.messageRoom _this.sala, _this.texto
          return
        , _this.intervalo

        _this.timeoutRepeticaoId = setTimeout () ->
          clearInterval(_this.intervaloRepeticaoId)
          _this.intervaloRepeticaoId = null
          clearTimeout(_this.timeoutRepeticaoId)
          _this.timeoutRepeticaoId = null
          _this._paradoEm = (new Date()).getTime()
          if _this.onStop
            _this.onStop()
          return
        , _this.timeout
        return
      , 500
      return


    reiniciar: () ->
      if (@timeout)
        @._reiniciarPorIntervalo()
      else if (@periodo)
        @._reiniciarPorPeriodo()
      else
        robot.logger.error("Repeticao.reiniciar: impossível distinguir sobre intervalo ou periodo. #{@.toString()}")
      return

    _reiniciarPorPeriodo: () ->
      @.iniciarPorPeriodo(true)
      return

    _reiniciarPorIntervalo: () ->
      @timeout = @_iniciadoEm + @timeout - (new Date()).getTime();
      if @timeout <= 0
        @timeout = 0
        return
      @repeticoes = Math.ceil(@timeout / @intervalo)
      @.iniciarPorIntervalo(true)
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
      return @._hash([
        @repeticoes,
        @intervalo,
        @timeout,
        @texto,
        @sala,
        @periodo
      ])


    isRodando: ->
      return (@timeout||@periodo) && !@_paradoEm

    isPeriodo: ->
      return !!@periodo

    toString: ->
      if (@repeticoes)
        return "[repeticões=#{@repeticoes}, intervalo=#{@intervalo} milisegundos, sala= '#{@sala}' texto= '#{@texto}']"
      else if(@periodo)
        return "[periodo=#{@periodo}, intervalo=#{@intervalo} milisegundos, sala= '#{@sala}', texto= '#{@texto}']"
      else
        return "[intervalo=#{@intervalo} milisegundos, sala= '#{@sala}', texto= '#{@texto}']"



  class RepeticaoSet
    @_hashSet
    @_keyList
    constructor: ->
      @_hashSet = {}
      @_keyList = []
    get: (hash) ->
      return @_hashSet[hash]
    put: (value) ->
      if (@.contains(value))
        return false
      key = value.hash()
      @_keyList.push(key)
      @_hashSet[key] = value
      return true
    remove: (value) ->
      if (!@.contains(value))
        return false
      key = value.hash()
      @_hashSet[key].parar()
      @_keyList.splice(@_keyList.indexOf(key), 1)
      @_hashSet[key] = undefined
      return true
    contains: (value) ->
      if !value
        return false
      return !!@_hashSet[value.hash()]
    values: ->
      values = []
      for key, value of @_hashSet
        if (!key || !value)
          continue
        if value.isRodando()
          values.push(value)
        else
          @.remove value
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
            sala: repeticao.sala,
            periodo: if repeticao.periodo then repeticao.periodo.toJSON() else null,
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

    return


  isCarregado = false;

  carregar = (response) ->

#    robot.brain.set 'repeticoes', undefined
#    robot.brain.set 'repeticoesListadas', undefined

    if isCarregado
      return

    fetch = (arr, f) ->
      if !arr || arr.length == 0
        return
      for dado in arr
        if (!dado.timeout && !(dado.periodo && dado.periodo.dateTimeInicio && dado.periodo.dateTimeFim))
          continue

        opcoes =
          repeticoes: dado.repeticoes
          intervalo :dado.intervalo
          timeout: dado.timeout
          texto: dado.texto
          sala: dado.sala
          periodo:
            if dado.periodo
              new Periodo(new Date(dado.periodo.dateTimeInicio), new Date(dado.periodo.dateTimeFim))
            else
              null
        rep = new Repeticao opcoes
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

    isCarregado = true
    return

