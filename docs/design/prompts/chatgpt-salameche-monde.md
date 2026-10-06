# Prompt ChatGPT — Salamèche du monde (planche de marche)

> Essai manuel de Kevin dans l'app ChatGPT (2026-10-06) : Codex refuse les versions fidèles. Joindre **deux images** : `build/art/PERSO_P2_PEINT_r1.png` (le héros, ancre de style) et `build/art/POKE_CARAPUCE_NE_r1.png` (un autre starter, ancre de proportions). Copier le texte entre les deux lignes. Enregistrer le résultat sous `build/art/POKE_SALAMECHE_NE_r4.png`.

---

POKE_SALAMECHE — planche d'animation d'un Pokémon du monde (laboratoire du Professeur Chen).
Style : exactement le rendu de la planche jointe jointe (le héros du jeu) : Pokémon peint simplifié, même finesse, même contour fin coloré sans trait noir, mêmes proportions, même manière de peindre le visage et les vêtements. Ni pixel art, ni 3D, ni anime aux contours noirs.
LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

POKÉMON (identique dans toutes les images) : Salamèche, le petit Pokémon Feu du laboratoire, interprété dans le style peint simplifié du jeu : petit lézard bipède trapu et arrondi, peau orange unie sans taches, ventre crème, grosse tête ronde aux grands yeux, petits bras, et une petite flamme orange et jaune au bout de la queue, visible dans toutes les poses. Allure enthousiaste.

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose du Pokémon, entier, centré horizontalement, les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule, à la même taille dans toutes les cellules (environ 160 px de haut). Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (marche vers le bas de l'écran).
- Ligne 2 : de profil, marche vers la gauche.
- Ligne 3 : de profil, marche vers la droite.
- Ligne 4 : de dos (marche vers le haut de l'écran).
- Colonnes : marche debout en 4 images, queue à flamme qui balance.
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus du Pokémon). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres autour des cellules.
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.

La deuxième image jointe est un autre Pokémon du même laboratoire : même taille, mêmes proportions trapues, même rendu.

---
