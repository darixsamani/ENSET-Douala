#include <IRremote.h>

// --- Broches ---
const int pinIR = 2;
const int pinRouge = 9;  // Broche PWM
const int pinVert = 10;  // Broche PWM
const int pinBleu = 11;  // Broche PWM
const int pinLDR = A0;

// --- Variables d'état ---
int modeLumineux = 0; // 0=Manuel, 1=Arc-en-ciel, 2=Stroboscope
int rVal = 0, vVal = 0, bVal = 0;
float facteurLuminosite = 1.0;

void setup() {
  Serial.begin(9600);
  
  // Initialisation du récepteur IR
  IrReceiver.begin(pinIR, ENABLE_LED_FEEDBACK);
  
  // Configuration des broches de la LED RVB
  pinMode(pinRouge, OUTPUT);
  pinMode(pinVert, OUTPUT);
  pinMode(pinBleu, OUTPUT);
}

void loop() {
  // 1. Lecture automatique de la luminosité ambiante (LDR)
  int valeurLDR = analogRead(pinLDR);
  // Plus il fait noir, plus on baisse l'intensité de la LED pour ne pas éblouir
  facteurLuminosite = map(valeurLDR, 0, 1023, 10, 100) / 100.0;

  // 2. Vérification des commandes de la télécommande IR
  if (IrReceiver.decode()) {
    unsigned long commande = IrReceiver.decodedIRData.decodedRawData;
    Serial.print("Code IR reçu : ");
    Serial.println(commande, HEX);

    // Décodage des touches spécifiques de la télécommande Tinkercad
    switch(IrReceiver.decodedIRData.command) {
      case 0x10: // Touche "1" -> Mode Manuel Rouge
        modeLumineux = 0; rVal = 255; vVal = 0; bVal = 0;
        break;
      case 0x11: // Touche "2" -> Mode Manuel Vert
        modeLumineux = 0; rVal = 0; vVal = 255; bVal = 0;
        break;
      case 0x12: // Touche "3" -> Mode Manuel Bleu
        modeLumineux = 0; rVal = 0; vVal = 0; bVal = 255;
        break;
      case 0x04: // Touche "Vol-" -> Mode Arc-en-ciel (Fondu)
        modeLumineux = 1;
        break;
      case 0x06: // Touche "Vol+" -> Mode Stroboscope
        modeLumineux = 2;
        break;
      case 0x00: // Touche "Power" -> Éteindre tout
        modeLumineux = 0; rVal = 0; vVal = 0; bVal = 0;
        break;
    }
    IrReceiver.resume(); // Recommencer à écouter le capteur IR
  }

  // 3. Gestion des effets lumineux
  if (modeLumineux == 0) {
    // Mode Manuel classique
    appliquerCouleur(rVal, vVal, bVal);
  } 
  else if (modeLumineux == 1) {
    // Mode Arc-en-ciel (Fondu de couleurs simplifié)
    effetArcEnCiel();
  } 
  else if (modeLumineux == 2) {
    // Mode Stroboscope blanc flash
    appliquerCouleur(255, 255, 255);
    delay(50);
    appliquerCouleur(0, 0, 0);
    delay(50);
  }
}

// Fonction pour envoyer les signaux PWM aux canaux de la LED RVB
void appliquerCouleur(int r, int v, int b) {
  // On applique le facteur de correction de la LDR
  analogWrite(pinRouge, r * facteurLuminosite);
  analogWrite(pinVert, v * facteurLuminosite);
  analogWrite(pinBleu, b * facteurLuminosite);
}

// Effet de transition fluide (Roue chromatique)
void effetArcEnCiel() {
  for (int i = 0; i < 255; i++) {
    if (modeLumineux != 1) return; // Quitter si le mode change
    appliquerCouleur(255 - i, i, 0); // Transition Rouge vers Vert
    delay(10);
  }
  for (int i = 0; i < 255; i++) {
    if (modeLumineux != 1) return;
    appliquerCouleur(0, 255 - i, i); // Transition Vert vers Bleu
    delay(10);
  }
  for (int i = 0; i < 255; i++) {
    if (modeLumineux != 1) return;
    appliquerCouleur(i, 0, 255 - i); // Transition Bleu vers Rouge
    delay(10);
  }
}