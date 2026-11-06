# Dossier JOH-07 — Les cendres : Tour Cendrée, Route 42, Acajou, Route 43, Lac Colère, repaire (jalon JOH6, v0.1)

> Premier jalon de l'acte 2 du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.3). Suite directe du JOH5 ([`dossier-joh-06-tour-radio.md`](dossier-joh-06-tour-radio.md) : équipe
> rendue, accroche d'Orme). Écrit par Claude le 2026-11-02 ; **textes C-1 à C-46 et arbitrages
> JH-44 à JH-47 validés par Kevin le jour même** (recommandations retenues) ; le reste est à valider. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- La Tour Carillon (JOH8 : elle reste fermée ici), les Îles Tourbillon et Suicune (JOH7).
- Le Mont Creuset (intérieur, cadre §1) : son entrée sur la Route 42 reste une façade fermée.
- L'Arène d'Acajou et Frédo, la Route 44, la Route de Glace, Ebènelle (cadre §1).
- Les chiens « errants » d'Or/Argent : ici, ils ne parcourent pas les routes (§9).

## 2. Hypothèses d'entrée

- JOH5 fait : `johto_team_returned`, `johto_act2`, Multi Exp, Stockage en ligne ; Vol entre régions
  et grotte marine ouverts.
- Équipe attendue : l'équipe de Ligue (55–65) et l'équipe de Johto montée par le Réveil (55–62,
  dossier JOH-11 §13). `johto_act2` est posé à la fin de l'arc des Pierres ; aucun texte ni niveau de
  ce jalon ne change (JH-63, JH-78).
- Le joueur a Surf (Kanto, J23) et ses CS ; la Peau Métal est placée ici (JOH-02 §1).

## 3. Géographie **[D]**

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Rosalia** (retour) | déjà faite (JOH2) | Les sages ouvrent la Tour Cendrée ; la Tour Carillon reste fermée ; Diane le dimanche |
| **Tour Cendrée** | 1F ≈ 28 × 24 (ruine, planchers effondrés), B1F ≈ 20 × 16 | 1F : poutres calcinées, trous qui font tomber au B1F ; B1F : salle des **trois chiens endormis** |
| **Route 42** | ≈ 72 × 20 | De l'est de Rosalia vers Acajou ; un lac central à traverser en **Surf** ; la porte du Mont Creuset (fermée, « éboulement ») ; herbes hautes en 3 poches |
| **Acajou** | ≈ 36 × 30 | Petite ville de montagne ; Centre, **boutique de souvenirs** (entrée du repaire), 2 maisons ; antennes sur le toit de la boutique |
| **Route 43** | ≈ 24 × 52 | D'Acajou vers le nord ; le **poste de péage** tenu par des Sbires ; herbes hautes en 3 poches ; sortie nord vers le Lac Colère |
| **Lac Colère** | ≈ 56 × 52 | Grand lac en **Surf**, rives boisées ; le **Léviator rouge** au centre ; un pêcheur sur la rive sud |
| **Repaire Rocket d'Acajou** | B1F ≈ 30 × 18, B2F ≈ 30 × 22, B3F ≈ 24 × 18 | B1F : **statues de Persian** à caméra (alarmes) ; B2F : dalles tournantes (une salle), **cellules** (le déserteur), porte à mot de passe ; B3F : le **générateur d'ondes** alimenté par **Raikou** en cage, **Brace** |

Points de Vol : Acajou (et Rosalia, Doublonville, Écorcia déjà connus).

