errors = require 'errors'

configFn = require 'a-http-server-config-fn'

module.exports = (next) ->

  configFn @config, "#{__dirname}/config"

  config = @config.plugins.error

  if config.includeStack then errors.stacks(true)

  defineError = (statusCode, message, name) ->

    name ?= "AHttpServer#{statusCode}Error"

    if not errors.find(name)

      errors.create

        name: name

        status: statusCode

        defaultMessage: message

  Object.keys(@config.plugins.error.status).map (statusCode) =>

    message = @config.plugins.error.status[statusCode]

    defineError statusCode, message

  started = false

  process.on "a-http-server:started", () =>

    if started then return null

    started = true

    ["plugins", "components"].map (key) =>

      Object.keys(@config[key]).map (extension) =>

        if errs = @config[key][extension].errors

          Object.keys(errs).map (name) =>

            if typeof errs[name] is "object"

              { status, message } = errs[name]

            else if typeof errs[name] is "string"

              status = 500

              message = errs[name]

            defineError status, message, name

  process.on "a-http-server:shutdown:dettach", () =>

    process.emit "a-http-server:shutdown:dettached", "error"

  process.emit "a-http-server:shutdown:attach", "error"

  Object.defineProperty @, "error", value: errors

  next null
