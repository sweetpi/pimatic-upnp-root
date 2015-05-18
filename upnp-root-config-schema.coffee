module.exports = {
  title: "pimatic-upnp-root plugin config options"
  type: "object"
  properties:
    presentationURL:
      description: "The URL of the pimatic web application accessible from the local network, e.g. http://raspberrypi.fritz.box:80"
      type: "string"
    port:
        description: "The UPnP listener port for device queries"
        type: "number"
        default: 8008
    debug:
      description: "Debug mode. Writes debug message to the pimatic log"
      type: "boolean"
      default: false
}