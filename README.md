# pimatic-upnp-root

[![npm version](https://badge.fury.io/js/pimatic-upnp-root.svg)](http://badge.fury.io/js/pimatic-upnp-root)

Pimatic UPnP Root-Device to advertise the Pimatic web interface on the Local Network. For example, this may be useful 
 for Windows users as the Pimatic device will show in the network view. Double-clicking the device will open
 the web interface using the default web browser.
 
![Network View](https://raw.githubusercontent.com/mwittig/pimatic-upnp-root/master/screenshots/screenshot-2.png)

## Configuration

You can load the plugin by editing your `config.json` to include the following in the `plugins` section. The property `
 presentationURL` specifies the URL of the pimatic web interface. If not set, a fallback will bet set. The property 
'friendlyName' set the friendly name of the device. It is set to "Pimatic Smart Home" by default. The property 
 'port' refers to the listener port of the UPnP peer to let other devices query the UPnP device description. The port is
 set to 8008 by default. Note, on first startup the plugin creates an unique identifier which will be stored as part
 of the configuration. A 'uuid' property will be added to the configuration file.

    { 
       "plugin": "upnp-root",
       "presentationURL": "http://raspberrypi.fritz.box",
       "friendlyName": "Pimatic Smart Home",
       "port": 8008
    }

## History

* 20150518, V0.0.1
    * Initial Version
* 20150522, V0.0.2
    * Fixed typos
    * Now using device type Basic:1.0 instead upnp:rootdevice
    * Fixed fallback code
* 20150528, V0.0.3
    * Added `friendlyName` property. Updated README.
* 20150609, V0.0.4 (release for testing, only)
    * Added device icons.
    * Now using a peer-upnp fork which handles icon requests
* 20150611, V0.0.5
    * Fixed icon path