#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <IRremote.h>

// --- Configuration de l'écran LCD (Met l'adresse de ton scanner ex: 0x27 ou 0x20)
LiquidCrystal_I2C lcd(0x20, 16, 2);

// --- Broches Matérielles ---
const int pinIR = 2;
const int pinPIR = 4;
const int pinTrig = 5;
const int pinEcho = 6;
const int pinLed = 7;
const int pinBuzzer = 8;

// --- Définition des États du Système ---
enum Etats {DESARME, ARME, ALERTE};
Etats etatActuel = DESARME;

// --- Variables de mesure ---
const int distanceSeuil = 100; // Seuil d'intrusion en cm (ex: 1 mètre)
unsigned long precedentMillis = 0;
bool etatLedFlash = false;

void setup() {
  Serial.begin(9600);
  
  // Initialisation des capteurs et actionneurs
  pinMode(pinPIR, INPUT);
  pinMode(pinTrig, OUTPUT);
  pinMode(pinEcho, INPUT);
  pinMode(pinLed, OUTPUT);
  pinMode(pinBuzzer, OUTPUT);
  
  // Initialisation IR et LCD
  IrReceiver.begin(pinIR, ENABLE_LED_FEEDBACK);
  lcd.init();
  lcd.backlight();
  
  afficherStatut();
}

void loop() {
  // 1. Gestion des commandes de la télécommande (Armement/Désarmement)
  if (IrReceiver.decode()) {
    // Bouton "Power" sur la télécommande Tinkercad
    if (IrReceiver.decodedIRData.command == 0x00) { 
      if (etatActuel == DESARME) {
        etatActuel = ARME;
        Bip(2); // Deux bips pour confirmer l'armement
      } else {
        etatActuel = DESARME;
        digitalWrite(pinLed, LOW);
        noTone(pinBuzzer);
        Bip(1); // Un long bip pour le désarmement
      }
      afficherStatut();
    }
    IrReceiver.resume();
  }

  // 2. Exécution de la logique selon l'état actuel
  switch (etatActuel) {
    case DESARME:
      // Rien à surveiller
      break;
      
    case ARME:
      // Surveillance active : Lecture des capteurs
      if (detecterMouvement() && calculerDistance() < distanceSeuil) {
        etatActuel = ALERTE;
        afficherStatut();
      }
      break;
      
    case ALERTE:
      // Comportement en cas d'intrusion : Clignotement et sirène
      unsigned long actuelMillis = millis();
      if (actuelMillis - precedentMillis >= 200) { // Cadence de 200ms
        precedentMillis = actuelMillis;
        etatLedFlash = !etatLedFlash;
        
        if (etatLedFlash) {
          digitalWrite(pinLed, HIGH);
          tone(pinBuzzer, 880); // Fréquence de la sirène
        } else {
          digitalWrite(pinLed, LOW);
          tone(pinBuzzer, 440);
        }
      }
      break;
  }
  delay(50); // Stabilité système
}

// --- Fonctions Utilitaires ---

long calculerDistance() {
  // Envoi d'une impulsion Trig de 10 microsecondes
  digitalWrite(pinTrig, LOW);
  delayMicroseconds(2);
  digitalWrite(pinTrig, HIGH);
  delayMicroseconds(10);
  digitalWrite(pinTrig, LOW);
  
  // Mesure de la durée de l'écho (temps de vol en microsecondes)
  long duree = pulseIn(pinEcho, HIGH);
  
  // Calcul de la distance en cm : (Vitesse du son 340m/s -> 0.034 cm/us) / 2 (aller-retour)
  long distance = duree * 0.034 / 2;
  return distance;
}

bool detecterMouvement() {
  return digitalRead(pinPIR);
}

void Bip(int nbre) {
  for (int i = 0; i < nbre; i++) {
    tone(pinBuzzer, 1000, 100);
    delay(150);
  }
}

void afficherStatut() {
  lcd.clear();
  lcd.setCursor(0, 0);
  if (etatActuel == DESARME) {
    lcd.print("SYSTEME: DISARM");
    lcd.setCursor(0, 1);
    lcd.print("Statut: Securise");
  } 
  else if (etatActuel == ARME) {
    lcd.print("SYSTEME: ARME");
    lcd.setCursor(0, 1);
    lcd.print("SURVEILLANCE...");
  } 
  else if (etatActuel == ALERTE) {
    lcd.print("!! INTRUSION !!");
    lcd.setCursor(0, 1);
    lcd.print("ALERTE GENERALE");
  }
}