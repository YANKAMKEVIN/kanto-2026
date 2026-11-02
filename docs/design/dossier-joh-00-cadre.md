# Dossier JOH-00 — Chapitre Johto : cadre général (v0.1)

> Dossier-cadre du Chapitre Johto (roadmap, phase 10), écrit par Claude le 2026-11-02 à partir de
> l'esquisse [`johto-esquisse.md`](johto-esquisse.md), dont les arbitrages JH-1 à JH-10 sont
> **tous tranchés par Kevin**. Ce dossier fixe la géographie, le scénario acte par acte, les
> systèmes neufs, la place des 50 espèces et le découpage en jalons **JOH0 à JOH9**.
>
> **Statut : proposition à valider.** Les points marqués **[D]** sont des valeurs par défaut de
> Claude (règle 4 de `CLAUDE.md`) ; les vraies questions de game design sont numérotées **JH-11
> et suivantes** (§11). Chaque jalon aura ensuite son propre dossier (cartes, textes, valeurs),
> comme pour Kanto. **Pas de code avant la fin de Kanto.**

## 0. Rappel des décisions (esquisse, 2026-10-30 → 2026-11-02)

| Sujet | Décision de Kevin |
|---|---|
| Région | Johto, même partie, même sauvegarde |
| Longueur | Histoire courte, **pas 8 badges** |
| Structure | 3 actes : menace Rocket sur quelques villes → quête de légendaires → Mont Argenté |
| Arrivée | Bourg Palette, passage secret par l'eau |
| Équipe | Volée la nuit au Centre d'Oliville (JH-1) ; rendue d'un coup avec le sac à la fin de l'acte 1, à la Tour Radio (JH-2, JH-3) |
| Types | Table actuelle (18 types modernes, déjà dans le jeu) (JH-4) |
| Espèces | 50, liste de l'esquisse §8 (JH-5) |
| Jour et nuit | Comme Or/Argent, heure et jour du téléphone (JH-6) |
| Adversaire final | **Dante**, ancien chef de la Team Rocket, mentor trahi de Giovanni (JH-7) |
| Giovanni | Réapparaît à la fin, sans combat (JH-7) |
| Kanto | Change le moins possible (JH-8) |
| Rival | Relais au Mont Argenté, puis dernier combat de rivaux (JH-9) ; combats en duo plus tard |
| Révélation | À la Tour Radio : les Sbires croyaient servir Giovanni, Dante les a repris et a fait voler l'équipe (JH-10) |
| Jalons | Numérotés JOH0, JOH1… |

## 1. Hors périmètre

- Les 8 Arènes de Johto, la Ligue de Johto, le Conseil 4 de Johto.
- Bourg Geon, Ville Griotte, Mauville, Caves Jumelles, Irisia, Ebènelle, Route de Glace, Antre du
  Dragon, Parc National, Mont Creuset (intérieur), le laboratoire d'Orme.
