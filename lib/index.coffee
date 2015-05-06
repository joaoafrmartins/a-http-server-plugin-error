configFn = require 'a-http-server-config-fn'

module.exports = (next) ->

  configFn @config, "#{__dirname}/config"

  config = @config.plugins.error

  error = (options) ->

    err = { status: 500, message: config.status['500'] }

    if typeof options is "number"

      err.status = options

      err.message =  config.status[options]

    else

      err = options

    err

  Object.defineProperty @, "error", value: { define: error }

  Object.keys(config?.errors or {}).map (name) =>

    Object.defineProperty @error, name,

      get: =>

        err = error name

        err = new Error err.message

        err.name = name

        err.status = err.status

        err

  @app.use (err, req, res, next) =>

    err = error err.name

    res.send err.status, err.message

  process.on "a-http-server:started", () =>

    errors = @config.plugins.error.errors

    Object.keys(errors or {}).map (name) =>

      @error.define errors[name]

  process.on "a-http-server:shutdown:dettach", () =>

    process.emit "a-http-server:shutdown:dettached", "error"

  process.emit "a-http-server:shutdown:attach", "error"

  next null
