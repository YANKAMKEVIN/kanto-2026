# Dossier JOH-08 — La mer : Routes 40 et 41, Îles Tourbillon, Suicune, Lugia (jalon JOH7, v0.1)

> Deuxième jalon de l'acte 2 du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.3). Suite du JOH6 ([`dossier-joh-07-acajou.md`](dossier-joh-07-acajou.md) : le déserteur envoie le
> joueur aux Îles Tourbillon, C-45). Écrit par Claude le 2026-11-02 ; **textes M-1 à M-34 et
> arbitrages JH-48 à JH-51 validés par Kevin le jour même** (recommandations retenues) ; le reste est à valider. Valeurs **[D]** = défauts. Grilles et vues
> peintes après validation.

## 1. Hors périmètre

- Le Phare d'Oliville (intérieur), Ampharos malade et l'Arène d'Oliville ; Irisia et la Route 41
  vers l'ouest au-delà des îles (cadre §1).
- La Tour Carillon et Entei (JOH8). Les Îles Tourbillon sont **un seul donjon** (une entrée), pas
  quatre îles reliées comme dans Or/Argent **[D]**.

## 2. Hypothèses d'entrée

- JOH6 fait : `johto_raikou_done`, `johto_whirl_clue` ; équipe 60–66 attendue.
- Le joueur a Surf et Force (Kanto) ; aucune CS neuve (JH-48).
- Arc des Pierres (JOH-11) : Cenere a déjà été battue à l'Antre du Dragon ; **M-14** dit désormais « Trois erreurs »
  (validé le 2026-11-05, le code du JOH7 change avec le JOHP3) ; la mer au sud d'Oliville est fermée tant que `johto_act2` manque (JH-72).

## 3. Géographie **[D]**

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Route 40** | ≈ 24 × 40 | De la plage d'Oliville vers le sud, en Surf ; rochers, bancs de sable, 3 Nageurs |
| **Route 41** | ≈ 60 × 48 | Mer ouverte ; au centre, les **Îles Tourbillon** (une grande île rocheuse) ; des **tourbillons** en décor qui dessinent les chenaux ; 3 Dresseurs |
| **Îles Tourbillon 1F** | ≈ 30 × 24 | Grotte d'entrée ; échelles, rochers à pousser (Force) |
| **Îles Tourbillon B1F** | ≈ 36 × 28 | Lac souterrain en Surf avec **courants** (puzzle, JH-48) ; un rocher plat où se tient **Suicune** ; une crique où vient **Lokhlass le vendredi** |
| **Îles Tourbillon B2F** | ≈ 24 × 24 | Salle de **Lugia** : grande cascade, bassin profond, lumière bleue venue d'en haut |

**Grilles validées par Kevin le 2026-11-03** (validation d'avance) : `tools/plans/route_40.txt`, `route_41.txt`,
`whirl_islands_1f.txt`, `whirl_islands_b1f.txt`, `whirl_islands_b2f.txt` (la grille fait foi pour la
géométrie ; défauts [D] dans leurs en-têtes) ; retouche d'`oliville.txt` (marin de la plage, raccord
sud) ; contrôle `tools/art/plan_check_joh7.py` (courants simulés) ; aperçu
`reference/joh7-grilles-apercu-v1.png`. **Vues générales peintes le 2026-11-03** (`reference/route-40-vue-generale-v1.png`,
`route-41-…`, `iles-tourbillon-1f-…`, `iles-tourbillon-b1f-…`, `iles-tourbillon-b2f-vue-generale-v1.png`, plans annotés
`reference/plans-johto/`, planche `reference/joh7-vues-v1.png`, écarts et défauts dans `fiches-assets/serie-johto-vues-acte1.md`),
**validées par Kevin le 2026-11-03** (« Oui, fusionne »).

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Oliville, plage | Un marin parle des tourbillons (M-1) | — |
| 2 | Routes 40, 41 | Surf ; 6 Dresseurs ; les tourbillons guident vers l'entrée des îles | — |
| 3 | Îles 1F | Force ; 2 Sbires | — |
| 4 | Îles B1F | Courants ; **Suicune** sur son rocher (il regarde le joueur, ne fuit pas) | `johto_suicune_seen` |
| 5 | Îles B1F | **Cenere** arrive par une autre galerie (M-14) : **combat obligatoire** | `johto_cenere_defeated_2` |
| 6 | Îles B1F | Cenere part (M-17) ; **Suicune** s'avance : combat et capture | `johto_suicune_done` |
| 7 | Îles B2F | Le courant qui fermait l'escalier s'apaise (JH-49) ; **Lugia** : combat et capture | `johto_lugia_done` |
| 8 | Oliville | Un marin raconte que les tourbillons se sont calmés ; Orme (au Centre) donne l'accroche du JOH8 (M-31) | `johto_bell_tower_clue` |
| — | Îles B1F, crique | **Lokhlass le vendredi** (JH-50) | `week_friday_lapras` *(remis à zéro chaque vendredi tant qu'il n'est pas capturé)* |

