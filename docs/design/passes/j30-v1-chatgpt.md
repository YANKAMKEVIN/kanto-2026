# Kanto 2026 — J30 : La Ligue Pokémon

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J30** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Remplace l'avant-projet incomplet `j30-v0-avant-projet.md`. Les images et liens de la
> passe d'origine ne sont pas repris. Notes de la session de coordination à la fin.

Point culminant de l'aventure principale : quatre membres du Conseil des Quatre, un Champion rival
et l'entrée au Panthéon. Un vrai test de tout ce que le joueur a appris : composition de l'équipe,
gestion des PP, des PV, des objets et des changements de Pokémon.

## 1. Les sept décisions définitives

| Sujet | Arbitrage verrouillé |
|---|---|
| Périmètre | Conseil des Quatre complet, Champion et Panthéon |
| Progression | Cinq combats successifs, sans retour libre entre les salles |
| Équipes | Cinq Pokémon par membre, six pour le rival, fidèles à Rouge/Bleu |
| Défaite | Retour au Centre Pokémon du Plateau Indigo, reprise depuis Olga |
| Soins | Objets du Sac autorisés, aucun Centre Pokémon intermédiaire |
| Champion | Rival obligatoire, équipe adaptée au starter initial |
| Après générique | Sauvegarde au Panthéon, retour libre dans Kanto, post-game ultérieur |

Capacités exactes, IA et modalités techniques auditées avant implémentation.

## 2. Déroulement de la Ligue

Plateau Indigo (préparation, soins, équipe) → **Olga** (Glace / Eau) → **Aldo** (Combat / Roche) →
**Agatha** (Spectre / Poison) → **Peter** (Dragons et Pokémon puissants) → **Rival** (Champion) →
**Panthéon** (équipe enregistrée, générique, post-game).

L'entrée est volontaire. Une fois le défi commencé, le joueur avance de salle en salle sans retour
libre au Centre Pokémon.

## 3. Les quatre membres du Conseil

| Membre | Types | Équipe (référence Rouge/Bleu) |
|---|---|---|
| Olga | Glace / Eau | Lamantine N54 · Crustabri N53 · Flagadoss N54 · Lippoutou N56 · Lokhlass N56 |
| Aldo | Combat / Roche | Onix N53 · Tygnon N55 · Kicklee N55 · Onix N56 · Mackogneur N58 |
| Agatha | Spectre / Poison | Ectoplasma N56 · Nosferalto N56 · Spectrum N55 · Arbok N58 · Ectoplasma N60 |
| Peter | Dragon | Léviator N58 · Draco N56 · Draco N56 · Ptéra N60 · Dracolosse N62 |

- Olga : équipe résistante, attaques Glace et effets de statut.
- Aldo : combat physique exigeant, Roche et combattants puissants.
- Agatha : altérations de statut et capacités perturbatrices.
- Peter : dernier obstacle avant le Champion, Pokémon rapides et puissants.

Attaques historiques, IA et règles de statut à confirmer dans le dossier technique.

## 4. Le rival : Champion de la Ligue

Devenu Champion juste avant l'arrivée du joueur. Six Pokémon, selon le starter choisi au début.

| Starter du joueur | Équipe du rival |
|---|---|
| Bulbizarre | Roucarnage N61, Alakazam N59, Rhinoféros N61, Noadkoko N61, Léviator N63, Dracaufeu N65 |
| Salamèche | Roucarnage N61, Alakazam N59, Rhinoféros N61, Arcanin N61, Noadkoko N63, Tortank N65 |
| Carapuce | Roucarnage N61, Alakazam N59, Rhinoféros N61, Léviator N61, Arcanin N63, Florizarre N65 |

La variante dépend du **starter enregistré au lancement de la partie**, jamais de l'équipe actuelle
du joueur. Combat obligatoire, dernier affrontement de la campagne principale.

## 5. Règles d'endurance de la Ligue

| Mécanique | Règle J30 |
|---|---|
| Entrée | Volontaire, depuis le Plateau Indigo |
| Équipe | Six Pokémon maximum, selon le système existant |
| Soins entre combats | Objets du Sac uniquement |
| PP | Conservés entre les combats |
| Statuts | Conservés jusqu'à guérison |
| Centre Pokémon intermédiaire | Aucun |
| Retour vers les salles précédentes | Interdit pendant la tentative |
| Défaite | Retour au Plateau Indigo, reprise depuis Olga |
| Victoire finale | Panthéon et générique |

La défaite restaure le joueur selon les règles générales du moteur, sans perte de Pokémon, de
Badges ni d'objets importants.

**Sauvegarde pendant la Ligue** : séparer la progression temporaire de la tentative et la
progression permanente du jeu. Un redémarrage ne permet jamais de contourner un combat, de dupliquer
des objets ou d'accéder directement au Champion. Reprise sécurisée dans la salle courante ou au
dernier point valide, jamais dans un état incohérent, à définir à partir du système existant.