- Le téléphone Pokématos, les appels de Dresseurs, les revanches.
- La reproduction et la Pension à œufs (seul l'œuf de Togepi existe, §5.4).
- Les objets tenus en combat, les Baies, les Noigrumes.
- Les combats en duo (après le chapitre, décision de Kevin).
- Les 50 autres espèces d'Or/Argent.

## 2. Hypothèses d'entrée

- **Kanto est fini** : Ligue battue, générique vu, `league_champion_defeated` posé. Le chapitre
  s'ouvre sur une sauvegarde d'après la Ligue, quelle que soit la progression du post-game (Mewtwo,
  Mew) **[D]**.
- **Surf** obtenu (CS03, J23) : il faut pour la grotte marine.
- L'équipe du joueur est une équipe de fin de Ligue (niv. 55–65 attendus).
- La sauvegarde passe en **v10** au JOH0 (équipe confisquée, heure, œuf, nouvelles espèces) :
  système risqué, validé seul (règle 1 de `CLAUDE.md`).

## 3. Géographie

Johto est réduit à un **arc ouest et centre**, de la côte d'Oliville au Mont Argenté. Environ la
moitié de la région d'Or/Argent, dans le même ordre que l'original pour garder les repères.

```
                         Mont Argenté ── Route 28 ── (Kanto, Route 22)
                              │
             Lac Colère ── Route 43
                              │
  Rosalia ── Route 42 ──── Acajou
     │
  Route 37 ─ 36 ─ 35 ── Doublonville ── Route 34 ── Bois aux Chênes ── Écorcia
     │
  Route 38 ── Route 39 ── Oliville ── Routes 40-41 (Surf) ── Îles Tourbillon
                             │
                       Grotte marine ── (Kanto, Bourg Palette)
```

### 3.1 Liste des cartes **[D]**

| Acte | Carte | Rôle | Taille indicative |
|---|---|---|---|
| 1 | Grotte marine de Bourg Palette (2 salles) | Passage secret, aperçu de Lugia | petite |
| 1 | Oliville (ville, Centre, Boutique, Phare en façade) | Arrivée, vol, Orme | ville moyenne |
| 1 | Route 39 (Ferme Meumeu en façade), Route 38 | Premières routes | 2 routes courtes |
| 1 | Rosalia (premier passage, tours fermées) | Présage de l'acte 2 | ville moyenne |
| 1 | Routes 37, 36, 35 | Chemin vers Doublonville | 3 routes courtes |
| 1 | Doublonville (grande ville, Grand Magasin, Souterrain) | Cœur de la menace | grande ville |
| 1 | Route 34, Bois aux Chênes, Écorcia | Détour sud | route, forêt, petite ville |
| 1 | Puits Ramoloss (2 niveaux) | Première base Rocket | petit donjon |
| 1 | Tour Radio de Doublonville (5 étages) | Fin de l'acte 1 | donjon vertical |
| 2 | Tour Cendrée (2 niveaux), Tour Carillon (sommet seul jouable + 2 étages) | Légendaires | 2 donjons |
| 2 | Route 42, Acajou, Route 43, Lac Colère | Repaire Rocket | 2 routes, petite ville, lac |
| 2 | Repaire Rocket d'Acajou (3 niveaux) | Un chien légendaire captif | donjon |
| 2 | Routes 40-41 (mer), Îles Tourbillon (3 niveaux) | Suicune, Lugia | mer, grotte |
| 3 | Mont Argenté (extérieur + 3 niveaux + sommet), Route 28 | Final | grand donjon |

Total ≈ **35 cartes**, contre une centaine pour Kanto. Chaque carte aura sa grille dans
`tools/plans/` et sa vue générale peinte, comme à Kanto.

### 3.2 Raccords avec Kanto

- **Aller** : grotte marine sous la côte sud de Bourg Palette, par Surf (§4.1).
- **Retour à Kanto** :
  - **acte 1** : impossible (le joueur n'a plus de Pokémon pour surfer ; la grotte est gardée par
    le courant **[D]**) ;
  - **à partir de l'acte 2** : par la grotte marine dans les deux sens, et par **Vol** entre les
    deux régions (les villes de Johto visitées s'ajoutent à la liste de Vol) **[D]** ;
  - **acte 3** : la sortie du Mont Argenté par la Route 28 rejoint la **Route 22**, à l'ouest de
    Jadielle : les deux régions sont alors reliées à pied, comme dans Or/Argent.
- **Carte** : une seconde page « Johto » dans la Carte du Menu Dresseur (JOH0).

## 4. Scénario acte par acte

### 4.1 Prologue — le passage (JOH1)

- **Déclencheur** : quelques jours après la Ligue (au retour au jeu après le générique), Chen
  appelle le joueur au labo. Il a reçu une lettre du **Professeur Orme**, de Johto : des Pokémon
  fuient la côte, la Team Rocket rôde, et Orme a entendu parler d'un « nouveau Maître de Kanto ».
  Chen montre une vieille carte : une grotte marine relie Bourg Palette à la côte de Johto, ouverte
  seulement à marée basse **[D]**.
- **La grotte** : deux salles en Surf, courants simples, quelques Tentacool et Kokiyas (espèces
  de Kanto). Au fond, une **ombre immense** passe sous l'eau (Lugia, sans combat).
- **Arrivée** : le joueur ressort sur la plage d'Oliville à la tombée de la nuit (scène forcée en
  nuit, quelle que soit l'heure réelle **[D]**).

### 4.2 Acte 1 — La menace (JOH1 à JOH5)

**Oliville (JOH1).** Le joueur, épuisé, confie son équipe à l'infirmière du Centre et dort au
Centre. **Nuit** : bruit de verre, des silhouettes en noir. **Matin** : le Centre est cambriolé,
l'équipe et le sac ont disparu (objets clés, argent, badges et Pokédex restent). Le PC ne répond
pas : « le réseau de Kanto est coupé ». Le **Professeur Orme**, venu à Oliville pour étudier les
fuites de Pokémon (et le Phare), arrive. Il confie au joueur un Pokémon de départ de Johto :
**Germignon, Héricendre ou Kaiminus**, au choix (même mise en scène que le choix de Kanto, dans
une salle du Centre). Orme donne 5 Poké Balls et une Potion.

**Routes 39 et 38, Rosalia (JOH2).** Premières captures de Johto (Fouinette, Wattouat, Hoothoot
la nuit). À Rosalia, les deux tours sont **fermées** par les sages : « la Tour Cendrée a brûlé il y
a 150 ans ; depuis, trois Pokémon dorment sous ses cendres ». Deux Sbires interrogent les sages et
s'enfuient à l'arrivée du joueur (premier contact, sans combat) **[D]**.

**Routes 37 à 35, Doublonville (JOH3).** Premiers combats de Sbires sur la Route 37, la nuit
(Malosse, Cornèbre). Doublonville est inquiète : la Tour Radio diffuse des messages brouillés, des
Sbires dans le Souterrain. Le joueur ne peut pas encore entrer dans la Tour (porte gardée). Un
indice mène au sud : « les Sbires vendent des queues de Ramoloss à Écorcia ». Orme, joint par le
PC du Centre, envoie son assistant qui remet l'**œuf de Togepi** (§5.4).

**Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss (JOH4).** Le Bois aux Chênes a un petit
autel (fermé, rôle au post-game : Celebi). À Écorcia, le Puits Ramoloss est la **première base
Rocket** : les Sbires coupent les queues des Ramoloss. Le joueur les chasse et trouve un
**ordre de mission** signé d'une initiale, « D. », et un passe pour la Tour Radio. Le gardien du
puits donne une **Roche Royale** (évolution de Ramoloss et Têtarte, §5.5).

**Tour Radio de Doublonville (JOH5).** Le joueur monte les 5 étages (Sbires, deux admins). Au
sommet, l'admin diffuse un message : « Giovanni, reviens ! ». Puis la vraie voix prend l'antenne :
**Dante**. Il se présente comme le chef d'avant Giovanni, celui que Giovanni a trahi, et révèle
que c'est lui qui a fait voler l'équipe du Maître, « pour qu'aucun champion ne se mette en
travers ». Il ne se montre pas en personne **[D]**. Dans la salle de l'admin : les Poké Balls de
l'équipe et le sac. **L'équipe et le sac sont rendus**, le PC se reconnecte. Fin de l'acte 1.

### 4.3 Acte 2 — Les légendaires (JOH6 à JOH8)

**Le plan de Dante.** Ho-Oh, le gardien du ciel, a fait renaître trois Pokémon des cendres de la
Tour Cendrée : **Raikou, Entei et Suicune**. Dante veut capturer les trois pour forcer Ho-Oh à
descendre sur la Tour Carillon, et se servir de sa flamme pour « tout réduire en cendres » et
refonder la Team Rocket sur les ruines. Le joueur doit libérer les trois avant lui.

**Tour Cendrée (JOH6).** Les sages ouvrent la tour au joueur, désormais célèbre. Au sous-sol, les
trois chiens se réveillent et fuient dans trois directions. Un admin de Dante en capture un sous
les yeux du joueur (**Raikou**), part vers Acajou.

**Acajou, Lac Colère, Repaire Rocket (JOH6, suite).** Au Lac Colère, un **Léviator rouge** forcé à
évoluer par les ondes de la Team Rocket (combat et capture, clin d'œil à Or/Argent). Sous la
boutique d'Acajou, le **repaire** (3 niveaux, dalles et pièges dans l'esprit du repaire de
Céladopole). Au fond, Raikou captif : le joueur le libère (**combat et capture possibles**).

**Routes 40-41, Îles Tourbillon (JOH7).** Suicune s'est réfugié dans les Îles Tourbillon. Le
joueur y arrive avant l'admin ; combat de l'admin, puis Suicune (**combat et capture**). Au plus
profond, **Lugia**, gardien de la mer, l'ombre de la grotte marine (**combat et capture**).

**Tour Carillon (JOH8).** Entei, le troisième, est capturé par **Dante en personne**, qui monte à
la Tour Carillon. Le joueur le rattrape au sommet : **premier combat contre Dante** (équipe forte,
mais pas complète). Ho-Oh descend, refuse Dante et s'envole ; Dante relâche Entei pour fuir
(**combat et capture d'Entei**) et jure de « finir là où tout a commencé, au sommet du monde ».
**Ho-Oh** se pose ensuite au sommet de la tour (**combat et capture**) **[D]**.

### 4.4 Acte 3 — Le Mont Argenté (JOH9)

- **Accès** : depuis Acajou, la Route 43 mène au pied du Mont Argenté **[D]** (dans Or/Argent, on
  y entre par Kanto ; ici l'entrée est côté Johto, la sortie côté Kanto).
- **Le relais (JH-9)** : au pied du mont, le **rival** arrive de Kanto. Il a entendu la Tour Radio.
  « Je ne fais pas ça pour toi. » Il retient les Sbires et les admins à l'entrée pendant que le
  joueur monte. On le recroise à mi-hauteur, essoufflé, qui soigne l'équipe du joueur une fois.
- **L'ascension** : extérieur enneigé, 3 niveaux de grotte, les Pokémon sauvages les plus forts du
  jeu (Ursaring, Donphan, Ymphect, Farfuret, Airmure).
- **Le sommet** : **combat final contre Dante** (équipe complète, niveaux 72–78).
- **Giovanni (JH-7)** : après la défaite de Dante, Giovanni apparaît derrière lui, sans combat.
  Échange court : Dante, à terre, l'accuse ; Giovanni répond qu'il a « appris de son maître » et
  emmène ce qui reste de la Team Rocket, ou la dissout (texte à écrire, §12). Il part.
- **Le rival** arrive au sommet : « Toi et moi, ce n'est pas fini. » **Dernier combat de rivaux**
  (obligatoire **[D]**, niveaux 75–80).
- **Épilogue** : descente par la Route 28 jusqu'à la Route 22 ; retour à Bourg Palette ; Chen et
  Orme (par lettre ou en visite). Petit générique de chapitre **[D]**.

### 4.5 Après le chapitre (post-game de Johto)

- **Celebi** à l'autel du Bois aux Chênes (condition à trancher, JH-16).
- Les trois chiens : ceux que le joueur n'a pas capturés reviennent à leur place d'origine
  (Tour Cendrée) **[D]**, comme les légendaires de Kanto qui reviennent après la Ligue.
- Les combats en duo viendront avec leur propre chantier.

## 5. Systèmes neufs

### 5.1 Heure de jeu : `GameClock` (JH-6)

- Lit l'**heure et le jour réels du téléphone** (comme `DeviceClock`, injectable pour les tests).
- **Trois moments**, comme Or/Argent : **matin** 4 h–10 h, **jour** 10 h–18 h, **nuit** 18 h–4 h.
- **Sept jours** de la semaine, pour les PNJ et événements datés (§5.2).
- **Johto seulement** (JH-8 : Kanto garde son éclairage golden hour). Les intérieurs gardent
  `interior_warm` ; seules les fenêtres changent **[D]**.
- **Lumière** : trois profils neufs dans `data/world/lighting.json` (`johto_morning`,
  `johto_day`, `johto_night`), sur le modèle du golden hour : on règle l'étalonnage et les
  lumières, **sans repeindre** chaque décor trois fois. La nuit ajoute des points lumineux
  (fenêtres, lampadaires) posés dans les cartes.
- **Changement en direct** : si le moment change pendant que le joueur est sur une carte, la
  lumière glisse sur 10 s **[D]**, sans recharger la carte.
- **Rencontres** : chaque table de rencontres de Johto peut avoir trois variantes (matin, jour,
  nuit) ; sans variante, la table vaut pour toute la journée.
- **Triche à l'heure** : rien n'empêche le joueur de changer l'heure du téléphone ; on ne le
  bloque pas (jeu personnel) **[D]**.

### 5.2 Ce qui dépend de l'heure (contenu, option C)

| Élément | Règle |
|---|---|
| Pokémon de nuit | Hoothoot, Noarfang, Malosse, Démolosse, Cornèbre, Farfuret : nuit seulement |
| Pokémon du matin | Scarhino, Teddiursa : matin seulement dans le Bois aux Chênes |
| Évoli | Mentali le jour, Noctali la nuit (§5.5) |
| Team Rocket | Sbires de route seulement la nuit sur les Routes 37 et 42 (hors scènes forcées) |
| Grand Magasin de Doublonville | Une promotion différente chaque jour de la semaine |
| Sept PNJ de la semaine | Un PNJ par jour, dans une ville différente, donne un objet une fois (dans l'esprit des frères et sœurs de la semaine d'Or/Argent, personnages neufs) |
| Lokhlass | Le vendredi, aux Îles Tourbillon (espèce de Kanto, clin d'œil à Or/Argent) |
| Phare d'Oliville | Allumé la nuit (décor) |
| Tour Carillon | Les cloches sonnent à l'aube (décor, son) |

### 5.3 Équipe confisquée (JH-1 à JH-3)

- Au vol, l'**équipe** et le **sac** (sauf les objets clés) passent dans un état « confisqué » de la
  sauvegarde, intouchable.
- Le **Stockage** est verrouillé (« réseau de Kanto coupé ») jusqu'à la fin de l'acte 1.
- **Pendant l'acte 1**, le joueur se constitue une nouvelle équipe et un nouveau sac. À la Tour
  Radio, l'équipe confisquée revient : si l'équipe active a 6 Pokémon, les Pokémon en trop vont au
  Stockage (reconnecté au même moment) **[D]** ; les deux sacs **fusionnent** (quantités
  additionnées, plafond habituel) **[D]**.
- **Sécurité** : si le joueur quitte l'application pendant la scène du vol, la sauvegarde ne doit
  jamais laisser l'équipe perdue sans état « confisqué » (test dédié, JOH0).
- **Défaite pendant l'acte 1** : retour au Centre d'Oliville ou au dernier Centre, comme à Kanto.

### 5.4 L'œuf de Togepi

- Seul œuf du jeu (pas de reproduction). Remis à Doublonville (JOH3).
- Occupe une place d'équipe ; **éclot après 2 000 pas** **[D]** (comme un cycle court d'Or/Argent),
  au niveau 5, avec une petite scène.
- Ne combat pas, ne peut pas être déposé au Stockage tant que le Stockage est verrouillé (il l'est
  pendant l'acte 1) **[D]**.

### 5.5 Évolutions nouvelles

Le moteur n'a **ni bonheur, ni objets tenus**. Les évolutions d'Or/Argent qui en dépendent sont
adaptées sans les créer :

| Évolution | Or/Argent | Kanto 2026 (proposition) |
|---|---|---|
| Steelix, Cizayox | Échange en tenant Peau Métal | **Peau Métal** utilisée comme une pierre, avec le Cordon d'échange déjà connu (règle du J14) **[D]** |
| Roigada, Tarpaud | Échange en tenant Roche Royale | **Roche Royale**, même règle |
| Hyporoi | Échange en tenant Écaille Draco | **Écaille Draco**, même règle |
| Porygon2 | Échange en tenant Améliorator | **Améliorator**, même règle |
| Leuphorie, Nostenfer, Togetic, Mentali, Noctali | Bonheur élevé (+ heure pour Évoli) | **JH-11** : système de lien simple, ou méthodes de remplacement |

### 5.6 Pokédex

- Le Pokédex passe de 151 à **201 espèces** (151 + 50). Numérotation nationale (n° 152 à 251, avec
  des trous) **[D]**, pour que chaque espèce garde son numéro officiel.
- Affichage « vus · capturés · 201 espèces ». Le Diplôme de Kanto reste lié aux 151 ; un second
  **Diplôme de Johto** pour les 50 **[D]**.

### 5.7 Pokémon de départ et rival

- Le rival **n'a pas** de Pokémon de départ de Johto (il n'est pas là au début). Son équipe de
  Kanto monte simplement en niveau, avec un ou deux ajouts de Johto **[D]**.

## 6. Les 50 espèces : où et quand

| Espèce(s) | Où | Quand / comment |
|---|---|---|
| Germignon, Héricendre, Kaiminus | Oliville (Orme) | Au choix, JOH1 |
| Leurs évolutions | — | Niveaux d'Or/Argent (16/32, 14/36, 18/30) |
| Fouinette | Routes 39, 38, 36 | Jour, matin |
| Fouinar | Routes 37, 42 | Jour |
| Hoothoot | Routes 38, 37, 36 | Nuit |
| Noarfang | Routes 42, 43, Bois aux Chênes | Nuit |
| Wattouat | Routes 39, 38 | Toute la journée |
| Lainergie, Pharamp | Évolution (niv. 15, 30) ; un Pharamp au Phare (PNJ) | — |
| Marill | Routes 35, 42, Lac Colère (herbe et Surf) | Toute la journée |
| Azumarill | Lac Colère (Surf) | Rare |
| Malosse | Route 37 | Nuit |
| Démolosse | Route 43, Mont Argenté (extérieur) | Nuit |
| Cornèbre | Bois aux Chênes, Rosalia (herbe des tours) | Nuit |
| Farfuret | Lac Colère, Mont Argenté | Nuit |
| Qulbutoké | Îles Tourbillon | Rare ; aussi Pokémon des admins |
| Scarhino | Bois aux Chênes | Matin, rare |
| Teddiursa | Bois aux Chênes, Mont Argenté (bas) | Matin |
| Ursaring | Mont Argenté | Toute la journée |
| Phanpy | Route 28 | Jour |
| Donphan | Mont Argenté | Toute la journée |
| Embrylex | Mont Argenté (niveau 2) | Rare |
| Ymphect | Mont Argenté (niveau 3) | Rare |
| Tyranocif | Évolution (niv. 55) | — |
| Airmure | Route 28, Mont Argenté (extérieur) | Jour |
| Togepi | Œuf, Doublonville | JOH3 |
| Togetic | Évolution (JH-11) | — |
| Mentali, Noctali | Évoli + JH-11 | — |
| Steelix, Cizayox | Onix / Insécateur + Peau Métal (Oliville, Phare, JOH1 ou JOH6) | — |
| Roigada, Tarpaud | Ramoloss / Têtarte + Roche Royale (Puits Ramoloss) | — |
| Hyporoi | Hypocéan + Écaille Draco (Îles Tourbillon) | — |
| Porygon2 | Porygon + Améliorator (Doublonville, Grand Magasin, toit) | — |
| Leuphorie | Leveinard + JH-11 | — |
| Nostenfer | Nosferalto + JH-11 | — |
| Raikou | Repaire d'Acajou | Fixe, JOH6 |
| Suicune | Îles Tourbillon | Fixe, JOH7 |
| Lugia | Îles Tourbillon (fond) | Fixe, JOH7 |
| Entei | Tour Carillon | Fixe, JOH8 |
| Ho-Oh | Tour Carillon (sommet) | Fixe, JOH8 |
| Celebi | Bois aux Chênes (autel) | Post-game (JH-16) |

Les routes de Johto mêlent aussi des espèces de Kanto (Rattata, Roucool, Abo, Nidoran, Chétiflor,
Paras, Mystherbe, Ramoloss, Tentacool…), comme dans Or/Argent, pour remplir les tables sans
dépasser 50 espèces neuves.

## 7. Courbe de niveau

| Moment | Équipe du joueur | Sauvages | Dresseurs / Rocket |
|---|---|---|---|
| JOH1 Oliville | départ niv. 5 | 3–6 | — |
| JOH2 Routes 39-38, Rosalia | 8–14 | 6–12 | 9–13 |
| JOH3 Routes 37-35, Doublonville | 14–20 | 12–17 | 14–19 |
| JOH4 Écorcia, Puits Ramoloss | 20–26 | 16–22 | 20–25 |
| JOH5 Tour Radio | 26–32 | — | 26–33, admin 34–36 |
| **Retour de l'équipe** | équipe de Ligue 55–65 + nouveaux | | |
| JOH6 Tour Cendrée, Acajou, repaire | 58–64 | 40–50 | 55–60, admin 60–62, Raikou 60 |
| JOH7 Îles Tourbillon | 60–66 | 42–52 | admin 62–64, Suicune 60, Lugia 65 |
| JOH8 Tour Carillon | 62–68 | — | Dante (1) 64–68, Entei 60, Ho-Oh 65 |
| JOH9 Mont Argenté | 68–75 | 55–65 | Dante (2) 72–78, rival 75–80 |

- **Acte 1 plus rapide que Kanto** : environ 4 h de jeu pour monter de 5 à 30 ; expérience
  multipliée par **1,5** pendant l'acte 1 **[D]** (JH-13).
- **Les nouveaux Pokémon après l'acte 1** : niv. 30 face à une équipe de 60, ils risquent de rester
  au Stockage. Piste : **Multi Exp** offerte à la Tour Radio (JH-14).
- **Difficulté** (mémoire « Difficulté des combats ») : victoire du premier coup ≤ 80 % par
  défaut, 35–60 % pour les grands combats (Dante 1 et 2, rival final).

## 8. Personnages

| Personnage | Rôle | Note |
|---|---|---|
| Professeur Orme | Donne le Pokémon de départ, envoie l'œuf, épilogue | Peint dans la même main que Chen |
| L'infirmière d'Oliville | Témoin du vol | Même modèle que les infirmières de Kanto |
| Les sages de Rosalia | Gardent les tours | 1 modèle |
| Deux admins de Dante | Puits Ramoloss / Tour Radio, puis Acajou / Îles Tourbillon | Noms à trouver (JH-15) |
| Dante | Adversaire final | Âgé, élégant, cicatrice de brûlure **[D]** ; DA à valider |
| Giovanni | Apparition finale | Modèle de Kanto |
| Le rival | Relais, dernier combat | Modèle de Kanto, tenue d'hiver au Mont Argenté **[D]** |
| Sept PNJ de la semaine | Objets du jour | Personnages neufs, noms à trouver |

**Équipe de Dante (proposition [D])** : Démolosse, Farfuret, Tyranocif, Cizayox, Magmar (Kanto),
Arcanin (Kanto). Thème feu et ténèbres, cohérent avec « feu et cendres ».

## 9. Art

- **Décors** : environ 35 cartes peintes (vues générales, grilles), même méthode que Kanto
  (Codex, cahier `cahier-art-monde-v0.1.md`). Plus le travail de nuit : points lumineux, fenêtres.
- **Personnages** : Orme, Dante, 2 admins, sages, 7 PNJ de la semaine, Sbires (déjà là).
- **Pokémon** : 50 artworks officiels (Pokédex, adversaire) et 50 dos de combat repeints (même
  chaîne que Kanto, mémoire « Pokémon art source »).
- **Effets de combat** : attaques nouvelles d'Or/Argent (environ 40 à prévoir dans la liste
  d'attaques du JOH0) avec les familles d'effets existantes.
- **Musique** : bande-son Let's Go pour Kanto ; pour Johto, **JH-12**.

## 10. Découpage en jalons

| Jalon | Contenu | Validation |
|---|---|---|
| **JOH0** | Systèmes : `GameClock` et lumières de Johto, équipe confisquée, œuf, évolutions par objet, JH-11, Pokédex 201, sauvegarde v10, données des 50 espèces et de leurs attaques, Carte de Johto | Sauvegarde validée seule ; le reste en un lot |
| **JOH1** | Grotte marine, Oliville, vol, Orme, Pokémon de départ | Sous-jalon |
| **JOH2** | Routes 39 et 38, Rosalia (premier passage) | Sous-jalon |
| **JOH3** | Routes 37 à 35, Doublonville, œuf | Sous-jalon |
| **JOH4** | Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss | Sous-jalon |
| **JOH5** | Tour Radio, Dante à l'antenne, retour de l'équipe | Sous-jalon (le retour de l'équipe touche la sauvegarde : test dédié) |
| **JOH6** | Tour Cendrée, Route 42, Acajou, Route 43, Lac Colère, repaire, Raikou | Sous-jalon |
| **JOH7** | Routes 40-41, Îles Tourbillon, Suicune, Lugia, Lokhlass du vendredi | Sous-jalon |
| **JOH8** | Tour Carillon, Dante (1), Entei, Ho-Oh | Sous-jalon |
| **JOH9** | Mont Argenté, Route 28, relais du rival, Dante (2), Giovanni, rival, épilogue, Celebi | Sous-jalon |

Selon `strategie-acceleration.md` : 2 à 3 jalons en code au plus. JOH0 seul d'abord, puis JOH1 →
JOH5 (l'acte 1) en série, l'acte 2 pouvant être conçu pendant.

## 11. Arbitrages pour Kevin (JH-11 et suivants)

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-11 | **Bonheur** : Leuphorie, Nostenfer, Togetic, Mentali, Noctali en dépendent. On crée un système de lien, ou on remplace ? | Un **lien simple** caché (monte avec les combats, les pas et le compagnon qui suit le joueur ; baisse au K.O.), seuil unique ; s'appuie sur le compagnon du J11 et donne du sens à Évoli de jour / de nuit |
| JH-12 | **Musique de Johto** | Bande-son de **HeartGold / SoulSilver** pour Johto, comme Let's Go pour Kanto |
| JH-13 | **Expérience ×1,5** pendant l'acte 1 | Oui, invisible pour le joueur |
| JH-14 | **Multi Exp** offerte à la Tour Radio pour remettre à niveau les nouveaux Pokémon | Oui |
| JH-15 | **Noms** des deux admins de Dante | Claude propose une liste au dossier JOH4 |
| JH-16 | **Celebi** : condition d'apparition | Après le chapitre, à l'autel du Bois aux Chênes, avec un objet donné par Orme à l'épilogue |
| JH-17 | **Ho-Oh et Lugia capturables tous les deux** dans la même partie ? | Oui (le joueur est Maître ; pas de version Or ou Argent) |
| JH-18 | **Retour à Kanto pendant l'acte 1** interdit (§3.2) ? | Oui : sinon le joueur va chercher des Pokémon forts ailleurs |
| JH-19 | **Dernier combat de rivaux** obligatoire ou facultatif ? | Obligatoire : c'est la vraie fin du chapitre |
| JH-20 | **Dante** a-t-il un passé visible (souvenirs, journal comme Mewtwo au Manoir) ? | Oui, léger : 3 notes trouvées dans le repaire d'Acajou, qui racontent la trahison de Giovanni |

## 12. Textes

Écrits jalon par jalon, dans chaque dossier JOH1 à JOH9, et validés **en un lot par jalon** comme
à Kanto (mémoire « Design review workflow »). Moments clés à soigner : la lettre d'Orme, le vol, le
message de Dante à la Tour Radio, la Tour Carillon, l'échange Dante–Giovanni, les mots du rival.

## 13. Prochaines étapes

1. Kevin valide ce cadre et tranche JH-11 à JH-20.
2. Claude écrit le **dossier JOH0** (systèmes) et les **grilles** des cartes de l'acte 1.
3. Vues générales peintes de l'acte 1 (Codex), à valider par Kevin.
4. Code, seulement après la fin de Kanto.
