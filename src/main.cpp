#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

#define LED_PIN 14

Adafruit_MPU6050 mpu;

void setup() {

    pinMode(LED_PIN, OUTPUT);

    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("INICIANDO MPU6050...");

    // SDA = 32 | SCL = 33
    Wire.begin(32, 33);

    if (!mpu.begin()) {

        Serial.println("ERRO: MPU6050 NAO ENCONTRADO!");

        while (1) {

            digitalWrite(LED_PIN, HIGH);
            delay(150);

            digitalWrite(LED_PIN, LOW);
            delay(150);
        }
    }

    Serial.println("MPU6050 CONECTADO!");
    Serial.println("----------------------------");

    digitalWrite(LED_PIN, HIGH);
    delay(500);
    digitalWrite(LED_PIN, LOW);

    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}
void loop() {

    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // eixo Y puro
    float ay = a.acceleration.y;

    // remove gravidade base
    float movimento = ay + 0.20;

    // intensidade real
    float intensidade = abs(movimento);

    Serial.print("Y REAL: ");
    Serial.println(movimento);

    static unsigned long ultimoMovimento = 0;

    unsigned long agora = millis();

    // =========================
    // ANTI-SPAM
    // =========================
    if (agora - ultimoMovimento < 600) {
        delay(15);
        return;
    }

    // =========================
    // MOVIMENTO LEVE
    // =========================
    if (intensidade > 2.2 && intensidade < 4.5) {

        Serial.println("BTN_SQUARE");

        digitalWrite(LED_PIN, HIGH);
        delay(70);
        digitalWrite(LED_PIN, LOW);

        ultimoMovimento = agora;
    }

    // =========================
    // MOVIMENTO FORTE
    // =========================
    else if (intensidade >= 4.5) {

        Serial.println("BTN_SQUARE_DOUBLE");

        // blink forte
        for (int i = 0; i < 2; i++) {

            digitalWrite(LED_PIN, HIGH);
            delay(70);

            digitalWrite(LED_PIN, LOW);
            delay(120);
        }

        ultimoMovimento = agora;
    }

    delay(15);
}