**Grilles validées par Kevin le 2026-11-03** (validation d'avance) : `tools/plans/burned_tower_1f.txt`,
`burned_tower_b1f.txt`, `route_42.txt`, `mahogany_town.txt`, `mahogany_souvenir_shop.txt`,
`route_43.txt`, `lake_of_rage.txt`, `mahogany_hideout_b1f.txt` à `b3f.txt` (la grille fait foi pour
la géométrie ; défauts [D] dans leurs en-têtes) ; retouche de `rosalia.txt` (porte de la Tour Cendrée
praticable, panneau C-3, raccord est) ; contrôle `tools/art/plan_check_joh6.py` ; aperçu
`reference/joh6-grilles-apercu-v1.png`. **Vues générales peintes le 2026-11-03** (`reference/tour-cendree-1f-vue-generale-v1.png`,
`tour-cendree-b1f-…`, `route-42-…`, `acajou-…`, `boutique-souvenirs-acajou-v1.png`, `route-43-…`, `lac-colere-…`,
`repaire-acajou-b1f-…` à `b3f-vue-generale-v1.png`, plans annotés `reference/plans-johto/`, planche `reference/joh6-vues-v1.png`,
écarts et défauts dans `fiches-assets/serie-johto-vues-acte1.md`), **validées par Kevin le 2026-11-03** (« Oui, fusionne »).

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Rosalia | Le doyen ouvre la Tour Cendrée (C-2) | `johto_burned_tower_open` |
| 2 | Tour Cendrée 1F | Exploration ; 2 Dresseurs (Médium, Sbire) ; un trou mène au B1F | — |
| 3 | Tour Cendrée B1F | Les trois chiens se réveillent et fuient (C-6) ; **Brace** surgit et capture **Raikou** avec une cage à ondes, sans combat, puis file vers l'est (C-7 à C-9) | `johto_beasts_awakened`, `johto_raikou_taken` |
| 4 | Rosalia | Le doyen comprend le plan (Ho-Oh, C-10, C-11) ; la Tour Carillon reste fermée (C-12) | `johto_dante_plan_known` |
| 5 | Route 42 | Surf ; 4 Dresseurs | — |
| 6 | Acajou | Les habitants parlent des ondes et du lac (C-16, C-17) ; boutique de souvenirs « normale » | — |
| 7 | Route 43 | **Péage** : 2 Sbires, le second obligatoire (C-20 à C-22) | `johto_toll_cleared` |
| 8 | Lac Colère | **Léviator rouge** (combat et capture, JH-46) ; le pêcheur montre d'où viennent les ondes (C-26) | `johto_red_gyarados_done` |
| 9 | Acajou, boutique | Le joueur trouve l'**escalier caché** (C-28) | `johto_hideout_found` |
| 10 | Repaire B1F | Statues de Persian : passer devant déclenche un Sbire (3 statues) | — |
| 11 | Repaire B2F | Dalles, 3 Sbires ; le **déserteur** en cellule raconte, **souvenir de Dante** (JH-44, JH-45) ; il donne le mot de passe (C-37) | `johto_dante_flashback_seen` |
| 12 | Repaire B3F | **Brace** (combat obligatoire) ; arrêt du générateur ; **Raikou** libéré (combat et capture) | `johto_brace_defeated_2`, `johto_raikou_done` |
| 13 | Acajou | Les ondes cessent ; le déserteur, au Centre, donne l'accroche du JOH7 (Cenere, Îles Tourbillon) (C-45) | `johto_whirl_clue` |
| — | Acajou, Rosalia | Samuel le samedi, Diane le dimanche | `week_saturday_gift`, `week_sunday_gift` |

Le Lac Colère (étape 8) est un **passage obligé** : l'escalier de la boutique ne se montre qu'avec
`johto_red_gyarados_done` **[D]**, pour que le Léviator rouge ne soit pas manqué.

## 5. Rencontres **[D]**

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Tour Cendrée 1F | toute la journée | Rattatac 30, Nosferalto 25, Smogogo 20, Spectrum 15, Magmar 10 | 40–44 |
| Route 42 | matin, jour | Fouinar 30, Roucoups 20, Ortie 20, Marill 15, Rapasdepic 15 | 40–45 |
| Route 42 | nuit | Noarfang 35, Nosferalto 25, Ortie 20, Marill 20 | 40–45 |
| Route 42, lac (Surf) | toute la journée | Marill 60, Azumarill 10, Tentacruel 30 | 40–45 |
| Route 43 | matin, jour | Fouinar 25, Nidorino 20, Nidorina 20, Roucoups 15, Aéromite 20 | 44–48 |
| Route 43 | nuit | Noarfang 30, **Démolosse 20**, Nidorino 15, Nidorina 15, Aéromite 20 | 44–48 |
| Lac Colère, rives | matin, jour | Nidorino 25, Nidorina 25, Fouinar 25, Roucoups 25 | 45–50 |
| Lac Colère, rives | nuit | **Farfuret 20**, Noarfang 30, Démolosse 20, Aéromite 30 | 45–50 |
| Lac Colère (Surf) | toute la journée | Magicarpe 50, Marill 20, **Azumarill 10**, Léviator 20 | 45–50 |
| Lac Colère (pêche) | toute la journée | Canne : Magicarpe ; Super Canne : Magicarpe, Léviator | comme Kanto |

Pas de rencontres dans le repaire (comme celui de Céladopole) **[D]**. Le Léviator sauvage du lac
est **normal** ; seul le Léviator fixe est rouge.

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Tour Cendrée 1F | Médium Odile | Spectrum 46, Ectoplasma 48 | oui |
| Tour Cendrée 1F | Sbire (P) | Smogogo 48, Rattatac 48 | oui |
| Route 42 | Pêcheur Marcel | Léviator 47, Tentacruel 46 | oui |
| Route 42 | Montagnard Hector | Grolem 48, Onix 47 | oui |
| Route 42 | Nageuse Coralie | Azumarill 48, Stari 46 | oui |
| Route 42 | Super Nerd Louis | Magnéton 47, Électrode 47 | **non** (passage étroit) |
| Route 43, péage | Sbire (Q) | Arbok 52, Nosferalto 52 | oui |
| Route 43, péage | Sbire péager | Démolosse 54, Smogogo 53 | **non** |
| Route 43 | Campeur Basile | Nidoking 52, Rapasdepic 51 | oui |
| Lac Colère | Pêcheur Ludovic | Léviator 52, Lokhlass 51 | oui |
| Repaire B1F | 3 Sbires d'alarme | Rattatac 55 + Arbok 55 · Grotadmorv 56 · Malosse 55 + Nosferalto 56 | **non** si l'alarme sonne, sinon évités |
| Repaire B2F | Sbire (R) | Smogogo 57, Magnéton 56 | oui |
| Repaire B2F | Sbire (S) | Démolosse 57, Cornèbre 56 | oui |
| Repaire B2F | Scientifique Rocket | Électrode 57, Magnéton 57, Porygon 56 | **non** (devant la porte) |
| Repaire B3F | **Brace**, admin | Rapasdepic 63, Arbok 63, Smogogo 64, **Démolosse 65** **[D]** (dossier JOH-11 §10) | **non** |
| Repaire B3F | **Raikou** | niv. 60, combat sauvage, capturable | (après Brace) |
| Lac Colère | **Léviator rouge** | niv. 50, combat sauvage, capturable | — |

- **Brace** est un grand combat (mémoire « Difficulté des combats » : 35–60 % du premier coup).
  Avec une équipe de Ligue à 58–64, les niveaux seuls ne suffisent pas : l'IA de Brace attaque fort
  (« je fonce ») et Démolosse a les meilleures attaques de Johto du jalon **[D]** ; réglage fin
  à l'équilibrage du jalon.
- **Raikou** : si le joueur le met K.O. ou fuit, Raikou disparaît et reviendra à la Tour Cendrée
  après le chapitre (cadre §4.5) ; il ne peut pas être perdu définitivement **[D]**.

## 7. Objets **[D]**

| Où | Objet |
|---|---|
| Tour Cendrée 1F | Rappel ; Hyper Potion (cachée sous une poutre) |
| Tour Cendrée B1F, coin | **Peau Métal** (JOH-02 §1) |
| Route 42 | Ultra Ball ×2 ; Super Bonbon (îlot du lac, Surf) |
| Route 43 | Max Potion |
| Lac Colère, rive nord | Rappel Max |
| Repaire B1F | Hyper Potion |
| Repaire B2F | Ultra Ball ×3 ; PP Plus |
| Repaire B3F | Max Repousse ×2 |

## 8. Le souvenir de Dante (JH-20, JH-44, JH-45)

**Où** : au repaire B2F, dans une cellule. Le prisonnier est un **déserteur** : un vieux Sbire qui
a servi sous Dante, puis sous Giovanni ; à la Tour Radio, il a refusé de suivre Dante (JH-43) et
Brace l'a enfermé. Le joueur ouvre la cellule (levier) ; il raconte (C-32 à C-34).

**Forme** : courte scène mise en scène (**≈ 40 s**, sans combat) **[D]** :
- **Filtre sépia**, bord d'image adouci ; fondu depuis la cellule.
- **Lieu** : l'ancien QG de la Team Rocket, à Kanto, vingt ans plus tôt **[D]** (un bureau ; décor
  peint, une seule vue).