## 6. Le Panthéon et le générique

**Séquence** : 1. le rival reconnaît sa défaite ; 2. le Professeur Chen intervient ; 3. le joueur est
conduit au Panthéon ; 4. les six Pokémon de l'équipe sont enregistrés ; 5. le titre de Champion est
attribué ; 6. le générique se lance ; 7. la partie sauvegardée permet de reprendre l'exploration.

- Le Panthéon enregistre un **instantané immuable** de l'équipe victorieuse : espèces, surnoms,
  niveaux, identifiants individuels, date de la victoire.
- Chaque nouvelle victoire crée une nouvelle entrée, sans effacer les précédentes.
- **Après le générique** : reprise au Bourg Palette, dans un état post-Ligue fidèle à l'esprit de
  Rouge/Bleu. Badges, Pokémon, objets, captures légendaires et événements résolus sont conservés.
  Aucune nouvelle aventure imposée.

## 7. Dépendances J29 → J30

| Dépendance | Origine | Contrat |
|---|---|---|
| Plateau Indigo | J29 | Entrée, Centre Pokémon et services |
| Huit Badges | J28 et antérieurs | Vérification de la collection réelle |
| Équipe de six Pokémon | Moteur existant | Combat, permutation et stockage |
| Capacités et PP | Combat | Conservation entre les cinq combats |
| Objets de soin | Inventaire | Utilisation pendant la tentative |
| Statuts persistants | Combat | Poison, sommeil, paralysie, etc. |
| Rival évolutif | J26 et J29 | Même starter initial, nouvelle équipe |
| Défaite et retour au Centre | Moteur | Retour sûr au Plateau Indigo |
| Sauvegarde | Système existant | Reprise sans contournement |
| Panthéon | Nouveau J30 | Historique des équipes victorieuses |
| Générique | Nouveau J30 | Retour en exploration libre |
| Post-game | J31 | Déverrouillage après le titre de Champion |

**Points de vigilance** :

- **A.** Les cinq combats forment **une seule tentative** : battre Olga n'est pas une victoire
  permanente qui permettrait de la contourner à la tentative suivante.
- **B.** Le rival a plusieurs rencontres distinctes : J26, J29 et J30 ont des identifiants de combat
  séparés, mais partagent le starter initial.
- **C.** Le générique n'affecte ni la capture ni le stockage : le post-game est un changement d'état
  narratif, pas une réinitialisation.
- **D.** Le moteur gère les Pokémon répétés dans une équipe (deux Onix, deux Ectoplasma, deux Draco).
- **E.** Les tables de types, statuts et effets ne changent pas pour rendre la Ligue plus difficile.

## 8. États persistants

| Identifiant proposé | Fonction |
|---|---|
| `league_attempt_active` | Tentative de Ligue en cours |
| `league_current_stage` | Prochain adversaire dans la tentative |
| `league_champion_defeated` | Champion battu au moins une fois |
| `league_first_clear_completed` | Première victoire enregistrée |
| `hall_of_fame_entries` | Historique des équipes victorieuses |
| `postgame_unlocked` | Contenu post-Ligue disponible |
| `league_credits_seen` | Générique déjà visionné |

États temporaires de tentative séparés des événements permanents. Une défaite réinitialise l'étape
de la tentative, jamais les entrées du Panthéon.

## 9. Tests et QA Galaxy S24

| Test | Résultat attendu |
|---|---|
| Entrée dans la Ligue | Déclenchement volontaire |
| Victoire contre Olga | Accès à Aldo |
| Retour arrière | Impossible pendant la tentative |
| PP après combat | Valeurs conservées |
| Objet de soin | Consommation unique |
| Défaite contre Agatha | Retour au Plateau Indigo |
| Nouvelle tentative | Reprise depuis Olga |
| Rival, starter Bulbizarre / Salamèche / Carapuce | Équipe correspondante |
| Victoire finale | Panthéon puis générique |
| Redémarrage après générique | Partie conservée, post-game accessible |
| Deuxième victoire à la Ligue | Nouvelle entrée au Panthéon |
| Fermeture de l'application pendant la tentative | Reprise sûre, sans duplication |

**Mobile** : session potentiellement longue ; transitions, animations et écrans de victoire fluides ;
aucune perte de progression sur interruption Android (mise en arrière-plan, fermeture inattendue,
reprise).

## 10. Découpage technique

| Lot | Livraison |
|---|---|
| 30.0 | Audit du dépôt et des équipes historiques |
| 30A | Plateau Indigo, entrée et machine à états de la Ligue |
| 30B | Olga et Aldo |
| 30C | Agatha et Peter |
| 30D | Rival Champion, trois variantes |
| 30E | Panthéon, générique et déverrouillage post-game |
| 30F | Tests, sauvegardes, équilibrage et QA Galaxy S24 |

