#include <LiquidCrystal_I2C.h>
#include <Adafruit_NeoPixel.h>

// --- Configuration du LCD (I2C) ---
LiquidCrystal_I2C lcd(0x20, 16, 2);

// --- Configuration de l'Anneau NeoPixel ---
#define PIN_NEOPIXEL 11
#define NUMPIXELS 12 // Change à 16 ou 24 si tu prends un anneau plus grand
Adafruit_NeoPixel anneau(NUMPIXELS, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800);

// --- Configuration des Boutons ---
const int btnSuivant = 2;
const int btnValider = 3;

int etatMenu = 0; // 0=Chenillard, 1=Couleurs, 2=Effacer
const int MAX_MENU = 2;

// Variables pour l'anti-rebond
bool dernierEtatBtnS = HIGH;
bool dernierEtatBtnV = HIGH;

void setup() {
  lcd.init();
  lcd.backlight();
  lcd.print("MENU ANIMATION");
  delay(1500);

  // Initialisation NeoPixel
  anneau.begin();
  anneau.setBrightness(50); // Luminosité (0 à 255)
  anneau.show(); // Éteint tout par défaut

  // Boutons en PULLUP interne (activés sur état BAS/LOW)
  pinMode(btnSuivant, INPUT_PULLUP);
  pinMode(btnValider, INPUT_PULLUP);

  afficherMenu();
}

void loop() {
  // --- Bouton "Suivant" ---
  bool lectureS = digitalRead(btnSuivant);
  if (lectureS == LOW && dernierEtatBtnS == HIGH) {
    etatMenu++;
    if (etatMenu > MAX_MENU) etatMenu = 0;
    afficherMenu();
    delay(200);
  }
  dernierEtatBtnS = lectureS;

  // --- Bouton "Valider" ---
  bool lectureV = digitalRead(btnValider);
  if (lectureV == LOW && dernierEtatBtnV == HIGH) {
    executerAction();
    delay(200);
  }
  dernierEtatBtnV = lectureV;
}

// --- Fonctions d'affichage et d'action ---

void afficherMenu() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Action LED:");
  lcd.setCursor(0, 1);
  if (etatMenu == 0) lcd.print("> 1. Chenillard");
  if (etatMenu == 1) lcd.print("> 2. Couleurs");
  if (etatMenu == 2) lcd.print("> 3. Effacer");
}

void executerAction() {
  anneau.clear();
  anneau.show();
  
  if (etatMenu == 0) {
    // Animation : Tourne en bleu, une LED à la fois
    for(int i = 0; i < NUMPIXELS; i++) {
      anneau.setPixelColor(i, anneau.Color(0, 150, 255)); // Bleu
      anneau.show();
      delay(100);
      anneau.setPixelColor(i, anneau.Color(0, 0, 0));     // Éteint
    }
    anneau.show(); // Laisse l'anneau éteint à la fin
  } 
  else if (etatMenu == 1) {
    // Affichage : Dégradé fixe multi-couleurs
    for(int i = 0; i < NUMPIXELS; i++) {
      int rouge = (i * 255) / NUMPIXELS;
      int bleu = 255 - rouge;
      int vert = (i % 2 == 0) ? 100 : 0; 
      anneau.setPixelColor(i, anneau.Color(rouge, vert, bleu));
    }
    anneau.show();
  }
  else if (etatMenu == 2) {
    // Effacer complètement
    anneau.clear();
    anneau.show();
  }
}