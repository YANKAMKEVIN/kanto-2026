# Dossier 09 — Jadielle, le premier hub (jalon 7)

> Conçu par Kevin (avec ChatGPT), reçu le 2026-10-02 ; passe d'alignement et décisions de Kevin du même jour intégrées. **Source de vérité du jalon 7 une fois la section « Textes à valider » (§19) relue par Kevin.**
>
> Le J7 est découpé en **J7A** puis **J7B** (§0), sans rien supprimer de la vision. La roadmap globale n'est pas modifiée. **Rien du J7 n'est codé avant la validation de ce dossier** ; le J5 reste prioritaire, puis le J6.

## Règle de déblocage (source de vérité, Kevin, 2026-10-02)

> **Une fonctionnalité visible n'existe pas pour le joueur avant son déblocage narratif, mais les données nécessaires peuvent déjà être collectées silencieusement lorsque cela garantit la continuité de son aventure.** (inscrite dans `vision.md`)

Application directe : le Pokédex (§6). Ses données sont enregistrées depuis le J5 ; l'écran n'existe pour le joueur qu'à partir de son activation par Chen.

## Intention

> **Bourg Palette : « Tu quittes chez toi. » — Jadielle : « Le monde commence ici. »**

La première vraie ville après Bourg Palette et la Route 1 : **dense et vivante plutôt que grande pour être grande** (échelle A+). Verdoyante, plus urbaine que Bourg Palette sans être une métropole ; ville de passage, commerces et voyageurs ; humains et Pokémon visibles dans la vie quotidienne (`vision.md` : « première vraie ville, commerces, voyageurs »). Les lieux importants se reconnaissent par l'architecture et le level design, **sans marqueur d'interface permanent**.

## Règles Kanto 2026 renforcées par le J7

- **A. Le monde existe indépendamment du joueur** : les personnages ont de petites activités et changent avec les événements.
- **B. Pas de tutoriel** quand un système peut se découvrir naturellement : architecture, animation et contexte font une partie de la pédagogie.
- **C. Un ancien système n'est conservé que s'il apporte encore quelque chose** : les rebords de la Route 1 restent (ils accélèrent le retour) ; la perte de la moitié de l'argent à la défaite disparaît.
- **D. Les lieux ont une fonction** : le Centre reste utile parce que le soin, le point de retour et le stockage y sont liés.
- **E. Le jeu se souvient de l'aventure** : lieux découverts, captures, rencontres et certains résultats narratifs influencent l'interface ou de petites répliques futures.
- **F. Pas de checklist omniprésente** : pas de pourcentage d'histoire, pas de compteur qui révèle des secrets, pas de GPS permanent.
- **Un personnage ne sait que ce qu'il a vécu ou ce qu'il peut raisonnablement avoir appris** : aucune omniscience des PNJ.

## 0. Découpage

| Partie | Contenu | Pourquoi |
|---|---|---|
| **J7A** | Jadielle (ville, habitants, Arène fermée), Centre Pokémon (soin, point de repos, stockage V1), Boutique, économie, colis, retour chez Chen, **activation du Pokédex**, sortie nord provisoire | Le premier hub et la boucle « argent → achats → soin » |
| **J7B** | Route 22, rival n°2, IA de combat de niveau 2, scène du rival contre un autre dresseur | Premier combat de dresseur hors prologue ; dépend de l'activation du Pokédex (§13) |

On ne construit pas tous les systèmes en même temps : J7A est validé sur S24 avant de commencer J7B.

---

# J7A

## 1. Jadielle — structure en micro-zones

Logique du lieu (**à ne pas reproduire au pixel près** ; le plan exact se conçoit dans Godot) :

```
                        NORD
                 (Route 2 : J8 — §11)
                         │
             ┌───────────┴───────────┐
       QUARTIER NORD            PARC / PASSAGE
             └──────────┐ ┌──────────┘
                 PLACE CENTRALE
               ╱        │        ╲
        CENTRE POKÉMON  │       BOUTIQUE
               ╲        │        ╱
                 QUARTIER SUD
                        │
                     ROUTE 1

   ROUTE 22 ── ARÈNE ── (vers la place centrale), à l'ouest
```

- **Arrivée progressive depuis la Route 1** : végétation sauvage → environnement entretenu → premiers bâtiments → titre discret « JADIELLE ».
- **Aucun PNJ n'explique où sont le Centre et la Boutique** : leur architecture et leur emplacement suffisent.

## 2. Une ville vivante

