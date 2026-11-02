# Dossier JOH-06 — La Tour Radio de Doublonville (jalon JOH5, v0.1)

> Cinquième et dernier jalon de l'acte 1 du Chapitre Johto (cadre
> [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md) §4.2 ; systèmes
> [`dossier-joh-01-systemes-joh0.md`](dossier-joh-01-systemes-joh0.md) §6 et §10). Écrit par Claude
> le 2026-11-02 ; **textes T-1 à T-38 et arbitrages JH-40 à JH-43 validés par Kevin le jour même**
> (recommandations retenues) ; le reste est à valider. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- Le sous-sol de la Tour Radio et l'entrepôt souterrain d'Or/Argent, la carte Radio du Pokématos,
  les émissions (Musique Pokémon, Loterie, Professeur Chen à la radio).
- Le souvenir de Dante (JH-20) : au JOH6. Brace : revient au JOH6 (Acajou, JH-15).
- Le contenu de l'acte 2 ; ce dossier s'arrête à l'accroche (Orme, sages de Rosalia).

## 2. Hypothèses d'entrée

- JOH4 fait : `johto_brace_defeated`, `johto_radio_pass` (Carte d'accès), Ordre de mission dans le
  Sac, équipe de Johto niv. 22–26, œuf en général éclos.
- JOH0 fait : section `confiscated`, `storage_offline`, écran de sélection des 6 (JH-24), fusion des
  sacs, Multi Exp (`exp_all`, objet clé du lot 32P).

## 3. Géographie **[D]**

La Tour est un **donjon vertical de 5 étages** (≈ 24 × 16 chacun), escaliers en alternance
gauche / droite, comme la Sylphe SARL en plus court. L'**ascenseur est en panne** (courant coupé
par les Sbires) jusqu'à la défaite de Cenere ; ensuite il dessert tous les étages.

| Étage | Contenu |
|---|---|
| **1F, hall** | Déjà vu au JOH3 (D-18, D-19). Le **faux employé** (JH-34) garde l'escalier ; comptoir d'accueil vide |
| **2F, studios** | Deux studios vitrés, micros, Sbires ; un haut-parleur passe le message de Cenere en boucle |
| **3F, archives** | Rayonnages ; la **réserve fermée** où sont enfermés les employés, dont **Raphaël**, le mari de la femme de D-37 |
| **4F, régie** | Pupitres, écrans, câbles au sol ; la dernière ligne de Sbires |
| **5F, studio de diffusion** | Grand studio vitré sur la ville ; **Cenere** au micro ; le **bureau du directeur** (porte fermée) où sont le directeur ligoté, les **Poké Balls de l'équipe** et le **sac** ; un escalier de secours (par où Cenere s'en va) |

Aucune rencontre sauvage dans la Tour.

