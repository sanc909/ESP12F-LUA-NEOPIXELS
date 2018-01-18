# ESP8266-ESP12F-LUA-NEOPIXELS
IOT:  Lua Script serves webpage which allows control of a 12 Neopixel ring  OR connection to Weather Underground for DATA

[![ESP8266-ESP12F-LUA-NEOPIXELS](http://img.youtube.com/vi/zxBsWhdXvhw/0.jpg)](https://youtu.be/zxBsWhdXvhw "ESP8266-ESP12F-LUA-NEOPIXELS")

Lua script runs under NodeMCU. ESP12F starts in station mode, User connects to SSID and browses to 192.168.4.1.

Two operating modes<br>
<b>1.</b> Initial standalone Wifi Station. Serves webpage via 192.168.4.1 and allows control of NeoPixel ring of Leds <br>
   User selects colour,<br>
   Which LEDs to light,<br>
   Direction(Clockwise or Anti-Clockwise)<br>
   Speed - transition speed  (ms)<br>
   and <b>Mode:</b><br>
   Loop - spins leds round display<br>
   Fade = Leds fade in and out<br>
   Step - move one LED at a time.<br>
   or IOT (Internet of Things)<br>

<b>2.</b>Select the IOT on the webpage.<br>
   This opens a form to specify an internet connected Wifi<br>
   Form allows you to specify City and Country Code<br>
   Form allows choice of displaying local time or temperature<br>
   Time and Weather from location is displayed on NeoPixel Ring.<br>
   Uses the Weather Underground API so API key needs to be added to code.<br>

Video shows running on nodemcu.
