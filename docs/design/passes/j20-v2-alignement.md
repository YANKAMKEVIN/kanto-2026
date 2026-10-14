# J20 — Céladopole, les lumières et les ombres : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-14. Conception seulement : aucune ligne de code. V2 reproduite dans
> `j20-v2-chatgpt.md`. Relu contre `vision.md`, `roadmap.md`, les dossiers 06, 09, 12, 14, 15 et 16,
> le code de `origin/main` (`4f0ee90`, J13 terminé) et de `jalon-15` (`2b224be`), la passe J16
> (`origin/ccr-fa255d49-wvvacc`, `j16-v2-alignement.md`) et la V2 du J18 (non commitée, worktree
> `doc-j18`).
>
> **Sources des faits Rouge/Bleu** : CSV publics de PokeAPI (groupe `red-blue`, rencontres, dons,
> Coin à lots) et **désassemblage pret/pokered** (`af51989`) pour les cartes, les Dresseurs, les
> objets, les scripts et les équipes. « **Vérifié** » renvoie à ces deux sources ; tout le reste est
> signalé « à recouper ».
>
> **2026-10-14 : Kevin retient toutes les recommandations (H-1 à H-14).** Dossier consolidé :
> `docs/design/dossier-23-celadopole.md`.
>
> Les 7 décisions de la V2 restent telles quelles. Je n'en rouvre aucune ; deux demandent une
> précision (n° 2 et n° 6). Mes arbitrages sont numérotés **H-1 à H-14** (§5). Réponds par numéro ;
> je consolide ensuite le dossier.
>
> Origine des règles : **RB** Rouge/Bleu · **RFVF** Rouge Feu / Vert Feuille · **K26** invention de
> Kanto 2026.

## 0. État réel du dépôt (vérifications prioritaires n° 6)

| Point | Constat |
|---|---|
| Branche de référence | `origin/main` = `4f0ee90`, **J13 terminé**. J12, J14 et J15 sont en cours dans d'autres sessions. |
| Schéma de sauvegarde | **v6** sur `main` (J11). **v7** sur `jalon-15` (pension). Les J16 à J19 pourront le monter encore : le J20 prendra « dernière version + 1 », et seulement s'il change la forme d'un champ (§3, point 9). |
| Numéros de dossiers | 16 = J13, 17 = J14, 18 = J15. La branche `docs/dossier-20-j17` réserve le **20 au J17**, d'où 19 = J16, 21 = J18, 22 = J19 → **dossier 23 = J20** (H-1). |
| Dossiers J16 à J19 | **Aucun n'est consolidé dans le dépôt.** Il existe seulement la passe J16 (branche `ccr-…`), la V2 du J18 (non commitée) et des branches J17 et J19 vides (= `main` au J11). J19 n'existe que dans ta V2. |
| Code J16–J19 | Rien : ni Coupe, ni Flash, ni Lavanville, ni Tour, ni spectres. |

Le J20 ne les attend pas : il écrit un **contrat d'entrée** (§4), que les sessions J16 à J19
reprendront ou contesteront. Seul le code reste soumis à C-7 : un jalon à la fois dans le moteur de
combat et dans la sauvegarde.

## 1. Les 7 décisions de la V2

