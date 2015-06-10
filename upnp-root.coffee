# #FroniusSolar plugin

module.exports = (env) ->

# Require the bluebird promise library
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  url = env.require('url')
  fs = env.require('fs')
  fpath = env.require('path')
  net = env.require 'net'
  os = env.require 'os'
  http = env.require("http")
  upnp = require("peer-upnp")

  # ###UPnPRootPlugin class
  class UPnPRootPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    #

    _getUUID: () ->
      _s4 = () ->
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
      return _s4() + _s4() + '-' + _s4() + '-' + _s4() + '-' + _s4() + '-' + _s4() + _s4() + _s4()

    _getAddress: (family) ->
      interfaces = os.networkInterfaces()
      for ifName of interfaces
        for networkIf in interfaces[ifName]
          if networkIf.family is family and not networkIf.internal
            return networkIf.address

    _has: (obj, path) ->
      return false if not _.isObject obj or not _.isString path
      keys = path.split '.'
      for key in keys
        if not _.isObject(obj) or not obj.hasOwnProperty(key)
          return false
        obj = obj[key]
      return true

    _serveIcon: (peer) ->
      peer.on "iconRequest", (pathname, response) =>
        env.logger.debug "Device icon requested: #{pathname}"

        fs.readFile fpath.normalize(__dirname + '/' + pathname), (error, data) =>
          unless error
            mimeType = 'image/png'
            if pathname.lastIndexOf('.jpg') >= 0
              mimeType = 'image/jpeg'
            else if pathname.lastIndexOf('.bmp') >= 0
              mimeType = 'image/bmp'

            response.writeHead(200, {'Content-Type': mimeType });
            response.end(data, 'binary');
          else
            env.logger.debug "Device icon error: #{error.toString()}"
            response.statusCode = 404;
            response.end("Not found");

    init: (app, @framework, @config) =>
      server = http.createServer()
      server.listen @config.port

      unless @config.uuid
        @config.uuid = @_getUUID()
        env.logger.debug "New Device UUID: " + @config.uuid

      presentationURL = @config.presentationURL
      unless presentationURL
        env.logger.warn "No presentationURL set"
        address = @_getAddress 'IPv4' || @_getAddress 'IPv6' || 'localhost'
        pConfig = @framework.config

        if @_has(pConfig, 'settings.httpsServer.enabled') and pConfig.settings.httpsServer.enabled
          presentationURL = 'https://' + address + ':' + (pConfig.settings.httpsServer.port || 443)
        else if @_has(pConfig, 'settings.httpServer')
          httpServer = pConfig.settings.httpServer
          if (if _.isBoolean(httpServer.enabled) then httpServer.enabled else true)
            presentationURL = 'http://' + address + ':' + (httpServer.port || 80)
        env.logger.warn "Using fallback: " + presentationURL if _.isString presentationURL

      pimaticVersion = require('../pimatic/package.json').version
      device = null
      peer = upnp.createPeer({
        prefix: "/upnp",
        server: server
      })
      @_serveIcon peer
      peer.on "ready", (peer) =>
        env.logger.debug("UPnP peer ready")
        device = peer.createDevice({
          autoAdvertise: false,
          root: true,
          deviceType: "urn:schemas-upnp-org:device:Basic:1.0",
          uuid: @config.uuid,
          productName: "Pimatic",
          productVersion: pimaticVersion,
          domain: "schemas-upnp-org",
          version: "1",
          friendlyName: @config.friendlyName,
          manufacturer: "Pimatic.org",
          manufacturerURL: "http://www.pimatic.org",
          modelName: "Pimatic Smart Home",
          modelDescription: "Pimatic is a home automation framework that runs on node.js",
          modelURL: "http://www.pimatic.org",
          modelNumber: pimaticVersion || "unknown",
          serialNumber: "",
          icons: [{
            url: "/icons/logo_app_icon.bmp",
            mimetype: "image/bmp",
            width: 48,
            height: 48,
            depth: 24
          },
          {
            url: "/icons/logo_app_icon.jpg",
            mimetype: "image/jpeg",
            width: 48,
            height: 48,
            depth: 24
          },
          {
            url: "/icons/logo_app_icon.png",
            mimetype: "image/png",
            width: 48,
            height: 48,
            depth: 24
          }]
          presentationURL: presentationURL || ""
        })
        device.advertise()

      peer.start()

  upnpPlugin = new UPnPRootPlugin
  # and return it to the framework.
  return upnpPlugin