**Grilles préparées le 2026-11-02 (à valider par Kevin)** : `tools/plans/radio_tower_1f.txt` à
`radio_tower_5f.txt` (24 × 16 chacune) ; contrôle `tools/art/plan_check_joh5.py`, aperçu
`reference/joh5-grilles-apercu-v1.png`. Les grilles font foi pour la géométrie. Escaliers en
alternance : 1F ↔ 2F (3, 0), 2F ↔ 3F (20, 0), 3F ↔ 4F (3, 0), 4F ↔ 5F (20, 0) ; ascenseur (18, 0) à
chaque étage, en panne jusqu'à `johto_cenere_defeated` ; sortie du 1F (11..12, 15) ↔ porte de la Tour à
Doublonville (10..11, 15). Défauts [D] notés dans les en-têtes : faux employé et Cenere lancés par un
déclencheur de scène (niche de l'escalier au 1F, ouverture de la vitre au 5F) ; Sbires inévitables par
rétrécissement (2F couloir du bas, 3F passage de la cloison sous la vue du gardien, 4F accès à la niche
de l'escalier) ; réserve et bureau du directeur fermés par une position `porte_cle` ; cabine de
l'ascenseur sur le modèle du Grand Magasin de Céladopole ; escalier de secours en décor dans le mur est.

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Doublonville | Retour du Bois aux Chênes ; les haut-parleurs passent « Giovanni, reviens ! » (T-1) | — |
| 2 | 1F | Avec la Carte d'accès, le faux employé se trahit : **combat obligatoire** (JH-40), il s'enfuit | `johto_radio_impostor_defeated` |
| 3 | 2F | 3 Sbires (1 obligatoire) | — |
| 4 | 3F | 3 Sbires (le gardien de la réserve obligatoire) ; on libère les employés et **Raphaël** | `johto_radio_staff_freed` |
| 5 | 4F | 3 Sbires (1 obligatoire) | — |
| 6 | 5F | Cenere au micro (T-15) ; **combat obligatoire** contre **Cenere seule** (JH-41) | `johto_cenere_defeated` |
| 7 | 5F | **Dante prend l'antenne**, voix seule (T-19) ; les Sbires présents se divisent (JH-43) ; Dante ordonne la retraite, Cenere laisse tout (JH-42) et part | `johto_dante_revealed` |
| 8 | 5F, bureau | Le directeur, les Poké Balls et le sac : **retour de l'équipe** (§7) ; le directeur offre la **Multi Exp** | `johto_team_returned`, `radio_exp_share_given` ; retire `johto_act1`, `storage_offline` |
| 9 | 1F | L'Agente garde l'**Ordre de mission** et la **Carte d'accès** comme preuves (§8) ; **Orme** donne l'accroche de l'acte 2 | `johto_act2` |
| 10 | Doublonville | Les haut-parleurs reprennent ; Raphaël est rentré chez lui (T-35) | `goldenrod_husband_gift` |

## 5. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| 1F | **Faux employé** (Sbire déguisé) | Arbok 26, Rattatac 26 | **non** |
| 2F | Sbire (H) | Nosferalto 26, Smogo 26 | oui |
| 2F | Sbire (I) | Malosse 27, Cornèbre 27 | **non** (couloir) |
| 2F | Sbire (J) | Magnéton 27 | oui |
| 3F | Sbire (K) | Grotadmorv 28, Abo 27 | oui |
| 3F | Sbire (L) | Rattatac 28, Nosferalto 28 | oui |
| 3F | Gardien de la réserve | Malosse 28, Smogo 28, Cornèbre 29 | **non** |
| 4F | Sbire (M) | Arbok 29, Grotadmorv 29 | oui |
| 4F | Sbire (N) | Magnéton 29, Smogogo 29 | oui |
| 4F | Sbire (O) | Malosse 30, Nosferalto 30 | **non** (devant l'escalier) |
| 5F | **Cenere**, admin | Smogogo 33, Qulbutoké 33, **Farfuret 35** | **non** |

- **Cenere** est un **grand combat** (mémoire « Difficulté des combats » : victoire du premier coup
  35–60 % avec l'équipe attendue niv. 28–32). Froide et méthodique : Qulbutoké en second pour
  bloquer les changements, Farfuret en dernier.
- Objectif : équipe de Johto niv. 28–32 à la sortie, conforme au cadre §7 (Exp ×1,5 jusqu'au
  retour de l'équipe).

## 6. Objets **[D]**

| Où | Objet |
|---|---|
| 2F, studio | Super Potion ×2 |
| 3F, rayonnage (caché) | Super Bonbon |
| 4F, sous un pupitre | Hyper Potion |
| 4F, coin de la régie | Rappel |
| Directeur | **Multi Exp** (ou Super Bonbon ×3 si le joueur l'a déjà, JOH0 §10) |
| Femme de D-37 (après) | Ultra Ball ×3 |

## 7. Le retour de l'équipe (JH-2, JH-3, JH-24)

Système du JOH0 (§6.4), ici sa mise en scène :

1. **Le bureau** : T-24 à T-26. Les Poké Balls sont sur le bureau, le sac posé à côté.
2. **Retrouvailles** : le compagnon d'avant le vol sort de sa Ball et saute vers le joueur (T-27),
   petite animation du compagnon du J11 **[D]**. S'il n'y avait pas de compagnon, le premier de
   l'équipe confisquée **[D]**.
3. **Choix des 6** (JH-24) : écran de sélection sur les deux équipes réunies (Johto et confisquée),
   l'œuf compris s'il n'a pas éclos. Si le total fait **6 ou moins**, pas d'écran : tout le monde
   reste dans l'équipe **[D]**. Les Pokémon non choisis vont au **Stockage**, qui se reconnecte au
   même moment (T-29).
4. **Sacs** : fusion, quantités additionnées, plafond habituel (le surplus est perdu au-delà du
   plafond ; en pratique jamais atteint) **[D]** (T-30).
5. **Une seule écriture** de sauvegarde (JOH0 §6.2), puis le directeur parle (T-31, T-32).
6. **Fin de l'acte 1** : `johto_act1` retiré (fin de l'Exp ×1,5), `storage_offline` retiré, terminal
   d'échange local rouvert, `johto_team_returned` posé ; à partir de là, **Vol entre régions** et
   **grotte marine** ouverts (JOH0 §5, JH-18) : le courant de la grotte (O-7) disparaît.

## 8. L'Ordre de mission et la Carte d'accès

À la sortie, au 1F, l'**Agente** de Doublonville (modèle des agentes de Kanto) demande les deux
objets clés comme preuves (T-33) ; ils **quittent le Sac** **[D]**. Le « D. » de l'ordre prend son
sens : « D. comme Dante ».

## 9. L'accroche de l'acte 2

Orme attend au 1F, avec l'Agente (T-34). Il a tout entendu à la radio ; Chen lui a déjà parlé de
Dante ; les **sages de Rosalia** ont appelé : la Tour Cendrée (JOH6). Le souvenir de Dante (JH-20)
vient au JOH6.

## 10. Drapeaux **[D]**

`johto_radio_impostor_defeated`, `johto_radio_staff_freed`, `johto_cenere_defeated`,
`johto_dante_revealed`, `johto_team_returned`, `radio_exp_share_given`, `johto_act2`,
`goldenrod_husband_gift` ; **retirés** : `johto_act1`, `storage_offline`.

## 11. Cas limites (à tester)

- **Application tuée** pendant l'écran de sélection : au rechargement, `confiscated` est intact et la
  scène reprend au bureau (T-24) ; jamais d'équipe perdue (JOH0 §6.5).
- Défaite contre Cenere : retour au Centre de Doublonville ; étages nettoyés, Cenere toujours au 5F.
- Le joueur sort de la Tour avant Cenere : les haut-parleurs passent toujours T-1.
- Total ≤ 6 Pokémon (pas d'écran) ; œuf non éclos au retour (sélectionnable, éclot ensuite) ;
  compagnon d'avant le vol non retenu dans les 6 (compagnon = premier de l'équipe, JOH0 §6.4).
- Multi Exp déjà possédée (Super Bonbon ×3).
- Sauvegarde chargée juste après : Vol vers Kanto proposé, grotte marine franchissable.

## 12. Validation (sous-jalon JOH5)

- Le retour de l'équipe touche la sauvegarde : **test dédié** (cadre §10), sur une copie de la vraie
  sauvegarde de Kevin passée par l'acte 1 en scène de test.
- Tests : ordre faux employé → étages → Cenere → Dante → bureau ; écran des 6 (total ≤ 6, > 6, œuf) ;
  fusion des sacs ; drapeaux de fin d'acte ; Multi Exp ou Super Bonbons ; preuves remises.
- Captures : 1F avec le faux employé, 3F réserve, 5F studio (Cenere), écran des 6, bureau.

## 13. Art

Intérieurs : 2F, 3F, 4F, 5F (le 1F vient du JOH3) ; vue du 5F sur Doublonville de nuit et de jour.
Personnages neufs : **Cenere** (froide, méthodique, tenue d'admin assortie à Brace), le
**directeur** de la radio, **Raphaël** (technicien), employés (1 modèle). L'Agente et Orme
existent. **Dante n'apparaît pas** (voix seule, cadre §4.2) : rien à peindre ; à l'écran, le
haut-parleur et un grésillement **[D]**.

## 14. Textes (lot validé par Kevin le 2026-11-02)

Format : bulles séparées par « / ». `{joueur}`, `{pokemon}` = noms ; *italique* = voix dans les
haut-parleurs.

| N° | Où | Texte |
|---|---|---|
| T-1 | Haut-parleurs de la ville (avant Cenere) | *Ici Radio Rocket.* / *À tous les membres de la Team Rocket, où que vous soyez :* / *Giovanni, reviens ! La Team Rocket t'attend à Johto.* / *Rassemblez-vous. Le grand retour approche.* |
| T-2 | Faux employé, avec la Carte d'accès | Désolé, la Tour est fermée au… / Une Carte d'accès ? Fais voir. / … / C'est la carte de Brace ! Comment tu l'as eue ? / … Oups. Bon, tant pis. Tu ne monteras pas ! |
| T-3 | Faux employé, défaite · après | défaite : Mon déguisement était parfait, pourtant… · après : Le vrai personnel ? Enfermé là-haut. Bonne chance ! |
| T-4 | Système, le faux employé s'enfuit | Le faux employé arrache son uniforme et file dans l'escalier ! |
| T-5 | Examen, ascenseur | L'ascenseur est en panne. / Quelqu'un a coupé le courant. |
| T-6 | Sbire H · I · J (2F) | H — avant : Les studios sont à nous ! · défaite : Coupez ! Coupez ! · après : Écoute bien la radio, gamin. Notre chef revient. — I — avant : Tu entends ? C'est l'appel de Giovanni ! · défaite : Giovanni ne sera pas content… · après : Bientôt, toute la Team Rocket sera réunie. — J — avant : Mon Magnéton brouille tout, même tes ordres ! · défaite : Plus de signal. · après : Les ordres arrivent par la radio. On ne voit jamais qui les donne. |
| T-7 | Sbire K · L (3F) | K — avant : Les archives, c'est interdit ! · défaite : Bon, lis ce que tu veux. · après : Il paraît que les vrais ordres viennent de très loin. — L — avant : Tu es le Maître de Kanto ? Sans tes Pokémon, tu n'es rien ! · défaite : … Tu n'en avais pas besoin, on dirait. · après : Ils sont là-haut, tes Pokémon. Mais tu n'iras pas si loin. |
| T-8 | Gardien de la réserve | avant : Personne ne touche à la réserve. Les employés restent dedans ! · défaite : D'accord, d'accord, je donne la clé ! · après : Cenere va me congeler sur place. |
| T-9 | Système, la réserve | {joueur} ouvre la porte de la réserve. |
| T-10 | Employée libérée | Enfin ! Ils nous ont enfermés ici depuis des jours. / Le directeur est resté là-haut, avec leur chef. |
| T-11 | Raphaël, libéré | Merci ! Je m'appelle Raphaël, je suis technicien. / Trois jours dans le noir… / Ma femme doit être morte d'inquiétude. Je rentre tout de suite ! |
| T-12 | Sbire M · N · O (4F) | M — avant : La régie, c'est le cœur de la Tour. Tu ne passeras pas ! · défaite : Le cœur a lâché. · après : Cenere règle tout à la seconde près. Toi, tu n'étais pas prévu. — N — avant : Le message passe sur toutes les ondes de Johto ! · défaite : Interférences… · après : Si Giovanni l'entend, il viendra. Forcément. — O — avant : Dernier étage avant Cenere. Fais demi-tour ! · défaite : Tu es vraiment têtu. · après : Vas-y. Elle t'attend, je crois. |
| T-13 | Examen, pupitre de la régie | Un écran affiche : « DIFFUSION EN COURS — TOUT JOHTO ». |
| T-14 | Description de zone, Tour Radio | La Tour Radio de Doublonville, prise par la Team Rocket. |
| T-15 | Cenere, au micro (le joueur entre) | *… Giovanni, reviens. La Team Rocket t'attend.* / … / Tu es en avance. / D'après mes calculs, tu ne devais pas arriver avant demain. |
| T-16 | Cenere, avant | Je suis Cenere. / Brace fonce. Moi, je calcule. / Et dans mes calculs, tu perds. |
| T-17 | Cenere, défaite | … Une erreur de calcul. / Je n'aime pas les erreurs. |
| T-18 | Cenere, après | Tu crois que ce message était pour Giovanni ? / Écoute. Quelqu'un veut te parler. |
| T-19 | **Dante**, à l'antenne (haut-parleurs, voix seule) | *Cenere. Coupe ce message, il a fait son travail.* / *Membres de la Team Rocket, écoutez-moi.* / *Vous attendez Giovanni. Giovanni ne viendra pas.* / *Il vous a abandonnés, comme il a abandonné celui qui lui a tout appris.* / *Je m'appelle Dante. Je dirigeais la Team Rocket bien avant lui.* / *C'est moi qui vous ai réunis. C'est moi qui donne les ordres, depuis le début.* |
| T-20 | **Dante**, au joueur | *Et toi, le Maître de Kanto…* / *Tes Pokémon, à Oliville, c'est moi qui les ai fait prendre.* / *Un champion n'avait rien à faire sur mon chemin.* / *Tu es venu quand même. Bien.* / *Ce qui a brûlé une fois peut brûler encore.* / *Nous nous reverrons quand tout sera cendres.* |
| T-21 | **Dante**, l'ordre de retraite | *Cenere. Laisse tout. On part.* |
| T-22 | Sbires, après la voix (JH-43) | Sbire 1 : Dante ? C'est qui, ça ? / Sbire 2 : Moi, je suis entré pour Giovanni… Je m'en vais. / Sbire 3 : Un chef qui gagne, c'est un chef. Je le suis. |
| T-23 | Cenere, départ | Tu as entendu. / Tes Pokémon sont dans le bureau. Garde-les bien. / Ils ne te serviront à rien contre ce qui vient. · *(système)* Cenere s'en va par l'escalier de secours… |
| T-24 | Système, le bureau | La porte du bureau est ouverte. / Sur la table : des Poké Balls. Et un sac. / Ce sont les tiens ! |
| T-25 | Directeur, ligoté | Mmmh ! Mmmh ! · *(système)* {joueur} détache le directeur. |
| T-26 | Directeur, libéré | Merci ! Ils m'ont enfermé dans mon propre bureau. / Ces Poké Balls… ils les gardaient comme un trésor. Elles sont à toi ? |
| T-27 | Système, retrouvailles | {pokemon} sort de sa Poké Ball et bondit vers {joueur} ! / {joueur} retrouve son équipe et son sac ! |
| T-28 | Écran de sélection (JH-24) | Choisis les six Pokémon qui t'accompagnent. / Les autres iront au Stockage. |
| T-29 | Système, Stockage | Connexion au réseau de Kanto… / … / Connexion rétablie ! Les autres Pokémon sont au Stockage. |
| T-30 | Système, sac | Les objets de ton ancien sac ont rejoint les nouveaux. |
| T-31 | Directeur, la Multi Exp | Tu as sauvé la Tour, et toute la radio de Johto. / La Radio de Doublonville t'offre ceci. / Avec, tes nouveaux Pokémon apprendront vite auprès des anciens. · *(système)* {joueur} reçoit une Multi Exp ! · *(déjà possédée)* Tu en as déjà une ? Alors prends ces bonbons. · *(système)* {joueur} reçoit 3 Super Bonbons ! |
| T-32 | Directeur, après | L'ascenseur remarche. Les émissions reprendront dès ce soir. / Reviens nous voir quand tu veux. |
| T-33 | Agente, 1F | C'est toi qui as libéré la Tour ? Bravo. / Ces papiers… un ordre signé « D. ». / D comme Dante, sans doute. Je les garde comme preuves. · *(système)* {joueur} remet l'Ordre de mission et la Carte d'accès. |
| T-34 | Orme, 1F (accroche de l'acte 2) | {joueur} ! J'ai tout entendu à la radio. / Dante… Chen m'a parlé de lui, un jour. Il le croyait disparu depuis des années. / « Quand tout sera cendres »… Ça ne me plaît pas. / Les sages de Rosalia ont appelé ce matin. Ils veulent te voir. / Je crois que c'est à propos de la Tour Cendrée. |
| T-35 | Femme de D-37, après | Mon mari est rentré ! Raphaël m'a tout raconté. / Merci, merci ! Prends ça, ça vient du fond du cœur. · *(système)* {joueur} reçoit 3 Ultra Balls ! · après : Il dort depuis hier soir. Il dit qu'il ne remontera jamais dans le noir. |
| T-36 | Raphaël, chez lui | La Tour est de nouveau à nous. / Grâce à toi, la radio chante de nouveau. |
| T-37 | Haut-parleurs de la ville (après) | *Ici Radio Doublonville ! Les programmes reprennent.* / *Et un grand merci à un jeune Dresseur venu de Kanto !* |
| T-38 | Système, grotte marine (premier passage après) | Le courant s'est calmé. / On peut repartir vers Kanto. |

## 15. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-40 | ✅ Le faux employé est démasqué par la **Carte d'accès** (il reconnaît la carte de Brace), **combat obligatoire**, puis il s'enfuit (Kevin, 2026-11-02) | — |
| JH-41 | ✅ **Cenere seule** à la Tour ; Brace gardé pour Acajou (Kevin) | — |
| JH-42 | ✅ **Dante ordonne la retraite** (« Laisse tout ») : Cenere abandonne l'équipe et le sac dans le bureau (Kevin) | — |
| JH-43 | ✅ Les Sbires **se divisent** après la révélation : certains partent, d'autres suivent Dante (Kevin) | — |