- **Personnages** : **Dante** (jeune, sans cicatrice), **Giovanni** (jeune, son bras droit), un
  Persian ; deux modèles neufs (cadre §9).
- **Action** : un incendie éclate dans le QG ; Dante est coincé derrière une porte ; Giovanni
  pourrait l'ouvrir, la regarde, et part avec le Persian (C-35). Fondu sur les flammes.
- **Retour** : la cellule ; le déserteur conclut (C-36) : Dante a survécu, brûlé ; tout le monde
  l'a cru mort ; Giovanni a pris la Team Rocket.

Le souvenir donne son sens au « feu et cendres » de Dante, à sa cicatrice (cadre §8) et à
l'apparition finale de Giovanni (JH-7, JOH9).

## 9. Les trois chiens

| Chien | Après la Tour Cendrée | Où le retrouver |
|---|---|---|
| **Raikou** | Capturé par Brace (cage à ondes) | Repaire B3F, ce jalon |
| **Suicune** | Fuit vers l'ouest, vers la mer | Îles Tourbillon, JOH7 |
| **Entei** | Fuit vers le nord | Capturé par Dante, Tour Carillon, JOH8 |

Ils **ne parcourent pas** les routes (pas de chiens errants à la Or/Argent) **[D]** : chacun a une
scène et un combat fixes.