- **Environ 6 habitants significatifs** plutôt que beaucoup de PNJ immobiles. Pistes : un **livreur lié à la Boutique** (il peut être le Voyageur de la Route 1, comme le prévoit déjà le dossier 07 §5), une jeune Dresseuse qui revient de la Route 2 avec son Pokémon, un enfant qui joue avec son Pokémon, un voyageur arrivé du nord, un habitant intrigué par la fermeture de l'Arène, le **vieil homme** (§19).
- **Petits comportements** : marcher, regarder son Pokémon, changer de réplique ou disparaître après certains événements (drapeaux `if` / `unless`, déjà disponibles).
- **Entrer ou sortir d'un bâtiment (V1)** : le PNJ marche jusqu'à la porte puis disparaît ; sa présence à l'intérieur dépend des drapeaux. Pas de système de continuité physique entre les cartes pour cette seule animation.
- **Première arrivée** (décision de Kevin, 2026-10-02) : micro-scène **à la première arrivée seulement**, **4 s au plus**, contrôles bloqués, **aucun dialogue** ni caméra spectaculaire : titre JADIELLE, l'enfant traverse en courant derrière son Rattata, le Roucool posé sur le toit de la Boutique s'envole à leur passage (et reste absent pour cette visite), un voyageur venu du nord croise le joueur et continue vers le sud ; puis contrôle rendu et la ville reprend sa vie normale. Elle dit seulement : il y a du monde ici.

## 3. L'Arène

Visible très tôt, légèrement à l'écart vers l'ouest, **fermée**. Examiner la porte donne une phrase (§19) ; un habitant s'interroge sur l'absence du Champion. Pas de cadenas d'interface, aucun message sur le moment où elle ouvrira. Le mystère (Giovanni, dossier 06) prendra son sens bien plus tard.

## 4. Première visite et colis de Chen

- **Arrivée libre** : Centre, Boutique, Arène, habitants, Route 22 et le reste sont accessibles ; le joueur n'est pas enfermé dans la quête principale.
- **À la première visite de la Boutique**, le marchand reconnaît que le Pokémon du joueur vient du labo de Chen et lui confie le colis (§19). Toast : « COLIS POUR CHEN — ajouté aux objets clés ».
- L'**objectif** du tableau de bord (dossier 08 §1) devient en silence « Objectif : remettre le colis au Professeur Chen ». **Jamais** de fenêtre « OBJECTIF MIS À JOUR » (dossier 02).
- La Boutique reste entièrement utilisable après. Le retour n'est pas imposé immédiatement.

## 5. Retour par la Route 1

Les rebords orientés vers le sud servent de raccourcis au retour (« ah, ces rebords permettent de revenir beaucoup plus vite »). **Déjà en place** : la Route 1 du J5 a un rebord à sens unique vers le sud.

## 6. Retour chez Chen et activation du Pokédex

