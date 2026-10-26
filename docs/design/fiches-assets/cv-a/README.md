# CV.A — points d'origine des effets de combat : planche validée

> **Validée par Kevin le 2026-10-26** (« c'est ok », sur la planche de synthèse).

> Chantier Combat vivant (`docs/tech/combat-vivant.md` §2.2, CV-10, décision de Kevin du
> 2026-10-26). Branche `cv-a-points`. Données : `data/battle/fx_anchors.json`. Outil :
> `tools/art/fx_anchors.py`. Test : `tests/unit/test_fx_anchors.gd` (vert).

## À regarder en premier : `synthese.webp`

**Planche de synthèse**, une espèce par ligne, lisible sur téléphone : les 24 espèces délicates
(formes sans tête, plusieurs têtes, canons, joues, Pokémon sans bouche visible, têtes cachées de
dos) et les cas où la session a hésité, chacun avec sa note en jaune. Si elle te convient, le
reste suit le même soin.

## Planches complètes (référence)

13 planches (`planche_01.webp` à `planche_13.webp`), 12 espèces par planche, dans l'ordre du
Pokédex. Chaque espèce a sa **face** (vue de l'adversaire, artwork officiel) et son **dos** (vue de
ton Pokémon, l'image que le combat affiche aujourd'hui). Les pastilles marquent l'endroit d'où
partiront les effets d'attaque :

| Pastille | Sert à |
|---|---|
| blanche `tete` | point par défaut (ondes Psy, statut, cris) ; présente partout |
| rouge `bouche` | jets et souffles (Lance-Flammes, Pistolet à O, Ultralaser) |
| rose `yeux` | Psyko, Regard Médusant, Hypnose |
| jaune `joues` | Éclair de Pikachu et Raichu |
| verte `mains` | poings et griffes |
| orange `queue` | queue de feu, queue éclair |
| violette `cornes` | Koud'Korne, Empal'Korne |
| bleue `canons` | Hydrocanon de Tortank |
| verte `bulbe` | Fouet Lianes, Tranch'Herbe, poudres (lignées de Bulbizarre, Mystherbe, Chétiflor, Paras) |
| grise `centre` | calculée (milieu du corps), repli final |

Un point **absent** n'est pas une erreur : l'attaque part alors de `bouche`, puis `tete`, puis
`centre`. Ce qui compte : **un point mal placé** (par exemple une `tete` sur une aile).

Réponse attendue : « je valide la planche », ou une liste de corrections du type
« 142 dos : tête en haut à gauche ; 035 face : pas de mains ».

## Ce qui reste provisoire

- Dos encore en pixel art (009 Tortank, 039 Rondoudou, 064 Kadabra, 135 Voltali) et 4 espèces sans dos (065
  Alakazam, 105 Ossatueur, 131 Lokhlass, 151 Mew) : leurs points de dos seront posés quand
  leur dos peint arrivera (DAF.1). Le test signale toute image changée.
- Les points ont été posés par des sous-agents sur des grilles quadrillées (précision ≈ 0,02),
  puis **les 13 planches ont été relues par la session, espèce par espèce, de face et de dos**
  (2026-10-26). Six corrections : 013 face (queue ajoutée), 055 face (fausse corne retirée), 063
  face (tête remontée), 088 face (mains retirées, informes), 100 face (bouche retirée, Voltorbe
  n'en a pas), 108 dos (la langue était notée « queue », devenue « bouche »).

## Cas signalés comme douteux

- **Têtes peu lisibles** (point au centre du « visage » ou du haut du corps) : 010, 011, 014,
  039, 041, 072 à 076, 081, 082, 090 à 092, 100 à 102, 109, 110, 114, 120, 121.
- **Dos où la tête est cachée** : 001 à 003 (bulbe), 029, 044, 045, 047, 093, 098, 099, 106,
  111, 138, 139, 142 (Ptéra, tête au bout du cou), 145 (Électhor, dans les plumes), 136.
- **Plusieurs têtes** : 051 (tête du haut), 084 (tête de gauche), 085 (tête du milieu), 103 (tête
  de droite).
- **Mains** : 015 (dards), 064 (main à la cuillère), 088 (estimation), 105 (main qui tient l'os),
  123 et 141 (lames) ; omises pour 063, 089, 106.
- **Cornes** : 028 et 031 non posées ; 111 = petite corne du nez ; 128 = corne de gauche.