## 10. Le Léviator rouge (JH-46)

- **Combat fixe** au milieu du Lac Colère, en Surf, niv. 50, capturable ; une fois battu ou capturé,
  il ne revient pas.
- **Variante rouge unique** : une forme de couleur à part (sprite repeint, artwork recoloré,
  champ `variant: "red"` sur ce Pokémon) **[D]** ; **pas de système de chromatiques**. Au Pokédex,
  il compte comme Léviator.
- Le pêcheur explique : les ondes d'Acajou forcent les Magicarpe à évoluer (C-26).

## 11. PNJ de la semaine (les deux derniers)

| Jour | Où | Personnage | Don (une fois) |
|---|---|---|---|
| Samedi | Acajou, devant le Centre | **Samuel**, guide de montagne du samedi | Hyper Potion ×3 |
| Dimanche | Rosalia, devant la maison des sages | **Diane**, sonneuse de cloches du dimanche | Rappel Max |

Les sept PNJ de la semaine sont alors placés (Lucien, Margot, Mercédès, Jérôme, Vincent, Samuel,
Diane).

## 12. Drapeaux **[D]**

`johto_burned_tower_open`, `johto_beasts_awakened`, `johto_raikou_taken`, `johto_dante_plan_known`,
`johto_toll_cleared`, `johto_red_gyarados_done`, `johto_hideout_found`, `johto_dante_flashback_seen`,
`johto_brace_defeated_2`, `johto_raikou_done`, `johto_whirl_clue`, `week_saturday_gift`,
`week_sunday_gift`.

## 13. Cas limites (à tester)

- Raikou K.O. ou fuite (§6) ; Raikou capturé avec équipe pleine (au Stockage, en ligne depuis le
  JOH5) ; Master Ball sur Raikou ou le Léviator rouge.
- Léviator rouge K.O. : drapeau posé, il ne revient pas ; le Pokédex le note « vu ».
- Alarme du B1F : chaque statue ne sonne qu'une fois ; le Sbire appelé vient même si le joueur
  recule.
- Défaite contre Brace : retour au Centre d'Acajou ; Brace et Raikou restent au B3F.
- Mot de passe : la porte du B2F refuse tant que le déserteur n'a pas parlé.
- Corde Sortie dans le repaire : ramène dans la boutique.
- Le joueur vole vers Kanto en plein jalon : rien ne se perd, tout reprend au retour.

## 14. Validation (sous-jalon JOH6)

- Tests : ordre Tour Cendrée → péage → lac → boutique → repaire ; alarmes ; mot de passe ; Raikou
  (capture, K.O., fuite) ; variante rouge ; tables par moment ; PNJ du samedi et du dimanche.
- Captures : Tour Cendrée B1F (les chiens), Lac Colère et le Léviator rouge, repaire B1F (statue),
  le souvenir de Dante (sépia), B3F (générateur, Raikou).

## 15. Art