| # | V2 | Avis |
|---|---|---|
| 1 | Route 8 + souterrain + Route 7 + Céladopole | Oui. Mais c'est **le plus gros jalon du projet**, environ **28 cartes** (§2). Je propose de le découper en deux sous-jalons validés sur S24 (H-2). |
| 2 | Ville complète, grand magasin, bâtiments principaux | Oui, sauf la **taille** : 110 × 80 cases vaut 3,8 fois Azuria (H-3). |
| 3 | Erika, Badge Prisme dès le J20 | Oui. Le niveau de l'équipe est à corriger : RB = **29 / 24 / 29**, pas 29 à 32 (§3, point 4). Le badge existe déjà : `badge_rainbow`, « Badge Prisme », dans `data/badges.json`. |
| 4 | Repaire complet, Giovanni, Scope Sylphe | Oui. La structure RB est vérifiée au §2.3, Clé Ascenseur comprise. |
| 5 | Dalles tournantes et ascenseur fidèles à RB | Oui. RB : dalles au **B2F et au B3F** seulement, ascenseur vers **B1F, B2F, B4F**. Règles mobiles par défaut au §3, point 8. |
| 6 | Casino narratif, sans jeu d'argent | Oui, mais il faut décider ce que deviennent **le Coin à lots et la Boîte Jetons** : Porygon n'existe que là dans RB (H-6). |
| 7 | Fin au Scope Sylphe, Tour au J21 | Oui. Le Scope est un simple objet-clé. Sa possession suffit, sans drapeau de plus (§3, point 7). |

## 2. Ce que RB contient vraiment (vérifié)

### 2.1 Routes et souterrain

| Lieu | RB | Remarque |
|---|---|---|
| Route 8 (Lavanville → poste ouest de Safrania) | **9 Dresseurs** : 3 Intellos, 2 Joueurs, 4 Fillettes, dont un trio côte à côte. Le passage souterrain s'ouvre au nord-ouest. | La V2 en propose 6 à 8 : valeur par défaut **7**, et le trio réduit à un duo. |
| Sauvages Route 8 (Rouge ∪ Bleu) | Roucool 18–20, Férosinge / Miaouss 18–20, Abo / Sabelette 17–19, **Caninos / Goupix 15–18** | Le projet fusionne les deux versions (Route 3 : Abo **et** Sabelette). Je garde cette règle. |
| Souterrain 7–8 | **Aucune rencontre, aucun Dresseur, 2 objets cachés.** Deux petits bâtiments d'entrée. | « Découverte facultative » de la V2 = ces 2 objets cachés. Les objets cachés existent déjà (Route 3, J12 ; Route 24, J13) : rien à créer. |
| Route 7 | **Aucun Dresseur.** Poste de garde vers Safrania, entrée du souterrain. | Sauvages : Roucool 19–22, Mystherbe / Chétiflor 19–22, Férosinge / Miaouss 17–20, Caninos / Goupix 18–20. |
| Postes de Safrania | RB : les gardes ont soif ; **une boisson du toit du grand magasin ouvre les quatre postes**. RFVF : le **Thé** de la vieille dame de la Résidence. | La « Maison liée au Thé » de la V2 vient de RFVF, pas de RB (H-5). |

### 2.2 Céladopole

