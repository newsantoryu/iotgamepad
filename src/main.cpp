#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <math.h>

// =====================================================
// PINOS
// =====================================================
#define LED_PIN 14
#define SDA_PIN 32
#define SCL_PIN 33

// =====================================================
// WIFI
// =====================================================
const char* ssid     = "Victor - 2.4G-EXT";
const char* password = "07110589";

IPAddress host(192,168,15,65);
const int port = 4210;

WiFiUDP udp;

// =====================================================
// MPU6050
// =====================================================
Adafruit_MPU6050 mpu;

// =====================================================
// DETECÇÃO
// =====================================================
#define CABECADA_LEVE_MIN   2.5f
#define CABECADA_FORTE_MIN  5.0f
#define ANTI_SPAM_MS        600

unsigned long ultimoMovimento = 0;

// =====================================================
// LED
// =====================================================
void blink(int vezes, int tempo = 80)
{
    for (int i = 0; i < vezes; i++) {
        digitalWrite(LED_PIN, HIGH);
        delay(tempo);

        digitalWrite(LED_PIN, LOW);
        delay(tempo);
    }
}

// =====================================================
// SETUP
// =====================================================
void setup()
{
    Serial.begin(115200);
    delay(1000);

    pinMode(LED_PIN, OUTPUT);

    Serial.println();
    Serial.println("================================");
    Serial.println("ESP32 HEAD TRACKER WIFI");
    Serial.println("================================");

    // I2C
    Wire.begin(SDA_PIN, SCL_PIN);

    // MPU
    Serial.println("Inicializando MPU6050...");

    if (!mpu.begin()) {
        Serial.println("ERRO: MPU6050 nao encontrado!");

        while (true) {
            blink(1, 150);
        }
    }

    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

    Serial.println("MPU6050 OK!");

    // WIFI
    Serial.println("Conectando WiFi...");

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    int tentativas = 0;

    while (WiFi.status() != WL_CONNECTED) {

        delay(500);
        Serial.print(".");

        tentativas++;

        if (tentativas > 40) {
            Serial.println();
            Serial.println("Falha no WiFi!");
            ESP.restart();
        }
    }

    Serial.println();
    Serial.println("WiFi conectado!");
    Serial.print("IP ESP32: ");
    Serial.println(WiFi.localIP());

    udp.begin(port);

    Serial.println("Sistema pronto!");
    blink(3, 100);
}

// =====================================================
// LOOP
// =====================================================
void loop()
{
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    float ax = a.acceleration.x;
    float ay = a.acceleration.y;
    float az = a.acceleration.z;

    float total =
        sqrt((ax * ax) +
             (ay * ay) +
             (az * az));

    float movimento = fabs(total - 9.8f);

    unsigned long agora = millis();

    if (agora - ultimoMovimento < ANTI_SPAM_MS) {
        delay(10);
        return;
    }

    // =================================================
    // CABEÇADA FORTE
    // =================================================
    if (movimento >= CABECADA_FORTE_MIN)
    {
        Serial.println("CABECADA FORTE");

        udp.beginPacket(host, port);
        udp.print("BTN_SQUARE_DOUBLE");
        udp.endPacket();

        blink(2, 60);

        ultimoMovimento = agora;
    }

    // =================================================
    // CABEÇADA LEVE
    // =================================================
    else if (movimento >= CABECADA_LEVE_MIN)
    {
        Serial.println("CABECADA LEVE");

        udp.beginPacket(host, port);
        udp.print("BTN_SQUARE");
        udp.endPacket();

        blink(1, 60);

        ultimoMovimento = agora;
    }

    delay(10);
}