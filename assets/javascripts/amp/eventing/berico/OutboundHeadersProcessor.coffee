define [
  '../../bus/berico/EnvelopeHelper'
  'uuid'
  'underscore'
  '../../util/Logger'
  '../../webstomp/topology/DefaultAuthenticationProvider'
  'jquery'
],
(EnvelopeHelper, uuid, _, Logger, DefaultAuthenticationProvider,$)->
  class OutboundHeadersProcessor
    userInfoRepo: null

    constructor: (config={})->
      {@authenticationProvider}=config

      unless _.isObject @authenticationProvider then @authenticationProvider = new DefaultAuthenticationProvider()

    processOutbound: (context)->

      deferred = $.Deferred()
      outboundDeferreds = []

      Logger.log.info "OutboundHeadersProcessor.processOutbound >> adding headers"
      env = new EnvelopeHelper(context.getEnvelope())

      messageId = if _.isString env.getMessageId() then env.getMessageId() else uuid.v4()
      env.setMessageId(messageId)

      correlationId = env.getCorrelationId()

      messageType = env.getMessageType()
      messageType = if _.isString messageType then messageType else @getMessageType context.getEvent()
      env.setMessageType messageType

      messageTopic = env.getMessageTopic()
      messageTopic = if _.isString messageTopic then messageTopic else @getMessageTopic context.getEvent()
      env.setMessageTopic messageTopic

      outboundDeferreds.push @getUsername(env.getSenderIdentity()).then (username)->
        env.setSenderIdentity username

      $.when.apply($,outboundDeferreds).done ->
        deferred.resolve()

      return deferred.promise()

    getUsername: (username)->
      deferred = $.Deferred()
      if _.isString username
        Logger.log.info "OutboundHeadersProcessor.getUsername >> using username from envelope: #{username}"
        deferred.resolve(username)
      else
        @authenticationProvider.getCredentials().then (data)->
          Logger.log.info "OutboundHeadersProcessor.getUsername >> using username from authenticationProvider: #{data.username}"
          deferred.resolve(data.username)
      return deferred.promise()
    getMessageType: (event)->
      type = Object.getPrototypeOf(event).constructor.name
      Logger.log.info "OutboundHeadersProcessor.getMessageType >> inferring type as #{type}"
      return type
    getMessageTopic: (event)->
      type = Object.getPrototypeOf(event).constructor.name
      Logger.log.info "OutboundHeadersProcessor.getMessageTopic >> inferring topic as #{type}"
      return type
  return OutboundHeadersProcessor