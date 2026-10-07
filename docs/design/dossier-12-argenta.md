# Dossier 12 — Argenta et l'Arène de Pierre (jalon 10)

> Conçu par Kevin avec ChatGPT, V1 reçue le 2026-10-07 (prompt : `docs/design/prompts/chatgpt-dossier-12-argenta.md`) ; passe d'alignement de Claude et **20 décisions de Kevin** le même jour (section « Arbitrages » : toutes les recommandations de Claude retenues). **Source de vérité** pour la Route 2 nord, Argenta, son Musée, son Arène et le premier badge (jalon 10 de la roadmap). Les tracés ASCII donnent la logique, **pas une grille de production**. Textes : section « Textes verrouillés » (**validés par Kevin le 2026-10-07**, retouches de Claude comprises). **Pas d'implémentation avant la fusion du J9 et le plan technique `docs/tech/jalon-10.md`.**

**Ligne directrice** : Argenta ferme la **première grande boucle** de Kanto 2026 : partir → explorer → capturer → construire son équipe → traverser une zone exigeante → atteindre une ville → se préparer → affronter un Champion → obtenir son premier badge. Après la Forêt de Jade, la ville apporte du **soulagement** : plus ouverte, minérale, calme et stable. Jadielle était le premier contact avec une vraie ville ; Argenta est **le premier objectif de Dresseur accompli**. Après Pierre : « Maintenant, mon aventure a vraiment commencé. »