## 5. Rencontres **[D]**

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Routes 40, 41 (Surf) | toute la journée | Tentacool 40, Tentacruel 25, Stari 15, Kokiyas 10, Krabby 10 | 42–48 |
| Routes 40, 41 (pêche) | toute la journée | Canne : Magicarpe, Tentacool ; Super Canne : Krabby, Hypotrempe, Stari | comme Kanto |
| Îles 1F | matin, jour | Nosferalto 30, Grolem 20, Racaillou 10, Krabboss 20, Lamantine 20 | 46–50 |
| Îles 1F | nuit | Nosferalto 40, Grolem 20, Lamantine 20, **Qulbutoké 5**, Krabboss 15 | 46–50 |
| Îles B1F (sol) | toute la journée | Nosferalto 35, Lamantine 25, Crustabri 20, Krabboss 15, **Qulbutoké 5** | 48–52 |
| Îles B1F (Surf) | toute la journée | Tentacruel 30, Lamantine 30, Hypocéan 25, Otaria 15 | 48–52 |

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Route 40 | Nageur Yanis | Tentacruel 50, Stari 49 | oui |
| Route 40 | Nageuse Élodie | Azumarill 51 | oui |
| Route 40 | Nageur Marius | Krabboss 50, Hypocéan 50 | oui |
| Route 41 | Nageuse Léa | Lamantine 52, Staross 52 | oui |
| Route 41 | Nageur Gabin | Tentacruel 51, Léviator 53 | oui |
| Route 41 | Pêcheur Noé | Hypocéan 52, Poissoroy 52 | **non** (chenal) |
| Îles 1F | Sbire (T) | Grotadmorv 58, Arbok 58 | oui |
| Îles 1F | Sbire (U) | Démolosse 59, Nosferalto 58 | **non** |
| Îles B1F | **Cenere**, admin | Smogogo 64, Qulbutoké 64, Noarfang 65, Lamantine 65, **Farfuret 66** **[D]** (dossier JOH-11 §10) | **non** |
| Îles B1F | **Suicune** | niv. 60, sauvage, capturable | (après Cenere) |
| Îles B2F | **Lugia** | niv. 65, sauvage, capturable | — |
| Îles B1F, crique | **Lokhlass** (vendredi) | niv. 50, sauvage, capturable | — |

- **Cenere** : grand combat (35–60 % du premier coup), méthodique : Qulbutoké pour piéger, Lamantine
  et Farfuret contre les Pokémon Dragon et Vol de l'équipe de Ligue **[D]**.
- **Suicune et Lugia** : K.O. ou fuite → ils disparaissent et reviennent après le chapitre (cadre
  §4.5) : Suicune à la Tour Cendrée, Lugia au B2F **[D]**. Jamais perdus définitivement.

## 7. Objets **[D]**

| Où | Objet |
|---|---|
| Route 40, banc de sable | Ultra Ball ×2 |
| Route 41, îlot | Max Potion |
| Îles 1F | Rappel Max |
| Îles B1F, au bout d'un courant | **Écaille Draco** (Hyporoi, JOH0 §9) |
| Îles B1F | PP Max |
| Îles B2F, derrière la cascade | Super Bonbon ×2 |

## 8. Courants et tourbillons (JH-48)

