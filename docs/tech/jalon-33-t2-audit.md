# J33 T2 — Audit visuel (33A), passe d'audit

> **Audit seulement** : aucune correction d'art ni de code. Les corrections passent par des lots d'art (gel du J33 :
> `dump_map_logic` identique avant / après). Fait le **2026-10-30** sur `main` @ `53c90a1f` (J0 à J32, DAF.0 à DAF.9,
> DAF.4 Ligue, J33 T1 / T3 / T4 / T5). Grille : `docs/design/phase-da-grille.md`. Registre : `docs/tech/reportes.md`
> (**RP-269 à RP-282** nouveaux ; RP-010, RP-023 et RP-157 complétés). Captures d'appui :
> `docs/design/fiches-assets/t2-audit/` (31 images, 1170 × 540 ; originales 2340 × 1080 dans `build/captures/t2*`, non versionnées).

## 1. Méthode et limites

- **Outils** (nouveaux, lecture seule, versionnés) : `tools/capture_t2_audit.sh` (vue d'ensemble d'une carte, sans joueur,
  2340 × 1080, Movie Maker, vrais composants et lumière de la carte), `tools/capture_t2_combats.sh` +
  `tools/capture_t2_combat.gd` (vrai combat sauvage sur le fond de la carte, premier point d'apparition), `tools/art/t2_planche.py`
  (planches 2 × 2). Menus : `tools/capture_menu.gd` existant.
- **Échantillon** : 97 cartes (toutes les villes, 34 routes, une vingtaine de donjons et grottes, une trentaine
  d'intérieurs dont les 8 Arènes), **20 combats** (un par grande famille de fond), **10 écrans de menu** (Équipe, Sac, Pokédex ×3,
  Carte, Dresseur, Paramètres, Boutique, Stockage). Pas d'étage par étage pour la Tour, Sylphe, le Manoir, le repaire :
  un étage de chaque.
- **Limites** : vue d'ensemble sans joueur ni PNJ mobiles (PER-3, PER-4, PER-5, POK-7, CMB-5 non jugés : relevés S24 du
  J33 T6) ; les cartes de petite taille (maisons, Centres, Boutiques) ne sont échantillonnées que par quelques-unes (série
  commune) ; rien n'a été mesuré en i/s (T3). Les écarts « à confirmer » le sont sur S24.

## 2. Tableau par zone

