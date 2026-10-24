# Dos à faire avec l'app ChatGPT (6 espèces)

Codex a refusé (modération) ou rendu un dos infidèle pour ces six espèces. Kevin les fait avec l'app ChatGPT (décision du 2026-10-22). Les 54 autres dos du lot sont déjà intégrés (`assets/sprites/pokemon/dos/`).

## Mode d'emploi

1. Ouvrir une conversation neuve de ChatGPT (génération d'image) ; coller le prompt de l'espèce. **Ne pas nommer l'espèce** ; si ChatGPT refuse, essayer sans image, puis avec la formulation « personnage original » (déjà dans le prompt).
2. Optionnel : joindre l'artwork de face (`assets/sprites/pokemon/official/NNN.png`) comme référence de couleurs, et `assets/sprites/pokemon/battle_proto/dos_ia_025.png` comme référence d'angle. Si l'app refuse avec les images, réessayer sans.
3. Format attendu pour toutes : **PNG carré 1024 × 1024, fond transparent (canal alpha), créature entière, centrée, environ 80 % de la hauteur**, de dos en trois quarts, regard vers le haut à droite. Un fond opaque est refusé par la préparation (« SANS ALPHA ») : demander « fond transparent » ou détourer ensuite. La préparation recadre et recale elle-même (sujet <= 870 px de haut, bas à 120 px).
4. Enregistrer l'image sous `~/Downloads/DOS_<ESPÈCE>.png` (nom indiqué ci-dessous).
5. Lancer la commande de l'espèce (depuis `~/dev/kanto-2026-wt-art-dos`) : elle dépose le fichier, le prépare, le copie dans `assets/sprites/pokemon/dos/` et régénère la planche `build/art/SERIE_DOS_CONTACT.png`. Puis import headless et commit (ou demander à Claude de le faire).

Le test `tests/unit/test_painted_backs.gd` vérifie que chaque dos présent dans `assets/sprites/pokemon/dos/` est lu par `BattleArt` ; rien d'autre à brancher.

## Kadabra (n° 064)

- Remarque : Ancien essai (r7) jugé infidèle : cuillère, plastron et moustaches à bien montrer.
- Taille et cadrage : PNG 1024 × 1024, alpha, créature entière (~80 % de la hauteur), de dos 3/4, regard en haut à droite.
- Référence de face (facultative) : `assets/sprites/pokemon/official/064.png`
- Dépôt : `~/Downloads/DOS_KADABRA.png`
- Commande : `cd ~/dev/kanto-2026-wt-art-dos && tools/art/serie_dos.py --ajouter KADABRA ~/Downloads/DOS_KADABRA.png`

Prompt à coller :

```text
POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.

Aucune image jointe (ou : une illustration de face pour les couleurs seulement).

SUJET : humanoïde JAUNE mince et debout, PLASTRON brun en forme d'armure sur le torse et les épaules, grandes oreilles pointues, longues MOUSTACHES blanches, longue queue épaisse jaune marquée d'une bande brune, tenant une CUILLÈRE d'argent dans une main.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
```

## Tortank (n° 009)

- Remarque : Codex refuse ; les deux tubes (canons) dépassant de la carapace sont le trait clé.
- Taille et cadrage : PNG 1024 × 1024, alpha, créature entière (~80 % de la hauteur), de dos 3/4, regard en haut à droite.
- Référence de face (facultative) : `assets/sprites/pokemon/official/009.png`
- Dépôt : `~/Downloads/DOS_TORTANK.png`
- Commande : `cd ~/dev/kanto-2026-wt-art-dos && tools/art/serie_dos.py --ajouter TORTANK ~/Downloads/DOS_TORTANK.png`

Prompt à coller :

```text
POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.

Aucune image jointe (ou : une illustration de face pour les couleurs seulement).

SUJET : grande tortue bipède massive à peau BLEUE, CARAPACE BRUNE à bords crème couvrant le dos, avec DEUX gros TUBES MÉTALLIQUES blancs et gris qui dépassent de la carapace au-dessus des épaules, courtes queue et pattes.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
```

## Rondoudou (n° 039)

- Remarque : Codex refuse ; sphère rose parfaite, mèche sur le front.
- Taille et cadrage : PNG 1024 × 1024, alpha, créature entière (~80 % de la hauteur), de dos 3/4, regard en haut à droite.
- Référence de face (facultative) : `assets/sprites/pokemon/official/039.png`
- Dépôt : `~/Downloads/DOS_RONDOUDOU.png`
- Commande : `cd ~/dev/kanto-2026-wt-art-dos && tools/art/serie_dos.py --ajouter RONDOUDOU ~/Downloads/DOS_RONDOUDOU.png`

Prompt à coller :

```text
POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.

Aucune image jointe (ou : une illustration de face pour les couleurs seulement).

SUJET : petite créature ROSE parfaitement ronde comme un ballon, une MÈCHE frisée sur le front, deux oreilles pointues, petite queue en boucle, minuscules pieds.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
```

## Staross (n° 121)

- Remarque : Codex refuse ; deux étoiles superposées, joyau central.
- Taille et cadrage : PNG 1024 × 1024, alpha, créature entière (~80 % de la hauteur), de dos 3/4, regard en haut à droite.
- Référence de face (facultative) : `assets/sprites/pokemon/official/121.png`
- Dépôt : `~/Downloads/DOS_STAROSS.png`
- Commande : `cd ~/dev/kanto-2026-wt-art-dos && tools/art/serie_dos.py --ajouter STAROSS ~/Downloads/DOS_STAROSS.png`

Prompt à coller :

```text
POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.

Aucune image jointe (ou : une illustration de face pour les couleurs seulement).

SUJET : créature marine formée de DEUX étoiles à cinq branches superposées, VIOLET ; un joyau ROUGE-VIOLET au centre ; vue de dessus et un peu de côté.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
```

## Léviator (n° 130)

- Remarque : Codex refuse ; corps en S, nageoire de queue visible.
- Taille et cadrage : PNG 1024 × 1024, alpha, créature entière (~80 % de la hauteur), de dos 3/4, regard en haut à droite.
- Référence de face (facultative) : `assets/sprites/pokemon/official/130.png`
- Dépôt : `~/Downloads/DOS_LEVIATOR.png`
- Commande : `cd ~/dev/kanto-2026-wt-art-dos && tools/art/serie_dos.py --ajouter LEVIATOR ~/Downloads/DOS_LEVIATOR.png`

Prompt à coller :

```text
POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.

Aucune image jointe (ou : une illustration de face pour les couleurs seulement).

SUJET : grand SERPENT MARIN BLEU à ventre crème, longue crête à nageoires, grande gueule, écailles ; de dos, on voit le corps bleu en S et la grande nageoire de la queue.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
```

## Voltali (n° 135)

- Remarque : Codex refuse ; pelage hérissé jaune, collerette blanche.
- Taille et cadrage : PNG 1024 × 1024, alpha, créature entière (~80 % de la hauteur), de dos 3/4, regard en haut à droite.
- Référence de face (facultative) : `assets/sprites/pokemon/official/135.png`
- Dépôt : `~/Downloads/DOS_VOLTALI.png`
- Commande : `cd ~/dev/kanto-2026-wt-art-dos && tools/art/serie_dos.py --ajouter VOLTALI ~/Downloads/DOS_VOLTALI.png`

Prompt à coller :

```text
POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.

Aucune image jointe (ou : une illustration de face pour les couleurs seulement).

SUJET : quadrupède fin au pelage JAUNE vif tout HÉRISSÉ en PIQUANTS pointus (surtout le dos, la croupe et la queue), COLLERETTE blanche en pointes autour du cou, grandes oreilles pointues jaunes.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
```
