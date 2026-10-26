# Registre des reportés

> Registre unique, établi le 2026-10-26 sur `main` @ `1b9b61d1` (mis à jour sur `b68ee46d`, DAF.5 2e partie), de **toutes les remarques laissées
> en attente** depuis le J4 (règle 3 de `CLAUDE.md` : les remarques de rendu se notent sans être
> corrigées tout de suite). Il remplace la section « Reportés (décision de Kevin) » d'`etat-projet.md`.
> Sources lues : cette section, les ≈ 130 mentions « report… » de l'historique d'`etat-projet.md`
> et d'`etat-projet-historique.md`, les clôtures, points ouverts et passations des
> `docs/tech/jalon-*.md` et des autres plans de `docs/tech/`, `docs/design/phase-da-grille.md`,
> puis, en lecture seule, les branches non fusionnées `jalon-23`, `prep/j26-j27`, `jalon-28` à
> `jalon-32`. Chaque point a été recherché dans le code, les données et l'historique git.
>
> Ce registre **alimente** le registre des anomalies du J33 (`registre-anomalies.md`, T6) : au
> J33, un point encore ouvert y passe avec son identifiant `RP-NNN`.

## Légende

- **Catégorie** : **rendu** · **défaut** (comportement faux) · **perf** · **idée** (ajout, réglage
  ou polish non demandé) · **fermé** (obsolète ou déjà corrigé, avec la preuve).
- **P** : gravités du J33 (`jalon-33.md`, tableau validé le 2026-10-21) et de la grille
  `phase-da-grille.md` : **P0** bloquant (crash, sauvegarde, progression, **texte coupé**, élément
  interactif illisible) ; **P1** majeur (rupture visible de tous, pixel art ou aplat résiduel,
  60 i/s non tenus) ; **P2** modéré (écart perceptible sans gêne) ; **P3** mineur (liste 1.0.x).
  Le critère de la grille est donné quand il y en a un (`POK-1`, `MEN-3`…).
- **Destination** : lot d'art **DAF.x** (`phase-da-cadrage.md`), **CV** (Combat vivant,
  `combat-vivant.md`), **Son**, **J33** (stabilisation, mesure, reproduction sur S24), **1.0.x**,
  **branche** (point propre à une branche non fusionnée : il se règle sur elle ou à sa fusion),
  **R-n** (arbitrage de Kevin, plus bas).
- **État** : *ouvert* (vérifié encore vrai), *ouvert, à reproduire* (visuel, aucun correctif trouvé,
  à revoir sur S24 au J33), *corrigé ici* (ce lot), *fermé* (preuve).

## Synthèse

| | Points |
|---|---|
| Recensés (doublons fusionnés) | **159** |
| Fermés avec preuve (obsolètes ou corrigés depuis) | **49** (§4) |
| Corrigés dans ce lot | **6** (§1 : RP-001, RP-003, puis R-1 à R-3 : RP-089, RP-090, RP-120, RP-121) |
| Ouverts sur `main` | **77** (§2) |
| Propres à une branche non fusionnée | **27** (§3) |

Ouverts sur `main`, par section : art des Pokémon 5 (DAF.1 reliquat, DAF.2) · monde, DAF.5 11 · lumière hors DAF.6 5 ·
polish DAF.8 17 · Combat vivant et Son 8 · J33 24 · 1.0.x 5 · arbitrages 2 (R-6 en attente, R-7 en 1.0.x).
Par gravité : **P0 0** (RP-090 réglé par R-1) · P1 6 · P2 27 · P3 44.
Aucun P0 sur les branches ; P1 des branches : RP-133, 136, 143, 150, 151.

## Arbitrages pour Kevin (R-n)

**Validés par Kevin le 2026-10-26 (« Oui, toutes les recos »)** : R-1 fait (`e772538c`), R-2 fait
(`04c1c2df`), R-3 fait (`41371de3`), R-4 et R-5 gardés tels quels, R-6 en attente des fusions du J23
et du J28, R-7 en 1.0.x, R-8 et R-9 tranchés au J33 sur S24.

- **R-1 — Orientation des adversaires et description du Sac de combat : fusionner
  `correctif-orientation-adversaires` dans `main` maintenant ?** La branche (3 commits du
  2026-10-24, base `38d8e446`, tests compris) retourne les artworks adverses tournés vers la droite
  (ta règle du 2026-10-26 : « jamais à droite », 17 espèces dont Herbizarre, Tortank, Roucarnage,
  RP-089) et passe la description du Sac de combat à 4 lignes (RP-090, texte coupé = **P0**).
  Elle touche `battle_art.gd`, `battle_stage.gd`, `battle_bag_panel.gd`, aussi modifiés par
  `jalon-29` à `jalon-31` (qui en ont repris tout ou partie) et voisins du chantier CV.
  *Recommandation : oui, maintenant, par la session de coordination* : les changements identiques des
  branches se fusionneront sans conflit, sauf la ligne « 3 lignes » de `jalon-30` (à régler à sa
  fusion en gardant 4) ; `jalon-23`, `prep/j26-j27`, `jalon-28`, `jalon-31`, `jalon-32` le
  récupèrent par `main`.
- **R-2 — Toast de la Clé Ascenseur (RP-120).** La donnée dit « ajoutée aux objets clés » ; le plan
  du J20 (§2.7.2, T-49) dit « obtenue » ; c'était resté ouvert (`jalon-20.md` §10.4).
  *Recommandation : « obtenue »* (comme le Scope Sylphe et les fossiles) : `"obtained": true` dans
  `data/items/items_j20.json` et ajout de `lift_key` à la liste de `test_item_obtained.gd`.
- **R-3 — Pokédex après une évolution (RP-121).** Défauts appliqués depuis le J9 sans décision :
  pas de toast « Pokédex mis à jour » à l'évolution ; la fiche d'une espèce obtenue par évolution
  affiche « capturé 0 fois ». *Recommandation : garder l'absence de toast ; masquer la ligne
  « capturé » quand le compte vaut 0* (ligne fausse en apparence, sans nouveau texte).
