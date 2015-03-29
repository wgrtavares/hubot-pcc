expect = require('chai').expect
{Executable, Buffer, MonitorDeSala} = require "../src/monitor"


describe 'Monitor', ->

  before () ->

    return

  describe 'Estrutura de dados', ->
    it 'Testando tamanho do buffer', ->
      maxLengthBuffer = 3
      i = 0
      callback_ = ->
        i++
        return
      monitorDeSala_ = new MonitorDeSala()
      monitorDeSala_.execute = (cb) ->
        cb()
        return
      buffer_ = new Buffer(maxLengthBuffer, [monitorDeSala_])
      buffer_.put callback_ for j in [1..10]
      expect(i).to.equal(10)
      expect(buffer_).to.have.any.keys('queue')
      expect(buffer_.queue).to.length(maxLengthBuffer)
      return
    it 'Testando ordem de execução a cada put', ->
      class Message
        constructor: (@id) ->
      maxLengthBuffer = 3
      monitorDeSala = new MonitorDeSala()
      sequencia = []
      monitorDeSala.execute = (msg) ->
        sequencia.push(msg.id)
        return
      buffer = new Buffer(maxLengthBuffer, [monitorDeSala])
      for i in [1..3]
        buffer.put new Message i
      expect(sequencia).to.have.deep.property '[0]', 1
      expect(sequencia).to.have.deep.property '[1]', 2
      expect(sequencia).to.have.deep.property '[2]', 2
      buffer.put new Message 4
      expect(buffer.queue).to.have.deep.property '[0].id', 2
      expect(buffer.queue).to.have.deep.property '[1].id', 3
      expect(buffer.queue).to.have.deep.property '[2].id', 4
      expect(sequencia).to.have.deep.property '[3]', 3
      buffer.put new Message 5
      expect(buffer.queue).to.have.deep.property '[0].id', 3
      expect(buffer.queue).to.have.deep.property '[1].id', 4
      expect(buffer.queue).to.have.deep.property '[2].id', 5
      expect(sequencia).to.have.deep.property '[4]', 4
      return
    it 'Testando Monitor', ->

    return
  return