| Zone | Cartes relues | Verdict | Écarts (RP) |
|---|---|---|---|
| Bourg Palette, Jadielle, Argenta, Azuria, Lavanville, Carmin, Cramois'Île, Safrania (ville), Plateau Indigo | villes + leurs Centres, Boutiques, maisons | **Peint, cohérent** (golden hour, façades peintes) | RP-023 (Céladopole : une façade grise) |
| Parmanie (ville, Arène, Centre) | `fuchsia_city`, `fuchsia_gym`, `fuchsia_center` | **Ville et Arène en tuiles provisoires** ; Centre peint | **RP-269 P1, RP-271 P1** |
| Parc Safari | `safari_zone_center/north`, pavillon | **Tuiles provisoires** (4 zones, pavillons) | **RP-270 P1, RP-272 P1** |
| Routes 1 à 12, 22 à 25 | 20 routes | **Peintes** ; raccords corrects sauf un panneau de ciel et deux coins de forêt | RP-281 P2, RP-282 P3 |
| Routes 13 à 15, 17, 18 | `route_13/14/15/18`, `route_17` | **Tuiles provisoires** | **RP-273 P1** |
| Routes 19 à 21 (mer) | 3 routes | Eau plate, lisible mais non peinte | **RP-274 P1** |
| Postes-frontière / gates | Route 12 (peint), Routes 15 et 16 (aplat) | Série mixte | **RP-272 P1** |
| Intérieurs (maisons, Centres, Boutiques, Musée, labo, Arènes de J3 à J10) | 22 | **Peints, lumière chaude** (références `chambre-joueur`, `labo-chen`) | RP-280 P2 (labo de Cramois'Île, Panthéon, Sylphe) |
| Arènes de Carmin, Céladopole, Azuria, Argenta, Jadielle, Safrania | 7 | Peintes (Jadielle et Safrania lisibles : dalles fléchées / téléporteurs visibles) | — |
| Donjons : Mont Sélénite, Grotte Sombre, Tour Pokémon, Manoir, repaire Rocket, Passage souterrain, Route Victoire, Grotte Azurée | 14 | Peints (lisibles, ambiance variée) | RP-040, RP-041 (ouverts) |
| Îles Écume 1F à B4F | `seafoam_1f/b3f` | **Tuiles provisoires** (courants lisibles) | **RP-275 P1** |
| Centrale | `power_plant` | **Tuiles provisoires** | **RP-276 P1** |
| Ligue, Panthéon, Palais du Plateau | `league_*`, `hall_of_fame`, lobby | Sprites peints (RP-136) mais salles quasi vides | **RP-277 P1 (à confirmer S24)** ; lobby peint |
| Combats (20 fonds) | Routes 1, 2, 4, 9, 22, 25, 19 ; Forêt, Mont Sélénite, Grotte Sombre, Azurée, Îles Écume, Route Victoire, Tour ; Arènes d'Argenta, de Parmanie, de Cramois'Île ; Sylphe 1F ; Safari | **Fonds dédiés peints, pieds sur la ligne de sol**, PV lisibles (CMB-2, CMB-3 tenus) ; 2 replis flous, 3 fonds réutilisés | RP-278 P2, RP-279 P2, RP-157 |
| Pokémon (dos, faces) | dos de Salamèche vu en combat, Roucool et Dracaufeu adverses ; inventaire des dos par numéro | 143 numéros sur 151 ont un dos peint ; faces officielles | RP-010 (8 numéros) |
| Menus | 10 écrans | Thème 2026 respecté, textes entiers, icônes présentes | aucun nouvel écart (RP-099 à RP-101 restent ouverts, non reproduits dans cet échantillon) |

## 3. Écarts de priorité élevée

**P0 : aucun trouvé.** Éléments interactifs et obstacles lisibles partout où la carte est peinte ; sur les cartes provisoires,
les cases spéciales (herbes, dalles, courants, escaliers) restent distinguables, donc pas de P0 (SOL-3, DON-4 tenus).

**P1 : 9 nouveaux** (tous « art », aucun correctif code) :

| RP | Zone | Critère |
|---|---|---|
| RP-269 | Parmanie (ville) | BAT-1, SOL-1, GLO-1 |
| RP-270 | Parc Safari (4 zones) | SOL-1, GLO-1 |
| RP-271 | Arène de Parmanie | BAT-2, DON-1 |
| RP-272 | Postes-frontière et pavillons (Routes 15, 16, Parc) | BAT-2 |
| RP-273 | Routes 13, 14, 15, 17, 18 | SOL-1, SOL-2 |
| RP-274 | Routes 19, 20, 21 (mer) | SOL-1, EAU-5 |
| RP-275 | Îles Écume (5 étages) | DON-1, EAU-4 |
| RP-276 | Centrale | DON-1 |
| RP-277 | Salles de la Ligue et Panthéon (à confirmer S24) | DON-1 |

**P1 déjà ouverts** non touchés par cet audit : RP-010 (dos de 8 numéros). Les
autres P1 du registre sont des branches non fusionnées (RP-133, 143, 150) ou ont été réglés (RP-136, RP-024, RP-014).
Rappel de la sortie : **zéro P0 et zéro P1** ouverts : cet audit en ajoute 9, tous corrigeables par art seul.

## 4. Proposition de lots d'art

Même méthode que DAF.4 / DAF.9 : kit de la série, intégration par remplacement à l'identique, `dump_map_logic` et
`dump_map_nodes` avant / après identiques, planche validée par Kevin (DA-6), CI GitHub verte. Dans l'ordre :

| Lot | Contenu | RP fermés | Cartes | Taille |
|---|---|---|---|---|
| **DAF.10a Parmanie et Parc Safari** | ville (façades, enclos, sol), Arène (+ fond de combat propre, RP-279), 4 zones du Parc, pavillons, accueil | 269, 270, 271, (272 partie), 157 | ≈ 25 cartes | le plus gros ; Kevin fournit la vue générale de Parmanie (dossier 17 ou 18) |
| **DAF.10b Routes 13 à 21** | sol peint des Routes 13, 14, 15, 17, 18 ; mer peinte des Routes 19 à 21 (réutilise la mer de DAF.9) ; postes-frontière (Routes 15, 16, 18…) | 272, 273, 274 | ≈ 20 cartes | moyen |
| **DAF.10c Îles Écume et Centrale** | kit de grotte glacée (5 étages), salles de la Centrale | 275, 276 | 6 cartes | moyen, **suit DAF.10a et b** |
| **DAF.10d Ligue** | salles et Panthéon (confirmer RP-277 sur S24 avant d'ouvrir) ; décor du labo de Cramois'Île, étages de Sylphe | 277, 280 | 8 à 20 cartes | petit à moyen |
| **DAF.2 bis Fonds de combat** | Sylphe 1F, Arène de Cramois'Île, Arène de Parmanie (si non couvert), Centrale, Parc Safari | 278, 279, 157 | 5 fonds | petit |

Ordre conseillé : **DAF.10a → DAF.10b** (les deux seules zones traversées par tous les joueurs avant la Ligue) puis
DAF.10c, DAF.10d et DAF.2 bis en parallèle. RP-281 et RP-282 (P2, P3) partent avec DAF.10b si les raccords sont ouverts.
Rien de tout cela ne change une collision, un déclencheur ou une coordonnée.

## 5. Valeurs par défaut [D] prises

- Écart « Ligue » classé P1 (DON-1) **à confirmer sur S24** plutôt que P2 : les fonds sont lisibles mais vides à l'écran.
- Les postes-frontière non capturés (Routes 13, 14, 17, 18, 16 ouest) sont rattachés à RP-272 et à échantillonner au lot.
- Captures versionnées en JPEG 1170 × 540 (2,4 Mio) ; originales régénérables avec les trois scripts ci-dessus.
