#include <SoftwareSerial.h>

// Création du port série virtuel (RX=2, TX=3)
SoftwareSerial liaisonRadio(2, 3);

const int pinCapteur = A0;
const int pinBouton = 4;

void setup() {
  Serial.begin(9600); // Pour le débogage sur PC
  liaisonRadio.begin(9600); // La vitesse de la liaison "Radio"
  
  pinMode(pinBouton, INPUT_PULLUP);
}

void loop() {
  // 1. Lecture de la Température
  int valeurBrute = analogRead(pinCapteur);
  float tension = valeurBrute * (5.0 / 1023.0);
  float temperature = (tension - 0.5) * 100.0;

  // 2. Lecture du Bouton (Inversé car PULLUP : appuyé = LOW)
  int etatBouton = !digitalRead(pinBouton); 

  // 3. Construction et envoi de la trame de données
  // Format attendu : <25.50,1>
  liaisonRadio.print("<");
  liaisonRadio.print(temperature);
  liaisonRadio.print(",");
  liaisonRadio.print(etatBouton);
  liaisonRadio.println(">"); // println ajoute un saut de ligne

  // Débogage local
  Serial.print("Trame envoyee : <");
  Serial.print(temperature);
  Serial.print(",");
  Serial.print(etatBouton);
  Serial.println(">");

  delay(1000); // Envoi toutes les secondes
}