- **D'où viennent les données ?** Avant l'activation, les observations sont collectées en arrière-plan par le **système de recherche de Chen**, notamment à travers les Pokémon et Poké Balls qu'il a confiés au joueur (dossier 04 §5 : stockage « lié aux recherches de Chen » ; dossier 05 §17). **Le Pokédex n'est pas l'origine des données, c'est l'interface qui permet de les consulter.** Aucun texte validé du prologue ne change.
- **Scène** : le joueur remet le colis ; Chen remarque les informations déjà enregistrées, avec **une seule variante dynamique** qui cite la **première espèce sauvage observée** (version générique si aucune) ; il présente le Pokédex comme un outil de recherche de terrain, pas comme une checklist (dossier 04 §14 : « Découvre-les tous »). **Le rival arrive après la remise du colis** (il n'attend pas au labo pendant tout le séjour du joueur à Jadielle) et reçoit lui aussi son Pokédex. Chen donne à chacun une motivation légèrement différente.
- Caption « POKÉDEX ACTIVÉ ». **Tout ce que le joueur a déjà découvert apparaît immédiatement** dans son Pokédex : Kevin tient à cet effet.
- **Avant l'activation, rien de ce qui vient du Pokédex n'est visible** (décision n° 3, appliquée dès le J5) :
  - pas de « Nouvelle entrée Pokédex » sur la carte de capture (J5, dossier 05 §17) ;
  - pas de toast « Pokédex mis à jour » ;
  - pas de compteur vus / capturés (tableau de bord, écran Dresseur) ;
  - pas de liste des Pokémon observés sur la Carte ;
  - la carte Pokédex est **absente** du tableau de bord, **pas grisée** (dossier 08, règle 8) ;
  - pas d'indication « Efficace / Peu efficace » en combat (dossier 05).
  - Un **drapeau de débogage** débloque tout pour développer et tester le J6.
- Les données continuent d'être enregistrées silencieusement (jalon 5 §16 : vu, capturé, lieux, dates, compteurs).

## 7. Centre Pokémon

Quatre fonctions : **refuge, soin, point de retour, stockage**. Compact mais vivant : comptoir de soins, quelques sièges, quelques Dresseurs et Pokémon, terminal de stockage, petites animations d'ambiance.

- **Soin rapide** : l'infirmière propose de soigner, avec deux gros boutons tactiles **SOIGNER / PAS MAINTENANT** ; le petit rituel Pokémon dure **environ 3 secondes** ; phrase de fin (§19).
- **Première utilisation** : toast « Point de repos enregistré — Jadielle ». **Le dernier Centre utilisé devient le point de retour après une défaite.** Tant qu'aucun Centre n'a été utilisé, le point de retour reste la maison (dossier 07 §11), y compris si le joueur perd avant d'être passé au Centre.
- **Maman continue de soigner gratuitement** à Bourg Palette (décision de Kevin du 2026-10-02), mais ne remplace pas le dernier Centre enregistré comme point de retour.
- Le soin déclenche une **sauvegarde automatique**.

## 8. Stockage Pokémon (V1)

- **Nom d'interface officiel : « Stockage Pokémon ».** Un stockage unique, pas de boîtes 1, 2, 3.
- **Équipe de 6 au plus.** À partir du 7e Pokémon capturé, il est envoyé automatiquement au stockage (déjà codé au J5). Texte narratif conservé : « {Pokémon} a été confié au système de recherche de Chen. » : il relie le stockage au travail de Chen sans nommer toute l'interface ainsi.
- **Accès uniquement depuis un Centre Pokémon** ou un lieu explicitement équipé pour cela, par le menu Équipe. **Pas de PC magique accessible partout.**
- **V1** : voir l'équipe et le stockage ; **déposer** ; **reprendre** ; glisser-déposer tactile **et** une alternative par sélection et bouton (accessibilité) ; **favori** ; **LIBÉRER** dans un menu secondaire, avec confirmation. **Un favori ne peut pas être libéré.** **Le dernier Pokémon de l'équipe ne peut être ni déposé ni libéré** (« Tu dois garder au moins un Pokémon avec toi. ») : **règle métier** (logique testable du stockage), pas seulement une protection de l'interface.
- **Reportés** : recherche et filtres (Type, Niveau, Récents, Favoris), quand la taille réelle de la collection les rendra utiles.

## 9. Boutique

- Un vrai petit lieu physique, mais des achats par une **interface tactile rapide** qui partage le langage visuel du Sac du J6 (dossier 08 §3).
- **ACHETER / VENDRE.** Pour chaque objet : nom, description courte, prix, quantité déjà possédée, sélecteur de quantité, **total calculé immédiatement**.
- Pas de succession inutile de confirmations. **Objets clés exclus de la vente.** Un objet favori demande une confirmation avant d'être vendu.
- **Le stock évolue avec la progression.** **Jamais d'objet pour une mécanique qui n'existe pas encore** (pas d'Antidote tant que le poison n'existe pas). Stock initial : **Poké Ball, Potion**.

## 10. Économie

- **Argent de départ : 3 000 ₽** (provisoire). Prix de référence provisoires : **Poké Ball 200 ₽, Potion 300 ₽**.
- Les 5 Poké Balls de Chen évitent toute obligation d'acheter tout de suite.
- **Sources d'argent** : combats de Dresseurs (`TrainerData.prize_money` existe déjà), objets de valeur, récompenses futures. **Les Pokémon sauvages ne donnent pas d'argent.**
- **Aucune perte d'argent à la défaite** (règle C ; le dossier 05 §23 laissait la question ouverte). La conséquence de la défaite est déjà le retour au point de repos.
- **L'argent n'apparaît que là où il sert à décider** (dossier 08) : Boutique, Sac quand c'est pertinent, écran Dresseur. Jamais dans le Pokédex ni sur la Carte.

## 11. Sortie nord (provisoire)

La Route 2 est au J8. Dans la version de développement seulement, la sortie nord mène à un écran « **ROUTE 2 — À venir** » (même principe que l'entrée de Jadielle au J5, dossier 07 §12). **Aucun faux obstacle** à justifier ensuite dans le scénario : au J8, la vraie transition remplace simplement cette limite.

---

# J7B

## 12. Route 22

- Accessible depuis Jadielle dès le J7, **exploration facultative**. Sensation : « Je ne suis peut-être pas censé aller très loin par ici… mais je peux regarder. »
- **Pas de « niveau recommandé »** : l'environnement, et éventuellement une remarque diégétique (§19), suffisent.
- Une portion **montre la direction du Plateau Indigo** sans permettre d'y progresser.
- **Bestiaire à fixer** (Rouge/Bleu : Rattata, Piafabec, Férosinge, Nidoran ♀ et ♂). Aux niveaux de la Route 22, aucune de ces espèces ne connaît de capacité de poison : pas de conflit avec les statuts, prévus plus tard.

## 13. Rival n°2

- **N'existe qu'après l'activation officielle du Pokédex.** Avant, la Route 22 peut être explorée, mais la rencontre ne se déclenche pas.
- **Le rival ne se contente pas d'attendre** : à l'arrivée, on le voit terminer un combat contre un autre jeune Dresseur (mise en scène, pas un combat jouable), puis il remarque le joueur (§19). Il poursuit sa propre aventure.
- **Rencontre facultative** : elle n'a pas besoin d'être gagnée pour continuer l'histoire.
- **Équipe (base de travail, à valider avec les données réelles et la QA)** : Pokémon secondaire **Nv. 7** (Roucool, ADN historique, sauf si le bestiaire de la Route 22 offre mieux), starter **Nv. 8** avec l'avantage de type (Bulbizarre → Salamèche, Salamèche → Carapuce, Carapuce → Bulbizarre). Simulation du J5 : arrivée naturelle à Jadielle vers Nv. 7–8.

## 14. IA du rival : niveau 2 (règle durable)

> **Le rival ne progresse pas seulement par ses niveaux et son équipe : sa manière de combattre progresse aussi**, et cette progression participe à son arc narratif (dossier 05 §19, dossier 06 §6).

- Rival n°1 (labo) : comportement très simple (IA `random`, la seule qui existe aujourd'hui).
- **Rival n°2** : privilégie les attaques super efficaces, évite les actions manifestement inutiles, n'abuse pas d'une capacité de statut, devient plus agressif quand il est faible.
- Plus tard : changements de Pokémon, meilleure lecture des types, objets, synergies, équipe plus construite.

## 15. Victoire, défaite et mémoire

- Victoire : répliques du rival (§19). Défaite : retour au point de repos (§7) ; **le résultat est accepté par l'histoire**.
- **Trois états enregistrés : pas affronté, gagné, perdu** (drapeaux). Ils pourront faire varier de petites répliques futures (« Ne prends pas trop confiance à cause de la Route 22. » / « Tu veux vraiment recommencer après la Route 22 ? »). **Jamais trois branches narratives** : ce sont des variations de mémoire du monde.

---

## 16. Conséquences sur le J5 et le J6

- **J5 (maintenant)** : le T15 n'affiche pas « Nouvelle entrée Pokédex » ; aucun élément visible du Pokédex au J5 ; les données continuent d'être enregistrées (`jalon-05.md` §17).
- **J6** (dossier 08 corrigé le 2026-10-02) : la carte Pokédex est absente du tableau de bord avant l'activation, les compteurs et la liste des Pokémon observés sont masqués, un drapeau de débogage débloque tout ; **favoris Pokémon adoptés** (et protégés contre la libération) ; la catégorie OBJETS CLÉS accueillera le colis.

## 17. Données et sauvegarde

Le format de sauvegarde est versionné (jalon 5 §16) : les ajouts du J7 passent par une nouvelle version, avec des valeurs par défaut pour les parties existantes.

| Fait | Forme | Arrive |
|---|---|---|
| Pokédex activé | drapeau | J7A |
| Argent | entier (3 000 ₽ pour une nouvelle partie et pour une partie existante) | J7A |
| Point de repos | `GameState.heal_map` / `heal_spawn` (existe déjà) | J7A |
| Colis | objet de catégorie « objets clés » dans le Sac | J7A |
| Pokémon favori | champ du Pokémon | J6 (favoris) ou J7A |
| Lieux et services découverts | cartes découvertes (existe depuis le J5) ; Arène vue = drapeau | J7A |
| Rival de la Route 22 | drapeaux : pas affronté / gagné / perdu | J7B |

## 18. Coûts techniques identifiés

- **Fenêtre de choix à deux boutons** dans les dialogues (SOIGNER / PAS MAINTENANT) : n'existe pas encore ; resservira pour les confirmations (libérer, vendre un favori).
- **Écran Boutique** et **écran Stockage** : deux nouveaux écrans, qui s'appuient sur le Sac et l'Équipe du J6.
- **Réplique dynamique de Chen** : une seule variante, qui cite une espèce.
- **Cartes** : Jadielle, Centre, Boutique, extérieur de l'Arène ; au J7B, Route 22 et la vue vers le Plateau Indigo.
- **J7B** : IA de niveau 2 (moteur) ; environ 10 nouvelles espèces si l'on suit Rouge/Bleu pour la Route 22 (données, apprentissages, sprites) ; mise en scène du rival contre un autre dresseur.
- Sprites : infirmière, marchand, habitants, jeune dresseur.

## 19. Textes de référence J7 V1 (validés par Kevin, 2026-10-02)

Textes **de référence**, plus des placeholders. **Raccourcissables à la QA** : une réplique juste sur papier peut être une bulle de trop au doigt.

**Boutique — marchand**
> Première visite : « Bonjour ! Première fois à Jadielle ? » · « Hmm… Ce Pokémon vient du laboratoire du Professeur Chen, non ? » · « Ça tombe bien. J'ai justement reçu quelque chose pour lui ce matin. » · « Tu pourrais lui remettre quand tu retourneras à Bourg Palette ? »
> Toast : « COLIS POUR CHEN — ajouté aux objets clés ». Objectif : « Objectif : remettre le colis au Professeur Chen. »
> Visites suivantes : « Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ? »
> Libellés : **ACHETER · VENDRE · QUANTITÉ · TOTAL · DANS LE SAC · CONFIRMER · RETOUR** (« Dans le Sac » plutôt que « Possédé »).
> Messages : « Tu n'as pas assez d'argent. » · « Je ne peux pas te reprendre ça. » (objet clé) · « Merci ! » (après un achat).

**Arène**
> Porte : « La porte est verrouillée. »
> Habitant : « Encore fermée… Je me demande où est passé le Champion. »

**Vieil homme** (clin d'œil au tutoriel historique, sans tutoriel ni quatrième mur)
> « Tu pars vers le nord ? » · « La Forêt de Jade surprend souvent les jeunes Dresseurs. » · « Garde toujours quelques Poké Balls avec toi. On ne sait jamais quelle rencontre nous attend. »
> En lui reparlant : « Il y a des choses qu'on apprend mieux sur la route qu'en écoutant un vieux monsieur. »

**Chen — remise du colis et activation**
> « Tiens… » · « Il a déjà commencé à enregistrer tes rencontres. »
> Si une espèce sauvage a été rencontrée en combat : « Un {espèce}… Tu n'as pas perdu de temps. » — {espèce} = **la première espèce sauvage rencontrée en combat** (J6 Q-7), jamais un Pokémon d'habitant ni un Pokémon seulement observé dans le décor ; aucune → la réplique est omise.
> « J'étudie depuis longtemps la manière dont les Pokémon vivent à travers Kanto. » · « Mais aucune recherche ne remplacera ce qu'un Dresseur découvre sur le terrain. » · « Ton voyage peut nous apprendre beaucoup. »
> Caption : **POKÉDEX ACTIVÉ**
> « Il enregistrera les Pokémon que tu observes, les endroits où tu les rencontres et ce que tu découvriras sur eux. »
> Au joueur : « Observe. Explore. Fais-toi ta propre idée du monde. » — **phrase importante de l'aventure**, à garder.

**Rival — au labo** (il arrive après la remise du colis ; il revient lui aussi de quelque part, il n'attendait pas le joueur)
> En entrant : « Professeur ! Je suis revenu. »
> Au joueur : « Tiens. T'es déjà revenu, toi aussi ? »
> Chen, au rival : « Et toi… apprends à regarder au-delà de la victoire. » — Rival, après une courte pause : « …On verra. » (Chen n'annonce pas l'arc du rival.)
> Après l'activation : « Pas mal. » · « Mais ne t'imagine pas que je vais t'attendre. »

**Centre Pokémon — infirmière**
> « Bonjour. Je m'occupe de ton équipe ? » — **SOIGNER / PAS MAINTENANT**
> PAS MAINTENANT : « Très bien. Reviens quand tu veux. »
> Après soin : « Voilà. Tout le monde est en pleine forme. »
> Toast (première fois) : « Point de repos enregistré — Jadielle »

**Stockage Pokémon**
> Libellés : **ÉQUIPE · STOCKAGE · DÉPOSER · REPRENDRE · FAVORI · LIBÉRER · RETOUR**
> Confirmation : **Libérer {Pokémon} ?** — « Il quittera définitivement ton équipe et ton stockage. » — **LIBÉRER / ANNULER**
> Favori : « Retire d'abord {Pokémon} de tes favoris pour pouvoir le libérer. » — **aucun bouton de contournement** dans cette boîte : il faut retirer le favori volontairement.
> Dernier Pokémon de l'équipe (déposer ou libérer) : « Tu dois garder au moins un Pokémon avec toi. » (règle métier, §8)
> Équipe pleine après une capture : « {Pokémon} a été confié au système de recherche de Chen. » (en jeu depuis le J5)

**Route 22 (J7B)**
> Voyageur revenant de l'ouest, **seulement si le joueur lui parle** (aucun déclencheur automatique) : « Tu vas par là ? » · « La route continue loin vers l'ouest… mais je n'irais pas trop loin sans une équipe prête. »
> Scène : Jeune Dresseur : « Sérieusement… ? » — Rival : « Tu hésites trop. »
> Rival, au joueur : « Tiens. » · « Toi aussi, tu es venu voir jusqu'où cette route mène ? » · « Ça tombe bien. » · « Voyons ce que tu as appris depuis notre premier combat. » → combat.
> Victoire du joueur : « …D'accord. » · « Tu progresses vite. » · « Mais moi aussi. » · « On verra lequel de nous deux arrive le plus loin. »
> Défaite du joueur (sans mépris : il n'a rien à prouver) : « Tu t'es amélioré. » · « Mais pas assez. » · (il rappelle son Pokémon) « La prochaine fois, ne me laisse pas autant d'avance. » → **fondu → réveil au dernier Centre utilisé**, ou chez Maman si aucun Centre n'a été enregistré. On ne montre pas le rival partir.

**Habitants de Jadielle** (une petite touche de monde chacun, aucune information de gameplay obligatoire ; pas de quota de PNJ)
> Livreur : « Encore une livraison pour la Boutique… » · « Jadielle est petite, mais tout le monde finit par passer par ici. »
> Jeune Dresseuse, avec son **Roucool** (petite animation à côté d'elle) : « On revient de la route au nord. » · « On pensait aller plus loin… mais on va d'abord souffler un peu. »
> Enfant, avec son **Rattata** qui trottine derrière lui (avant-goût discret du compagnon, sans l'annoncer) : « Il me suit partout. » · « Même quand je lui dis de rester à la maison ! »
> Voyageur venant du nord : « Tu viens de Bourg Palette ? » · « Alors tu verras : au nord de Jadielle, le paysage change vite. »
> Habitant près de l'Arène et vieil homme : ci-dessus.

**Micro-scène d'arrivée** : sans texte, voir §2.

## 20. Questions (réponses par défaut validées par Kevin, 2026-10-02)

1. **Argent gagné contre le rival n°2** : formule de Rouge/Bleu (base du dresseur × niveau du dernier Pokémon), valeurs provisoires.
2. **Où marquer un Pokémon favori** : depuis sa fiche Équipe (J6) et depuis le Stockage (J7A).
3. **Bestiaire exact de la Route 22** (§12) : celui de Rouge/Bleu, à confirmer avec le coût en sprites.

## Décisions verrouillées

Découpage J7A / J7B · Jadielle dense et vivante, sans marqueurs ni PNJ guide · Arène fermée, mystère sans calendrier · Colis à la Boutique, arrivée et retour libres, objectif silencieux · Rebords de la Route 1 conservés · Données collectées par le système de recherche de Chen, Pokédex = interface activée par Chen, rien de visible avant · Rival au labo après la remise du colis · Centre : soin ~3 s, dernier Centre utilisé = point de retour, Maman soigne toujours · « Stockage Pokémon » unique, accès au Centre seulement, V1 minimale, favoris protégés · Boutique rapide, rien pour une mécanique absente · 3 000 ₽, aucune perte d'argent à la défaite · Sortie nord « ROUTE 2 — À venir » en développement · Rival n°2 seulement après l'activation, facultatif, trois états mémorisés · IA du rival qui progresse avec son arc · Aucun PNJ omniscient · Textes J7 V1 (§19) validés, raccourcissables à la QA · Dernier Pokémon de l'équipe ni déposé ni libéré (règle métier) · Pokémon des habitants : Roucool (Dresseuse), Rattata (enfant), aucune espèce nouvelle pour habiller Jadielle.
