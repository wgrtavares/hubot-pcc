expect = require('chai').expect

###Configuring test target###
{Executable, Buffer, MonitorDeSala} = require "../src/monitor"

###Global Vars###
buffers = null
robot =
  messageRoom: "Transforme esta string em uma função dentro dos testes"
monitor =
  regexp: 'teste$',
  salaMonitorada: 'chat#testeMonitorada',
  salaResposta: 'chat#testeResponsta',
  autores: ['Autor_Teste'],
  excetoAutores: ['Exceto_Autor_Teste']
bufferMaxLength = 10

describe 'Monitor', ->
  describe 'Estrutura de dados', ->
    describe 'Buffer', ->
      it 'Testando tamanho do buffer', ->
        maxLengthBuffer = 3
        i = 0
        monitorDeSala_ = new MonitorDeSala()
        monitorDeSala_.execute = (obj) ->
          i++
          return
        buffer_ = new Buffer(maxLengthBuffer, [monitorDeSala_])
        buffer_.put j for j in [1..10]
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
      return
    describe 'MonitorDeSala', ->
      beforeEach ->
        createBuffer = ->
          buffers_ = {}
          monitoresDados_ = [monitor]
          indicePorChat = {}
          for monitorDado_ in monitoresDados_
            indicePorChat[monitorDado_.salaMonitorada] = [] unless indicePorChat[monitorDado_.salaMonitorada]?
            indicePorChat[monitorDado_.salaMonitorada].push new MonitorDeSala robot, buffers_, monitorDado_.regexp,
              monitorDado_.salaMonitorada, monitorDado_.salaResposta, monitorDado_.autores, monitorDado_.excetoAutores
          for salaMonitorada_, monitoresDeSala_ of indicePorChat
            buffers_[salaMonitorada_] = new Buffer(bufferMaxLength, monitoresDeSala_)
          return buffers_
        buffers = createBuffer()
        return
      it '#execute() Happyday', ->
        expect(buffers).to.be.exists
        expect(robot).to.be.exists
        expect(robot).to.contains.keys('messageRoom')
        robot.messageRoom = (room, text) ->
          expect(text).to.equal('Autor_Teste: 1\nAutor_Teste: 2\nAutor_Teste: 3\nAutor_Teste: 4\nAutor_Teste: 5\n' +
              'Autor_Teste: teste\nAutor_Teste: 7\nAutor_Teste: 8\nAutor_Teste: 9\nAutor_Teste: 10\n')
          return
        buffer_ = buffers[monitor.salaMonitorada]
        expect(buffer_).to.be.exists
        envelopes = []
        envelopes.push {
          room: monitor.salaMonitorada
          user: monitor.autores[0]
          message: {text: "#{i}"}
        } for i in [1..bufferMaxLength]
        envelopes.splice Math.floor(bufferMaxLength/2), 1, {
          room: monitor.salaMonitorada
          user: monitor.autores[0]
          message: {text: 'teste'}
        }
        buffers[monitor.salaMonitorada].put envelope for envelope in envelopes
        return
      it '#execute() autores +', ->
        robot.messageRoom = (room, text) ->
          expect(text).to.equal('Wagner: teste 1\nWagner: teste 2\nWagner: teste 3\nWagner: teste 4\nWagner: ' +
              'teste 5\nAutor_Teste: teste\nWagner: teste 7\nWagner: teste 8\nWagner: teste 9\nWagner: teste 10\n')
          return
        envelopes = []
        envelopes.push {
          room: monitor.salaMonitorada
          user: 'Wagner'
          message: {text: 'teste ' + i}
        } for i in [1..bufferMaxLength+1]
        envelopes.splice Math.floor(bufferMaxLength/2), 1, {
          room: monitor.salaMonitorada
          user: monitor.autores[0]
          message: {text: 'teste'}
        }
        buffers[monitor.salaMonitorada].put(envelope) for envelope in envelopes
        return
      it '#execute() autores -', ->
        robot.messageRoom = (room, text) ->
          expect(text).to.not.exists
          return
        envelopes = []
        envelopes.push {
          room: monitor.salaMonitorada
          user: 'Wagner'
          message: {text: 'teste ' + i}
        } for i in [1..bufferMaxLength+1]
        buffers[monitor.salaMonitorada].put(envelope) for envelope in envelopes
        return
      it '#execute() excetoAutores +', ->
        robot.messageRoom = (room, text) ->
          expect(text).to.equal('Exceto_Autor_Teste: teste\nExceto_Autor_Teste: teste\nExceto_Autor_Teste: teste\n' +
              'Exceto_Autor_Teste: teste\nExceto_Autor_Teste: teste\nAutor_Teste: teste\nExceto_Autor_Teste: teste\n' +
              'Exceto_Autor_Teste: teste\nExceto_Autor_Teste: teste\nExceto_Autor_Teste: teste\n')
          return
        envelopes = []
        envelopes.push {
          room: monitor.salaMonitorada
          user: monitor.excetoAutores[0]
          message: {text: 'teste'}
        } for i in [1..bufferMaxLength+1]
        envelopes.splice Math.floor(bufferMaxLength/2), 1, {
          room: monitor.salaMonitorada
          user: monitor.autores[0]
          message: {text: 'teste'}
        }
        buffers[monitor.salaMonitorada].put(envelope) for envelope in envelopes
        return
      it '#execute() excetoAutores -', ->
        robot.messageRoom = (room, text) ->
          expect(text).to.not.exists
          return
        envelopes = []
        envelopes.push {
          room: monitor.salaMonitorada
          user: monitor.excetoAutores[0]
          message: {text: 'teste ' + i}
        } for i in [1..bufferMaxLength+1]
        buffers[monitor.salaMonitorada].put(envelope) for envelope in envelopes
        return
      return
    return
  return