- **R-4 — « Tu prends la fuite ! » (RP-122).** Le jeu tutoie partout ; la remarque du J19 proposait
  d'harmoniser. *Recommandation : garder « Tu prends la fuite ! »* (tutoiement, `messages.json:31`).
- **R-5 — Vampirisme à 80 de puissance (RP-123)** (valeur moderne ; RB : 20) laissé « à juger au
  T26 » au J12, jamais tranché. *Recommandation : garder la valeur moderne*, cohérente avec la passe
  « règles modernes » S2G ; à revoir seulement si l'équilibrage du J33 le signale.
- **R-6 — Titre de zone du repaire Rocket (RP-124)** : on lit « CÉLADOPOLE » dans le repaire
  (`zones.json` le range dans la zone `celadon`). *Recommandation : une sous-zone « Repaire
  Rocket »*, posée **après** les fusions J23 et J28 (qui modifient `zones.json`).
- **R-7 — Cinématique de première sortie (RP-125)** (révélation de Bourg Palette, « Le commencement
  de toute aventure », reportée depuis le J3 au chantier ouverture, qui ne l'a pas prise).
  *Recommandation : 1.0.x (DAF.8)*, pas avant la RC.
- **R-8 — Lumière hors des trois lieux de DAF.6 (RP-040, RP-041).** Grotte Sombre, Route 10,
  Lavanville et Tour Pokémon gardent des remarques de lumière du J17 au J19. *Recommandation : les
  juger au J33 T2 sur S24 avec la grille (DON-2, DON-6), et ne rouvrir un lot DAF.6 que pour un P1.*
- **R-9 — 60 i/s dehors sur l'A17 (RP-102).** L'étalonnage de l'heure dorée coûte ≈ 8 ms ; le réglage
  « Lumière d'ambiance : économie » existe. Reste ouvert depuis le moteur commun : un étalonnage
  « à plat » des extérieurs et/ou une baisse de résolution. *Recommandation : trancher au J33 T3 sur
  les mesures du profilage, l'A17 n'étant pas la cible (le S24 tient 59 i/s).*

## 1. Corrigés dans ce lot (2026-10-26, dont les arbitrages R-1 à R-3)

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-001 | [jalon-11.md](jalon-11.md) T22 ; audit | `audit-pending-moves.md` périmé : listait encore Guillotine (effet `ohko` actif depuis le J24) | défaut | P3 | corrigé ici | régénéré par `tools/audit_pending_moves.py` : 126 espèces, 142 capacités, **5** en attente |
| RP-003 | [jalon-18.md](jalon-18.md) §9.5 n° 2 ; QA 2026-10-19 | Pas de départ de débogage à l'arrivée de l'échelle B du B1F de la Grotte Sombre (côté Marcel) | défaut | P3 | corrigé ici | nouveau `tools/debug_start/dark_cave_b1f_b.json` (spawn `arrivee_b`), ligne du README |
| RP-089 | Règle de Kevin (2026-10-26, QA S24 J29) | Adversaires dont l'artwork regarde à droite : ils tournent le dos au joueur (17 espèces, dont Herbizarre, Tortank, Roucarnage) | défaut | P1 | corrigé ici | corrigé : fusion de `correctif-orientation-adversaires` (R-1, `e772538c`), `BattleArt.FACING_RIGHT` |
| RP-090 | [jalon-20.md](jalon-20.md) ; QA J30, J31 | Description d'objet du Sac de combat coupée à 2 lignes (« … pendant un », Guérison à « d'un », Flûte, Hyper Ball à « Elle ») | défaut | **P0** (MEN-3) | corrigé ici | corrigé : même fusion (R-1, `e772538c`), description sur 4 lignes |
| RP-120 | [jalon-20.md](jalon-20.md) §10.4 | Toast de la Clé Ascenseur « ajoutée aux objets clés » au lieu de « obtenue » | défaut | P3 | corrigé ici | corrigé (R-2, `04c1c2df`) : `"obtained": true`, tests `test_item_obtained`, `test_celadon_data`, `test_hideout_key` |
| RP-121 | J9 (T21) | Pas de toast « Pokédex mis à jour » à l'évolution ; « capturé 0 fois » pour une espèce obtenue par évolution | idée | P3 | corrigé ici | corrigé (R-3, `41371de3`) : « capturé N fois » et la carte Capturé seulement si N > 0 ; pas de toast à l'évolution (gardé) |

## 2. Ouverts sur `main`

### 2.1 Art des Pokémon (DAF.1 reliquat, DAF.2)

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-010 | J11 à J20 ; DAF.1 (`0063e5cf`, « refusés à faire avec ChatGPT ») | **5 espèces sans dos peint** sur 126 : Tortank, Rondoudou, Kadabra, Voltali (+ Ossatueur, jamais montré de dos) ; repli pixel 64 px | rendu | P1 (POK-1) | DAF.1 reliquat (ChatGPT, Kevin) | ouvert : 121 / 126 dos dans `assets/sprites/pokemon/dos/` (rb 62, ia 77, 3d 16) ; le dos de Tortank est aussi relevé en QA du J31 |
| RP-011 | J20 (2026-10-16) | Dos d'Empiflor trop proche de Boustiflor | rendu | P3 (POK-2 non atteint) | DAF.8 | ouvert, à reproduire |
| RP-012 | [jalon-18.md](jalon-18.md) §9.5 ; J18 | Horizons des fonds de combat CB.3 à recaler sur capture | rendu | P3 (CMB-2) | DAF.2 | ouvert, à reproduire : DAF.2 a fixé 455/460 pour les nouveaux fonds seulement |
| RP-013 | DAF.2 (2026-10-25) | Emblème du fond de l'Arène d'Argenta qui ressemble à une Poké Ball | rendu | P3 | DAF.8 | ouvert (fond validé par Kevin, remarque notée) |
| RP-014 | DAF.2 (2026-10-25) | Fonds de combat de la 2e moitié (cartes des J23, J26 à J31) | rendu | P1/P2 (CMB-1) | DAF.2, après les fusions | ouvert (dépend des fusions) |