| Bâtiment | Contenu RB vérifié |
|---|---|
| Centre Pokémon | Standard. |
| Grand magasin | RdC accueil · **2e** : 2 vendeurs (soins et Balls ; **9 CT** : Reflet, Protection, Coupe-Vent, Empal'Korne, Bombe-Œuf, Ultimapoing, Ultimawashi, Bélier, Sacrifice) · **3e** : jeux, **CT18 Riposte offerte** · **4e** : Poupée Poké et **4 pierres d'évolution** · **5e** : objets X et vitamines · **toit** : distributeurs (Eau Fraîche, Soda Cool, Limonade) et fillette qui échange une boisson contre **CT13 Laser Glace / CT48 Éboulement / CT49 Triplattaque** · ascenseur. |
| Résidence Céladon | 3 étages + toit ; par l'escalier de service, maison du toit avec **Évoli N25 offert** (unique). Au 3e : le bureau de Game Freak (Diplôme du Pokédex complet = post-game). |
| Arène | **Coupe nécessaire pour entrer** (arbuste). **7 Dresseuses** (Fillettes, Beautés, Topdresseuse) puis Erika : **Empiflor 29, Saquedeneu 24, Rafflesia 29**. Récompense **CT21 Méga-Sangsue** + Badge Prisme. |
| Casino | 11 PNJ, un **Rocket qui garde l'affiche** ; une fois battu, l'interrupteur derrière l'affiche ouvre l'escalier du B1F. Jetons cachés au sol. |
| Coin à lots (en face) | Rouge : Abra 9, Mélofée 8, Nidorina 17, Insécateur 25, Minidraco 18, **Porygon 26** · Bleu : Abra 6, Mélofée 12, Nidorino 17, Scarabrute 20, Minidraco 24, **Porygon 18** · CT23 Draco-Rage, CT15 Ultralaser, CT50 Clonage. |
| Restaurant | Un client offre la **Boîte Jetons**. |
| Maison du chef, Hôtel | PNJ seulement. |
| Ville | **CT41 Œuf** offerte par un PNJ, 1 objet caché, 2 Rocket en extérieur, un pêcheur et son Tartard, un étang. **Sortie ouest vers la Route 16** (maison de Vol derrière un arbuste, Ronflex plus loin). |

### 2.3 Repaire Rocket (vérifications prioritaires n° 1 et n° 3)

| Niveau | RB vérifié |
|---|---|
| Casino | 1 Rocket devant l'affiche. |
| B1F | 5 Rocket ; Corde Sortie, Hyper Potion ; 1 objet caché ; ascenseur. |
| B2F | **Dalles tournantes** ; 1 Rocket ; Pierre Lune, Pépite, CT07 Empal'Korne, Super Potion ; ascenseur. |
| B3F | **Dalles tournantes** ; 2 Rocket ; CT10 Damoclès, Super Bonbon ; 1 objet caché. |
| B4F, partie ouest (par l'escalier du B3F) | 1 Rocket. **Après sa défaite, quand on lui reparle, il laisse tomber la Clé Ascenseur** (`EVENT_ROCKET_DROPPED_LIFT_KEY`). PV Plus, CT02 Coupe-Vent, Fer. |
| B4F, partie est (**par l'ascenseur seulement**) | 2 Rocket devant la porte, puis **Giovanni** : **Onix 25, Rhinocorne 24, Kangourex 29**. Après sa défaite, il part et le **Scope Sylphe** reste au sol, à côté de lui. 1 objet caché. |
| Ascenseur | Dessert **B1F, B2F, B4F**. Inutilisable sans la Clé. |

Soit **12 Rocket + Giovanni**. La Clé n'est donc **pas** dans la salle de Giovanni : elle se trouve
dans l'autre moitié du B4F, qu'on atteint à pied.

**Ordre Erika / repaire (n° 3)** : vérifié, aucun lien dans RB. L'Arène demande seulement Coupe. Le
repaire ne demande rien : ni badge, ni Coupe. Les deux objectifs sont indépendants, comme le
recommande la V2.

### 2.4 Spectres avant et après le Scope (n° 4 — pour information du J19)

RB : aux étages **3 à 7** de la Tour, **toute** rencontre sauvage s'affiche « SPECTRE » sans le
Scope, **Osselait compris** (9 à 10 % des rencontres ; la V2 du J19 ne cite que Fantominus et
Spectrum).

Le combat contre un SPECTRE se déroule ainsi :
- une Ball lancée est esquivée : il est impossible de le capturer ;
- le Pokémon du joueur est « trop effrayé pour bouger » ;
- la fuite reste possible.

Avec le Scope, l'espèce est révélée et la rencontre redevient normale. L'Ossatueur du 6e étage est
un combat scripté. Le J20 n'a besoin que d'une chose : que le J19 teste **la possession de
l'objet** (`silph_scope` dans le Sac), et non un drapeau posé par un événement du J20.

## 3. Ce que la V2 oublie ou contredit

1. **Taille du jalon.** Il faut environ 28 cartes :
   - 3 routes et souterrain, plus 2 bâtiments d'entrée et 2 postes de garde ;
   - la ville ;
   - le Centre ;
   - 7 cartes pour le grand magasin (5 étages, toit, ascenseur) ;
   - 5 cartes pour la Résidence (3 étages, toit, maison du toit) ;
   - l'Arène, le Casino, le Coin à lots, le restaurant, la maison du chef et l'hôtel ;
   - 5 cartes pour le repaire (4 sous-sols et l'ascenseur).

   Le J13 (Azuria) en comptait 7. Le moteur ne gère encore **ni ascenseur, ni dalles, ni don de Pokémon** hors starter :
   je n'ai trouvé aucun de ces mécanismes sur `main` ni sur `jalon-15`. Ce sont 3 mécaniques
   nouvelles → H-2. (Correction du 2026-10-14 : les objets cachés existent déjà, Route 3 du J12.)
2. **Dimensions.** RB Céladopole fait **50 × 36** cases, et RB Azuria 40 × 36. Azuria a été produite
   en 56 × 41. Le même rapport donne **environ 70 × 46** pour Céladopole, au lieu de 110 × 80. Elle
   reste la plus grande ville du jeu à ce stade → H-3.
3. **Sortie ouest et Route 16.** La V2 n'en parle pas. Dans RB, la ville s'ouvre à l'ouest. Derrière
   cette sortie : la maison qui donne **Vol** (derrière un arbuste), Ronflex (lié à la Poké Flûte,
   donc après le J21) et la Piste Cyclable (Vélo). → H-4.
4. **Erika.** Ses niveaux RB sont 29 / 24 / 29. Comme pour Pierre (simulation T16 du J10, où le
   Pierre « historique » donnait 0 % de victoire), **les niveaux seront fixés par simulation**, avec
   ces valeurs comme référence. Ce qui manque dans les données :
   - **Méga-Sangsue** est absente des données (`main` et `jalon-15`), donc la CT21 n'enseigne rien
     tant qu'on ne la crée pas ;
   - Empiflor, Saquedeneu et Rafflesia sont à créer (leurs pré-évolutions Boustiflor et Ortide
     existent sur `main`) ;
   - les 7 Dresseuses → H-9 (nombre).
5. **Badge Prisme et Force.** Dans RB, ce badge autorise Force. Le dossier 06 §11 fait de Force une
   capacité d'exploration, et le dossier 12 supprime tout effet caché des badges. Le lien badge →
   capacité dépend de ce que le J16 a tranché (G-2 / G-3 de sa passe). Par défaut : **aucun effet**,
   le badge enregistre la victoire. RB n'a besoin de Force qu'aux Îles Écume et plus tard.
6. **Économie du grand magasin.** Repris tel quel de RB, il apporte d'un coup :
   - **16 CT**, dont beaucoup demandent une mécanique absente : KO en un coup (Empal'Korne),
     charge d'un tour (Coupe-Vent), Riposte, soin (Œuf), Clonage, Ultralaser avec recharge ;
   - les 4 pierres d'évolution, qui ouvrent environ 10 évolutions nouvelles : Évoli ×3, Caninos,
     Goupix, Pikachu, Ortide, Boustiflor, Têtarte… ;
   - des vitamines : les EV existent (`stat_calc.gd`) mais restent à 0, donc une vitamine ne fait
     rien aujourd'hui ;
   - des objets X.

   → H-7 et H-8.
7. **Scope Sylphe.** C'est un objet-clé unique (`category: key`, comme les fossiles du J12). Le
   Rocket et Giovanni sont vaincus pour de bon (drapeaux de Dresseur déjà persistés). Le repaire
   reste explorable, sans réinitialisation. **Aucun champ de sauvegarde nouveau** pour le Scope.
8. **Dalles tournantes, règles mobiles par défaut** (pas d'arbitrage) :
   - la flèche pousse le joueur, case par case, jusqu'à une **case d'arrêt** prévue dans les
     données ;
   - pendant la glisse, l'entrée est ignorée et le menu fermé ;
   - **aucune sauvegarde automatique** pendant une glisse : la position sauvegardée est toujours
     une case d'arrêt ou la case de départ ;
   - un test parcourt toutes les flèches de chaque carte et vérifie que chacune finit sur une case
     d'arrêt praticable ;
   - le compagnon se rétracte pendant la glisse ;
   - le même moteur resservira pour l'Arène de Jadielle (RB).
9. **Sauvegarde.** Les objets-clés, les Dresseurs vaincus, les objets ramassés et les drapeaux
   d'histoire sont déjà génériques. Le seul ajout possible est le **don d'Évoli** quand l'équipe est
   pleine : il passe par le stockage existant (J7). Le J20 ne devrait **pas** avoir à monter la
   version. Le plan le confirmera sur la version en vigueur à ce moment.
10. **Rocket en ville.** RB en place 2 dans les rues, plus celui du Casino. Ils s'accordent avec
    « la Team Rocket opère sous la ville » ; ce sont des PNJ, pas des combats, sauf celui de
    l'affiche.
11. **Giovanni, Grand moment.** Par défaut : sa défaite est inscrite comme Grand moment (règle des
    combats majeurs, J6 §6E). Une défaite du joueur ramène au dernier Centre, sans rien inscrire.
12. **Rencontres sur l'eau** (étang de la ville, pêche) : Surf et pêche ne sont pas encore conçus.
    L'étang reste un décor. Le pêcheur et son Tartard restent des PNJ.
13. **J21 préservé** (n° 5) : le J20 ne touche à aucune carte de Lavanville. Il ne pose aucun
    drapeau « Fuji », « Ossatueur » ou « Flûte ». Un test le vérifie.

## 4. Contrat d'entrée (hypothèses sur les J16 à J19)

| Le J20 suppose | Jalon | Si c'est faux |
|---|---|---|
| **Coupe** disponible hors combat (capacité d'exploration, dossier 06 §11) et au moins une espèce compatible accessible | J16 | L'Arène est inaccessible : il faut un autre accès (K26). |
| Lavanville et la Route 8 raccordées par le bord ouest de Lavanville | J18 | Le raccord est repris au plan du J20. |
| Spectres conditionnés à la **possession de `silph_scope`** | J19 | Il faut une migration ou un drapeau en plus. À écrire dans le dossier 22. |
| Rival n° 5 vaincu à la Tour (drapeau du J19). Le J20 n'a **aucun** combat de rival (RB : le n° 6 est à Sylphe SARL). | J19 | Rien. |
| Niveau d'équipe en arrivant : environ 25 à 28 (rival n° 5 de RB : N20 à 25) | J19 | La simulation d'Erika l'absorbe. |

## 5. Arbitrages H-1 à H-14

| # | Question | Options | Recommandation |
|---|---|---|---|
| **H-1** | Numéro du dossier | 23 · autre | **23** (`dossier-23-celadopole.md`). Branche `docs/dossier-23-j20`. |
| **H-2** | Découpage | A : un seul sous-jalon · B : **20-I** = Routes 8 / 7, souterrain, ville, grand magasin, Résidence, Arène (lots 20A–20C) ; **20-II** = Casino, repaire, Giovanni (20D–20E) ; une validation S24 par sous-jalon · C : trois sous-jalons | **B**. Les dalles et l'ascenseur (mécaniques risquées) sont validés à part, comme le veut la règle 1. |
| **H-3** | Taille de Céladopole | 110 × 80 · **≈ 70 × 46** (rapport RB / Azuria) | **≈ 70 × 46**, à ajuster sur la grille. |
| **H-4** | Sortie ouest (Route 16) | A : fermée, obstacle naturel sans promesse (comme le Sentier est d'Argenta) · B : poste de garde fermé et texte · C : Route 16 et Vol au J20 | **A** ou **B**. La Route 16, Vol et Ronflex arrivent avec leur jalon. |
| **H-5** | Accès à Safrania | A : RB, les boissons du toit ouvrent les postes · B : RFVF, le Thé de la Résidence · C : décidé avec le jalon de Safrania | **C**. Au J20, la Résidence et sa vieille dame existent, **sans objet**. Les gardes ne parlent pas de soif. Les distributeurs vendent leurs boissons pour l'échange contre des CT. On évite ainsi un objet qui ne servirait à rien pendant tout un jalon. |
| **H-6** | Coin à lots et Boîte Jetons, sans jeu d'argent | A : on les retire et **Porygon** (seule source RB) sera donné plus tard par Sylphe SARL (K26) · B : on les retire, Porygon reste un problème du post-game · C : le Coin à lots échange autre chose que des jetons | **A**. Le restaurant n'offre pas de Boîte Jetons. Le Coin à lots devient un **décor fermé** ou disparaît. Les Pokémon du comptoir (Abra, Mélofée, Minidraco, Insécateur / Scarabrute) restent trouvables ailleurs dans RB, sauf **Porygon** : à confier au dossier de Safrania. CT23, CT15 et CT50 sont reportées. |
| **H-7** | CT du J20 | A : RB complet (16 CT, plus 6 mécaniques nouvelles) · B : **seulement les CT dont la capacité existe** à l'ouverture du J20 ; les autres attendent une passe de systèmes, comme au J11 | **B**. Le plan liste les CT retenues ; Méga-Sangsue (CT21) est créée en tout cas. |
| **H-8** | Pierres d'évolution au 4e | A : vendues dès le J20 (RB), avec les données des évolutions et l'art en lot · B : vendues plus tard · C : vendues, art des évolutions en provisoire | **A** si le lot d'art suit ; sinon **C**. Les vitamines (EV à 0) restent hors vente jusqu'à ce que les EV comptent. Les objets X sont vendus si le moteur gère déjà les niveaux de statistiques ; sinon ils sont reportés. |
| **H-9** | Dresseurs | Route 8 : 9 (RB) ou 7 · Arène : 7 (RB) ou 4–5 · repaire : 12 (RB) ou 8–10 | Route 8 **7** ; Arène **5** (chemin lisible, Coupe) ; repaire **10** (B1F allégé). Même logique « A+ » que le Mont Sélénite (6 au lieu de 8). |
| **H-10** | Évoli | A : don unique, maison du toit par l'escalier de service (RB) · B : don plus visible | **A**. C'est une découverte, pas une quête, sans marqueur. |
| **H-11** | Giovanni | Défaite → dernier Centre et nouvel essai (V2) ; IA `smart` ; niveaux RB 25 / 24 / 29 en référence, puis simulation | Oui, comme la V2. Il ne dit pas qu'il est Champion de Jadielle : la révélation reste à Jadielle (dossier 06). |
| **H-12** | Casino | A : salle visible, machines éteintes ou en décor, PNJ · B : salle fermée sauf la zone de l'affiche | **A**. Machines **en décor** (non interactives, ou un texte neutre), sans aucun mot sur les jetons. |
| **H-13** | Sauvages des Routes 7 et 8 | Union Rouge + Bleu (règle des Routes 3 et 4) · une seule version | **Union**. Caninos et Goupix sont nouveaux, Miaouss arrive au J15. |
| **H-14** | Objets cachés | A : on en place (souterrain, ville, repaire), avec le mécanisme existant du J12 · B : objets visibles seulement | **A**. La « découverte facultative » du souterrain repose dessus. |

## 6. Suite

1. Tu réponds à H-1 à H-14.
2. Je consolide le **dossier 23**, avec les textes à valider en un seul lot (règle des dossiers
   précédents), les grilles `tools/plans/` à produire et la liste d'assets :
   - **espèces** : Évoli, Caninos, Goupix, Empiflor, Saquedeneu, Rafflesia, Rhinocorne, Kangourex,
     plus les Pokémon des Rocket ;
   - **PNJ** : Erika, Giovanni, Intello, Joueur, Beauté ;
   - **fonds de combat CB.3** : ville, arène végétale, repaire ;
   - **intérieurs** et vues générales ;
   - **musique**.
3. Le plan technique `docs/tech/jalon-20.md` vient ensuite. Le code commence après la clôture du J19
   (C-7).
