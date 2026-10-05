# Série combat — pilote de 5 dos HD (cran C)

Fiche de production des vues de dos des Pokémon du joueur en combat. Pilote : **5 Pokémon**,
aucune production des 151 avant validation en situation sur téléphone (S21 / S24).

## 1. Décisions figées (2026-10-05)

Issues des prototypes de la branche `art/pokemon-pilote` (scènes QA `proto/battle_faceoff/`) :

| Sujet | Décision |
|---|---|
| Cadrage du combat | **Validé** : composition dédiée. Lieu réel resserré, adversaire en haut à droite au second plan, ton Pokémon **de dos** au premier plan en bas à gauche, interface sur l'autre diagonale (carte adverse en haut à gauche, la tienne en bas à droite au-dessus des commandes). |
| Échelle | Salamèche ≈ **60 %** de la taille du premier essai = référence de gabarit ; à normaliser ensuite par taille réelle (Onix ≠ Salamèche). |
| Adversaire | **Artwork officiel HD** de face (PokeAPI, `official-artwork`). |
| Pokédex et menus | Artwork officiel HD. |
| Face à face (deux artworks de face) | **Rejeté** : deux illustrations posées sur le décor, pas un duel. |
| Sprite de dos brut, agrandi | **Rejeté** pour la version finale. |
| Lissage Scale2x | **Rejeté**. |
| Reconstruction automatique (`tools/art/reconstruire_sprite.py`) | **Rejetée** pour la production (forme lissée, pas un artwork : l'anatomie n'existe pas dans les 46 px). Outil gardé comme expérience documentée. |
| Génération par OpenAI (ChatGPT / Codex) | **Inutilisable** pour ces Pokémon : refus répétés du filtre (Salamèche, Carapuce, Bulbizarre de dos). |

## 2. Le pilote

| Pokémon | N° | Pourquoi |
|---|---|---|
| Bulbizarre | 001 | quadrupède, bulbe végétal sur le dos (le dos est sa face la plus chargée) |
| Salamèche | 004 | bipède, longue queue et flamme |
| Carapuce | 007 | carapace (dos = carapace entière) |
| Roucool | 016 | oiseau, ailes repliées et queue |
| Onix | 095 | morphologie très longue, difficile à cadrer |

## 3. Références (dossier `pack_dos_pilote/`, un sous-dossier par Pokémon)

Chaque référence a **un seul rôle** :

| Fichier | Sert à | Ne sert PAS à |
|---|---|---|
| `sprite_dos_bw*.png` / `.gif` (sprite officiel de dos, Noir/Blanc) | **pose, angle, silhouette** | résolution, style, détails |
| `artwork_officiel_face.png` (artwork officiel 475 px) | **anatomie, couleurs, proportions, style de rendu** | pose |
| `cadrage_combat_reference.png` | taille et place à l'écran, angle de vue | — |
| `style_monde_*.png` | ambiance du monde dans lequel le dos sera posé | rendu du Pokémon |

## 4. Cahier des charges de chaque image

- **Style : celui des artworks officiels de face** (même trait, même ombrage, même palette) : le
  dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D,
  pas de style peint différent de l'artwork officiel.
- **Vue** : de dos, de trois quarts, légèrement par-dessus l'épaule gauche ; le Pokémon regarde
  vers le **haut à droite** de l'image (son adversaire est loin devant lui). On voit le dos,
  l'arrière de la tête, au plus un peu du profil. Même angle que le sprite de dos de référence.
- **Pose** : celle du sprite de dos (posture de combat, prêt, attentif). Aucun accessoire.
- **Anatomie et couleurs** : strictement celles de l'artwork officiel ; aucun détail inventé.
- **Lumière** : neutre (milieu de journée, diffuse, légèrement du haut à gauche). Le jeu ajoute
  l'ambiance (heure, lieu) lui-même.
- **Fond** : **transparent** (PNG avec canal alpha, aucun damier dessiné). Aucun sol, aucune
  ombre portée (le jeu la dessine), aucun décor, aucun texte, aucune signature.
- **Taille** : le Pokémon **entier**, centré, qui occupe environ 85 % de la hauteur d'une image
  carrée de **1024 × 1024** px au moins (le jeu affiche Salamèche à environ 400 px de haut sur
  un écran de 1080).
- **Une image fixe par Pokémon** pour le pilote (l'animation de respiration est faite par le
  jeu). Une animation dessinée n'est pas demandée.
- **Nommage** : `dos_001_bulbizarre.png`, `dos_004_salameche.png`, `dos_007_carapuce.png`,
  `dos_016_roucool.png`, `dos_095_onix.png`.

## 5. Validation du pilote

1. Intégration dans la scène QA du duel (cadrage validé, adversaire en artwork officiel).
2. Captures sur S21 / S24 de chacun des 5 contre Roucool (ou un adversaire de gabarit
   comparable).
3. Kevin juge, Pokémon par Pokémon : **même jeu que l'adversaire ? lisible au premier coup
   d'œil ? « mon Pokémon devant moi » ?**
4. Seulement si le pilote est validé : production des 151 par lots, dans l'ordre des routes.

## 6. Question ouverte (Kevin)

- **Qui produit les dos** : illustrateur (commande, budget, délai) ou autre outil de génération
  hors OpenAI (par exemple un modèle local guidé par la pose du sprite). La fiche vaut pour les
  deux.

## 7. Décision (2026-10-06) : dos rendus en 3D puis repeints par IA

Après le pilote (5 dos 3D) et le stress-test (8 morphologies), **Kevin retient la chaîne
« rendu 3D → repeint IA »** pour les dos (« on peut aller dessus ») ; l'illustrateur n'est plus
qu'une solution de secours.

| Étape | Outil | Réglages retenus |
|---|---|---|
| 1. Modèle 3D extrait de Pokémon X/Y | The Models Resource (voir `provenance-modeles-3d.md`) | — |
| 2. Rendu de dos, pose de combat | `tools/art/blender/rendre_lot.py` + `dos_pokemon.json` | passe couleur + passe profondeur, 512 px |
| 3. Repeint « artwork officiel » | notebook Colab (`tools/art/ia/creer_notebook_colab_v2.py`, GPU T4 gratuit) | AnyLoRA (SD 1.5), LoRA Pokémon 0,7, ControlNet profondeur 0,8 + traits 0,6, IP-Adapter = artwork officiel de face à **35 %**, force 0,6, puis agrandissement repeint 1024 px à 0,35 |
| 4. Choix à l'œil | une variante par Pokémon | découpe à la silhouette du rendu |

Pourquoi pas sur le Mac : 8 Go de mémoire, déjà occupés par l'appli Claude (machine virtuelle
de 4 Go) ; ComfyUI y est installé (`~/dev/comfyui`) mais ne peut pas tourner pendant une session.

**Limites connues** : un Pokémon dont le dos diffère beaucoup de la face peut recevoir des traits
de face (Smogo : visage dessiné sur le dos) → pour lui, référence de face désactivée ou rendu 3D
seul ; les défauts du rendu 3D passent dans le repeint (barbillon de Magicarpe) → à corriger dans
la pose ; chaque Pokémon est vérifié à l'œil.

**Suite** : vie des dos dans Godot (respiration, queue, flamme, ailes) ; production route par
route, au rythme des jalons ; intégration au vrai combat avec le cadrage validé (J11).
