# J18 — Route 9, Route 10, la grotte et Lavanville : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-14. J'ai relu la V2 (`j18-v2-chatgpt.md`) contre `vision.md`, la bible UI/UX,
> `roadmap.md`, les dossiers 06, 15 (J12), 16 (J13), 17 (J14, branche `docs/dossier-17-j14`) et
> 18 (J15, branche `docs/plan-j15`), les plans `jalon-12.md` à `jalon-15.md`, le code de `main`
> (`4f0ee90`, J13 terminé) et les branches de code du J14 (`j14-t23`) et du J15. Pour Rouge/Bleu :
> mémoire des tables de `pret/pokered`, **à revérifier une par une à la consolidation** (je marque
> « à vérifier » ce dont je ne suis pas sûr). Aucune ligne de code.
>
> **Numéro de dossier : 21** (`dossier-21-…`). 16 = J13, 17 = J14, 18 = J15 ; **19 = J16 et
> 20 = J17 réservés** (une branche `docs/dossier-20-j17` existe déjà, vide). Branche de ce travail :
> `docs/dossier-j18`.
>
> **Arbitrages numérotés I-1 à I-26** (D = J13, E = J14, F = J15 ; G et H restent au J16 et au J17).
> Les références J18-A à J18-J de la V2 sont gardées telles quelles.
>
> **Réponses de Kevin (2026-10-14) : « Tout ok sauf I-1 : on garde Grotte Sombre ».** Toutes les
> recommandations sont retenues ; **I-1 : le nom « Grotte Sombre » est gardé**. Consolidation :
> `docs/design/dossier-21-grotte-sombre-lavanville.md`.
>
> Origine des règles : **RB** = Rouge/Bleu, **G+** = génération plus récente, **K26** = invention de
> Kanto 2026. **[D]** = valeur par défaut, notée et non bloquante.

## 1. Les sept décisions verrouillées de la V2

Aucune n'est rouverte. D'accord sur le fond ; quatre demandent une précision technique.

| # | V2 | Avis |
|---|---|---|
| 1 | Route 9 + Route 10 + grotte + Lavanville | Oui. C'est exactement l'enchaînement RB après Coupe. **Mais le nom « Grotte Sombre » est celui d'une grotte de Johto** (RB/G+ : *Tunnel Roche*) → **I-1**. |
| 2 | Deux niveaux, embranchements lisibles | Oui, fidèle (RB : 1F et B1F). Les tailles proposées sont **trop grandes** (§4) → **I-9**. |
| 3 | Flash très utile mais facultatif | Oui. **Flash n'existe nulle part** : ni dans le code, ni dans un dossier, ni dans un plan. Le dossier 06 interdit qu'elle occupe un emplacement de capacité → **I-3 à I-6**. |
| 4 | Petit halo sans Flash, visibilité étendue avec | Oui, mais **rien n'existe** : la pénombre du Mont Sélénite est une image fixe, et des tests interdisent les `Light2D`. Faisable autrement, à coût modéré (§3) → **I-7, I-8**. |
| 5 | Difficulté modérée, rencontres variées | Oui. Les équipes ne peuvent pas être calées tant que J16 et J17 ne sont pas conçus → **I-12**. |
| 6 | Lavanville mélancolique, respectueuse | Oui, conforme à `vision.md` (« silence, brume, ancien ») et à la bible (« la ville où reposent les souvenirs »). **RB fait de Lavanville la plus petite ville** : la taille proposée est trop grande → **I-19**. |
| 7 | Tour : extérieur et rez-de-chaussée, étages au J19 | Oui. **Dans RB, le rival n° 5 est au 1er étage, accessible dès la première visite** : le verrou des étages est donc une adaptation volontaire, qui demande un motif dans le monde → **I-21**. |

## 2. Frontières avec les jalons voisins (audit point 1)

1. **J16 et J17 n'ont aucun dossier.** Tout ce que la V2 leur attribue (Coupe au J16, Flash au J17)
   n'est écrit nulle part dans le dépôt. Je l'écris comme **prérequis** du J18, sans le concevoir à
   leur place.