### 2.2 Monde : séries en attente et reliquats (DAF.5)

DAF.5, 2e partie (fusionnée dans `main` le 2026-10-26, `b68ee46d`, planche validée par Kevin) a livré la
série 25, le Chenipan d'ambiance et la vérification du pont du S.S. Anne ; « DA-9 sans retouche »
pour les séries 22 bis et 28. RP-020 et RP-021 sont donc fermés (§4).

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-022 | [jalon-16.md](jalon-16.md) §9.3 ; J16 | S.S. Anne : navire peu visible du quai, passerelle peinte comme un appontement, titre de zone en même temps que DEP-02, trémie 2,5 × 3, portes cabine B et restaurant mal calées, barrière haute, superstructure étroite, mer répétée ; mémoire du pont > 64 Mo | rendu | P2 | DAF.5 puis J33 T2 | ouvert : le pont est « vérifié » par DAF.5, la géométrie n'a pas changé |
| RP-023 | J20 (2026-10-21) ; série 22 bis | Céladopole : façades et intérieurs provisoires, fontaine petite, coin nord-ouest sans arbres, tabourets dessinés sous les clients assis | rendu | P2 (BAT-6) | J33 T2 (DA-9 : retouche seulement si le lot est rouvert) | ouvert ; Casino et repaire peints (série 22 bis) |
| RP-024 | [jalon-25.md](jalon-25.md) §3 (T10–T13) | Cramois'Île (Manoir, Arène) notée en aplats provisoires à la clôture du J25 | rendu | P1 si confirmé (BAT-2) | J33 T2 | ouvert, à reproduire : `phase-da-cadrage.md` dit le Manoir en coques peintes (série 28) |
| RP-025 | Reportés, raccords J21 ↔ J22 (2026-10-23) | Route 16 est : porte haute du poste lue comme une tache de terre (façade `bldg_velos_01` 7 rangées sur 8) ; arbre à Couper peu distinct de la forêt | rendu | P2 (SOL-2) | DAF.5 (raccords) | ouvert, à reproduire |
| RP-026 | [jalon-15.md](jalon-15.md) §9 ; J15 | Postes du souterrain : ouverture nord peinte visible derrière l'escalier ; grande plante du poste de la Route 5 (5, 2) qui masque l'ouverture vers Safrania | rendu | P3 | DAF.5 | ouvert, à reproduire |
| RP-027 | J20 (Route 8) | Arbre repère (3, 19) qui masque la porte du poste de la Route 8 ; corniche peu lisible | rendu | P2 (BAT-3) | DAF.5 | ouvert, à reproduire |
| RP-028 | [jalon-17.md](jalon-17.md) §9.4 ; J17 | Arbuste de FUTUR A peu lisible sous la forêt ; jeune arbre qui s'estompe sous le joueur | rendu | P2 (SOL-3) | DAF.5 | ouvert, à reproduire |
| RP-029 | [jalon-12.md](jalon-12.md) §10.3 n° 5 | Fouilleuse de la Route 2 lue comme une personne en noir, « R » illisible | rendu | P3 | DAF.5 | ouvert, à reproduire |
| RP-030 | [jalon-14.md](jalon-14.md) clôture | Rocket d'Azuria qui marche vite (pas de planche de course `sbire_h`) | rendu | P3 (PER-4) | DAF.5 | ouvert |
| RP-031 | J15 (2026-10-15) | Compagnon Miaouss petit en marche ; compagnon peut-être invisible dans le bâtiment de la Route 6 | rendu | P3 | J33 | ouvert, à reproduire (planche de 56 px depuis `84d569d6`) |
| RP-032 | Ouverture (OUV) ; J3 | Moitié ouest de la porte du rez-de-chaussée derrière le porte-manteau ; starters à 60 px | rendu | P3 | DAF.5 | ouvert, à reproduire |

### 2.3 Lumière et ambiance hors DAF.6

DAF.6 (fusionné le 2026-10-26, `da861440`) a traité la Forêt de Jade, les intérieurs et le Mont Sélénite.

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-040 | [jalon-18.md](jalon-18.md) §9.5 n° 3 ; J17, J18 | Bandeau « utilise Flash ! » peu contrasté ; voile sans Flash léger ; sol de la Grotte Sombre plus gris que la vue peinte ; Tour presque cachée depuis la Route 10 ; forêt de Lavanville très verte ; pas de brume | rendu | P2 (DON-2) | R-8 (J33 T2) | ouvert, à reproduire |
| RP-041 | [jalon-19.md](jalon-19.md) §9.5 n° 4 | Tour Pokémon : brume du 6F très discrète, voile du 7F plus clair que le 6F, dalle purifiée blanche saturée | rendu | P2 (DON-6) | R-8 (J33 T2) | ouvert, à reproduire |
| RP-042 | [jalon-09.md](jalon-09.md) T23 | Bord net en bas des rais de lumière de la Forêt de Jade | rendu | P3 | DAF.8 | ouvert : DAF.6 l'a laissé « inchangé » |
| RP-043 | J12 (2026-10-13) ; section Reportés | Mont Sélénite et Route 3 : masse d'ardoise uniforme à l'est de la Route 3, bande noire de 36 px à droite du sas, bouche du sas vue de face, ouverture ≈ 1,3 case pour 2, mare rectangulaire, bords en tranches, rochers du goulet ; Rondoudou compagnon peu contrasté ; « lumière rare » à confirmer sur téléphone | rendu | P2 (BAT-8) | DAF.8 ; lumière : J33 T2 | ouvert : DAF.6 a renvoyé la géométrie aux reportés |
| RP-044 | [jalon-10.md](jalon-10.md) ; J10 | Argenta plus verte et moins minérale que la vue peinte, paroi en bandes, forêt d'une colonne, pavé uniforme, porte du poste nord discrète | rendu | P2 (GLO-2) | DAF.8 | ouvert, à reproduire |