## Arbitrages de Kevin (2026-10-07)
1. **Équipe de Pierre, fidèle à Rouge/Bleu** : **Racaillou Nv. 12** (Charge, Boul'Armure) et **Onix Nv. 14** (Charge, Grincement, Armure, Jet-Pierres). Une seule attaque Roche, portée par son Pokémon fort. La V1 (Jet-Pierres sur les deux, ×4 sur Papilusion) rendait Pierre bien plus dur que l'original. **Niveaux ajustés après la mesure de la vraie partie de Kevin à la fin du J9.**
2. **IA de Pierre : `smart`** (celle du rival n° 2), pas de troisième IA. Elle fait déjà ce que la V1 décrivait (préférence pour le super efficace, capacité de statut deux fois au plus, jamais un statut sans effet). L'identité de Pierre passe par ses capacités.
3. **Réponse de Salamèche** (corrige la V1, d'après les données réelles) : Férosinge n'a Poing-Karaté qu'au Nv. 15 et Nidoran ♂ Double Pied au Nv. 43 ; la vraie réponse est **Papilusion** (Choc Mental dès l'évolution au Nv. 10, J9) et **Flammèche**, puisque Racaillou et Onix ont une **Défense Spéciale très faible**. Vérifié en QA avec un départ Salamèche.
4. **Sabelette chez le Dresseur de l'Arène** : oui (artwork officiel en face, coût faible). Il s'appelle **Campeur Liam** et il est **évitable**, comme dans Rouge/Bleu.
5. **Verrou de la Route 3 : un garde** à l'entrée est d'Argenta (sprite de garde du J9), qui énonce la règle. Ni gamin qui escorte, ni passage libre.
6. **Réactions au badge, seulement de qui peut savoir** : l'enfant, la jeune Dresseuse et le guide de l'Arène. Le tailleur, le vieil habitant, la visiteuse et l'employé du Musée gardent leur réplique. Le Montagnard de la Route 2 nord **remarque** le badge, il ne le sait pas.
7. **« Montagnard »** (nom français du Hiker de Rouge/Bleu) pour le PNJ de la Route 2 nord : « Randonneuse » est déjà sur la Route 2 sud.
8. **Réplique de victoire de Pierre neutre** : elle ne suppose aucune stratégie (on peut gagner par les niveaux).
9. **Sentier est de la Route 2 nord** : **obstacle naturel** (éboulis) et réplique d'environnement, pas de panneau « Accès fermé » (même principe que le FUTUR A du dossier 11).
10. **Arrivée** : titre « ARGENTA » seul, comme Jadielle ; **le Musée est visible dès le premier écran** par le level design. Pas de mouvement de caméra (l'étape de scène n'existe pas), pas de micro-scène.
11. **Remise du badge** : grande inscription **« BADGE ROCHE »** et vibration, puis la réplique de Pierre. **Pas de toast** « Badge Roche obtenu » en double.
12. **Grand moment générique « badge »**, réutilisable pour les 8 badges (badge, ville, Champion) ; il porte le **souvenir de l'équipe** au moment de la victoire : espèce, niveau, surnom, ordre. Ni formes ni états.
13. **Carte de présentation du Champion** (« PIERRE — Champion d'Arène d'Argenta ») avant le combat : oui, **simple et réutilisable pour les 8 Champions**, conçue avec le chantier des maquettes de combat. Nouvel élément d'interface, signalé.
14. **Deux maisons sur une même enveloppe peinte**, mobilier différent (comme les deux postes de la forêt). Nouveaux intérieurs peints du J10 : **Musée (2 salles), Arène, maison** ; Centre et Boutique réutilisés.
15. **Maison de la chercheuse** : deux répliques qui s'enchaînent (première fois, puis les suivantes), **sans drapeau** lié aux vitrines.
16. **Musée gratuit.**
17. **Mew** : un fragment de journal anonyme derrière une vitre, **aucun nom**.
18. **Team Rocket** : une seule phrase sur les collectionneurs de fossiles, **ni nom ni rumeur**.
19. **Rival** : une seule allusion, par Pierre, **après** la victoire. Rien avant.
20. **Roadmap inchangée** : J11 = grande passe de systèmes, **la Route 3 arrive au J12** avec le Mont Sélénite (la V1 suggérait la Route 3 au J11).

## Vue générale peinte v1 (validée par Kevin le 2026-10-07)
- **`reference/argenta-vue-generale-v1.png`** (essai 2, `tools/art/prompts/CONCEPT_ARGENTA_VUE_GENERALE_r2.txt`) = **référence DA et composition** d'Argenta et de la Route 2 nord : paroi de montagne, Arène-forteresse dans les rochers, place pavée au gros rocher, Musée à colonnes (le plus grand bâtiment), enseigne Centre / Boutique, chantier du tailleur et son Racaillou, bande de forêt entre la ville et la route, relief rocheux de la Route 2 nord ; ville minérale sans être aride.
- **`reference/argenta-plan-v1.png`** (`tools/art/plan_aplats.py --empiler tools/plans/argenta.txt tools/plans/route_2_nord.txt 3`) = **référence fonctionnelle et autorité de la géométrie**. En cas de contradiction, **le plan gagne**.
- **Ne pas reproduire** les écarts de la vue, tous sur la Route 2 nord : le décrochement du chemin principal et le poste décalé (le chemin est droit, du poste à l'avenue d'Argenta) ; le détour par l'ouest autour de la haie de buissons, à peine lisible (il existe) ; la Potion absente (elle est au bout du détour).
- Deux essais (r1 : ville écrasée dans la moitié haute, bâtiment en trop, hautes herbes en ville, clôtures ; r2 retenu). **Pas d'essai 3.**

## 1. Intention
- **Soulagement** en sortant de la forêt, puis une ville qu'on a envie de parcourir quelques minutes avant d'entrer à l'Arène.
- **Argenta se reconnaît sans lire son nom** (constitution) : **la pierre, le Musée, la montagne**.
- **Leçon de Pierre : comprendre les types** (dossier 06 §3), **sans tutoriel** : ni guide qui explique les faiblesses, ni énigme. Le premier puzzle est l'équipe du joueur.

## 2. Périmètre du jalon 10
| Maintenant | Visible mais fermé | Pas au J10 |
|---|---|---|
| Route 2 nord, Argenta (extérieur), Centre, Boutique, Musée (2 salles), Arène, 2 maisons, raccord est (« ROUTE 3 — À venir » en développement) | laboratoire du Musée (Ambre Vieille plus tard), sentier est de la Route 2 nord (futur secteur de la Grotte Taupiqueur) | Route 3 jouable, CT, nouveaux statuts, capacités d'exploration, échange de Pokémon, Corde Sortie, Team Rocket, rival |

**Aucune nouvelle mécanique de combat.** Deux ajouts signalés et acceptés : la **carte de présentation du Champion** (arbitrage 13) et des **capacités choisies à la main** pour les Pokémon d'un Dresseur (Pierre ; aujourd'hui un Pokémon de Dresseur n'a qu'une espèce et un niveau).

