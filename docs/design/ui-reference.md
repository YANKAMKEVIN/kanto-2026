# Référence UI — planche DA 2026 v1

Image : [`reference/da-2026-planche-v1.webp`](reference/da-2026-planche-v1.webp) (validée par Kevin). Les légendes en bas à gauche de chaque case (« Écran d'exploration… ») sont des annotations de la planche, **pas** des éléments du jeu.

Le style est implémenté dans le skill `ui-theme-2026` (tokens, Theme Godot).

## Exploration
- Haut gauche : icône Poké Ball + nom de zone (BOURG PALETTE) + région (Kanto) en petit ; apparaît à l'arrivée puis s'efface.
- Haut droite : mini-carte circulaire translucide + bouton menu rond (☰).
- Bas gauche : joystick circulaire translucide (anneau + pastille + flèches) — **décision : apparaît au toucher, transparent au repos**.
- Bas droite : boutons ronds « courir » (chaussure) et contextuel « parler » (bulle).
- Le Pokémon de tête suit le joueur.

## Combat
> **Nouvelle référence de Kevin (2026-09-26)** : `reference/combat-v1.webp` — elle précise la planche : combat **dans le décor** (golden hour, pas de socle), Pokémon du joueur de dos au premier plan gauche, adversaire au centre droit ; carte adversaire en haut à droite (NOM ♂, Nv., barre PV **sans chiffres**) ; carte joueur en bas à gauche (NOM ♂, Nv., barre PV, « 24 / 24 ») avec au-dessus **6 pastilles d'équipe** (Poké Ball = Pokémon présent) ; grille 2×2 en bas à droite, **boutons colorés** : ATTAQUER (rouge, lueur de sélection) · SAC (or) · ÉQUIPE (bleu, remplace « POKÉMON ») · FUITE (gris sombre), avec icônes. Dossier combat : `dossier-05-combat.md`.
> **Sélection des capacités (référence de Kevin, 2026-09-26, fichier attendu : `reference/combat-capacites-v1.png`)** : après ATTAQUER, la grille d'actions est remplacée par **4 cartes de capacités en 2×2** sur un bandeau sombre en bas à droite ; carte joueur toujours en bas à gauche ; **bouton retour rond « ‹ »** en bas à gauche, sous la carte joueur. Chaque carte : icône du type à gauche, **NOM** en gras, **PP x/y** en haut à droite, **pastille du type** colorée (ÉLECTRIQUE jaune, NORMAL gris), et en bas à droite « Puissance 40 » ou « Statut ». Cartes teintées selon le type (dorée pour Électrique, grise pour Normal). Sélection : **bordure lumineuse jaune + flèche ▶** à gauche de la carte. Exemple : Éclair 15/15 (Puissance 40), Vive-Attaque 30/30 (Puissance 40), Cage-Éclair 20/20 (Statut), Mimi-Queue 30/30 (Statut).
> **Capture avec une Poké Ball (storyboard de Kevin, 2026-09-26)** : `reference/combat-capture-v1.webp`, 9 cases. 1) SAC en surbrillance (or), PV adverses bas (barre rouge). 2) Panneau **SAC** sombre à gauche : section Balls (Poké Ball ×12 sélectionnée — bordure jaune + ▶ —, Super Ball ×3, Hyper Ball ×1), séparateur, soins (Potion ×5, Super Potion ×2, Rappel ×1), icône par objet, bouton retour « ‹ ». 3) **Le dresseur lance la Ball** (vue par-dessus l'épaule, trajectoire). 4) Impact : le Pokémon est absorbé dans un tourbillon lumineux rouge. 5–7) La Ball **tremble trois fois** au sol (traits de mouvement) — avec vibration (dossier 04 §11). 8) **Éclat** doré : capture réussie. 9) Carte « **ROUCOOL CAPTURÉ !** » avec vignette du Pokémon et « **Nouvelle entrée Pokédex** », ▼ pour continuer. Pas de mini-jeu d'adresse (dossier 04 §12).

- Adversaire en haut à droite sur un socle, décor en perspective ; Pokémon du joueur au premier plan gauche, de dos.
- Carte info adversaire en haut à droite : NOM ♂, Nv. 5, barre PV, « 18 / 18 ».
- Carte info joueur en bas à gauche : même structure.
- Grille 2×2 en bas à droite : ATTAQUER (accent jaune, sélection) · SAC · POKÉMON · FUITE, avec icônes.
- ATTAQUER → 4 cartes de capacités (nom, type, PP).

## Menu principal
- Carte dresseur à gauche : portrait, nom (KEVIN), ID, lieu actuel, 8 emplacements de badges, fond paysage.
- Liste à droite : ÉQUIPE (sélection jaune) · SAC · POKÉDEX · CARTE · QUÊTES · OPTIONS, avec icônes.

## Équipe
Grille 2×3 de cartes : sprite, nom + sexe, Nv., PV x/y, barre PV verte. Carte de tête mise en avant (bordure accent).

## Pokédex
Titre + compteur (25 / 151), champ de recherche, filtres en onglets (Tous / Kanto / Types ▾), grille 5 colonnes de vignettes avec numéro.
**Fiche** : #025, nom, badge de type coloré, sexe, taille/poids, description, onglets Infos / Capacités / Lieux, grand sprite animé.

## Dialogue
> **Remplacé (décision de Kevin, 2026-09-26)** par la bible UI/UX §3 : panneau sombre translucide, sans portrait, nom dans le panneau, « › ». La description ci-dessous est l'ancienne version de la planche.

Portrait du personnage au-dessus de la boîte, étiquette de nom bleue (« Prof. Chen »), boîte claire arrondie, texte sombre, indicateur ▼ de suite.

## Carte du monde
Carte de Kanto stylisée avec nœuds, liste des lieux à droite avec icônes ; lieux non découverts = « ??? ».

## Sac
Onglets Objets / CT/CS / Baies / Objets clés ; lignes icône + nom + quantité (× 12), ligne sélectionnée en accent jaune.

## Sauvegarde
Toast translucide avec ✓ vert, « Sauvegarde effectuée ! » + date/heure, sur la scène du jeu.
