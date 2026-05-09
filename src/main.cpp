#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// ==============================================================
// PINOS
// ==============================================================
#define LED_PIN 14
#define SDA_PIN 32
#define SCL_PIN 33

// ==============================================================
// SENSIBILIDADE — ajuste se necessário
// CABECADA_LEVE  → BTN_SQUARE  (chute/cabeçada normal)
// CABECADA_FORTE → BTN_SQUARE_DOUBLE (finalização / chute forte)
// ==============================================================
#define CABECADA_LEVE_MIN  2.5f   // m/s² — abaixo disso ignora
#define CABECADA_LEVE_MAX  5.0f   // m/s² — entre aqui = cabeçada leve
#define CABECADA_FORTE_MIN 5.0f   // m/s² — acima disso = cabeçada forte
#define ANTI_SPAM_MS       600    // ms entre acionamentos

Adafruit_MPU6050 mpu;

void blink(int vezes, int ms = 80) {
    for (int i = 0; i < vezes; i++) {
        digitalWrite(LED_PIN, HIGH); delay(ms);
        digitalWrite(LED_PIN, LOW);  delay(ms);
    }
}

void setup() {
    pinMode(LED_PIN, OUTPUT);
    Serial.begin(115200);
    delay(500);

    Wire.begin(SDA_PIN, SCL_PIN);

    if (!mpu.begin()) {
        Serial.println("ERRO: MPU6050 nao encontrado!");
        while (1) blink(1, 150);
    }

    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

    Serial.println("MPU6050 OK — aguardando cabecada...");
    blink(3, 100);
}

void loop() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // Usa o vetor total de aceleração (X+Y+Z) descontando a gravidade (9.8)
    // Isso detecta qualquer direção de movimento brusco — ideal para cabeçada
    float ax = a.acceleration.x;
    float ay = a.acceleration.y;
    float az = a.acceleration.z;

    float total     = sqrt(ax*ax + ay*ay + az*az);
    float movimento = abs(total - 9.8f);   // remove componente da gravidade

    static unsigned long ultimoMovimento = 0;
    unsigned long agora = millis();

    // Anti-spam
    if (agora - ultimoMovimento < ANTI_SPAM_MS) {
        delay(10);
        return;
    }

    // ── CABEÇADA FORTE ────────────────────────────────────────
    if (movimento >= CABECADA_FORTE_MIN) {

        Serial.println("BTN_SQUARE_DOUBLE");

        for (int i = 0; i < 2; i++) {
            digitalWrite(LED_PIN, HIGH); delay(60);
            digitalWrite(LED_PIN, LOW);  delay(100);
        }

        ultimoMovimento = agora;
    }
    // ── CABEÇADA LEVE ─────────────────────────────────────────
    else if (movimento >= CABECADA_LEVE_MIN && movimento < CABECADA_LEVE_MAX) {

        Serial.println("BTN_SQUARE");

        digitalWrite(LED_PIN, HIGH); delay(60);
        digitalWrite(LED_PIN, LOW);

        ultimoMovimento = agora;
    }

    delay(10);
}