**« J30 terminé »** : le joueur commence volontairement la Ligue, bat les quatre membres et le rival
dans l'ordre, gère ses ressources entre les combats, enregistre son équipe au Panthéon, regarde le
générique et reprend librement son aventure.

## 11. Prompt de transmission à Claude (au lancement du J30)

> **Kanto 2026 — J30 : audit et conception technique.** Conseil des Quatre, Champion de la Ligue,
> Panthéon et générique.
>
> **Arbitrages verrouillés** (n'en rouvrir aucun) : 1. Conseil des Quatre complet, Champion et
> Panthéon. 2. Cinq combats successifs, sans retour libre entre les salles. 3. Équipes historiques
> Rouge/Bleu : cinq Pokémon par membre, six pour le rival. 4. Défaite : retour au Centre Pokémon du
> Plateau Indigo et reprise depuis Olga. 5. Objets du Sac autorisés, aucun Centre intermédiaire.
> 6. Rival Champion obligatoire, équipe évolutive selon le starter initial. 7. Panthéon, générique,
> sauvegarde et retour libre dans Kanto ; post-game ultérieur.
>
> **Audit** : inspecter code, ressources et dossiers J16–J29 en distinguant l'implémenté, le
> seulement spécifié et l'absent ; vérifier équipes, niveaux, capacités, ordre des Pokémon,
> dialogues, IA et règles de combat. Équipes de référence : Olga (Lamantine 54, Crustabri 53,
> Flagadoss 54, Lippoutou 56, Lokhlass 56) ; Aldo (Onix 53, Tygnon 55, Kicklee 55, Onix 56,
> Mackogneur 58) ; Agatha (Ectoplasma 56, Nosferalto 56, Spectrum 55, Arbok 58, Ectoplasma 60) ;
> Peter (Léviator 58, Draco 56, Draco 56, Ptéra 60, Dracolosse 62) ; rival Champion : trois
> variantes de six Pokémon selon le starter, à vérifier avant de les figer.
>
> **Travail technique** : machine à états des cinq combats et transitions entre les salles ; PV, PP,
> statuts et objets préservés entre les combats, sans soin gratuit ni retour libre ; comportement sûr
> en cas de défaite, sauvegarde, mise en arrière-plan et fermeture Android ; cérémonie du Panthéon,
> instantané immuable de l'équipe, générique, retour à Bourg Palette, déverrouillage du post-game ;
> préserver les rencontres du rival J26/J29, les huit Badges, les Pokémon capturés et les objets
> importants.
>
> **Livrables** : 1. Contrat d'entrée J29 → J30. 2. Plans des salles et transitions. 3. Machine à
> états complète. 4. Équipes et capacités vérifiées. 5. IA et équilibrage des cinq adversaires.
> 6. Objets, PV, PP et statuts. 7. Défaite, reprise et sauvegarde. 8. Panthéon et historique.
> 9. Générique et état post-game. 10. Assets peints et fonds de combat. 11. Lots 30.0 à 30F.
> 12. Tests automatisés et QA Galaxy S24. 13. Risques, incohérences et questions ouvertes.
> Distinguer règles Rouge/Bleu, adaptations Kanto 2026 et état réel du dépôt. DA 2D HD peinte, vue
> orthogonale, sans pixel art, isométrie, minimap ni flèches d'objectif.
>
> Conception et audit uniquement. Ne rien coder avant validation.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 30.0

- **Équipes** : les équipes du Conseil des Quatre et les trois variantes du rival Champion
  correspondent à celles de Rouge/Bleu dont la session se souvient ; à confirmer par l'audit comme
  le demande le dossier.
- **Rival** : `data/trainers/rival.json` calcule déjà les équipes par starter (`team_by_starter`).
  Identifiant à prévoir, distinct de `rival_route22` (J7B) et du combat final du J29
  (vigilance B).
- **Défaite** : `game/battle/battle_conclusion.gd` gère déjà le `blackout`. Reste à vérifier où il
  ramène le joueur (dernier Centre utilisé) et comment il interagit avec une tentative de Ligue.
- **Mise en arrière-plan Android** : aucune sauvegarde déclenchée par la mise en pause de
  l'application n'a été trouvée dans `game/` (les autosaves sont décidées par Boot à des moments
  précis). C'est un point de **sauvegarde**, donc un système risqué à valider seul (règle 1 de
  `CLAUDE.md`), et utile à tout le jeu, pas seulement à la Ligue : candidat pour la passe
  systèmes 2.
- **Panthéon et générique** : rien d'existant trouvé ; ce sont de vrais nouveaux systèmes du J30.
