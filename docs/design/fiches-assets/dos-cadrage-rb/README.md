# Dos de combat : essai du cadrage « façon Rouge/Bleu » (2026-10-24)

Question de Kevin : les dos actuels (corps entier, souvent de profil) paraissent bizarres et
Onix paraît minuscule. Faut-il un cadrage RB (trois quarts arrière, légère plongée, corps coupé
par le bas de l'écran), et des dos demandés ainsi à Codex seraient-ils moins refusés ?

## Images

- `apercu-dos-81.webp` : les 81 espèces à dos peint de `art-dos-combat-maj` @ `53fcf867`
  (IA de préférence, sinon 3D brut encadré en orange). Sur `main`, aucun dos peint n'est lu
  par le jeu (pixel 64 px ; Osselait et Ossatueur : artwork officiel de face).
- `apercu-dos-pokemon.webp` : les 27 dos IA et 4 dos 3D de `main` (`battle_proto/`).
- `comparaison-dos-rb.webp` : ces 31 dos à côté des dos Rouge/Bleu (PokeAPI, 32 px agrandis).
- `echantillon-cadrage-dos.webp` : montage A (cadrage actuel, `BattleLayout`) / B (dos existants
  agrandis et coupés par le bas) dans le décor de la Route 1, Rattata en face. Sans HUD.
- `test-dos-rb-codex.webp` : Carapuce et Onix, dos actuel contre nouveau dos Codex en cadrage RB.

## Captures du vrai jeu avec l'interface (2026-10-25)

`combat-hud-a-b.webp` : vrai combat sauvage de la Route 1 (`tools/capture_combat_cb3.gd`),
Carapuce et Onix N9 contre Roucool, A à gauche, B à droite (menu, capacités, message).
Prototype sur la branche locale `proto/dos-cadrage-rb` (worktree `~/dev/kanto-2026-wt-dos-rb`,
**à ne pas fusionner**) : `KANTO_DOS_DIR=<dossier>` lit `<espèce>.png` comme dos peint,
`KANTO_DOS_RB=<hauteur en fraction d'écran>` (Carapuce 0,58, Onix 0,86) pose le bas de l'image
au bas de l'écran, à 0,58 hauteur d'écran à gauche du centre.
Constats : aucun conflit avec l'interface (carte en haut à gauche, commandes en bas à droite) ;
le feuillage flou du premier plan du décor passe devant le bas du Pokémon en B (à trancher :
dos devant ou derrière ce feuillage) ; l'ombre au sol n'a plus de sens en B.

### Taille de l'adversaire en B

En B, l'adversaire paraît petit par contraste (sa taille n'a pas changé). `taille-adversaire-b.webp` :
`FOE_PRESENCE` 0,27 (actuel) / 0,34 / 0,40 (`KANTO_FOE_PRESENCE`, boîte maximale doublée
pour l'essai) sur Roucool, Rattata et Dracaufeu. À 0,40, Dracaufeu touche presque le haut de
l'écran et descend sur ta carte. **Proposition : 0,34**, boîte maximale de l'adversaire
inchangée (elle protège l'interface). Ne pas déplacer `FOE_FEET` : l'échelle du décor peint
en dépend (`BattleDecor.fit`).

### Grands adversaires en B

`grands-adversaires-b.webp` (passe `--pass=foes` du prototype) : Onix, Léviator, Ronflex,
Florizarre, Arcanin, Ptéra, Artikodin, Grolem contre Carapuce de dos. Avec la vraie boîte
maximale de l'adversaire (`FOE_MAX_BOX` 0,50 × 0,38), passer la présence de 0,27 à 0,34 ne
change rien pour eux : c'est la boîte qui les plafonne (Léviator très petit). Boîte × 1,4
(`KANTO_FOE_BIGBOX=1.4`) : tous gagnent nettement, mais Onix touche le haut de l'écran (ses
pieds sont à 0,50, la boîte monte à 0,53). **Proposition** : présence 0,34 et boîte
0,70 × 0,46 (largeur × 1,4, hauteur plafonnée sous le haut de l'écran).

Capture de la proposition (`grands-adversaires-b-v2.webp`, `KANTO_FOE_BOX=0.70,0.46`) :
Onix ne touche plus le haut ; tous un peu plus grands qu'aujourd'hui, mais moins qu'avec × 1,4.
Léviator et Onix, hauts, restent plafonnés par la hauteur (pieds de l'adversaire à 0,50) :
les agrandir davantage demanderait de descendre `FOE_FEET`, donc de recaler les décors.

## Test Codex (prompts `tools/art/prompts/dos_rb/`, sorties `build/art/DOS_RB_*.png`, 1254 px RGBA)

| Espèce | Avec artwork joint (r1) | Sans image (r2) |
|---|---|---|
| Salamèche (004) | refus | refus |
| Carapuce (007) | refus | **accepté** |
| Pikachu (025) | refus | refus |
| Onix (095) | **accepté** | — |

Tous les refus sont `moderation_blocked` à l'étape **output** : l'image produite est reconnue,
quel que soit le cadrage. Le cadrage serré ne fait donc pas tomber les refus des espèces très
connues ; il ne les aggrave pas non plus. Les deux images acceptées sont propres (vrai dos,
plongée, coupe nette en bas) et, en situation, nettement plus lisibles qu'en corps entier ;
Onix gagne sa taille (tête et blocs qui sortent par le bas).

## Décision de Kevin (2026-10-25)

**Cadrage B façon Rouge/Bleu retenu**, avec l'adversaire à présence **0,34** et une boîte
maximale de l'adversaire de **0,70 × 0,46** (hauteurs d'écran). `FOE_FEET` inchangé.
Restent à trancher en défaut pendant le code : le dos devant ou derrière le feuillage flou du
premier plan, l'ombre au sol du dos (à retirer en B), la hauteur à l'écran par espèce (0,58
pour Carapuce, 0,86 pour Onix dans l'essai), et la production des dos (recadrage des 81
existants ou nouveaux dos en plongée : rendu Blender caméra haute puis Colab, ou Codex).

### Production des dos (décision de Kevin, 2026-10-25)

Mot pour mot : « Recadrer d'abord les 81 dos existants en cadrage B, puis refaire en plongée
seulement ceux qui rendent mal, au fil des lots. » Les 81 dos peints de `main` sont donc
affichés en cadrage B par le code (agrandis, coupés par le bas de l'écran) ; les nouveaux dos
(70 restants de DAF.1) sont produits en plongée avec les prompts de `tools/art/prompts/dos_rb/`.

## Avant la décision

Cadrage A (actuel) ou B (façon RB). B toucherait `BattleLayout` (ancre et coupe du dos) et
la production des dos restants (session DAF.1, branche `art-dos-combat-maj`), voire la reprise
des 81 dos existants : à lui transmettre une fois la décision prise.