Tour Cendrée (1F, B1F), Route 42, Acajou (vue générale + plan), boutique de souvenirs, Route 43 et
poste de péage, Lac Colère (vue générale), repaire (3 étages, générateur d'ondes, cellules),
**décor du souvenir** (bureau de l'ancien QG, en flammes). Personnages neufs : **Dante jeune**,
**Giovanni jeune**, le **déserteur**, Samuel, Diane, le vendeur de souvenirs ; le doyen et Brace
existent. Pokémon : Raikou, Entei, Suicune (dos et face), **Léviator rouge** (variante),
cage à ondes (objet de décor).

## 16. Textes (lot validé par Kevin le 2026-11-02)

Format : bulles séparées par « / ». `{joueur}` = nom ; *italique* = souvenir.

| N° | Où | Texte |
|---|---|---|
| C-1 | Sage, devant la Tour Cendrée (avant le doyen) | Le doyen t'attend, jeune Dresseur. / Toute la ville a entendu la radio. |
| C-2 | Doyen, l'ouverture | Tu es revenu. Et avec tes vrais compagnons, cette fois. / Cet homme, à la radio… « quand tout sera cendres ». / Je crains qu'il ne parle de notre tour. / Je t'ouvre la Tour Cendrée. Va voir si les trois dorment toujours. |
| C-3 | Panneau, Tour Cendrée | **TOUR CENDRÉE** / Elle brûla il y a cent cinquante ans. Ne pas allumer de feu. |
| C-4 | Médium Odile · Sbire P | Odile — avant : Les esprits de la tour n'aiment pas les visiteurs. · défaite : Ils t'acceptent, finalement. · après : En bas, quelque chose respire. — P — avant : Le patron veut ce qui dort en bas. Dégage ! · défaite : Le patron va être furieux. · après : De toute façon, Brace est déjà en route. |
| C-5 | Examen, plancher effondré | Le plancher a brûlé. / On voit une salle, en dessous. |
| C-6 | Système, les trois chiens | Trois Pokémon dorment au milieu des cendres. / … / Ils ouvrent les yeux ! / Ils bondissent hors de la tour, chacun dans une direction ! |
| C-7 | Brace, arrivée | Ha ! Je savais que tu les réveillerais pour moi ! / Merci du coup de main, le gamin ! |
| C-8 | Système, la capture | Brace lance une cage métallique ! / Raikou est pris dans un filet d'éclairs ! |
| C-9 | Brace, départ | Un sur trois, c'est déjà pas mal. / Le patron s'occupera des deux autres. / À plus, le gamin ! |
| C-10 | Doyen, après | Ils sont réveillés… et l'un d'eux est captif. / Écoute. La légende dit que Ho-Oh veille sur ces trois-là. / Si un homme les tient tous les trois, Ho-Oh descendra à la Tour Carillon pour les sauver. |
| C-11 | Doyen, le plan | C'est donc ça, son plan : forcer Ho-Oh à descendre. / Et s'emparer de sa flamme. La flamme qui a fait renaître la tour… / Entre de mauvaises mains, elle peut tout réduire en cendres. / L'homme qui a pris Raikou est parti vers l'est. Vers Acajou. |
| C-12 | Garde, chemin de la Tour Carillon (acte 2) | La Tour Carillon reste fermée. / Le doyen dit que le moment n'est pas encore venu. |
| C-13 | Panneau, Route 42 | **ROUTE 42** / Rosalia — Acajou |
| C-14 | Examen, porte du Mont Creuset | Un éboulement bloque l'entrée. / Le passage est fermé. |
| C-15 | Marcel · Hector · Coralie · Louis | Marcel — avant : Le lac est à moi aujourd'hui ! · défaite : Bon, partageons. · après : À Acajou, les poissons deviennent bizarres. — Hector — avant : Les montagnes forgent les Pokémon ! · défaite : Ils étaient mal forgés. · après : Le Mont Creuset est fermé depuis l'éboulement. — Coralie — avant : Tu nages bien ? Voyons ça ! · défaite : Tu nages mieux que moi. · après : Acajou est juste après le lac. — Louis — avant : Mes Pokémon captent des ondes étranges depuis une semaine ! · défaite : Les ondes m'ont déconcentré. · après : Elles viennent de l'est. D'Acajou, peut-être. |
| C-16 | Panneau, Acajou | **ACAJOU** / La ville des montagnes et des vieux secrets |
| C-17 | Habitant, Acajou | Tu as vu l'homme en noir, tout à l'heure ? Il traînait une cage qui crépitait. / Il est entré quelque part en ville, mais où ? |
| C-18 | Habitante, Acajou | Au Lac Colère, au nord, les Magicarpe sont devenus fous. / Ils évoluent tous en Léviator, et ils sont furieux. |
| C-19 | Vendeur de souvenirs (avant) | Bienvenue ! Des souvenirs d'Acajou ? / … Non ? Alors ne traîne pas, je ferme bientôt. |
| C-20 | Panneau, Route 43 | **ROUTE 43** / Acajou — Lac Colère |
| C-21 | Sbire Q (péage) | avant : Péage ! 1 000 Pokédollars pour passer. Ou tes Pokémon. · défaite : Bon, c'est gratuit aujourd'hui. · après : Le péager, devant, ne rigole pas. |
| C-22 | Sbire péager | avant : Tu veux passer sans payer ? Chez nous, ça se règle en combat. · défaite : Le péage est fermé. Définitivement. · après : Va voir le lac, si ça t'amuse. Les ondes, c'est notre œuvre. |
| C-23 | Campeur Basile | avant : La route du lac est à moi ! · défaite : Elle est à toi. · après : Au milieu du lac, il y a un Léviator rouge. Rouge ! |
| C-24 | Panneau, Lac Colère | **LAC COLÈRE** / Ne pas déranger les Pokémon du lac |
| C-25 | Système, Léviator rouge | Un Léviator rouge surgit des eaux ! / Il est furieux ! |
| C-26 | Pêcheur, après le Léviator rouge | Tu l'as calmé ? Bravo ! / Ce Léviator était un Magicarpe, il y a dix jours. / Des ondes viennent d'Acajou et forcent les Magicarpe à évoluer. / J'ai vu une antenne sur le toit de la boutique de souvenirs. Drôle d'endroit pour une antenne, non ? |
| C-27 | Pêcheur Ludovic | avant : Le lac est calme, enfin. Un combat pour fêter ça ? · défaite : Bien joué. · après : Les Léviator reviendront à la normale, j'espère. |
| C-28 | Système, boutique (après le lac) | Un courant d'air froid sort de sous une étagère. / … / Un escalier ! |
| C-29 | Vendeur de souvenirs (escalier trouvé) | Hé ! Qui t'a permis de… / … Tant pis. De toute façon, Brace t'attend. |
| C-30 | Système, statue de Persian | Les yeux de la statue s'allument ! / *Une alarme retentit !* |
| C-31 | Sbires du repaire (B1F, B2F) | Alarme — avant : Intrus ! Pas un pas de plus ! · défaite : Coupez l'alarme… · après : Tu ne sortiras pas d'ici. — R — avant : Dante a dit : personne ne passe. · défaite : Dante ne va pas aimer ça. · après : Moi, j'ai choisi Dante. Les autres sont partis, les lâches. — S — avant : On n'est plus pour Giovanni. On est pour Dante ! · défaite : Pour Dante… aïe. · après : Il a un plan. Un vrai. — Scientifique — avant : Mes ondes sont parfaites ! Tu ne toucheras pas à la porte ! · défaite : Erreur de mesure. · après : Le mot de passe ? Je ne le dirai jamais. Jamais ! |
| C-32 | Le déserteur, en cellule | Hé, toi ! Le gamin de la radio ! Sors-moi de là. / Je ne suis pas avec eux. Plus maintenant. |
| C-33 | Le déserteur, libéré | Merci. / Après la Tour Radio, j'ai dit non. Je suis venu pour Giovanni, pas pour lui. / Brace m'a jeté ici. / Tu veux savoir qui est Dante ? J'étais là, moi. Il y a vingt ans. |
| C-34 | Le déserteur, le récit | Dante était notre chef. Le premier. / Giovanni était son bras droit. Son élève. Presque son fils. / Et puis il y a eu l'incendie… |
| C-35 | **Souvenir** (sépia) | *Dante : Giovanni ! La porte est bloquée ! Ouvre !* / *…* / *Giovanni : Tu m'as tout appris, Dante.* / *Giovanni : Même ça. Surtout ça.* / *(Giovanni s'éloigne avec Persian. Les flammes montent.)* |
| C-36 | Le déserteur, après | Tout le monde l'a cru mort. Giovanni a pris la Team Rocket. / Mais Dante a survécu. Brûlé, défiguré. / Il a attendu vingt ans. Et maintenant, il veut tout brûler à son tour. |
| C-37 | Le déserteur, le mot de passe | La porte du fond a un mot de passe. / Avant, c'était « Vive Giovanni ». Maintenant, c'est « Gloire à Dante ». / Ça me brûle la langue de le dire. |
| C-38 | Système, porte à mot de passe | « Mot de passe ? » / {joueur} : Gloire à Dante. / La porte s'ouvre. |
| C-39 | Examen, générateur d'ondes | Une énorme machine bourdonne. / Des câbles partent de la cage de Raikou. / Raikou sert de pile à la machine ! |
| C-40 | Brace, avant | Encore toi ! Tu me suis partout ! / Tant mieux. Au puits, tu avais des Pokémon de rien du tout. / Montre-moi tes vrais Pokémon. Je fonce ! |
| C-41 | Brace, défaite | Non, non, non ! Pas encore ! |
| C-42 | Brace, après | Ta victoire ne change rien. / Cenere est déjà partie chercher le deuxième. / Et le patron ira chercher le troisième lui-même. / On se reverra au sommet, le gamin ! · *(système)* Brace s'enfuit par un passage secret ! |
| C-43 | Système, arrêt du générateur | {joueur} coupe le générateur. / … / Le bourdonnement s'arrête. La cage s'ouvre ! |
| C-44 | Système, Raikou | Raikou rugit ! |
| C-45 | Le déserteur, au Centre d'Acajou (après) | Le lac est calme, la machine est morte. Merci. / Écoute : Cenere est partie vers la mer, à l'ouest. / Le Pokémon bleu, celui qui court sur l'eau… / Elle le cherche aux Îles Tourbillon. Les Sbires en parlaient. |
| C-46 | Samuel (samedi, Acajou) · Diane (dimanche, Rosalia) | Samuel — Le samedi, je guide les randonneurs dans la montagne. / Tiens, en montagne, on n'en a jamais trop. · *(système)* {joueur} reçoit 3 Hyper Potions ! · après : À samedi, sur les sentiers ! — Diane — Le dimanche, je sonne les cloches de Rosalia. / Elles réveillent les cœurs endormis. Prends ceci. · *(système)* {joueur} reçoit un Rappel Max ! · après : Reviens un dimanche écouter les cloches. |

Descriptions de zone **[D]** (validées avec le lot) : Tour Cendrée « Une tour noircie, où dorment les
légendes. » · Route 42 « Une route entre lac et montagne, vers Acajou. » · Acajou « Une petite ville
de montagne, plus secrète qu'elle n'en a l'air. » · Route 43 « Une route boisée, vers le Lac
Colère. » · Lac Colère « Un grand lac de montagne, troublé par d'étranges ondes. » · Repaire
« Le repaire de la Team Rocket, sous Acajou. »

## 17. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-44 | ✅ Le souvenir est raconté au **repaire d'Acajou** par un **déserteur** emprisonné (Kevin, 2026-11-02) | — |
| JH-45 | ✅ Le souvenir montre **l'incendie de l'ancien QG** : Giovanni laisse Dante derrière la porte ; Dante survit, brûlé (Kevin) | — |
| JH-46 | ✅ **Léviator rouge** = variante unique, combat et capture, pas de système de chromatiques (Kevin) | — |
| JH-47 | ✅ **Joueur seul** au repaire, pas de Peter (Kevin) | — |

## Annexe : textes hors dossier validés par Kevin (2026-11-06)

Lot `docs/design/passes/johto-textes-a-valider.md`, validé tel quel.

- `mahogany_house_1_habitante` (Habitante) : Depuis une semaine, la radio grésille toute la journée. / Ça vient de quelque part en ville, je crois.
- `mahogany_house_2_habitant_1` (Habitant) : Acajou était un village bien tranquille. / Jusqu'à cette semaine.
- `mahogany_house_2_habitant_2` (Habitant) : Mon petit-fils dit que les Magicarpe sont furieux.
- `mahogany_souvenir_shop_etagere` : Des cartes postales et des porte-clés d'Acajou.
- `mahogany_hideout_b2f_levier/variants/0` : Un levier. Il commande les grilles des cellules.
- `joh6_lever_pulled` : Le levier bascule. / La grille de la cellule du milieu s'ouvre !
