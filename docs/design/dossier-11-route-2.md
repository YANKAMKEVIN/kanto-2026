# Dossier 11 — Route 2 (Route 2 sud)

> Conçu par Kevin avec ChatGPT, reçu le 2026-10-06 ; passe d'alignement de Claude et **14 décisions de Kevin** le même jour (section « Arbitrages »). **Source de vérité** pour la Route 2 sud (jalon 8 de la roadmap). Le tracé ASCII donne la topologie, **pas une grille de production**. Textes : section « Textes à valider » (dernière lecture de Kevin avant verrouillage). **Ni production d'art ni implémentation avant la validation des textes et du plan technique `docs/tech/jalon-08.md`.** Prompt d'origine : `docs/design/prompts/chatgpt-dossier-11-route-2.md`.

**Ligne directrice** : la Route 2 est un **sas entre Jadielle et la Forêt de Jade**, pas une Route 1 bis. Le jeu resserre progressivement l'espace : « La ville est derrière moi. L'aventure continue vraiment. » Le J8 est **volontairement plus simple que le J7 et le J9** : son travail est de **donner envie d'avancer**.

## Arbitrages de Kevin (2026-10-06)
1. **Poste sud** : au J8, **seulement la façade** du poste sud de la forêt, objectif visuel de la route ; sa porte mène provisoirement à « **FORÊT DE JADE — À venir** » (même principe que la sortie nord de Jadielle au J7). Intérieur, garde et `poison_unlocked` : **J9** (dossier 10).
2. **Objets** : **2 visibles + 2 cachés**. La Poké Ball posée au sol est une petite évolution du langage d'exploration : **briques existantes et un asset peint**, pas de système générique complexe.
3. **Ambiance plus sombre et fraîche au nord** : **uniquement par le décor peint** (densité des arbres, canopée, ombres peintes, ciel moins visible). **Aucun changement dynamique de lumière** dans la carte (profil de lumière unique, `golden_hour`).
4. **Son et musique** : **intentions de DA documentées** (§15), **sans implémentation** au J8 ; reprises au chantier audio.
5. **Rattata d'ambiance** : il disparaît **en fondu derrière la végétation** avec les briques existantes ; si l'intégration montre qu'un nouveau système serait nécessaire, **repli sur une petite animation sur place**.
6. **Objectif du tableau de bord** : après l'activation du Pokédex, « **continuer vers le nord.** » (point final, règle des objectifs) ; actif pendant toute la Route 2 ; son remplacement à l'entrée de la forêt : J9.
7. **Panneaux** : au sud, « ROUTE 2 / Jadielle — Forêt de Jade » ; devant le poste, « FORÊT DE JADE » seul (pas « Entrée nord »).
8. **Noms affichés** : P1 « **Randonneuse** », P2 « **Jeune Dresseur** ». P2 est un **PNJ** : aucun champ de vision, aucun combat.
9. **Description de zone** (Carte, Pokédex) : « Un chemin bordé de prairies qui s'enfonce peu à peu sous les arbres. »
10. **Férosinge à 3 %** ; la Route 22 (15 %) reste l'endroit où le chercher.
11. **FUTUR A** : seulement **l'obstacle végétal et son texte** ; ni Coupe, ni CS, ni manière de le franchir verrouillées.
12. **Route 2 nord** : **non construite** au J8 ; seul son raccord futur est documenté (poste nord de la forêt → Route 2 nord → Argenta).
13. **Méthode d'art** : **vue générale peinte → validation de Kevin → assets nécessaires → construction directe de la vraie carte** ; pas de prototype séparé. La vue générale respecte le plan fonctionnel du dossier et sert à valider composition, densité, lisibilité et transition vers la forêt **avant** la découpe des assets. **Premier livrable du J8 après validation du dossier et du plan : la vue générale peinte.**
14. **Un seul rebord** franchissable vers le sud, sur le détour de H2 : **raccourci de retour vers Jadielle**, système existant, placement lisible, sans casser la progression vers le nord.

