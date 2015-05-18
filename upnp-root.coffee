# #FroniusSolar plugin

module.exports = (env) ->

# Require the bluebird promise library
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  net = require 'net'
  os = require 'os'
  http = require("http")
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
        if not _.isObject obj or not obj.hasOwnProperty key
          return false
        obj = obj[key]
      return true

    init: (app, @framework, @config) =>
      server = http.createServer();
      server.listen @config.port

      unless @config.uuid
        @config.uuid = @_getUUID()
        env.logger.debug "New Device UUID: " + @config.uuid

      presentationURL = @config.presentationURL
      unless presentationURL
        env.logger.warn "No presentationURL set"
        address = @_getAddress 'IPv4' || @_getAddress 'IPv6' || 'localhost'
        pConfig = require '../../config.json'
        if @_has pConfig, 'settings.httpServer.port'
          presentationURL = 'http://' + address + ':' + pConfig.settings.httpServer.port
        else if @_has pConfig, 'settings.httpsServer.port'
          presentationURL = 'https://' + address + ':' + pConfig.settings.httpsServer.port
        env.logger.warn "Using fallback: " + presentationURL if _.isString presentationURL

      pimaticVersion = require('../pimatic/package.json').version

      peer = upnp.createPeer({
        prefix: "/upnp",
        server: server
      })
      peer.on "ready", (peer) =>
        env.logger.debug("UPnP peer ready")
        device = peer.createDevice({
          autoAdvertise: true,
          root: false,
          deviceType: "upnp:rootdevice",
          uuid: @config.uuid,
          productName: "Pimatic",
          productVersion: pimaticVersion,
          domain: "schemas-upnp-org",
          version: "1",
          friendlyName: "Pimatic Smart Home",
          manufacturer: "Pimatic.org",
          manufacturerURL: "http://www.pimatic.org",
          modelName: "Pimatic Smart Home",
          modelDescription: "Pimatic is a home automation framework that runs on node.js",
          modelURL: "http://www.pimatic.org",
          modelNumber: pimaticVersion || "unknown",
          serialNumber: "",
#          icons: [{
#            url: "http://forum.pimatic.org/uploads/files/site-logo.jpg",
#            mimetype: "image/jpeg",
#            width: 102,
#            height: 99,
#            depth: 24
#          }]
          presentationURL: presentationURL || ""
        })

      peer.start()

  upnpPlugin = new UPnPRootPlugin
  # and return it to the framework.
  return upnpPlugin