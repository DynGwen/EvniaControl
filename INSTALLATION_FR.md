# Evnia Control 1.0.34 — installation

Mac Apple Silicon sous macOS 27 ou plus récent, avec les outils de développement
et un SDK macOS 27+. Une connexion Internet est nécessaire pour les dépendances.

1. Décompresser l'archive dans un nouveau dossier.
2. Ouvrir le dossier contenant install.command et double-cliquer dessus.
   Depuis Terminal, dans ce dossier :

       chmod +x install.command
       ./install.command

3. Attendre la compilation et les quatorze contrôles de routage sans XCTest.
   Autoriser l'installation dans Applications lorsque macOS le demande.
4. Conserver l'autorisation d'Evnia Control dans Réglages Système >
   Confidentialité et sécurité > Accessibilité pour les touches de contrôle.
   Le clavier reste actif en permanence dans l'application.

L'installation remplace /Applications/Evnia Control.app, supprime l'ancienne
copie connue dans ~/Applications et nettoie les anciens fichiers de diagnostic,
de raccourcis et de compilation dans le dossier des sources. Les réglages de
luminosité, de volume et d'atténuation sont conservés.

## Utilisation

Fermer le menu Evnia et appuyer directement sur petit Soleil puis grand Soleil,
sans Fn : la luminosité doit varier de 5 points et afficher le popup Brightness.
Cette version ajoute les codes Soleil natifs du Magic Keyboard Lightning
(144/145), qui n'étaient pas traités par la version précédente. Les mêmes
touches restent prises en charge lorsqu'elles émettent F1/F2.
Aucun changement du réglage global des touches de fonction n'est effectué.
Les anciens raccourcis avec les flèches et le diagnostic clavier sont retirés.

Le popup Volume fonctionne avec les touches de son. Les deux popups se ferment
deux secondes après le dernier changement, avec pause au survol/glissement.
L'interface principale et les réglages audio restent disponibles.

## Vérification

verify.command compile l'application et lance les contrôles de routage.
L'environnement de préparation Linux ne permet pas de compiler AppKit/Carbon
ni de tester l'écran. La compilation native et l'usage direct sans Fn de cette
version restent donc à valider sur le Mac cible.