**Contrainte de raccord (Kevin)** : le raccord sud de la Route 2 correspond **exactement aux 3 cases de la sortie nord actuelle de Jadielle** (carte 56 × 36 ; avertissements `Route2SoonW/C/E`, colonnes 27 à 29). **Jadielle n'est pas modifiée** : c'est la Route 2 qui s'adapte.

## 1. Intention
Le **premier départ préparé** : le joueur quitte la sécurité de Jadielle avec son équipe, son Sac et son Pokédex et s'enfonce vers une zone inconnue.
- **Route 1** : découverte du monde et premières rencontres ;
- **Route 22** : détour facultatif, captures et rival ;
- **Route 2** : progression vers l'inconnu, exploration calme, préparation implicite à la forêt.
L'absence de Dresseurs est voulue : la nature reprend progressivement sa place.

## 2. Périmètre du jalon 8
**Route 2 sud seulement** : Jadielle → Route 2 sud → façade du poste sud → (« FORÊT DE JADE — À venir »). La Route 2 nord vient après la forêt (arbitrage 12).

## 3. Taille et durée
**≈ 42 × 60 cases** (moins massive que la forêt, ≈ 58 × 74 ; Route 1 : 48 × 44). Cibles de ressenti, **non verrouillées** (mesurées sur S24, elles ne dictent pas la géométrie) : traversée directe ≈ 2–4 min avec rencontres ; exploration attentive ≈ 7–10 min.

## 4. Entrées et sorties
- **Sud** : la sortie nord de Jadielle (3 cases, contrainte de raccord). L'écran « ROUTE 2 — À venir » est remplacé par la vraie transition ; **pas de bâtiment** entre Jadielle et la Route 2. Les dernières clôtures de Jadielle cèdent la place à la végétation.
- **Nord** : la **façade du poste sud** de la Forêt de Jade, visible avant d'y arriver, grand objectif visuel. Sa porte → « FORÊT DE JADE — À venir » (arbitrage 1).
- **Autres** : FUTUR A et FUTUR B, visibles mais fermés (§6). Aucune autre sortie.

## 5. Tracé
Topologie (pas une grille de production) :

```text
                         N
                         │
████████████████ ┌───────┴───────┐ ███████████████
████████████████ │ POSTE (façade)│ ███████████████
████████████████ └───────┬───────┘ ███████████████
████████████████         │          ███████████████
████████████████    C3   │          ███████████████
██████████████ ┌─────────┘          ███████████████
██████████████ │  ~~~~~ H3 ~~~~~    ███████████████
██████████████ │  ~~~~~~~~~~~~~~    ███████████████
██████████████ │             O4     ███████████████
██████████████ └──────┐             ███████████████
█████████████████████ │ ███████████████████████████
██████ FUTUR A ─ X ───┤ ███████████████████████████
█████████████████████ │ ███████████████████████████
██████████████         │        P2 █████████████████
██████████████   C2 ───┘           █████████████████
██████████████       GRANDE PIERRE █████████████████
██████████████             │       █████████████████
██████████████ ~~~~~ H2 ~~~│       █████████████████
██████████████ ~~~~~~~~~~~~│       █████████████████
██████████████ O2   ═ R ═  │       █████████████████
██████████████ ┌───────────┘       █████████████████
██████████████ │                   █████████████████
██████████████ │      O3           █████████████████
██████████████ │  ┌──────── X ─ FUTUR B ████████████
██████████████ │  │                █████████████████
██████████████ └──┤ P1             █████████████████
████████████       │                █████████████████
████████████  H1 ~~~~~~~            █████████████████
████████████      ~~~~~ O1          █████████████████
████████████        │               █████████████████
████████████       C1               █████████████████
████████████        │               █████████████████
                  JADIELLE (3 cases)
                         S
```

