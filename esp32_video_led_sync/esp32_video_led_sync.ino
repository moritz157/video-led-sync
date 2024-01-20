/*
 * WebSocketServer.ino
 *
 *  Created on: 22.05.2015
 *
 */

#include <Arduino.h>

#include <WiFi.h>
#include <ESPmDNS.h>
#include <WiFiClient.h>
#include <WiFiAP.h>

#include <Adafruit_NeoPixel.h>

#include <WebSocketsServer.h>

WebSocketsServer webSocket = WebSocketsServer(81);

#define USE_SERIAL Serial

#define NEOPIXEL_PIN 12
#define NUMPIXELS 10



// #define AP_MODE

#ifdef AP_MODE 
  const char* ssid = "VideoLEDSync";
  const char* password = "videoledsync";
#else
  const char* ssid = "****";
  const char* password = "*****";
#endif

// TCP server at port 80 will respond to HTTP requests
WiFiServer server(80);

Adafruit_NeoPixel pixels(NUMPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

void hexdump(const void *mem, uint32_t len, uint8_t cols = 16) {
  const uint8_t* src = (const uint8_t*) mem;
  USE_SERIAL.printf("\n[HEXDUMP] Address: 0x%08X len: 0x%X (%d)", (ptrdiff_t)src, len, len);
  for(uint32_t i = 0; i < len; i++) {
    if(i % cols == 0) {
      USE_SERIAL.printf("\n[0x%08X] 0x%08X: ", (ptrdiff_t)src, i);
    }
    USE_SERIAL.printf("%02X ", *src);
    src++;
  }
  USE_SERIAL.printf("\n");
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {

    switch(type) {
        case WStype_DISCONNECTED:
            USE_SERIAL.printf("[%u] Disconnected!\n", num);
            break;
        case WStype_CONNECTED:
            {
                IPAddress ip = webSocket.remoteIP(num);
                USE_SERIAL.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);

        // send message to client
        webSocket.sendTXT(num, "Connected");
            }
            break;
        case WStype_TEXT:
            USE_SERIAL.printf("[%u] get Text: %s\n", num, payload);

            // send message to client
            // webSocket.sendTXT(num, "message here");

            // send data to all connected clients
            // webSocket.broadcastTXT("message here");
            break;
        case WStype_BIN:
            //USE_SERIAL.printf("[%u] get binary length: %u\n", num, length);
            //hexdump(payload, length);
            if(length>=3) {
                const uint8_t red = *payload;
                const uint8_t green = *(payload+1);
                const uint8_t blue = *(payload+2);
                /**Serial.print(red);
                Serial.print(" ");
                Serial.print(green);
                Serial.print(" ");
                Serial.println(blue);*/

                for(int i=0; i<NUMPIXELS; i++) {
                  pixels.setPixelColor(i, pixels.Color(red, green, blue));
                }
                pixels.show(); 
            }

            // send message to client
            // webSocket.sendBIN(num, payload, length);
            break;
    case WStype_ERROR:      
    case WStype_FRAGMENT_TEXT_START:
    case WStype_FRAGMENT_BIN_START:
    case WStype_FRAGMENT:
    case WStype_FRAGMENT_FIN:
      break;
    }

}

void setup() {
    Serial.begin(115200);

    pixels.begin();
    pixels.clear();
    for(int i=0; i<NUMPIXELS; i++) {
      pixels.setPixelColor(i, pixels.Color(255, 0, 0));
    }
    pixels.show();

        Serial.begin(115200);

    #ifdef AP_MODE
      if (!WiFi.softAP(ssid, password)) {
        log_e("Soft AP creation failed.");
        while(1);
      }
      IPAddress myIP = WiFi.softAPIP();
      Serial.print("AP IP address: ");
      Serial.println(myIP);
    #else
      // Connect to WiFi network
      WiFi.begin(ssid, password);
      Serial.println("");
  
      // Wait for connection
      while (WiFi.status() != WL_CONNECTED) {
          delay(500);
          Serial.print(".");
      }
      Serial.println("");
      Serial.print("Connected to ");
      Serial.println(ssid);
      Serial.print("IP address: ");
      Serial.println(WiFi.localIP());
    #endif
    

   

    // Set up mDNS responder:
    // - first argument is the domain name, in this example
    //   the fully-qualified domain name is "esp32.local"
    // - second argument is the IP address to advertise
    //   we send our IP address on the WiFi network
    if (!MDNS.begin("esp32")) {
        Serial.println("Error setting up MDNS responder!");
        while(1) {
            delay(1000);
        }
    }
    Serial.println("mDNS responder started");

    // Start TCP (HTTP) server
    server.begin();
    Serial.println("TCP server started");

    // Add service to MDNS-SD
    MDNS.addService("videoledsync", "tcp", 80);

    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
}

void loop() {
    webSocket.loop();
}

byte inputArray[] = {0, 0, 0, 0};
int inputArrayReadIndex = 0;
void serialEvent() {
  while (Serial.available()) {
    inputArray[inputArrayReadIndex] = (byte)Serial.read();
    inputArrayReadIndex++;
    if (inputArrayReadIndex == 4) {
      Serial.println("done");
      for(int i = 0; i<sizeof(inputArray); i++) {
        Serial.print(inputArray[i]);
        Serial.print(" ");
      }
      Serial.println();
      
      for(int i=0; i<NUMPIXELS; i++) {
        pixels.setPixelColor(i, pixels.Color(inputArray[0], inputArray[1], inputArray[2]));
      }
      pixels.show(); 
      
      inputArrayReadIndex = 0;
    }
  }
}