2. **Coupe et le menu des capacités de terrain = J16.** Le dossier 17 §7.4 (E-9) reporte « Tunnel
   hors combat » au « jalon des ex-CS (Coupe, S.S. Anne), qui concevra une seule fois le menu des
   capacités de terrain » ; le dossier 18 met Coupe au J16. **Flash doit se brancher sur ce menu,
   pas en inventer un second.**
3. **Route 11 et Grotte Taupiqueur ne sont attribuées à aucun jalon** (hors périmètre du J15, aucun
   dossier après). Or la V2 dit « progression depuis Route 11 », et **RB passe par la Grotte
   Taupiqueur ou par Coupe pour atteindre l'assistant de Chen qui donne Flash** → **I-4, I-13**.
4. **Ordre de RB : Route 9 est ouverte dès Coupe, avant Major Bob.** Dans RB, on peut traverser le
   Tunnel Roche avant le Badge Foudre. Le J18 vient après le J17 dans la roadmap, mais dans le
   **jeu**, le joueur y arrivera peut-être avant → **I-12**.
5. **J19.** Rival n° 5 (Tour, dossier 06 §6 : le Rattata a disparu), Médiums possédés, Osselait et
   sa mère, M. Fuji, Team Rocket. Dans RB, les étages hauts demandent le **Scope Sylphe**, gagné à
   Céladopole ; seul le rival (1er étage) est accessible avant. **Le J18 ne doit rien montrer de
   tout cela** → **I-21, I-22**.
6. **Roadmap.** Celle de `main` s'arrête à « J14+ … ← ICI » ; celle du J15 nomme J16 et J17 puis
   « J18+ Suite de Kanto ». **Je n'y touche pas** sans ton accord ; proposition au §6.

## 3. Ce que l'audit du code apporte

### Lumière (audit points 3 et 4)

1. **Aucun halo autour du joueur n'existe.** La pénombre du Mont Sélénite est **précalculée** à la
   construction de la carte : `CaveShade` (image de pénombre multipliée, sous les personnages),
   `CaveFloorLight` (sol éclairci autour des lampes) et `LightGlow` (≤ 16 halos fixes par carte).
   Rien ne bouge avec le joueur.
2. **Aucune `Light2D`, et des tests l'interdisent** (`test_light_glow.gd:241-254`,
   `test_mt_moon_maps.gd:117`). Le rendu `mobile` n'a jamais été mesuré avec des `Light2D`.
3. **Ma proposition technique (K26) : un voile d'obscurité percé**, sans `Light2D`. Une couche
   unique au-dessus du monde et des personnages, sous l'interface : noir bleuté à opacité réglable,
   avec un trou radial doux centré sur le joueur (shader d'un seul rectangle, rayon et douceur en
   paramètres). Les halos `LightGlow` existants percent aussi le voile (lampes, puits de lumière).
   **Flash = le même voile, rayon agrandi et ambiance relevée** : aucun changement de collision ni
   de carte, ce qui satisfait le risque n° 1 de la V2 *par construction*. Coût : une passe plein
   écran, à mesurer sur S21/S24 (budget du J12 : ≥ 58 fps moyens, creux ≥ 50).
4. **Ce voile change la règle du J12** (« les personnages ne sont jamais assombris ») : dans le
   noir, un Dresseur hors du halo **doit** être dans le noir, sinon il flotte. Conséquences à
   trancher : la bulle « ! » des Dresseurs passe au-dessus du voile ; le compagnon est adjacent,
   donc toujours dans le halo → **I-8**.
5. **Lisibilité mesurable.** `tools/art/luminance_grotte.py` mesure déjà le sol près du joueur, le
   contraste du héros et l'écart centre / pourtour. Il suffit d'ajouter un seuil **hors du halo**
   (relief encore lisible) pour garantir « jamais d'obscurité totale » → **I-7**.

### Capacités de terrain (audit point 3)