## 3. Route 2 nord
Un **sas court** entre la forêt et Argenta, pas une deuxième Route 2.
- **Taille** : ≈ 30 × 24 cases. Traversée directe ≈ 25–35 s ; en explorant ≈ 1 min 30 (indicatif, mesuré sur S24).
- **Raccords** : sud = porte nord du **poste nord** de la forêt (aujourd'hui « ROUTE 2 NORD — À venir », J9) ; nord = entrée sud d'Argenta.

```text
                 ARGENTA
              ═════╤═════
                   │
        herbe      │       relief
       ┌──────┐    │      rocheux
       │  H2  │    │
       └───┐  │    │
           │  │    │       ÉBOULIS (sentier est, fermé)
      ─────┘  └────┘
             │
        gros rocher
             │
     H1 ─────┼────────
             │
       POSTE NORD
             │
       FORÊT DE JADE
```

- **Hautes herbes** : deux petites zones (H1, H2), facultatives.
- **Rencontres** : même famille que la Route 2 sud, un niveau plus haut ; **aucune espèce nouvelle** (la forêt garde son identité biologique).

| Pokémon | Niveaux | Fréquence |
|---|---:|---:|
| Roucool | 5–7 | 35 % |
| Rattata | 5–7 | 30 % |
| Nidoran ♀ | 5–7 | 12 % |
| Nidoran ♂ | 5–7 | 12 % |
| Piafabec | 6–7 | 8 % |
| Férosinge | 6–7 | 3 % |

- **PNJ** : un **Montagnard** qui revient d'Argenta (arbitrages 6 et 7).
- **Objet** : **une Potion visible** dans un petit détour. Rien d'autre.
- **Sentier est** (arbitrage 9) : un embranchement fermé par des **éboulis**, réplique d'environnement. Ne promet ni Coupe, ni Force, ni échange. Pas de maison d'échange.

## 4. Argenta — structure
≈ **52 × 44 cases** (Jadielle : 56 × 36).

```text
                 RELIEFS ROCHEUX
┌────────────────────────────────────────────┐
│                                            │
│   ┌─────────┐        POINT DE VUE          │
│   │ MUSÉE   │              ▲               │
│   └────┬────┘                              │
│        │                    ┌───────────┐  │
│        │                    │  ARÈNE    │  │
│        │                    │  PIERRE   │  │
│        │                    └─────┬─────┘  │
│                                            │
│              PLACE CENTRALE                │
│        rochers · arbres · bancs            │
│                                            ├── GARDE ── ROUTE 3
│ ┌──────┐                    ┌──────────┐   │
│ │MAISON│      BOUTIQUE      │ MAISON   │   │
│ └──────┘                    └──────────┘   │
│                                            │
│          CENTRE POKÉMON                    │
│                │                           │
│       végétation plus dense                │
└────────────────┼───────────────────────────┘
                 │
             ROUTE 2 NORD
```

- **Grilles fonctionnelles** (2026-10-07, défauts de la règle 4) : `tools/plans/argenta.txt` et `tools/plans/route_2_nord.txt`, sources de la géométrie (plan en aplats, vue générale, construction). Pour tenir l'arbitrage 10, **le Musée est au sud-ouest, contre l'avenue d'arrivée**, et l'Arène ferme la ville au nord-est ; le tracé ci-dessus garde la logique, pas les positions.
- **Le Musée et l'Arène** sont les deux masses architecturales dominantes ; **les reliefs** se voient derrière la ville.
- **Le Musée est visible dès le premier écran** en arrivant du sud (arbitrage 10).
- **Sortie est** vers la Route 3 : existe dès l'arrivée, gardée jusqu'au badge (§9). Après le badge : « ROUTE 3 — À venir » en développement.
- **Arène accessible dès l'arrivée.**

## 5. Arrivée
Titre **« ARGENTA »** à la première entrée, comme Jadielle. Pas de cinématique, pas de caméra, aucun dialogue (arbitrage 10). Grand moment d'arrivée (« Arrivée à Argenta », système existant).
**Objectif** (en silence) : « continuer vers le nord. » devient « **obtenir le Badge Roche.** » (§16).

## 6. Habitants
Six habitants significatifs dehors, plus les personnages des bâtiments. **Ne réagissent au badge que ceux qui peuvent le savoir** (arbitrage 6).

| # | Habitant | Où, routine | Réagit au badge |
|---|---|---|---|
| 1 | Tailleur de pierre | chantier léger, aller-retour de 3 cases ; son **Racaillou** travaille près de lui | non |
| 2 | Enfant | autour du gros rocher de la place | oui |
| 3 | Visiteuse du Musée | place ↔ entrée du Musée | non |
| 4 | Vieil habitant | point de vue | non |
| 5 | Jeune Dresseuse (PNJ, pas de combat) | près du Centre | oui |
| 6 | Employé du Musée | courte routine devant l'entrée | non |

**Pokémon d'ambiance** : **Racaillou** (le seul nouveau dans le monde extérieur, avec son sprite peint), plus des espèces déjà connues chez les habitants. Racaillou n'est pas capturable au J10.

## 7. Musée d'Argenta
**Gratuit** (arbitrage 16), facultatif. Ambiance beaucoup plus silencieuse.
- **Salle principale**, trois vitrines : **Fossile Dôme**, **Fossile Nautile**, **Pierre Lune** (première préparation du Mont Sélénite). On ne donne aucun fossile au joueur.
- **Salle « science »** : l'évolution et les traces laissées par les Pokémon anciens ; deux chercheurs. L'un dit la phrase sur les **collectionneurs de fossiles** (arbitrage 18), qui prendra son sens au Mont Sélénite.
- **Fragment de journal d'expédition** derrière une vitre (arbitrage 17) : origine inconnue, pages manquantes, **aucun nom**. Mewtwo : aucune mention.
- **Porte « LABORATOIRE — Personnel autorisé »**, fermée (l'Ambre Vieille pourra s'y trouver plus tard).

## 8. Centre et Boutique
**Même enseigne que Jadielle** : mêmes intérieurs peints, quelques variations de décor extérieur, pas de nouvelle architecture. Le Centre devient point de repos (toast « Point de repos enregistré — Argenta », système existant).
**Stock de la Boutique** : Poké Ball 200 ₽, Potion 300 ₽, Antidote 100 ₽. Rien d'autre (pas de Corde Sortie).

## 9. Verrou de la Route 3
Un **garde** se tient au passage est (arbitrage 5). Avant le badge, il énonce la règle ; en lui reparlant, il dit qui dirige l'Arène. Il ne dit pas « va à l'Arène » et n'escorte pas le joueur. Après le badge, il dit sa réplique **une fois** et **se décale définitivement**.
**Valeur par défaut** (règle 4) : avancer sur l'entrée est sans le badge déclenche sa réplique, puis le joueur recule d'une case (comme les obstacles existants).

## 10. Arène d'Argenta
**Extrêmement simple, aucune énigme.** Salle de roche claire, grands piliers naturels, sol sableux et minéral, quelques formations rocheuses. **Pierre est visible depuis l'entrée.** Percussion discrète et espace minéral (intention audio).

```text
                 PIERRE
                   P
              ┌────┴────┐
         roche│         │roche
              └────┬────┘
                   │
               D1 ─┼── détour
                   │
             rochers bas
                   │
                   G
                   │
                ENTRÉE
```

- **G — guide d'Arène** : accueil, **aucun conseil de types** ; réagit au badge.
- **D1 — Campeur Liam** (arbitrage 4) : champ de vision 5 cases, **évitable** par le détour ; **Racaillou Nv. 10, Sabelette Nv. 10** ; 200 ₽ ; IA `random` (débutant). Battu = mémorisé (système du J9).

## 11. Pierre
Calme, observateur, sûr de lui, **pas arrogant**. Il ne traite pas le joueur en enfant à instruire : il veut voir comment il combat.
- **Carte de présentation** avant le combat : « PIERRE — Champion d'Arène d'Argenta » (arbitrage 13).
- **Équipe** (arbitrage 1, niveaux ajustables après la mesure du J9) :

| Pokémon | Niveau | Capacités |
|---|---:|---|
| Racaillou | 12 | Charge, Boul'Armure |
| Onix | 14 | Charge, Grincement, Armure, Jet-Pierres |

- **IA `smart`** (arbitrage 2). **Aucun objet.** **1 300 ₽** (montant fixe, comme les Dresseurs de la forêt).
- **Starters** : Carapuce (Écume dès le Nv. 8) a un net avantage ; Bulbizarre aussi à partir de Fouet Lianes (Nv. 13 ; avant, Vampigraine) ; **Salamèche est le plus exigeant** : Papilusion (Choc Mental) et Flammèche contre une Défense Spéciale faible, ou les niveaux, les changements et les baisses de statistiques (arbitrage 3). Aucun blocage.

## 12. Défaite contre Pierre
Pierre dit sa réplique de défaite, puis **système existant** : fondu, réveil au dernier Centre utilisé, **aucun argent perdu**. Au retour, Pierre **ne rejoue pas son introduction** (réplique courte de reprise). Campeur Liam, s'il a été battu, **reste battu**. L'objectif ne change pas.

## 13. Le premier badge
Après le dernier K.O. : bilan d'XP (et évolution éventuelle) → retour dans l'Arène → Pierre.
1. Réplique de victoire **neutre** (arbitrage 8).
2. Inscription **« BADGE ROCHE »** seule ≈ 2 s, vibration légère (arbitrage 11 ; même famille que « POKÉDEX ACTIVÉ »). Pas de toast.
3. Réplique de Pierre sur le badge.
4. Drapeau `badge_boulder` (existe dans `data/badges.json`) → écran Dresseur à jour (badge visible, détail « Badge Roche — Argenta — Pierre »), objectif changé en silence, sauvegarde automatique.
5. **Grand moment « badge »** générique (arbitrage 12) avec le **souvenir de l'équipe** (espèce, niveau, surnom, ordre), enregistré même si l'écran pour le revoir arrive plus tard (règle « données avant interface »).

**Effet mécanique du badge** : **aucun bonus caché** (l'Attaque augmentée de Rouge/Bleu disparaît définitivement), pas d'obéissance, pas de Flash. Le badge **reconnaît la victoire et ouvre la Route 3**. C'est suffisant.

## 14. La CT de Pierre
**Pas de CT au J10**, surtout pas une CT inutilisable dans le Sac. **Au J11**, quand les CT existent, Pierre a une nouvelle interaction pour les parties qui ont déjà le badge (« J'allais oublier. » → remise de la CT, drapeau propre à la CT) ; une partie commencée après le J11 enchaîne badge puis CT. Aucune partie lésée, aucune mécanique morte. **Rien à coder au J10.**

## 15. Rival
Absent. **Une seule allusion** (arbitrage 19) : en reparlant à Pierre après la victoire, un autre Dresseur de Bourg Palette est passé récemment, avec une façon de combattre très différente. Ni nom, ni équipe.

## 16. Objectifs du tableau de bord
| Moment | Objectif |
|---|---|
| Entrée à Argenta (jusqu'au badge, défaite comprise) | « obtenir le Badge Roche. » |
| Après la victoire | « continuer vers la Route 3. » |
| Quand la Route 3 existe (J12) | « continuer vers l'est. » |

Aucun sous-objectif (Musée, Centre…).

## 17. Ambiance
- **Golden hour**, légèrement plus sèche et minérale que Jadielle. Palette : pierre chaude gris-beige, ardoise, terre claire, verts un peu moins saturés, touches de fleurs discrètes. **Pas de filtre brun, pas de poussière permanente.** La ville reste belle et vivante, pas un biome rocheux uniforme.
- **Repères** : Musée, Arène, paroi montagneuse, gros rocher de la place.
- **Musique** (intention, sans implémentation) : calme, fière, plus posée que Jadielle ; Musée silencieux ; Arène en percussion discrète.

## 18. Données et sauvegarde
| Fait | Forme |
|---|---|
| Badge Roche (= Pierre battu, = Route 3 ouverte) | drapeau `badge_boulder` (existe) ; **aucun drapeau dérivé** |
| Campeur Liam battu | `beaten_<id>` (système du J9) |
| Potion de la Route 2 nord | objets trouvés (système existant) |
| Route 2 nord et Argenta découvertes | cartes découvertes (existe) |
| Point de repos Argenta | `heal_map` / `heal_spawn` (existe) |
| Grand moment « badge » + souvenir de l'équipe | détails du moment (`record_moment`) : **pas de changement de format** |
| Garde de la Route 3 décalé | dérivé du badge |
| CT de Pierre | **J11** seulement, drapeau séparé |

Pas de drapeau « Musée visité » ni « Musée payé ».

## 19. Les deux maisons
Une seule enveloppe peinte, deux mobiliers (arbitrage 14). Aucune récompense : elles rendent Argenta habitée.
- **Maison du tailleur** : sa compagne, un enfant.
- **Maison de la chercheuse** : bibliothèque, notes, quelques pierres ; deux répliques enchaînées (arbitrage 15). Sa sœur travaille au Musée.

## 20. Coûts techniques identifiés (pour le plan du jalon 10)
- **Données** : Racaillou, Onix, Sabelette (espèces, apprentissages, Pokédex), Jet-Pierres et Boul'Armure (Armure arrive au J9), table de la Route 2 nord, Campeur Liam, Pierre, stock de la Boutique d'Argenta, zones (`pewter_city` existe dans `zones.json` sans description).
- **Art** : Racaillou dans le monde (avec le tailleur) ; Racaillou, Onix, Sabelette en combat (artwork officiel en face) ; Pierre, tailleur, habitants ; intérieurs **Musée (2 salles), Arène, maison** ; Argenta et Route 2 nord (méthode du J8 : vue générale peinte → validation → kit → carte).
- **Moteur** : capacités choisies à la main par Pokémon de Dresseur ; répliques de défaite et de reprise pour Pierre (sur le modèle du rival) ; carte de présentation du Champion ; inscription « BADGE ROCHE » ; moment « badge » ; garde qui se décale.
- **Valeur par défaut** (règle 4) : la Route 2 nord est une zone à part, titre « Route 2 », sous-titre « Forêt de Jade — Argenta » (le sous-titre de la Route 2 sud, « Jadielle — Forêt de Jade », ne convient pas au nord).

## Textes verrouillés
Proposés par ChatGPT (V1), retouchés par Claude selon les arbitrages 6 à 9 et 15 (repérés **[retouche]**), **validés par Kevin le 2026-10-07**. Bulles de 2 lignes ; raccourcissables à la QA.

**Montagnard (Route 2 nord)** — avant le badge : « Argenta est juste devant. » / « On voit le Musée depuis la route. » · avec le badge **[retouche]** : « C'est le Badge Roche que je vois là ? » / « La Route 3 t'attend, alors. »
**Sentier est (Route 2 nord)** **[retouche]** : « Des éboulis bloquent le sentier. »
**Carte, description d'Argenta** **[retouche]** (reprend le sous-titre de la V1) : « Une ville entre pierre et montagne, au pied des reliefs de l'est. »
**Tailleur de pierre** : « Ici, la roche fait partie de la ville. » (inchangé après le badge **[retouche]**)
**Enfant** — avant : « Pierre connaît tout sur les Pokémon Roche ! » · après : « Tu l'as vraiment battu ?! »
**Visiteuse du Musée** : « Je suis venue pour les fossiles. » / « Certains ont des millions d'années. »
**Vieil habitant** : « Par temps clair, on distingue » / « les montagnes à l'est. » (inchangé après le badge **[retouche]**)
**Jeune Dresseuse** — avant : « Je me prépare avant d'affronter Pierre. » · après : « Alors c'est toi qui l'as battu… » / « Il faut que je m'entraîne encore. »
**Employé du Musée** : « Le Musée d'Argenta est ouvert. »
**Maison du tailleur** — compagne : « Il travaille la pierre depuis toujours. » · enfant : « Racaillou peut soulever des pierres énormes ! »
**Maison de la chercheuse** **[retouche]** — première fois : « Ma sœur travaille au Musée. » · ensuite : « Les fossiles racontent un monde » / « que personne n'a vu. »
**Musée — vitrines** — Fossile Dôme : « Un fossile extrêmement ancien. » / « Sa structure reste remarquablement intacte. » · Fossile Nautile : « Un fossile provenant d'une ancienne mer. » · Pierre Lune : « Une roche rare trouvée près du Mont Sélénite. » / « Sa composition intrigue encore les chercheurs. » · Fragment : « Fragment de journal d'expédition. » / « Origine : inconnue. » / « Plusieurs pages sont manquantes. »
**Musée — chercheurs** — « Les fossiles sont comme des pages » / « arrachées au passé. » · « Certains Pokémon ont changé au fil du temps. » / « D'autres semblent presque inchangés. » · « Les fossiles rares attirent parfois » / « les collectionneurs. »
**Musée — laboratoire** : panneau « LABORATOIRE — Personnel autorisé. » · porte : « L'accès est réservé aux chercheurs. »
**Garde de la Route 3** **[retouche : garde au lieu du jeune Dresseur]** — avant : « La Route 3 est réservée aux Dresseurs » / « qui ont obtenu le Badge Roche. » · en lui reparlant : « Pierre dirige l'Arène d'Argenta. » · avec le badge (une fois, puis il se décale) : « Badge Roche confirmé. » / « Bonne route ! »
**Guide d'Arène** — avant : « Bienvenue à l'Arène d'Argenta. » / « Ici, chacun vient avec sa propre stratégie. » · après : « Ton premier Badge… » / « Tu t'en souviendras longtemps. »
**Campeur Liam** — avant : « Pour atteindre Pierre, il faudra » / « d'abord passer par moi ! » · vaincu : « D'accord… Tu es prêt. » · après : « Pierre est encore plus solide. »
**Pierre** — avant : « Je suis Pierre, Champion d'Argenta. » / « Mes Pokémon ont été entraînés pour tenir bon. » / « Montre-moi comment tu comptes les faire céder. » · défaite du joueur : « Une équipe solide ne suffit pas. » / « Reviens avec une autre approche. » · reprise : « Prêt à essayer autrement ? » · victoire du joueur **[retouche, arbitrage 8]** : « Bien joué. » / « Mes Pokémon n'ont pas tenu face aux tiens. » · inscription : **BADGE ROCHE** · puis : « C'est la preuve de ta victoire » / « à l'Arène d'Argenta. » · en lui reparlant : « Un autre Dresseur de Bourg Palette » / « est passé récemment. » / « Vous avez des façons de combattre » / « très différentes. »
**Carte de présentation** : « PIERRE » / « Champion d'Arène d'Argenta »
**Objectifs** : « obtenir le Badge Roche. » · « continuer vers la Route 3. »
**Grand moment « badge »** **[retouche, arbitrage 12]** : titre « {badge} » · détail « Obtenu à {ville} contre {champion}. »
**J11, pour mémoire (non codé au J10)** : « J'allais oublier. » / « Ceci devrait t'être utile. »

## Décisions verrouillées
| Élément | Décision |
|---|---|
| Identité d'Argenta | Pierre · Musée · montagne |
| Route 2 nord | Sas court ≈ 30 × 24, 2 herbes, table de la Route 2 sud +1 niveau, Montagnard, 1 Potion, sentier est fermé par des éboulis |
| Argenta | ≈ 52 × 44, Musée visible dès l'arrivée, titre seul |
| Arène | Accessible dès l'arrivée ; aucune énigme ; guide sans conseil de types ; Campeur Liam évitable (Racaillou 10, Sabelette 10, 200 ₽) |
| Pierre | Racaillou 12, Onix 14 (une seule attaque Roche) ; IA `smart` ; aucun objet ; 1 300 ₽ ; carte de présentation |
| Leçon | Comprendre les types, sans tutoriel ; Salamèche le plus exigeant (Papilusion, Flammèche), jamais bloqué |
| Défaite | Dernier Centre, aucune perte d'argent, Pierre sans réintroduction, Dresseur battu le reste |
| Badge Roche | Inscription + vibration, pas de toast ; aucun bonus caché ; ouvre la Route 3 |
| Grand moment | « badge » générique, souvenir de l'équipe (espèce, niveau, surnom, ordre) |
| CT | Au J11, remise par Pierre aux parties déjà badgées |
| Route 3 | Garde jusqu'au badge, puis « À venir » ; jouable au J12 |
| Musée | Gratuit ; 2 salles ; laboratoire fermé ; aucun fossile donné |
| Mew / Mewtwo | Fragment anonyme / aucune mention |
| Team Rocket | Phrase sur les collectionneurs, sans nom |
| Rival | Une allusion de Pierre après la victoire |
| Réactions au badge | Seulement l'enfant, la jeune Dresseuse, le guide (et le Montagnard qui le remarque) |
| Nouvelles espèces | Racaillou (monde + combat), Onix, Sabelette (combat) |
| Centre / Boutique | Enseigne de Jadielle ; stock Ball, Potion, Antidote |
| Maisons | 2, une seule enveloppe peinte, sans récompense |
| Objectifs | « obtenir le Badge Roche. » → « continuer vers la Route 3. » |
| Audio | Intentions seulement |
| Roadmap | Inchangée (Route 3 au J12) |
| Textes | Verrouillés (2026-10-07), raccourcissables à la QA |