- **Pas de CS Siphon** (Kanto n'en a pas) : les tourbillons sont du **décor infranchissable** qui
  dessine les chenaux sur la Route 41 **[D]**.
- Au B1F, des **courants** poussent le joueur en Surf d'une case à l'autre, dans un sens (même
  mécanique que la grotte marine du JOH1 et les dalles tournantes de Céladopole, en version
  aquatique) ; le puzzle mène à Suicune, à l'Écaille Draco et à l'escalier du B2F.
- Au 1F, deux rochers à pousser avec **Force**.

## 9. Lugia (JH-49)

- L'escalier du B2F est fermé par un **courant violent** qui s'apaise après Suicune (M-21) : Suicune
  « purifie » l'eau, clin d'œil à son rôle dans Or/Argent **[D]**. Aucun objet requis (pas d'Argent
  Aile).
- Mise en scène : la cascade, une ombre sous l'eau (celle de la grotte marine, O-6), puis Lugia
  émerge (M-23, M-24).

## 10. Lokhlass du vendredi (JH-50)

Le **vendredi** seulement, un Lokhlass niv. 50 nage dans la crique du B1F (cadre §5.2). S'il n'est pas
capturé (K.O., fuite), il revient le **vendredi suivant** ; capturé, il ne revient plus **[D]**.

## 11. Cenere (JH-51)

Battue, Cenere reste **fidèle à Dante** : elle repart vers le nord et sera au Mont Argenté (JOH9),
où le rival retiendra les admins (cadre §4.4). Elle annonce que Dante a déjà Entei et monte à la
Tour Carillon (M-17).

## 12. Drapeaux **[D]**

`johto_suicune_seen`, `johto_cenere_defeated_2`, `johto_suicune_done`, `johto_lugia_done`,
`johto_bell_tower_clue`, `week_friday_lapras`.

## 13. Cas limites (à tester)

- Suicune ou Lugia K.O., fuite, Master Ball ; capture avec équipe pleine (Stockage).
- Lokhlass : jour qui change pendant que le joueur est dans la crique (il reste jusqu'à la sortie
  de la carte **[D]**) ; vendredi suivant après un K.O.
- Défaite contre Cenere : retour au Centre d'Oliville ; Cenere et Suicune restent.
- Corde Sortie dans les îles : ramène à l'entrée (Route 41, en Surf devant la grotte).
- Courants : jamais de boucle sans sortie (test de la grille).

## 14. Validation (sous-jalon JOH7)

- Tests : courants (grille), ordre Cenere → Suicune → courant du B2F → Lugia, Lokhlass par jour
  (horloge injectée), Écaille Draco et Hyporoi au terminal d'échange local.
- Captures : Route 41 et ses tourbillons, B1F (Suicune sur son rocher), B2F (Lugia, la cascade).

## 15. Art

Routes 40 et 41 (mer, tourbillons animés), Îles Tourbillon (extérieur sur la Route 41, 1F, B1F,
B2F). Personnages : Nageurs (modèles de Kanto), Cenere (JOH5). Pokémon : Suicune et Lugia (dos,
face), Lokhlass (existe). Musique de Lugia (HeartGold / SoulSilver, JH-12).

## 16. Textes (lot validé par Kevin le 2026-11-02)

Format : bulles séparées par « / ». `{joueur}` = nom.

| N° | Où | Texte |
|---|---|---|
| M-1 | Marin, plage d'Oliville | Au large, il y a des îles entourées de tourbillons. / Personne n'y va jamais. / Mais hier, un bateau noir s'est approché. |
| M-2 | Panneau, Route 40 | **ROUTE 40** / Oliville — Îles Tourbillon |
| M-3 | Panneau, Route 41 | **ROUTE 41** / Attention : tourbillons. Suivez les chenaux. |
| M-4 | Examen, tourbillon | L'eau tourne violemment. / Impossible de passer par là. |
| M-5 | Yanis · Élodie · Marius | Yanis — avant : La mer est mon terrain ! · défaite : J'ai bu la tasse. · après : Les îles sont plus au sud. — Élodie — avant : Tu nages jusqu'aux îles ? Moi aussi ! · défaite : Bon, vas-y la première. Enfin, le premier. · après : Fais attention aux courants. — Marius — avant : Mes Pokémon pincent fort ! · défaite : Ils ont lâché prise. · après : Suis les chenaux, pas les tourbillons. |
| M-6 | Léa · Gabin · Noé | Léa — avant : Si tu veux passer, il faut nager plus vite que moi ! · défaite : Tu nages vraiment vite. · après : J'ai vu un Pokémon bleu courir sur l'eau, ce matin. — Gabin — avant : Mon Léviator n'a peur de rien ! · défaite : Si, de toi. · après : Les îles grondent la nuit. — Noé — avant : Ce chenal est à moi. Un combat pour le droit de passage ! · défaite : Passe, passe. · après : Au fond des îles, il y a quelque chose d'immense. Mon grand-père le disait. |
| M-7 | Description de zone, Routes 40 et 41 | Route 40 : Une route marine, au sud d'Oliville. · Route 41 : La haute mer, autour des Îles Tourbillon. |
| M-8 | Panneau, Îles Tourbillon | **ÎLES TOURBILLON** / Lieu sacré. On dit qu'un gardien dort sous la mer. |
| M-9 | Description de zone, Îles Tourbillon | Des grottes battues par la mer, où l'eau tourne sans fin. |
| M-10 | Sbire T · Sbire U (1F) | T — avant : Cenere a dit : personne ne descend ! · défaite : Elle avait tout calculé, sauf toi. · après : Elle est déjà en bas. — U — avant : Pour Dante ! Tu ne passes pas ! · défaite : … Pour Dante… · après : Le bleu court plus vite que nous. Mais Cenere a un plan. |
| M-11 | Examen, courant | Le courant emporte {joueur} ! |
| M-12 | Système, Suicune | Un Pokémon bleu se tient sur le rocher. / Il regarde {joueur}, sans bouger. |
| M-13 | Examen, Suicune (avant Cenere) | Suicune observe {joueur}. / On dirait qu'il attend quelque chose. |
| M-14 | Cenere, arrivée | Tu es là avant moi. Encore. / Trois erreurs de calcul. Ça commence à faire beaucoup. |
| M-15 | Cenere, avant | Cette fois, j'ai étudié ton équipe. Chaque Pokémon. Chaque attaque. / Recule, ou je te range dans mes statistiques. |
| M-16 | Cenere, défaite | … Je ne comprends pas. / Mes calculs étaient justes. |
| M-17 | Cenere, après | Garde ton Suicune. Il ne compte plus. / Le maître a déjà le troisième. Le rouge. / Il monte à la Tour Carillon. / Quand Ho-Oh descendra, tu comprendras que tu as perdu depuis le début. · *(système)* Cenere s'en va… |
| M-18 | Système, Suicune s'avance | Suicune saute de son rocher. / Il s'approche de {joueur}… / Il veut se mesurer à {joueur} ! |
| M-19 | Système, Suicune après | L'eau de la grotte devient plus claire. |
| M-20 | Examen, escalier du B2F (avant Suicune) | Un courant violent remonte de l'escalier. / Impossible de descendre. |
| M-21 | Examen, escalier du B2F (après Suicune) | Le courant s'est apaisé. / On entend une cascade, tout en bas. |
| M-22 | Description de zone, B2F | Le cœur des îles, où la mer tombe en cascade. |
| M-23 | Système, Lugia (arrivée) | Le bassin est immobile. / … / Une ombre immense passe sous l'eau. / La même que dans la grotte de Bourg Palette ! |
| M-24 | Système, Lugia (émergence) | L'eau se soulève. / Lugia surgit des profondeurs ! |
| M-25 | Système, Lugia après (K.O. ou fuite) | Lugia replonge dans le bassin et disparaît. |
| M-26 | Système, Lokhlass du vendredi | Un Lokhlass nage dans la crique. / Il chante doucement. |
| M-27 | Système, Lokhlass absent (autre jour) | La crique est calme. / Il paraît qu'un Lokhlass y vient, certains jours. |
| M-28 | Système, Écaille Draco | {joueur} trouve une Écaille Draco ! / Une écaille dure et brillante. |
| M-29 | Marin, Oliville (après) | Les tourbillons se sont calmés d'un coup, cette nuit. / Comme si quelque chose, au fond, s'était enfin reposé. |
| M-30 | Enfant d'Oliville (O-22, après) | Mon papa dit que tu as vu le Pokémon le plus fort de la mer. / C'est vrai ? |
| M-31 | Orme, Centre d'Oliville (accroche du JOH8) | {joueur} ! Les sages de Rosalia m'ont appelé. / Un homme a forcé la porte de la Tour Carillon cette nuit. / Il avait un Pokémon rouge, enfermé dans une cage de feu. / Les sages t'attendent. Ils t'ouvriront la tour. |
| M-32 | Orme, après | Raikou, Suicune… Et maintenant Entei. / Dante veut les trois pour faire descendre Ho-Oh. / Il ne lui en manque plus qu'un. Fais vite. |
| M-33 | Description de zone, crique | Une petite crique, à l'abri des courants. |
| M-34 | Examen, cascade du B2F | L'eau tombe de très haut. / Derrière, on devine une petite grotte. |

## 17. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-48 | ✅ **Pas de CS neuve** : tourbillons en décor, puzzle de courants au B1F, Force au 1F (Kevin, 2026-11-02) | — |
| JH-49 | ✅ **Lugia accessible après Suicune** (le courant du B2F s'apaise), sans objet (Kevin) | — |
| JH-50 | ✅ **Lokhlass chaque vendredi** jusqu'à sa capture (Kevin) | — |
| JH-51 | ✅ **Cenere reste fidèle à Dante** et sera au Mont Argenté (Kevin) | — |