6. **Aucun code ni plan pour Flash, Coupe ou une CS** (`field_move`, `hm`, `cs05` : rien). Le seul
   « flash » du dépôt est un éclair de cinématique du J14 (`CutsceneStep.Kind.FLASH`).
7. **Dossier 06 §11 (verrouillé)** : les ex-CS restent, « sans occuper l'un des 4 emplacements de
   combat », et sont **visuelles**. Donc **pas d'« apprentissage » de Flash** au sens de la V2
   (J18-B) : on la *débloque*, et un Pokémon compatible de l'équipe l'utilise → **I-3**.
8. **Compteur du Pokédex** : `Pokedex.caught_count()` existe (affichage seulement). À la fin du
   J15, environ 22 espèces sauvages sont capturables : le seuil RB de l'assistant (10 espèces) est
   atteint par presque tous les joueurs.

### Grotte, rencontres, sorties (audit points 5 et 6)

9. **Rencontres seulement sur les cases de gravats** (J12 : `rubble`, table par étage, taux 25,
   rampe 15 → 20 ; 96 % du parcours du Mont Sélénite en couloirs calmes). RB : tout le sol de la
   grotte. Le système du J12 est gardé ; avec le voile, **les gravats doivent rester lisibles dans
   le halo sans Flash** → **I-10**.
