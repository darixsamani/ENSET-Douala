#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <Servo.h>
#include <EEPROM.h>

// ===================== ECRAN LCD I2C =====================
LiquidCrystal_I2C lcd(0x20, 16, 2);

// ===================== CLAVIER MATRICIEL 4x4 =====================
const byte LIGNES = 4;
const byte COLONNES = 4;

char touches[LIGNES][COLONNES] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};

byte brochesLignes[LIGNES]   = {9, 8, 7, 6};   // R1, R2, R3, R4
byte brochesColonnes[COLONNES] = {5, 4, 3, A3}; // C1, C2, C3, C4

Keypad clavier = Keypad(makeKeymap(touches), brochesLignes, brochesColonnes, LIGNES, COLONNES);

// ===================== SERVOMOTEUR (VERROU) =====================
Servo servoVerrou;
const int pinServo = 10;
const int angleFerme = 0;
const int angleOuvert = 90;

// ===================== BUZZER ET LEDs =====================
const int pinBuzzer = 11;
const int pinLedRouge = 12;
const int pinLedVerte = 13;

// ===================== CAPTEUR ULTRASON (DETECTION DE PRESENCE) =====================
const int pinTrigger = A0;
const int pinEcho = A1;
const int seuilDetectionCm = 15; // Distance en dessous de laquelle on considère une présence

// ===================== GESTION DU CODE PIN EN EEPROM =====================
// Adresses EEPROM 0 à 3 : code PIN à 4 chiffres (un octet par chiffre)
const int adresseEEPROM = 0;
const byte tailleCode = 4;
char codeSaisi[tailleCode + 1]; // +1 pour le caractère de fin de chaîne
byte indexSaisie = 0;

// Code PIN par défaut, écrit en EEPROM uniquement si elle est vierge (première utilisation)
char codeParDefaut[tailleCode + 1] = "1234";

void setup() {
  Serial.begin(9600);

  // --- Initialisation LCD ---
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("CONTROLE ACCES");
  lcd.setCursor(0, 1);
  lcd.print("Initialisation..");
  delay(1500);

  // --- Initialisation Servo (verrou fermé par défaut) ---
  servoVerrou.attach(pinServo);
  servoVerrou.write(angleFerme);

  // --- Initialisation des sorties ---
  pinMode(pinBuzzer, OUTPUT);
  pinMode(pinLedRouge, OUTPUT);
  pinMode(pinLedVerte, OUTPUT);
  pinMode(pinTrigger, OUTPUT);
  pinMode(pinEcho, INPUT);

  digitalWrite(pinLedRouge, HIGH); // LED rouge = système verrouillé/au repos
  digitalWrite(pinLedVerte, LOW);

  // --- Initialisation du code PIN en EEPROM (si première utilisation) ---
  initialiserCodeEEPROM();

  afficherEcranAttente();
}

void loop() {
  // 1. Détection de présence par ultrason (simule l'approche d'un badge/utilisateur)
  long distance = mesurerDistanceCm();

  if (distance > 0 && distance < seuilDetectionCm) {
    demarrerSaisieCode();
  }

  // 2. Lecture du clavier si une saisie est en cours
  char touche = clavier.getKey();
  if (touche) {
    gererTouche(touche);
  }
}

// ===========================================================
//                  FONCTIONS DE MESURE ULTRASON
// ===========================================================
long mesurerDistanceCm() {
  digitalWrite(pinTrigger, LOW);
  delayMicroseconds(2);
  digitalWrite(pinTrigger, HIGH);
  delayMicroseconds(10);
  digitalWrite(pinTrigger, LOW);

  long duree = pulseIn(pinEcho, HIGH, 30000); // timeout 30 ms
  long distance = duree * 0.034 / 2; // vitesse du son ~340 m/s
  return distance;
}

// ===========================================================
//                  GESTION DE LA SAISIE DU CODE
// ===========================================================
void demarrerSaisieCode() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Entrez le code:");
  lcd.setCursor(0, 1);
  indexSaisie = 0;
  memset(codeSaisi, 0, sizeof(codeSaisi));

  bip(50); // léger bip pour signaler la détection de présence
}

void gererTouche(char touche) {
  // Touche '*' : annuler la saisie en cours
  if (touche == '*') {
    afficherEcranAttente();
    return;
  }

  // Touche '#' : valider le code saisi
  if (touche == '#') {
    verifierCode();
    return;
  }

  // Sinon, on enregistre le chiffre saisi (dans la limite de 4 chiffres)
  if (indexSaisie < tailleCode) {
    codeSaisi[indexSaisie] = touche;
    indexSaisie++;
    lcd.setCursor(indexSaisie - 1, 1);
    lcd.print('*'); // masquage du chiffre saisi à l'écran
    bip(20);
  }
}

// ===========================================================
//             VERIFICATION DU CODE ET PILOTAGE DU VERROU
// ===========================================================
void verifierCode() {
  char codeEnregistre[tailleCode + 1];
  lireCodeEEPROM(codeEnregistre);

  if (strncmp(codeSaisi, codeEnregistre, tailleCode) == 0) {
    accesAutorise();
  } else {
    accesRefuse();
  }
}

void accesAutorise() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("ACCES AUTORISE");

  digitalWrite(pinLedRouge, LOW);
  digitalWrite(pinLedVerte, HIGH);
  bip(100);

  servoVerrou.write(angleOuvert); // déverrouillage
  delay(3000);                    // maintien ouvert 3 secondes
  servoVerrou.write(angleFerme);  // reverrouillage automatique

  digitalWrite(pinLedVerte, LOW);
  digitalWrite(pinLedRouge, HIGH);

  afficherEcranAttente();
}

void accesRefuse() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("ACCES REFUSE");

  // Triple bip d'alerte
  for (int i = 0; i < 3; i++) {
    bip(150);
    delay(150);
  }

  delay(1000);
  afficherEcranAttente();
}

void afficherEcranAttente() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Approchez-vous");
  lcd.setCursor(0, 1);
  lcd.print("pour entrer code");
  indexSaisie = 0;
}

// ===========================================================
//                   GESTION DU BUZZER
// ===========================================================
void bip(int dureeMs) {
  digitalWrite(pinBuzzer, HIGH);
  delay(dureeMs);
  digitalWrite(pinBuzzer, LOW);
}

// ===========================================================
//                 GESTION DU CODE PIN EN EEPROM
// ===========================================================
void initialiserCodeEEPROM() {
  // Vérifie si l'EEPROM contient déjà un code valide (caractères numériques)
  bool codeValide = true;
  for (int i = 0; i < tailleCode; i++) {
    char c = EEPROM.read(adresseEEPROM + i);
    if (c < '0' || c > '9') {
      codeValide = false;
      break;
    }
  }

  // Si aucun code valide n'est trouvé, on écrit le code par défaut
  if (!codeValide) {
    for (int i = 0; i < tailleCode; i++) {
      EEPROM.write(adresseEEPROM + i, codeParDefaut[i]);
    }
  }
}

void lireCodeEEPROM(char* destination) {
  for (int i = 0; i < tailleCode; i++) {
    destination[i] = EEPROM.read(adresseEEPROM + i);
  }
  destination[tailleCode] = '\0';
}