### 2.4 Polish 1.0.x (DAF.8)

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-050 | Reportés, J16 (2026-10-16) | Un Pokémon de Coupe sans planche d'exploration (Sabelette, Mystherbe…) coupe avec le trait seul ; idem pour Surf et Vol | rendu | P3 (POK-7) | DAF.8 | ouvert : `companions.json` 27 espèces |
| RP-051 | [jalon-04.md](jalon-04.md) §13 ; Reportés (2026-09-26) | Tassement des sauts (compression en paliers), anticipation, trajectoire, retour à l'attente | rendu | P3 (PER-5) | DAF.8 | ouvert : `Npc.HOP_STYLE_PARAMS` |
| RP-052 | [jalon-04.md](jalon-04.md) §13.10 ; Reportés | Recul du joueur dans la scène du starter joué en marche inversée (« moonwalk ») | rendu | P3 (PER-5) | DAF.8 | ouvert |
| RP-053 | Reportés | Orientations et animations fines des cinématiques (Chen sur « Un peu de patience. ») | rendu | P3 (PER-5) | DAF.8 | ouvert |
| RP-054 | [ouverture.md](ouverture.md) ; OUV (2026-10-10/11) | Ouverture : sous-titre de la légende petit, bandes grises latérales pendant le fondu depuis le blanc, pas de rayon de soleil, tapis Poké Ball dominant au labo, Nidorino qui flotte, éclair de Poké Ball discret, Chen sans expression gênée, « 2026 » du logo pâle, buste de la carte Continuer ancien | rendu | P3 | DAF.8 | ouvert, à reproduire (DAF.7b n'a repris que le décor du titre et l'ombre du logo) |
| RP-055 | [jalon-07.md](jalon-07.md) ; J7 | Vraie colonne d'attente (pieds joints) par planche ; bras lointain brun de l'enfant de profil ; bras du héros non inversés en course | rendu | P3 (PER-4) | DAF.8 | ouvert |
| RP-056 | J20 (2026-10-16) | Erika et PNJ adultes à l'air enfantin ; Rocket en civil caricatural ; serre trop dorée | rendu | P3 | DAF.8 | ouvert |
| RP-057 | J12 T18 | Goulet de Léa : rochers de la rangée 22 sur la case de chemin (51, 21) ; indice du Réveil caché par la tête du joueur | rendu | P3 | DAF.8 | ouvert, à reproduire |
| RP-058 | J20 | Poké Ball du Scope en partie cachée par la tête du joueur arrêté en (25, 3) | rendu | P3 | DAF.8 | ouvert, à reproduire |
| RP-059 | [jalon-08.md](jalon-08.md) §4 | Ombre en ellipse d'un objet au sol trop grande | rendu | P3 (SOL-6) | DAF.8 | ouvert, à reproduire |
| RP-060 | [jalon-14.md](jalon-14.md) clôture | Azuria : décor aléatoire retiré, rivage `relief_rivage_06` répété, lueur `hint` discrète sur bois clair | rendu | P3 (SOL-5) | DAF.8 | ouvert, à reproduire |
| RP-061 | [systemes-2.md](systemes-2.md) | Pas de mise en scène d'envol (Vol) hors combat | idée | P3 | DAF.8 | ouvert |
| RP-062 | [pokedex-refonte.md](pokedex-refonte.md) | Portrait du Pokédex : lisibilité du texte sur le verre, décor flouté (essai réversible, pas de décor par habitat), silhouette « ??? » peu contrastée, Pokémon derrière le nom à 1920 | rendu | P3 | DAF.8 | ouvert |
| RP-063 | Reportés ; DAF.6 | Intérieurs « vraie DA » : la lumière chaude est faite, le décor riche des références reste à peindre ; bas de la douche du rival sous le bouton Courir | rendu | P2 (BAT-5) | DAF.8 ; J33 T2 | ouvert |
| RP-064 | [integration-da-bourg-route1.md](integration-da-bourg-route1.md) | Télés de remplacement et meubles de côté (option A, géométrie gardée, « réversible en phase DA ») | rendu | P3 | DAF.8 | ouvert (défaut gardé) |
| RP-065 | DA.1 | Ombres de contact sous les arbres de forêt et les meubles (clé de règle prête, non activée) | idée | P3 (SOL-6) | DAF.8 | ouvert |
| RP-066 | J12 | Après une évolution par pierre, retour sur la carte et non au Sac | idée | P3 | 1.0.x | ouvert (conforme au dossier) |

### 2.5 Combat vivant (CV) et Son

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-070 | [jalon-11.md](jalon-11.md) T22 n° 10 ; J9 | Statuts : voile du poison plus rose que violet, effets simples (zigzags, « z » en police de secours), gel grisâtre, pas de respiration du sommeil ; pastille PSN de l'adversaire posée après « est empoisonné ! » | rendu | P2 | CV.3 | ouvert : `status_aura.gd`, `STATUS_POISON #A33EA1` |
| RP-071 | J14 (2026-10-14) | Enfoncement de Tunnel discret | rendu | P3 (CMB-5) | CV.2 | ouvert |
| RP-072 | [combat-vivant.md](combat-vivant.md) §1.3 | Le son d'une attaque et du coup part après l'élan et la descente des PV | défaut | P2 | CV.0 | ouvert (repères sonores prévus) |
| RP-073 | Reportés ; [combat-maquettes.md](combat-maquettes.md) | Le monde reste dessiné sous le décor opaque du combat (≈ 150 appels) ; le décor préchargé garde ≈ 20 Mo de VRAM hors combat | perf | P2 | CV (budget §2.8), mesure J33 T3 | ouvert, non remesuré |
| RP-074 | J9 T23 ; Reportés | « Touchez l'écran pour continuer » petit et pâle ; bouton ARRÊTER de l'évolution petit | rendu | P2 (MEN-1 si < 48 dp) | J33 | ouvert, à reproduire |
| RP-075 | [jalon-son.md](jalon-son.md) §5 sexies | « Sea » boucle sur une vague de 3 s ; « Cubone's Mother » reboucle avec une coupure | défaut | P3 | Son (avant le gel) | ouvert |
| RP-076 | [jalon-son.md](jalon-son.md) | 38 bruitages sans fichier ; ambiances `city`, `casino`, `rain` ; atténuation dans la zone purifiée ; atténuation pendant les cris ; clé `music` des cinématiques des branches | idée | P2 | Son (SON-16) | ouvert : 7 ambiances dans `assets/audio/ambience/` |
| RP-077 | [jalon-son.md](jalon-son.md) | Titres « The Final Road » (Route 23) et « Guide » (Chen) à confirmer à l'écoute | idée | P3 | Son | ouvert |

