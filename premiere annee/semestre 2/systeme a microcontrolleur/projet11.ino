#include <LiquidCrystal_I2C.h>

// Initialisation de l'écran LCD I2C (Adresse 0x20 pour Tinkercad, 16 colonnes, 2 lignes)
LiquidCrystal_I2C lcd(0x20, 16, 2);

const int pinTemperature = A0; // TMP36 connecté à A0
const int pinHumidite = A1;    // Potentiomètre connecté à A1

void setup() {
  // Initialisation de la communication série (pour le débogage)
  Serial.begin(9600);
  Serial.println("Initialisation du système...");

  // Initialisation du LCD
  lcd.init();
  lcd.backlight();
  
  // Message d'accueil sur le LCD
  lcd.setCursor(0, 0);
  lcd.print("STATION METEO");
  lcd.setCursor(0, 1);
  lcd.print("INTELLIGENTE");
  delay(2000);
  lcd.clear();
}

void loop() {
  // --- 1. Lecture et calcul de la Température (TMP36) ---
  int lectureA0 = analogRead(pinTemperature);
  // Conversion de la valeur brute (0-1023) en tension (0-5V)
  float tension = lectureA0 * (5.0 / 1023.0);
  // Conversion de la tension en degrés Celsius (Le TMP36 a un offset de 500mV)
  float temperature = (tension - 0.5) * 100.0;

  // --- 2. Lecture et calcul de l'Humidité (Potentiomètre) ---
  int lectureA1 = analogRead(pinHumidite);
  // On transforme la valeur (0-1023) en un pourcentage d'humidité (0-100%)
  int humidite = map(lectureA1, 0, 1023, 0, 100);

  // --- 3. Affichage dans le Moniteur Série (Vérification) ---
  Serial.print("Temp: ");
  Serial.print(temperature, 1);
  Serial.print(" C | Humidite: ");
  Serial.print(humidite);
  Serial.println(" %");

  // --- 4. Affichage sur le LCD ---
  // Ligne 1 : Température
  lcd.setCursor(0, 0);
  lcd.print("Temp: ");
  lcd.print(temperature, 1); // 1 chiffre après la virgule
  lcd.print(" C  ");

  // Ligne 2 : Humidité
  lcd.setCursor(0, 1);
  lcd.print("Humidite: ");
  lcd.print(humidite);
  lcd.print(" %   ");

  // Pause de 1 seconde avant la prochaine mise à jour
  delay(1000);
}