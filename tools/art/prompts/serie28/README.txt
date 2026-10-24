Série 28 (numéro PROVISOIRE) — kit d'art du jalon 25 : Manoir Pokémon, Arène d'Auguste,
réserve du Musée d'Argenta, PNJ, décors de combat, dos de Pokémon. Lot 25.0, tâches T10 à T12.

Fiche : docs/design/fiches-assets/serie-28-cramois.md ; conception : dossier 28 §4, §7, §8, §9, §13 ;
plan : docs/tech/jalon-25.md §2.9 ; géométrie (fait foi) : tools/plans/manoir_*.txt, cramois_arene.txt,
argenta_musee_reserve.txt. Aucune intégration Godot : rien dans `assets/`, aucun manifeste lancé ;
tout sort dans $ART (défaut : build/art de cette copie), sous `serie28/`.

Méthode des cartes (comme la Tour du J19, `tools/build_pokemon_tower.gd`, et les grottes) : un KIT
MODULAIRE (sols raccordables, masses de murs, faces / couronnements / flancs, objets) posé par la
GRILLE, jamais une image peinte d'un coup (une image de 30 × 28 cases n'a que ≈ 43 px par case et
suit mal le plan, essai du 2026-10-19 : 75 % des cases justes). `--cartes` recompose chaque carte à
1 case = 96 px, état « ARRÊT » (jeu A fermé, jeu B ouvert) : c'est la « carte peinte » de contrôle.

Usage :
  tools/art/serie28.py --prompts            écrit tous les prompts (sans Codex)
  tools/art/serie28.py --ancres             copie les ancres de style dans $ART
  tools/art/serie28.py --refs               recadre les vues validées dans $ART (REF_*)
  tools/art/serie28.py --commandes [VAGUE]  liste les appels tools/art/generer.sh
  tools/art/serie28.py --tuiles ESSAI       portions TL / TR d'une composition de décor
  tools/art/serie28.py --decor ID ESSAI     assemble un décor (manoir_salle | arene_cramois)
  tools/art/serie28.py --preparer           prépare les essais retenus -> $ART/serie28/
  tools/art/serie28.py --cartes             recompose les cartes (kit + grille) -> $ART/serie28/cartes/
  tools/art/serie28.py --controle [sortie]  planche de contrôle -> build/art/SERIE28_CONTROLE_v1.png