### 2.6 À mesurer ou reproduire au J33

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-091 | J7 à J19 (≈ 10 relevés) | Mémoire des textures au-dessus du repère de 64 Mo : 66 à 139 Mo selon la carte et l'appareil (≈ 106 Mo pour l'appli) ; « carte + voisines » ≤ 36 Mo | perf | P1 (MEN-7) | J33 T3 | ouvert : `perf_counter.gd:12` ; budget « carte + voisines » décidé au J10 |
| RP-092 | J9 à J22 | Creux de fps aux transitions de carte (7 à 40 i/s), à l'ouverture du menu, en fin de combat ; Menu → Équipe à 50 i/s | perf | P2 | J33 T3 | ouvert ; seule la Route 11 a eu un correctif (`fff8d3bc`) |
| RP-093 | [jalon-22.md](jalon-22.md) §8 | Carmin (quai) à 26–27 i/s, mesuré avant le moteur commun | perf | P1 si confirmé | J33 T3 | ouvert, à remesurer |
| RP-094 | [jalon-son.md](jalon-son.md) | A17 : ≈ 30 i/s dans le Pokédex, ≈ 34 dans les Paramètres | perf | P2 (A17) | J33 T3 | ouvert |
| RP-095 | [jalon-09.md](jalon-09.md) §8.3 | Forêt de Jade : 2 983 nœuds pour un budget de 3 000 ; traversée (7–9 min) et durée d'un combat jamais mesurées sur téléphone | perf | P3 | J33 | ouvert (`test_node_budget` vert) |
| RP-096 | [jalon-06.md](jalon-06.md), [jalon-07.md](jalon-07.md) | Fond flouté du menu et Stockage sans réutilisation de cartes (> ≈ 100 Pokémon) jamais mesurés sur S24 | perf | P3 | J33 T3 | ouvert |
| RP-097 | Reportés (J5) | Incident de saisie vu une fois (joueur reparti dans le mauvais sens), non reproduit | défaut | P2 | J33 (surveiller) | ouvert |
| RP-098 | J11, J14, J15 (4 relevés) | Panneau « oublier une capacité » collé au bord droit et bas, hors du cadre intérieur | rendu | P2 (MEN-1) | J33 | ouvert, à reproduire (`move_forget_panel.gd`) |
| RP-099 | [jalon-11.md](jalon-11.md) T22 n° 8 ; QA J27 | Nom de CT tronqué sur la carte du Sac (« CT34 — Pati… », CT46) | rendu | P2 (P0 si illisible, MEN-3) | J33 | ouvert, à reproduire |
| RP-100 | [jalon-12.md](jalon-12.md) §10.3 n° 11 | Sélecteur d'équipe : nom long et « K.O. » tronqués (« Rondou… ») | rendu | P2 (MEN-3) | J33 | ouvert : ellipse voulue, `party_target_card.gd:242` |
| RP-101 | [jalon-son.md](jalon-son.md) (2026-10-25) | Bouton « Cri » qui chevauche un peu le portrait du Pokédex | rendu | P2 | J33 | ouvert, à reproduire |
| RP-102 | [moteur-commun.md](moteur-commun.md) §1.4 | A17 : 60 i/s non tenus dehors (étalonnage par copie ≈ 8 ms + carte ≈ 8,5 ms) ; images isolées à 25–33 ms | perf | P1 (A17) | **R-9** | ouvert |
| RP-103 | Reportés J9 (T21) | Carte : rangée « Pokémon observés » rognée au format S24 ; image de zone « Forêt de Jade » générique ; fiche du Pokédex ouverte sur Aperçu | rendu | P2 (MEN-5) | J33 | ouvert, à reproduire (MM.2 n'en parle pas) |
| RP-104 | [jalon-14.md](jalon-14.md) clôture | Toasts de résultat du Sac qui restent jusqu'au toucher ; liste d'équipe défilée après un refus du Super Bonbon ; sélecteur de quantité d'une CT déjà possédée | défaut | P3 | J33 | ouvert, à reproduire |
| RP-105 | J17 (2026-10-16) ; J19 | Boîte de dialogue qui couvre le joueur quand la caméra est bornée (6F de la Tour) ou le compagnon | rendu | P2 | J33 | ouvert, à reproduire |
| RP-106 | [jalon-17.md](jalon-17.md) §9.4 n° 1 | Bouche de la Cave Taupiqueur coupée par le bord haut de l'écran à l'arrivée sur la Route 11 | rendu | P2 | J33 | ouvert, à reproduire |
| RP-107 | [jalon-19.md](jalon-19.md) | Rencontres trop fréquentes dans la Tour (taux 10 et 15) | idée | P3 | J33 (comparer à RB) | ouvert |
| RP-108 | [jalon-13.md](jalon-13.md) | `tools/check_json_keys.py` à lancer après chaque fusion : pas branché dans `tools/test.sh` | idée | P3 | J33 | ouvert |
| RP-109 | [jalon-19.md](jalon-19.md) §9.5 n° 2 | Départ de débogage : starter déduit de `party[0]` (un starter évolué en tête casse l'équipe du rival n° 5) | défaut | P3 (outil) | J33, après la fusion du J23 | ouvert : `debug_start.gd:334` ; fichier modifié par `jalon-23` |
| RP-110 | [jalon-25.md](jalon-25.md) §9.4 | Panneau intérieur de l'Arène de Cramois'Île (texte 78 « Le maître du quiz au sang chaud ! ») non posé | défaut | P3 | J33, après la fusion du J23 | ouvert : `cinnabar_gym.json` modifié par `jalon-23` |
| RP-111 | [jalon-15.md](jalon-15.md) §9 | Souterrain sans ciel (`interior = false`, hors `caves.json`) : à reprendre avec le jour/nuit | idée | P3 | J33 | ouvert |
| RP-112 | J22, J24, J32 | Évolutions de niveau absentes : Voltorbe → Électrode (30), Smogo → Smogogo (35), Machoc → Machopeur (28) | défaut | P2 | J32 (lot 32K) | ouvert sur `main`, **corrigé sur `jalon-32`** (`ce94335a`) |
| RP-113 | J14, J32 | Évolutions par échange inactives : Alakazam, Mackogneur, Ectoplasma absents des données de `main` | idée | P2 | J32 (`LocalTrade`) et fusions J26–J30 | ouvert |
| RP-114 | [audit-pending-moves.md](audit-pending-moves.md) ; J30 Q30-3 | 5 capacités sans effet moteur : Frénésie, Mimique, Brume, Danse Fleur, Mania | idée | P3 | 1.0.x | ouvert (défauts gardés par Kevin le 2026-10-22) |

### 2.7 1.0.x (petits défauts d'interface)

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-115 | J20 | Sélecteur d'équipe du combat translucide sur le décor ; carte de l'étage courant sans bordure | rendu | P3 | 1.0.x | ouvert, à reproduire |
| RP-116 | [jalon-07.md](jalon-07.md) | Stockage : bandeau translucide du résultat, pastilles sur le sprite, croix de fermeture non assombrie ; recherche, filtres et boîtes multiples | rendu | P3 | 1.0.x | ouvert |
| RP-117 | [jalon-06.md](jalon-06.md) T20 | Carte : illustration rognée aux coins seulement, réduction sans mipmaps, étiquettes qui se recouvriraient | rendu | P3 | 1.0.x | ouvert |
| RP-118 | [jalon-11.md](jalon-11.md) T22 n° 11, 15 | Compagnon peu lisible derrière le joueur ou la balustrade ; bulle haute ; bulle « ! » des PNJ chargée à part (`npc.gd:133`) au lieu d'`EmoteBubble` | rendu | P3 | 1.0.x | ouvert |
| RP-119 | [jalon-20.md](jalon-20.md) §10.4 | Panneau de cabine du repaire qui ne s'ouvre pas en entrant ; équilibrage de Giovanni à juger en jeu réel | défaut | P3 | J33 | ouvert |

### 2.8 Points qui attendent un arbitrage

| ID | Origine | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-124 | [jalon-20.md](jalon-20.md) §10.4 | Titre « CÉLADOPOLE » affiché dans le repaire Rocket | défaut | P3 | R-6 validé : après les fusions du J23 et du J28 | en attente : `zones.json:151` (fichier modifié par `jalon-23` et `jalon-28`) |
| RP-125 | Reportés (J3) | Cinématique de première sortie (révélation de Bourg Palette) | idée | P3 | DAF.8 (1.0.x, R-7 validé) | ouvert : hors du périmètre d'OUV |

## 3. Propres à une branche non fusionnée

Lecture seule ; ces points se règlent sur la branche ou à sa fusion (session du jalon). Les lignes
« Reportés » des branches qui diffèrent de `main` sur la lumière (forêt, intérieurs) sont d'anciennes
versions, déjà réglées sur `main` par DAF.6 : non reprises.

| ID | Branche | Description | Cat. | P | Destination | État / preuve |
|---|---|---|---|---|---|---|
| RP-130 | `jalon-23`, `prep/j26-j27`, `jalon-28`, `jalon-31`, `jalon-32` | Pas de `FACING_RIGHT` (adversaires tournés à droite) ; `jalon-29` et `jalon-30` l'ont | défaut | P1 | R-1 (par `main`) | `main` l'a depuis `e772538c` (R-1) : chaque branche le récupère à sa mise à jour sur `main` |
| RP-131 | `jalon-30` (correctif) ; probablement `main` | Après une reprise de l'appli pendant un combat, fond flou recadré (zoom différent) | défaut | P3 | branche ; à porter à la fusion du J30 | corrigé sur `jalon-30` (`Player.hold_camera`) seulement |
| RP-132 | `jalon-29` | Sulfura de carte = sprite d'oiseau générique (`pokemon/fearow`), petit, caché par la tête du héros | rendu | P2 | DAF.4 | ouvert |
| RP-133 | `jalon-29` | Sol haut et sol bas de la Route Victoire peu distincts (tuiles provisoires) ; vue générale peinte, poste de la Route 22, Route 23 | rendu | P1 (DON-3) | DAF.4 | ouvert |
| RP-134 | `jalon-29` | Rencontres très fréquentes dans la Route Victoire (1 toutes les 3 à 5 cases) | idée | P3 | branche (comparer à RB) | ouvert |
| RP-135 | `jalon-29` | Départ `moltres` sans Master Ball (objet du J26) | défaut | P3 | branche (fusion J26) | ouvert |
| RP-136 | `jalon-30` | Sprites provisoires de la Ligue : Olga (`cooltrainer_f`), Aldo (`docker`), Agatha (`channeler`), Peter (`traveler`) | rendu | P1 (PER-1) | DAF.4 | ouvert |
| RP-137 | `jalon-30` | Panthéon et générique : fond nuit uni ; textes [D] du générique à valider ; entrée Panthéon du Menu Dresseur (Q30-4) et Grand moment « champion » non faits | idée | P2 | branche, décision de Kevin portée par le J30 | ouvert |
| RP-138 | `jalon-30` | QA 30A de sauvegarde (Panthéon) réservée à Kevin (règle 1) | idée | P2 | branche | ouvert |
| RP-139 | `jalon-30` | Objectif du Menu Dresseur « traverser le Pont Pépite » (drapeaux du départ de débogage) | défaut | P3 | branche | ouvert, sans effet en vraie partie |
| RP-140 | `jalon-30`, `jalon-28` | A17 : ≈ 40 i/s en combat, 49–50 dans la Ligue ; Jadielle 39–41 i/s | perf | P2 (A17) | J33 T3 | ouvert (S24 à 59 i/s) |
| RP-141 | `jalon-31` | Mewtwo de carte (artwork réduit) qui recouvre le héros ; capture non vérifiée ; grilles et vue générale à valider | rendu | P2 | DAF.4 | ouvert |
| RP-142 | `jalon-31` | Capture à la Master Ball (T9, après J26), capture en équipe pleine, Max Élixir caché des Îles Écume | idée | P3 | branche / J33 | ouvert |
| RP-143 | `prep/j26-j27` (J26) | Mémoire de textures du 7F de la Sylphe : 161 Mo | perf | P1 (MEN-7) | DAF.3 | ouvert |
| RP-144 | `prep/j26-j27` (J26) | Fond de combat « bureaux », vue générale de Safrania, bords des salles de l'Arène sans mur peint | rendu | P2 | DAF.2, DAF.3 | ouvert |
| RP-145 | `prep/j26-j27` (J26, J27) | Équilibrage : rival n° 6 très dur, rival n° 5 Bulbizarre dur, Morgane 12–36 % au premier essai | défaut | P2 | branche (resimuler, décision de Kevin du 2026-10-22) | ouvert |
| RP-146 | `prep/j26-j27` (J26) | Trois drapeaux `saffron_gate_offer_*` restent dans la sauvegarde ; T26-05 non posé | défaut | P3 | branche | ouvert |
| RP-147 | `prep/j26-j27` (J27) | Karatékas du Dojo en sprite de randonneuse ; Médium Nestor avec une casquette ; fonds « Arène Psy » et « Dojo » | rendu | P2 | DAF.4, DAF.2 | ouvert |
| RP-148 | `prep/j26-j27` (J27), `jalon-28` | Icônes génériques de la CT46 (nom tronqué) et de la CT27 | rendu | P3 (MEN-2) | DAF.5 après fusion | ouvert |
| RP-149 | `prep/j26-j27`, `jalon-29`, `jalon-30` | Dédoublonnages de fusion : `kanto_j27_emprunts.json`, `j27_emprunts.json`, `tm_compatibility.json`, `jump_kick` / `counter` / `high_jump_kick` | défaut | P3 | branche (fusion) | ouvert |
| RP-150 | `jalon-28` | Arène de Jadielle en art provisoire, sans fond de combat ; Giovanni absent au retour dans l'Arène (à couvrir par un test) | rendu | P1 (DON-1) | DAF.4, DAF.2 | ouvert |
| RP-151 | `jalon-23` | Textures ≈ 75 Mo dans la Maison Secrète et la maison du Gardien | perf | P1 (MEN-7) | phase DA (décision de Kevin du 2026-10-26) | ouvert |
| RP-152 | `jalon-23` | Pêche du Parc (aucune case pêchable), Corde Sortie dans le Parc, art T7/T8 (vues peintes, sprites, dos du joueur) | idée | P2 | DAF.4, 1.0.x | ouvert |
| RP-153 | `jalon-23` | T21 équilibrage non fait (Koga) ; l'IA choisit Détritus plutôt que Toxik pour le Smogogo de Koga (IA inchangée jusqu'au T21) | défaut | P2 | branche | ouvert |
| RP-154 | `jalon-23` | « HYPNO » tronqué sur la carte de combat | rendu | P2 (MEN-3) | branche | corrigé sur `jalon-23` (`f7ccf543`), à valider |
| RP-155 | `jalon-32` | Matrice des 151 espèces « à compléter » ; Électhor sans artwork sur `jalon-29` ; `StaticRespawn.on_league_won` à brancher à la fusion du J30 | idée | P2 | J33 (intégration) | ouvert |
| RP-156 | `jalon-23`, `jalon-29`, `jalon-31` | Parcours non joués sur téléphone (zones nord/ouest du Parc, Surf de la Route 23, Route Victoire 2F/3F, rival n° 7, capture de Sulfura et de Mewtwo) | idée | P3 | J33 (QA de bout en bout) | ouvert |

## 4. Fermés (obsolètes ou corrigés depuis)

| ID | Origine | Description | Preuve |
|---|---|---|---|
| RP-200 | Reportés (J5) | Écran de démarrage « GODOT » | DAF.7 (`21f83a55`), fond sombre Android 12+ DAF.7c (`9c59f65d`) |
| RP-201 | Reportés J9 | Forêt de Jade trop claire (« parc ensoleillé ») | DAF.6 (`da861440`), validé |
| RP-202 | Reportés | Lumière chaude des intérieurs | DAF.6 (`da861440`), validé |
| RP-203 | Reportés J12 | Grotte du Mont Sélénite trop claire | passe « lumière rare » (`96a46f71`) puis profils `moon_*` de DAF.6 |
| RP-204 | Reportés J9 | Bulle « ! » de Théo rognée en haut de l'écran | `afc26ec3`, `EmotePlacement` |
| RP-205 | Reportés (combat-maquettes) | Grands Pokémon sans dos côté joueur (Florizarre, Dracaufeu…) | DAF.1 : 121 / 126 dos peints, Florizarre et Dracaufeu compris |
| RP-206 | J12 à J20 | Dos pixel de Salamèche, Reptincel, Pikachu, Abra, Machoc, Pyroli ; 16 dos 3D non branchés | DAF.1 (`dos_ia_*`, `dos3d_*`) |
| RP-207 | J13, J17 | Passe Colab des dos de Taupiqueur, Triopikeur, Soporifik | dos 3D `dos3d_050/051/096` branchés |
| RP-208 | J9, J11, J20, J29, J31 | Icônes génériques du Sac (Antidote, remèdes, Super et Hyper Ball, CT, objets clés, objets du J20) | DAF.5 (`9bb1d803`) : 68 / 68, `test_item_icons.gd` |
| RP-209 | DA.3, ouverture | Petit-déjeuner et affaires du rival provisoires | DAF.5 : `int_petit_dejeuner_01`, `int_lit_affaires_rival_01` |
| RP-210 | J9 | Bandeau « X souffre du poison » sous le voile | T23 du J9 (`BattleDirector._play_poison`, test) |
| RP-211 | J11, J12 | Test instable `test_rival_route22`, « Parameter "t" is null » | `5caf1059`, `371a6e76` |
| RP-212 | Passe systèmes 2 | Colonne « Services » de Jadielle très étroite | `01d32dc0` |
| RP-213 | J12, J17 | Héros caché sous le bouton Courir (échelle C du B1F) ; bouton Course qui masque un PNJ | D5 du J24 : boutons transparents sous le joueur (`ff771bae`, `moteur-commun.md` §3) |
| RP-214 | J17 | Contraste du héros < 3,0 sur `flash_qa` | `865d7fb0`, `b9ae971f` |
| RP-215 | J17 | CS05 au Sac, départs `flash_qa_*` | `d277e8e8` |
| RP-216 | J16 | Art `FX_COUPE` | `assets/world/fx/fx_coupe_01..04.png`, `cut_slash.gd` |
| RP-217 | J20 | Planche d'Évoli (compagnon) | `eevee` dans `data/pokemon/companions.json` |
| RP-218 | J20 | Art du Casino et du repaire | série 22 bis intégrée |
| RP-219 | J11 A-4 | IA qui change de Pokémon, Hurlement, Cyclone, Vol en combat | `ai_switch_rule.gd`, `roar`, `whirlwind`, `5130f409` |
| RP-220 | J12 | Mur Lumière sans effet | effet `screen` (`moves/mt_moon.json`) |
| RP-221 | J24 | Guillotine sans effet | `ohko` (`moves/j24.json:4`) |
| RP-222 | J14 | Tunnel et capacités de terrain hors combat | `field_moves.gd` (passe systèmes 2) |
| RP-223 | Passe systèmes 2 | Mise en scène du Surf ; Surf forcé après une chute | `553b5c3c` ; `MapTraits.forced_surf_cells` |
| RP-224 | J21, J22, S2 | Jeu muet : cris, musiques, Flûte, thème de la Tour | jalon Son (151 cris, 54 morceaux) |
| RP-225 | J22 T27 | Krabby → Krabboss | `kanto_j22.json` |
| RP-226 | J22–J24 | `vice_grip` / `vise_grip` en double ; `*_reprises.json` | absents de `data/` (rebasage du 2026-10-23) |
| RP-227 | J25 | `plan_check_argenta`, `plan_check_j24_mer` en échec | verts au T23 du J25 |
| RP-228 | J15, J22, J24 | Cartes de QA `qa_daycare`, `qa_sea`, `qa_teleport` (intérieur faux, `tex` élevé, courants invisibles) | cartes retirées (`9f2cb0b5`), aucun `qa_*` |
| RP-229 | J16 | Réplique d'Armand sans point final | `ss_anne_life.json:5` |
| RP-230 | J14 | « Cela n'aurait aucun effet » / « Sans effet » | même texte pour `NOT_USABLE` et `NO_EFFECT` (`bag_query.gd:57-58`) |
| RP-231 | J7 T0 | Clés `money` / `storage` de `DebugStart` | `debug_start.gd:27-37` |
| RP-232 | J15 | Panneau de la Route 5 « Azuria ↔ Safrania » | texte T-13 validé par Kevin, conforme à RB : pas un défaut |
| RP-233 | J19 | Objectif `tower_later` seulement pour une sauvegarde du J18 | comportement voulu (`jalon-19.md` §9.5) |
| RP-234 | J6 | `MoveCard` à 0 PP touchable (`ignore_pp`) | voulu pour le panneau d'oubli (`move_forget_panel.gd:73`) |
| RP-235 | Reportés | Un pas en trop si on lève le doigt à la fin du fondu | laissé tel quel (décision de Kevin) |
| RP-236 | J19 | Fuji qui reste debout | prière branchée le 2026-10-22 |
| RP-237 | J17, J15 | Rangées de retouches « reportées » dans `route_2.txt` ; textes de l'annexe A « reportés dans les données » | « reporté » au sens de « recopié » : fait |
| RP-238 | J4 | `BattleLayout`, étape `battle`, `GameState`, MEET, alias de cinématique | livrés au 4B |
| RP-239 | J23 | Parcours vers Koga long, indice de contact appuyé | validés par Kevin le 2026-10-25 |
| RP-240 | J23 | Rencontres Safari peu fréquentes, Rhinocorne qui fuit au premier caillou | taux RB gardés (Kevin, 2026-10-26) |
| RP-241 | J29, J31 | Hyper Ball sans icône | `assets/ui/items/ultra_ball.webp` (DAF.5) |
| RP-242 | J16 | Pikachu et Salamèche de dos en pixel art | `dos_rb_025`, `dos_*_004` |
| RP-243 | J22 | Héros dessiné à pied sur la Piste Cyclable | vélo provisoire (`mount_placeholder.gd:68`) ; planches : RP-021 |
| RP-244 | J9 T23 (ancien RP-020) | Planche du Chenipan d'ambiance | DAF.5 2e partie (`b68ee46d`) |
| RP-245 | J22, DAF.0 (ancien RP-021) | Série 25 non intégrée (vélo, pêche, Motard, Ornithologue, Loubard, frères pêcheurs) | DAF.5 2e partie (`b68ee46d`) |
| RP-246 | [jalon-15.md](jalon-15.md) §9 (ancien RP-002) | Départ de débogage `route_5` sans `route_5_entered` (objectif « Badge Cascade » au premier pas) | voulu : `test_route_5_life.gd` part de ce départ pour vérifier que l'entrée pose le drapeau ; correctif annulé après la CI (2026-10-26) |
| RP-247 | [jalon-19.md](jalon-19.md) §9.5 n° 5 (ancien RP-122) | « Tu prends la fuite ! » : tu ou vous | tutoiement gardé (R-4, Kevin, 2026-10-26) |
| RP-248 | J12 (ancien RP-123) | Vampirisme à 80 de puissance | valeur moderne gardée (R-5, Kevin, 2026-10-26) |
