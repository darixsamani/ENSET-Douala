// --- Attribution des Broches ---
const int pinVert  = 4;
const int pinJaune = 2;
const int pinRouge = 3;

// --- Temporisations (en millisecondes) ---
const unsigned long DUREE_VERT  = 3000; // 3 secondes
const unsigned long DUREE_JAUNE = 1000; // 1 seconde
const unsigned long DUREE_ROUGE = 3000; // 3 secondes

// --- Gestionnaire de la Machine à États ---
enum Etats {FEU_VERT, FEU_JAUNE, FEU_ROUGE};
Etats etatCourant = FEU_VERT;

unsigned long tempsPrecedent = 0;

void setup() {
  // Configuration des broches en sortie
  pinMode(pinVert, OUTPUT);
  pinMode(pinJaune, OUTPUT);
  pinMode(pinRouge, OUTPUT);
  
  // État initial : Feu Vert allumé
  rafraichirLeds(HIGH, LOW, LOW);
}

void loop() {
  unsigned long tempsActuel = millis();
  unsigned long dureeEtape = 0;

  // Détermination de la durée selon l'état en cours
  if (etatCourant == FEU_VERT)  dureeEtape = DUREE_VERT;
  else if (etatCourant == FEU_JAUNE) dureeEtape = DUREE_JAUNE;
  else if (etatCourant == FEU_ROUGE) dureeEtape = DUREE_ROUGE;

  // Vérification du temps écoulé (Structure asynchrone)
  if (tempsActuel - tempsPrecedent >= dureeEtape) {
    tempsPrecedent = tempsActuel; // Réinitialisation du chronomètre
    
    // Transition d'état (Séquence classique)
    switch (etatCourant) {
      case FEU_VERT:
        etatCourant = FEU_JAUNE;
        rafraichirLeds(LOW, HIGH, LOW); // Allume Jaune
        break;
        
      case FEU_JAUNE:
        etatCourant = FEU_ROUGE;
        rafraichirLeds(LOW, LOW, HIGH); // Allume Rouge
        break;
        
      case FEU_ROUGE:
        etatCourant = FEU_VERT;
        rafraichirLeds(HIGH, LOW, LOW); // Allume Vert
        break;
    }
  }
}

// Fonction utilitaire pour commander les sorties logiques d'un coup
void rafraichirLeds(int v, int j, int r) {
  digitalWrite(pinVert, v);
  digitalWrite(pinJaune, j);
  digitalWrite(pinRouge, r);
}