10. **Échelles** : `WarpPoint` sans code dédié (24–54 ms par changement d'étage). Rien à créer.
11. **Corde Sortie** : `caves.json` → `escape` (une seule destination par grotte). Le Tunnel Roche
    a **deux entrées** : il faut choisir laquelle → **I-11**. **Tunnel** hors combat suit déjà la
    même règle (dossier 17 §7.4) et arrive avec le menu du J16.
12. **Compagnon** : visible en grotte, phrase « écoute l'écho de ses pas », masqué dans les passages
    étroits jusqu'au premier pas libre, jamais sur une échelle. **Rien à créer** (J18-I) ; seul le
    voile le concerne (point 4).
13. **Fonds de combat CB.3** : `data/battle/decors.json`, choisis par carte et par zone. Existants :
    `route_3_roche`, `mt_moon_galerie`, `mt_moon_chambre`… Il en faut **deux nouveaux** (route
    rocheuse de la Route 9 / 10, galerie sombre du Tunnel Roche) → défaut au §5.

### Espèces, capacités, Dresseurs (audit points 5 et 7)

14. **Espèces RB** (à vérifier) : Route 9 = Rattata, Piafabec, Abo / Sabelette ; Route 10 = les
    mêmes + **Voltorbe** ; Tunnel Roche = Nosferapti, Racaillou, **Machoc**, **Onix**. Kanto 2026
    a déjà mis Abo et Sabelette ensemble (pas d'exclusivités de version).
    - **Données présentes** : toutes, sauf Machoc, qui arrive avec le J14 (`j14-t23`).
    - **Face et icône** : l'artwork officiel couvre les 151.
    - **Dos peints : aucun, pour aucune espèce** (dos provisoires pixel art partout). Hors J18.
    - **Planches de marche** (compagnon) : Racaillou, Nosferapti, Piafabec, Rattata, Abo… oui ;
      **Onix, Voltorbe, Sabelette, Machoc, Nosferalto : non**. Non bloquant (elles
      ne servent qu'au compagnon) → défaut au §5.
15. **Capacités nécessaires aux niveaux 13–20** : toutes actives (Poing-Karaté, Balayage au J14,
    Ligotage, Jet-Pierres, Grincement, Sonicboom, Vampirisme, Ultrason, Morsure, Boul'Armure,
    Destruction, Picpic, Furie…). **Frénésie (`rage`) reste en attente** : à ne donner à aucun
    adversaire du J18. **Aucune capacité nouvelle obligatoire**, sauf si I-14 ajoute Osselait.
16. **Classes de Dresseurs** : planches existantes pour Montagnard, Randonneuse, Campeur, Fillette,
    Scout, Gamin… **Absentes : Pokémaniac** (classe emblématique du Tunnel Roche dans RB) et
    **Médium** (Tour) → **I-14, I-22**.
17. **Sauvegarde** : `main` en v6, J15 en v7 (Pension seulement). Dresseurs battus (`beaten_*`),
    objets (`got_*`) et événements vont dans `flags` : **le J18 ne demande aucune nouvelle version**
    si l'état de Flash est un drapeau (J18-G) → **I-6**.
18. **Objets** : Corde Sortie, Super Potion (J15) existent. **Repousse, Super Ball, Rappel, Poupée
    Pokémon : absents** ; Repousse est reportée par décision constante depuis le J12 → **I-20**.

### Accès à la Route 9 (audit point 2)

19. **Azuria est fermée à l'est par un arbre et une clôture, sans aucun warp** (`tools/plans/
    azuria.txt` l. 41 et 114, texte 17 « On ne passe pas par là pour l'instant. »). Le dossier 16
    a posé un indice (trou dans la clôture, l. 112). **Le J18 doit modifier la grille d'Azuria** :
    remplacer la barrière par l'arbre à couper du J16 et ajouter le raccord → **I-2**.

## 4. Durée de la traversée (risque n° 2 de la V2)

| | Mont Sélénite (J12, réel) | Tunnel Roche (V2) |
|---|---|---|
| Surface | 60×46 + 40×30 + 50×38 = **5 860 cases** | 78×58 + 64×52 = **7 852 cases** (+ 34 %) |
| Durée | estimée ≈ 10 min ; **mesurée** 1F 3 min, B1F 3 min 30, B2F 11 min 30 (événements et CT compris) | — |
| Dresseurs | 4 (dont 3 Sbires) | 4 à 6 |

La V2 veut une traversée **différente** du Mont Sélénite, pas plus longue. Avec un halo qui réduit
la vue, chaque case coûte plus cher : on hésite, on revient. Ma cible : **≈ 6 à 8 minutes sans
détour, Flash éteint**, soit environ **≈ 4 000 cases au total**, et un **chemin principal de
≈ 180 pas** (Mont Sélénite : 206 pas et 4 échelles).

**Proposition de géographie** (RB adapté) : entrée nord au **1F** (côté Centre) → première échelle
vers le **B1F** (le cœur de la traversée : colonne, paroi fissurée, zone humide) → seconde échelle
qui **remonte au 1F, dans sa moitié sud**, non reliée à la moitié nord → sortie sud. Deux cartes,
deux échelles sur le chemin principal, aucune téléportation : la moitié nord et la moitié sud du 1F
sont simplement séparées par la roche. → **I-9**.

## 5. Arbitrages

| # | Question | Recommandation |
|---|---|---|
| **I-1** | Nom de la grotte | **« Tunnel Roche »** (nom français officiel, RB/G+) ; « Grotte Sombre » est la grotte de Johto (Or/Argent), un joueur la reconnaîtrait. Alternative : garder « Grotte Sombre » comme nom propre de Kanto 2026 (K26). |
| **I-2** | Accès à la Route 9 | **Le J18 modifie la grille d'Azuria** : la barrière est (53, 22..24) devient l'**arbre à couper du J16** (même tuile, même règle) et la clôture s'ouvre ; raccord Azuria ↔ Route 9. Le texte 17 reste tant que l'arbre est debout. **Prérequis : Coupe du J16 codée** ; avant cela, départs de débogage seulement. |
| **I-3** | Nature de Flash | **Capacité de terrain du dossier 06 §11** : jamais dans les 4 emplacements, jamais en combat (pas de « Flash » qui baisse la précision). Elle est **débloquée** par l'objet clé **CS05** et utilisée par **un Pokémon compatible de l'équipe** (compatibilités RB), dans le **menu des capacités de terrain conçu au J16**. Le badge Roche (déjà obtenu) suffit, comme dans RB. |
| **I-4** | Source de Flash | **L'assistant de Chen, au poste de la Route 2, après 10 espèces capturées** (RB). La V2 la met au J17 sans dossier. **Je recommande** : si le dossier 20 (J17) ne la prévoit pas, **le J18 la pose** (le poste, l'assistant, la CS05), puisque c'est le premier jalon qui en a besoin. Le poste est atteint par Coupe (J16) depuis la Route 2 ; la Grotte Taupiqueur n'est pas nécessaire. **À confirmer avec la session du J17.** |
| **I-5** | Déclenchement de Flash | **Proposition à l'entrée** (K26, mobile) : en entrant dans le Tunnel Roche avec Flash disponible et éteinte, « Il fait très sombre. Utiliser Flash ? » OUI / NON, une fois par entrée ; ensuite par le menu des capacités de terrain. Alternative RB : par le menu seulement (moins découvrable). |
| **I-6** | Persistance de Flash | **Jusqu'à la sortie de la grotte**, changements d'étage compris (RB : jusqu'au changement de carte ; ici la grotte compte comme un tout). Corde Sortie, Tunnel, défaite ou porte extérieure l'éteignent. **Gardée dans la sauvegarde** par un drapeau effacé à la sortie (`flags`, **pas de nouvelle version**) : reprendre la partie dans le noir après l'avoir allumée surprendrait. |
| **I-7** | Visibilité sans Flash / avec Flash [D] | **Sans Flash** : halo net sur **≈ 2,5 cases**, fondu jusqu'à ≈ 4 ; au-delà, relief **encore lisible** (seuil de luminance mesuré, sol ≥ ≈ 0,10) : jamais de noir total. **Avec Flash** : halo de ≈ 7 cases (presque tout l'écran en hauteur), pénombre légère au bord. Réglés et validés sur S24 à luminosité moyenne. |
| **I-8** | Le voile et les personnages | **Le voile couvre aussi les personnages** (sinon un Dresseur hors du halo flotte dans le noir), **sauf** : le joueur, la bulle « ! » des Dresseurs et les halos fixes (lampes). Un Dresseur qui marche vers le joueur sort donc de l'ombre. Écart volontaire à la règle du J12 (« personnages jamais assombris »), à noter dans le dossier 15. |
| **I-9** | Taille et forme de la grotte | **≈ 4 000 cases au total** (ex. 1F ≈ 56 × 44 en deux moitiés, B1F ≈ 48 × 36), chemin principal ≈ 180 pas, **2 échelles** (1F nord → B1F → 1F sud), repères de la V2 au B1F. Grilles dans `tools/plans/` + `plan_check`, comme les J12–J15. Alternative : les deux cartes de la V2 réduites, sortie au niveau 2 (moins RB). |
| **I-10** | Rencontres dans la grotte | **Système du J12 (gravats seulement)**, un peu plus de gravats qu'au Mont Sélénite pour « rencontres variées » ; aucun gravat obligatoire hors du halo de 2,5 cases (on les voit toujours avant d'y marcher). Espèces RB : Nosferapti, Racaillou, Machoc, Onix, niveaux ≈ 13–17 [D]. |
| **I-11** | Corde Sortie et Tunnel | **Entrée nord (côté Centre), depuis les deux étages** : règle du J12 (« entrée extérieure »), une seule destination dans `caves.json`, le joueur retrouve le Centre. Alternative : l'entrée la plus proche selon la moitié du 1F (demande un second champ dans `caves.json`). |
| **I-12** | Calibrage de la difficulté | **Calibré pour un joueur qui sort du J16** (Coupe, sans Badge Foudre), **sans punir celui qui sort du J17** : RB permet les deux ordres, et rien ne bloque la Route 9 après Coupe. Niveaux RB ≈ 15–20 pour les Dresseurs [D], à reprendre quand les dossiers 19 et 20 existeront. |
| **I-13** | « Progression depuis Route 11 » | **Retirer la référence.** La Route 11 n'est attribuée à aucun jalon ; le J18 ne la suppose pas. La question « qui fait la Route 11 et la Grotte Taupiqueur ? » est **signalée** pour les sessions J16 / J17, pas tranchée ici. |
| **I-14** | Dresseurs et classes | **Route 9 : 7** (dont 2 inévitables) ; **Route 10 : 2** (sud, facultatifs) ; **Tunnel Roche : 5** (dont 2 inévitables) — dans la fourchette de la V2, bien moins que RB (≈ 15 dans la grotte : adaptation volontaire). Classes existantes + **une nouvelle : Pokémaniac** (emblème RB du Tunnel Roche), avec des Pokémon **déjà présents** (Rondoudou, Nidorino…) : **pas d'Osselait**, réservé à l'émotion du J19. |
| **I-15** | Route 10 nord | Centre Pokémon + **rivière et centrale visibles, non accessibles** (V2) ; la rivière arrête le joueur (pas de Surf), la centrale est un décor lointain sans porte atteignable. Aucun texte qui promette « plus tard ». |
| **I-16** | Route 10 sud et découverte de Lavanville | **La Tour est le repère visible depuis la sortie de la grotte** (silhouette au-dessus des arbres), pour « ressentir quelque chose » ; 0 rencontre forcée entre la grotte et la ville ; brume légère [D]. |
| **I-17** | Arrivée à Lavanville | **Légende de première arrivée** (mécanisme de l'ouverture OUV.3, déjà codé) : « LAVANVILLE / La ville où reposent les souvenirs » (formule de la bible). Pas de Grand moment (réservés aux combats et événements). |
| **I-18** | Sorties de Lavanville | **Ouest (Route 8) et sud (Route 12) : bords fermés « À venir »** en développement (mécanisme existant), aucun PNJ bloquant, aucun texte qui annonce Céladopole ou le Ronflex. |
| **I-19** | Taille de Lavanville | **≈ 44 × 36** (RB : la plus petite ville ; « silence » de `vision.md`), pas 58 × 46 (plus grand qu'Azuria, 56 × 41). Bâtiments : Centre, Boutique, Tour, **maison des Pokémon de M. Fuji**, 2 maisons. **Pas d'Expert en surnoms** : les surnoms n'existent pas encore (nouveau système, hors J18). |
| **I-20** | Boutique de Lavanville | **Objets déjà existants seulement** : Poké Ball, Super Potion, Potion, Antidote, remèdes du J11, Corde Sortie. Repousse et Super Ball : **reportées** (règle constante depuis le J12), sauf si un jalon antérieur les a créées. Alternative : créer la Super Ball ici (donnée simple, ×1,5). |
| **I-21** | Verrou des étages de la Tour | **Un motif du monde, pas un panneau de développement** : une **Médium en prière sur l'escalier** (PNJ non combattant) qui demande le silence ; elle s'écarte au J19 (un drapeau). RB n'a pas ce verrou (le rival est au 1er étage) : adaptation volontaire. Texte proposé au §7. |
| **I-22** | Rez-de-chaussée de la Tour | **Visiteurs, tombes, un gardien, la Médium** ; **aucun** : spectre, brume violette agressive, rival, Rocket, Osselait, allusion à un enlèvement. Le « dernier moment » du J18 = entrer, lire une tombe, entendre le silence. Planche **Médium** à créer (la même servira au J19). |
| **I-23** | M. Fuji | **Maison ouverte, Fuji absent sans alarme** : un enfant dit qu'« il passe ses journées à la Tour » (vrai dans RB, et rien n'annonce les Rocket). Alternative plus prudente : maison fermée au J18. |
| **I-24** | Nombre de sous-jalons | **Trois au lieu de six** (règle 1 : une validation S24 par sous-jalon) : **18.0** (grilles, vues peintes, données, art) ; **18A** Route 9 + Route 10 nord + Centre ; **18B** Tunnel Roche complet (géographie, voile, Flash, rencontres, Corde) ; **18C** Route 10 sud + Lavanville + Tour (RDC) + QA de bout en bout. Flash n'est pas un système à risque de perte de données : pas de validation isolée. |
| **I-25** | Dépendances de code | Le J18 **conçoit** maintenant, mais son **code** attend : Coupe et le menu des capacités de terrain (J16), Machoc et Balayage (J14), Super Potion (J15). En attendant : grilles, vues peintes, données et voile (indépendant) avancent. |
| **I-26** | Roadmap | **Après ton accord** : « J16 S.S. Anne + rival n° 4 + Coupe (dossier 19) · J17 Major Bob + Badge Foudre (dossier 20) · J18 Route 9 + Route 10 + Tunnel Roche + Lavanville (dossier 21) · J19 Tour Pokémon… ». Je ne la modifie pas sans ton « go ». |

## 6. Défauts verrouillables tout de suite [D]

- Fonds de combat : `route_9_roche` (sert aussi à la Route 10) et `tunnel_roche_galerie` (sombre
  mais lisible) ; aucune rencontre à Lavanville.
- Planches de marche manquantes (Onix, Voltorbe, Sabelette, Machoc) : **hors J18**, ces espèces ne
  sont simplement pas éligibles comme compagnon tant qu'elles n'ont pas de planche (règle du J11).
- Objets au sol : « nature dense, objets rares » — Route 9 : 3, Tunnel Roche : 2 (+ 1 caché si le
  système du J12 est codé), Route 10 : 1. Une Corde Sortie au 1F nord.
- Durée du voile au changement d'étage : le halo se recrée pendant le fondu existant, sans effet
  propre. « Réduire les animations » coupe seulement le léger battement du halo.
- Le voile ne s'applique **qu'aux cartes du Tunnel Roche** (`caves.json` : champ `dark`), pas au
  Mont Sélénite, qui garde son rendu validé.
- Centre de la Route 10 : point de repos comme les autres Centres.
- Musique : hors J18 (pas de système audio par zone à ce stade, à vérifier).

## 7. Textes proposés (à valider en lot dans le dossier)

1. *(entrée, Flash disponible)* « Il fait très sombre. Utiliser Flash ? » — OUI / NON
2. *(Flash utilisée)* « {pokemon} utilise Flash ! »
3. *(entrée, sans Flash, une fois)* « Il fait très sombre ici… Mieux vaut avancer prudemment. »
4. *(Médium, escalier)* « Chut… Les étages sont réservés au recueillement. Revenez plus tard,
   s'il vous plaît. »
5. *(tombe, examen)* « Ici repose Plumo, un ami fidèle. » (plusieurs variantes, sans drame)
6. *(enfant, maison de M. Fuji)* « Papy Fuji ? Il passe ses journées à la Tour. Il dit que
   quelqu'un doit veiller sur eux. »
7. *(légende)* « LAVANVILLE / La ville où reposent les souvenirs »
8. *(assistant de Chen, si I-4)* « Tu as déjà capturé {n} espèces ! Le professeur m'a demandé de te
   remettre ceci. » → « {joueur} reçoit la CS05 ! » ; sous le seuil : « Reviens quand tu auras
   capturé 10 espèces différentes. »

## 8. À fournir par la consolidation (après tes réponses)

- `docs/design/dossier-21-tunnel-roche-lavanville.md` (structure du dossier 18 : intention,
  périmètre, lieux, ambiance, espèces / capacités / objets / assets, données et sauvegarde,
  découpage S24, cas limites, lot complet de textes, valeurs par défaut, décisions verrouillées).
- Grilles `tools/plans/route_9.txt`, `route_10.txt`, `rock_tunnel_1f.txt`, `rock_tunnel_b1f.txt`,
  `lavender.txt`, `pokemon_tower_1f.txt` + contrôles `plan_check`, puis prompts des vues générales
  peintes.
- Vérification des tables RB (`pret/pokered`) : espèces, niveaux, Dresseurs, objets.
- Correctifs à reporter : dossier 15 (règle des personnages dans le noir, I-8), dossier 16
  (barrière est d'Azuria, I-2), roadmap (I-26, après ton accord).
