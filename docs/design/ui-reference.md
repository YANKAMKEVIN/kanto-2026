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
