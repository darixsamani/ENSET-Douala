/**
 * PROJET 10 : VÉHICULE AUTONOME - ÉVITEMENT D'OBSTACLES
 * Navigation, Télémétrie Série et Machine à états finis
 */

// --- Broches HC-SR04 ---
const int pinTrig = A2;
const int pinEcho = A3;

// --- Broches L298N ---
const int ENA = 10; const int IN1 = 9; const int IN2 = 8; // Moteur Gauche
const int ENB = 5;  const int IN3 = 7; const int IN4 = 6; // Moteur Droit

// --- Broches IHM (RGB & Buzzer) ---
const int pinLedRouge = A0;
const int pinLedVerte = A1;
const int pinLedBleue = 4;
const int pinBuzzer   = 11;

// --- Paramètres de Navigation ---
const int DISTANCE_CRITIQUE = 25; // cm
const int VITESSE_MAX = 200;      // PWM 0-255
const int VITESSE_MANOEUVRE = 150;

// --- Machine à états ---
enum EtatRobot { ARRET, AVANCE, RECUL, ROTATION };
EtatRobot etatActuel = ARRET;

bool robotActive = false; // Remplacera le signal RF433
unsigned long chronoManoeuvre = 0;

void setup() {
  Serial.begin(9600);

  pinMode(pinTrig, OUTPUT); pinMode(pinEcho, INPUT);
  pinMode(ENA, OUTPUT); pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(ENB, OUTPUT); pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);

  pinMode(pinLedRouge, OUTPUT); pinMode(pinLedVerte, OUTPUT);
  pinMode(pinLedBleue, OUTPUT); pinMode(pinBuzzer, OUTPUT);

  couleurRGB(0, 0, 1); // Bleu = En attente d'activation
  stopperMoteurs();

  Serial.println(F("SYSTEME INITIALISE."));
  Serial.println(F("Tapez 'START' pour lancer la navigation, 'STOP' pour arreter."));
}

void loop() {
  unsigned long tempsCourant = millis();

  // 1. Écoute du canal de commande (Simule la télécommande RF 433MHz)
  if (Serial.available() > 0) {
    String commande = Serial.readStringUntil('\n');
    commande.trim();
    if (commande == "START") {
      robotActive = true;
      etatActuel = AVANCE;
      Serial.println(F(">>> MODE AUTONOME ENGAGE <<<"));
    } else if (commande == "STOP") {
      robotActive = false;
      etatActuel = ARRET;
      Serial.println(F(">>> ARRET D'URGENCE <<<"));
    }
  }

  if (!robotActive) {
    stopperMoteurs();
    couleurRGB(0, 0, 1); // Bleu
    return; // Coupe l'exécution de la boucle ici
  }

  // 2. Acquisition Capteur
  long distance = mesurerDistance();

  // 3. Logique de Navigation (Machine à états)
  switch (etatActuel) {

    case AVANCE:
      if (distance > 0 && distance < DISTANCE_CRITIQUE) {
        // Obstacle détecté ! On passe en manoeuvre d'urgence
        etatActuel = RECUL;
        chronoManoeuvre = tempsCourant;
        Serial.print(F("OBSTACLE a ")); Serial.print(distance); Serial.println(F(" cm. Evitement en cours..."));
      } else {
        avancer(VITESSE_MAX);
        couleurRGB(0, 1, 0); // Vert
        noTone(pinBuzzer);
      }
      break;

    case RECUL:
      // Recule pendant 600 ms
      if (tempsCourant - chronoManoeuvre < 600) {
        reculer(VITESSE_MANOEUVRE);
        couleurRGB(1, 0, 0); // Rouge
        tone(pinBuzzer, 1000); // Bip de recul (camion)
      } else {
        etatActuel = ROTATION;
        chronoManoeuvre = tempsCourant; // Reset chrono
      }
      break;

    case ROTATION:
      // Tourne sur lui-même pendant 400 ms
      if (tempsCourant - chronoManoeuvre < 400) {
        tournerDroite(VITESSE_MANOEUVRE);
        couleurRGB(1, 1, 0); // Jaune (Rouge + Vert)
        tone(pinBuzzer, 2000); // Bip aigu de rotation
      } else {
        etatActuel = AVANCE; // Fin de la manoeuvre, on repart
      }
      break;

    case ARRET:
      stopperMoteurs();
      break;
  }

  delay(50); // Stabilité du CPU
}

// ==========================================
// FONCTIONS DE CONTRÔLE MOTEURS (L298N)
// ==========================================
void avancer(int vitesse) {
  analogWrite(ENA, vitesse); digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  analogWrite(ENB, vitesse); digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}
void reculer(int vitesse) {
  analogWrite(ENA, vitesse); digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  analogWrite(ENB, vitesse); digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
}
void tournerDroite(int vitesse) {
  analogWrite(ENA, vitesse); digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); // G avance
  analogWrite(ENB, vitesse); digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH); // D recule
}
void stopperMoteurs() {
  analogWrite(ENA, 0); analogWrite(ENB, 0);
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}

// ==========================================
// FONCTION CAPTEUR & LED
// ==========================================
long mesurerDistance() {
  digitalWrite(pinTrig, LOW); delayMicroseconds(2);
  digitalWrite(pinTrig, HIGH); delayMicroseconds(10);
  digitalWrite(pinTrig, LOW);
  long duree = pulseIn(pinEcho, HIGH, 30000);
  if (duree == 0) return 999;
  return duree * 0.034 / 2;
}

void couleurRGB(bool r, bool g, bool b) {
  digitalWrite(pinLedRouge, r);
  digitalWrite(pinLedVerte, g);
  digitalWrite(pinLedBleue, b);
}
