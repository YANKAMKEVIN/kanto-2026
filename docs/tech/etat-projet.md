# État du projet

Mis à jour : 2026-11-06.

> **Ce fichier reste court (quelques Ko).** On y **remplace** ce qui change, on n'empile pas une ligne par tâche : le détail d'une tâche va dans le plan du jalon (`docs/tech/jalon-*.md`) et dans le message de commit.
> Historique complet jusqu'au 2026-11-05 : [`etat-projet-archive.md`](etat-projet-archive.md) (6,5 Mo, à chercher avec `grep`, pas à lire) et [`etat-projet-historique.md`](etat-projet-historique.md).

## Où en est le projet

- **Kanto :** jalons fusionnés dans `main` jusqu'au J34 en cours. RC **0.34.1** (Kanto seul, sauvegarde v9) sur la branche `release/0.34`, qui ne passe pas par `main`.
- **Art de Kanto :** toutes les cartes ont leur décor peint, les 202 espèces ont un dos peint, Sulfura, Électhor et Mewtwo sont peints sur la carte (`reportes.md`, RP-010, RP-132, RP-141, RP-290). Pas dans la RC 0.34.1. Vu sur l'A17 le 2026-11-06 sans blocage, dos peints du joueur compris, à terre et sur l'eau, en tenue d'origine et en costume pour la joueuse et les 16 costumes (`jalon-34-rapport.md` §3, lignes 9 bis et 9 ter).
- **Johto :** JOH0 à JOH9 et l'arc des Pierres (JOHP0 à JOHP3) sont dans `main`, ainsi que les personnages peints. L'arc est jouable de la Tour Radio à l'acte 2, retour de l'équipe compris.
- **Musiques de Johto :** 32 pistes HeartGold / SoulSilver branchées (cartes, Centres et Boutiques, combats par région, légendaires, générique) ; détail dans `docs/tech/johto-musiques.md` §10. Jingles, victoires et « ! » restent ceux de Let's Go.
- **Personne n'a encore joué Johto d'un bout à l'autre.**
- **CI :** 14 lots équilibrés par durée (`tools/ci_shard.py`, `tools/ci_test_times.json`) et cache de l'import Godot : environ 10 min au lieu de 24. Quand les lots se déséquilibrent, refaire le fichier de durées avec `tools/ci_shard.py --update <dossier des artefacts>`.

## Prochaines étapes

1. **J34 T4 (Kevin) :** première utilisation de la RC par un proche ; consignes dans `docs/tech/jalon-34-t4-consignes.md` sur `release/0.34`. Go technique donné le 2026-11-05.
2. **Peinture :** plus aucune carte en tuiles (Kanto et Johto) ; RP-292.
3. **Johto, vérifié sur l'A17 le 2026-11-06 (`docs/tech/qa-johto-a17-2.md`) :** onze jonctions passées par morceaux, Raikou, Entei, Ho-Oh, rival du sommet, remontée et descente du Mont Argenté. Un blocage trouvé et corrigé : sortie de la chambre du Centre d'Oliville. Reste : une partie complète et l'écoute des musiques par Kevin, relecture de deux objectifs [D] (JOH9).
4. **Suite de Kanto :** J35 à J40, plans dans `docs/tech/`.

## Questions ouvertes

- Remise du dépôt en privé : public temporairement depuis le 2026-10-26 pour la CI GitHub, alors que la décision de diffusion prévoit un dépôt privé.

Remarques de rendu et points reportés : registre unique [`reportes.md`](reportes.md) (identifiants `RP-NNN`).

## Décisions de Kevin en vigueur

- **Ordre de l'acte 2 (2026-11-06) :** JOH6 avant JOH7. La mer au sud d'Oliville reste fermée jusqu'au déserteur d'Acajou (`johto_whirl_clue`).
- **Hurlement des légendaires sauvages (2026-11-06) :** Raikou et Entei gardent l'attaque, mais ne la maintiennent qu'une fois sur quatre (`Battle._restrain_force_out`). Après une fuite, on peut toujours les retrouver.
- **Validation déléguée (2026-11-04) :** les sessions Kanto et Johto avancent sans lui. Tests ciblés, CI verte (« Conclusion : success ») et auto-validation sur téléphone suffisent pour fusionner dans `main`, avec un compte rendu. Seules les vraies décisions de game design et les décisions juridiques lui remontent.
- **Diffusion (2026-10-24) :** jeu privé, pour Kevin et un cercle restreint de proches. Jamais de store, de lien ouvert ni de page publique.
- **Retours des testeurs (2026-11-06) :** groupe WhatsApp.
- **RC :** Kanto seul pour les proches (2026-11-04). Toute nouvelle RC part de `release/0.34`, en version 0.34.2 ou plus.
- **Son (2026-10-24) :** musiques de Let's Go Pikachu / Évoli à Kanto, HeartGold / SoulSilver à Johto ; cris PokeAPI. Arbitrages : `docs/design/passes/son-arbitrages-kevin.md`.
- **Art :** option B de `docs/design/phase-da-cadrage.md`, arbitrages DA-1 à DA-9. Une maquette validée par Kevin se reproduit à l'identique.
- **Entrée des combats de Dresseur (2026-11-02) :** deux niveaux, jamais sautée ; `docs/design/dossier-05-combat.md` §3.
- **Difficulté :** première tentative gagnée à 80 % au plus, grands combats autour de 35 à 60 %. Ne pas adoucir au-delà de 80 % sans Kevin.
- **Nom :** le jeu s'appelle Pokemake ; dépôt, dossier et package gardent « kanto2026 ».

Les décisions propres à un jalon restent dans son dossier et son plan.