Légende : `│ ─` chemin · `████` végétation infranchissable · `~~~~` hautes herbes · `H` zone de rencontres · `C` clairière / respiration · `P` PNJ · `O` objet · `X` obstacle infranchissable (pour l'instant) · `FUTUR` zone visible destinée à plus tard · `═ R ═` **rebord** vers le sud (arbitrage 14 ; emplacement indicatif, sur le détour de H2).
Le chemin principal change quelques fois de direction mais reste très lisible : contrairement à la forêt, **le joueur voit presque toujours dans quelle direction continuer**. Détours courts. Chemins à angles droits.

## 6. Ce qui ne s'ouvre que plus tard
Repasser un jour et découvrir qu'un lieu contenait davantage : esprit Rouge/Bleu, **aucune mécanique future au J8**.
- **FUTUR A — passage boisé à l'ouest** : un chemin secondaire derrière les arbres, bloqué par un petit arbre dense. Interaction (texte). Mécanique future signalée (franchissement de végétation), **non définie** (arbitrage 11).
- **FUTUR B — sentier vers l'est** : fermé par une barrière légère et entretenue, avec un panneau. Interactions (panneau, barrière). Raccord géographique réservé (secteur de la Grotte Taupiqueur dans Rouge/Bleu), **destination non verrouillée**, rien d'indiqué au joueur.
Aucun état sauvegardé pour A et B au J8.

## 7. Zones de hautes herbes (3)
- **H1 — sortie de Jadielle** : petite, **entièrement contournable** ; réhabitue aux rencontres.
- **H2 — prairie centrale** : la plus grande ; **chemin sûr plus long ou traversée plus courte** (sécurité contre raccourci), sans tutoriel. Le rebord (§5) est sur son détour.
- **H3 — lisière** : quelques cases **obligatoires**, **5 à 7 au plus** sur le chemin principal, juste avant le poste.
Une seule table de rencontres pour les trois zones.

## 8. Rencontres sauvages
| Pokémon | Niveaux | Fréquence |
|---|---:|---:|
| Roucool | 4–6 | 35 % |
| Rattata | 4–6 | 30 % |
| Nidoran ♀ | 4–6 | 12 % |
| Nidoran ♂ | 4–6 | 12 % |
| Piafabec | 5–6 | 8 % |
| Férosinge | 5–6 | 3 % |

Nouveaux par rapport à la Route 1 : Nidoran ♀ et ♂, Piafabec, Férosinge, déjà rencontrables sur la Route 22, **volontairement** : qui a exploré la Route 22 les reconnaît, qui l'a ignorée peut encore les découvrir. **Aucun Chenipan, Aspicot, Coconfort, Chrysacier ni Pikachu** : la lisière annonce visuellement la forêt, ses rencontres restent une découverte. Rythme de rencontre : celui de la Route 1 (taux et rampe existants), sauf avis contraire au plan technique.

## 9. Pokémon d'ambiance (3 tableaux)
- **Roucool** : deux Roucool picorent dans l'herbe courte près du début ; à l'approche, l'un s'écarte de quelques cases, l'autre peut s'envoler (comportement existant).
- **Rattata** : près d'une souche sur le détour central ; il fouille brièvement le sol puis disparaît **en fondu** derrière la végétation à l'approche (arbitrage 5).
- **Nidoran** : un seul, au loin derrière une barrière naturelle dans la prairie ; il ne réagit pas au joueur (sexe choisi à la DA).
**Aucun Pokémon Insecte d'ambiance** : la forêt garde ce privilège.

## 10. PNJ non-combattants (2)
- **P1 — Randonneuse**, près du premier embranchement : marche entre trois cases, regarde vers le nord, revient. Sert à orienter.
- **P2 — Jeune Dresseur**, près de la grande pierre, avec son Pokémon si c'est visuellement léger. **Ne combat pas**, aucun champ de vision. Rappelle l'apprentissage de capacités **sans tutoriel**.
Pas d'échange de Pokémon, pas de don d'objet ni de Pokémon.

## 11. Objets (4)
| | Objet | Visible / caché | Emplacement | Découverte |
|---|---|---|---|---|
| O1 | Poké Ball ×1 | visible au sol | petit détour dans H1 | ramassée ; toast standard |
| O2 | Potion ×1 | visible au sol (même aspect qu'une Poké Ball, comme Rouge/Bleu ; Kevin, 2026-10-06) | au fond de H2 | ramassée ; toast standard |
| O3 | Poké Ball ×1 | cachée | près d'une souche | texte, puis toast standard |
| O4 | Potion ×1 | cachée | près de la lisière | texte, puis toast standard |

Objets visibles : asset peint posé au sol, disparaît une fois ramassé (arbitrage 2). Objets cachés : comme la Potion de la Route 1 (texte environnemental puis toast « Potion ×1 — Ajoutée au Sac » ; pas de deuxième bulle). **Aucun Antidote** (J9).

## 12. Capture et équipe qui se construit
Pas de nouveau système : la **composition des rencontres** fait le travail. Un joueur qui n'a que son starter et Roucool / Rattata rencontre régulièrement les espèces de la Route 22 ; celui qui a exploré la Route 22 peut chercher une espèce manquée ou renforcer son équipe avant la forêt. Les niveaux 4–6 rendent les nouvelles recrues utiles. Résultat recherché : **2 à 4 Pokémon que le joueur considère comme son équipe**, sans équipe imposée.

## 13. Apprentissage de capacités
**Aucune mécanique nouvelle** : la réplique de P2 rappelle le système ; s'il apprend une capacité sur la route, la présentation existante s'applique. Pas de fenêtre explicative, pas de CT, aucun PNJ ne donne de capacité.

## 14. Événements et narration
**Aucune cinématique.** Micro-moment environnemental : dans **C3** (≈ aux deux tiers), première vue franche sur **la canopée dense de la forêt et le toit du poste au loin** ; aucun contrôle retiré, aucun texte, **aucun drapeau** (pur level design). Rival absent ; Team Rocket absente et non mentionnée ; pas un mot de l'Arène d'Argenta (au plus la destination géographique sur un panneau).

## 15. Ambiance
Transition visuelle continue, **par le décor peint seulement** (arbitrage 3) :
- **sud** : beaucoup de lumière, prairies, clôtures ponctuelles, arbres espacés ; Jadielle encore perceptible ;
- **centre** : végétation plus haute, grosses pierres, chemin plus étroit, plus d'ombre ;
- **nord** : grands arbres, canopée qui se rejoint, ombres plus froides, ciel moins visible ; puis le poste.
**La Route 2 ne change pas l'heure ; elle change la quantité de lumière qui atteint le joueur.**
**Repères** : C1 deux grands arbres encadrant le départ → C2 grande pierre claire → C3 première vue franche sur la canopée (« arbres → pierre → forêt »).
**Son et musique (intentions, non implémentées au J8, arbitrage 4)** : au sud, vent doux, herbes, quelques cris de Pokémon lointains ; au nord, davantage de feuillage et de branches ; aucun insecte réel (sons animaux = Pokémon). Musique : route calme, plus de mouvement que la Route 1 ; « départ, curiosité, marche vers l'inconnu » ; pas de tension.

## 16. Défaite
Règle existante : réveil au **dernier point de repos** (Centre de Jadielle, sinon la maison). Aucun texte propre à la Route 2, aucun point intermédiaire.

## 17. Données et sauvegarde
À mémoriser : Route 2 découverte ; O1 à O4 ramassés, **chacun** ; « première fois / ensuite » de la Randonneuse et du Jeune Dresseur par **deux drapeaux** (méthode existante, comme le vieil homme de Jadielle ; décision de Kevin du 2026-10-06 sur le plan technique) ; espèces vues / capturées (Pokédex existant). Pas à mémoriser : Pokémon d'ambiance, clairières, herbes visitées, FUTUR A / B, le moment C3. **Format de sauvegarde inchangé attendu** (drapeaux d'histoire existants) : à confirmer par le plan technique.

## 18. Ce qui reste à faire au J9 (rappel)
Intérieur du poste sud, garde et `poison_unlocked` (dossier 10) ; remplacement de l'objectif « continuer vers le nord. » ; la porte du poste cesse de mener à « À venir ».

## Textes à valider
**Validés par Kevin le 2026-10-06, tels quels (T1 à T16).** Lot unique (règle : Kevin relit les textes en une fois). Bulles de 2 lignes de ~40 caractères au plus.

| # | Où | Texte |
|---|---|---|
| T1 | Panneau sud | **ROUTE 2** / Jadielle — Forêt de Jade |
| T2 | Panneau devant le poste | **FORÊT DE JADE** |
| T3 | P1 Randonneuse, première fois | Plus on monte, plus les arbres / deviennent serrés. |
| T4 | P1 Randonneuse, ensuite | La Forêt de Jade est droit devant. |
| T5 | P2 Jeune Dresseur, première fois | Mon Pokémon vient d'apprendre / une nouvelle capacité ! |
| T6 | P2 Jeune Dresseur, ensuite | Je ne savais même pas / qu'il pouvait apprendre ça. |
| T7 | FUTUR A (arbre dense) | Les branches sont trop épaisses. / Impossible de passer par ici. |
| T8 | FUTUR B, panneau | **ACCÈS FERMÉ** / Travaux sur le sentier. |
| T9 | FUTUR B, barrière | Le passage est fermé pour l'instant. |
| T10 | O3, cache | Quelque chose dépasse / sous les feuilles. |
| T11 | O4, cache | Quelque chose est coincé / près des racines. |
| T12 | Toasts des objets (format existant) | « Poké Ball ×1 — Ajoutée au Sac » ; « Potion ×1 — Ajoutée au Sac » |
| T13 | Objectif du tableau de bord | continuer vers le nord. |
| T14 | Description de zone (Carte, Pokédex) | Un chemin bordé de prairies qui s'enfonce peu à peu sous les arbres. |
| T15 | Porte du poste (provisoire, version de développement) | FORÊT DE JADE — À venir |
| T16 | Noms affichés | Randonneuse · Jeune Dresseur |

Points d'attention pour la relecture : T4 et T11 ressemblent à des textes existants (Route 1 : « Quelque chose est coincé entre les racines. ») — volontaire ou à varier ? ; T13 commence par une minuscule comme les autres objectifs (le tableau de bord les affiche après « Objectif : »).

## Décisions verrouillées
| Élément | Décision |
|---|---|
| Périmètre J8 | Route 2 sud ; façade du poste sud → « FORÊT DE JADE — À venir » |
| Route 2 nord | après la forêt ; raccord documenté seulement |
| Taille | ≈ 42 × 60 cases ; durées mesurées sur S24 |
| Raccord sud | exactement les 3 cases de la sortie nord de Jadielle, Jadielle inchangée |
| Dresseurs | aucun (le Scout Léo, forêt, reste le premier) |
| Hautes herbes | 3 zones ; 5–7 cases obligatoires au plus, près du poste |
| Rencontres | Roucool 35, Rattata 30, Nidoran ♀ 12, Nidoran ♂ 12, Piafabec 8, Férosinge 3 (%) ; Nv. 4–6 (Piafabec, Férosinge 5–6) |
| Insectes, Pikachu | aucun (rencontres et ambiance) |
| Pokémon d'ambiance | Roucool ×2 (écart / envol), Rattata (fondu), Nidoran (immobile, au loin) |
| PNJ | Randonneuse, Jeune Dresseur (sans combat) |
| Objets | Poké Ball ×2, Potion ×2 (2 visibles au sol, 2 cachés) ; aucun Antidote |
| Rebord | un seul, vers le sud, sur le détour de H2 |
| Futur | A : arbre dense (franchissement non défini) ; B : sentier fermé (destination non verrouillée) |
| Narration | aucune cinématique ; moment C3 sans drapeau ; rival et Team Rocket absents |
| Lumière | un seul profil (golden hour) ; transition par le décor peint |
| Son, musique | intentions documentées, non implémentées |
| Objectif | « continuer vers le nord. » après l'activation du Pokédex |
| Défaite | dernier point de repos |
| Nouvelle mécanique | aucune (objet visible au sol = briques existantes + un asset) |
| Art | vue générale peinte → validation → assets → vraie carte ; rien avant validation des textes et du plan |
