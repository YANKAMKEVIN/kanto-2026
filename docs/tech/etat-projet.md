# État du projet

Mis à jour : 2026-11-06.

> **Ce fichier reste court (quelques Ko).** On y **remplace** ce qui change, on n'empile pas une ligne par tâche : le détail d'une tâche va dans le plan du jalon (`docs/tech/jalon-*.md`) et dans le message de commit.
> Historique complet jusqu'au 2026-11-05 : [`etat-projet-archive.md`](etat-projet-archive.md) (6,5 Mo, à chercher avec `grep`, pas à lire) et [`etat-projet-historique.md`](etat-projet-historique.md).

## Où en est le projet

- **Kanto :** jalons fusionnés dans `main` jusqu'au J34 en cours. RC **0.34.1** (Kanto seul, sauvegarde v9) sur la branche `release/0.34`, qui ne passe pas par `main`.
- **Art de Kanto :** toutes les cartes ont leur décor peint, les 202 espèces ont un dos peint, Sulfura, Électhor et Mewtwo sont peints sur la carte (`reportes.md`, RP-010, RP-132, RP-141, RP-290). Pas dans la RC 0.34.1 ; pas encore vu sur téléphone. Reste le décor riche des intérieurs (RP-063).
- **Johto :** JOH0 à JOH9 et l'arc des Pierres (JOHP0 à JOHP3) sont dans `main`, ainsi que les personnages peints. L'arc est jouable de la Tour Radio à l'acte 2, retour de l'équipe compris.
- **Personne n'a encore joué Johto d'un bout à l'autre.**
- **CI :** 14 lots équilibrés par durée (`tools/ci_shard.py`, `tools/ci_test_times.json`) et cache de l'import Godot : environ 10 min au lieu de 24. Quand les lots se déséquilibrent, refaire le fichier de durées avec `tools/ci_shard.py --update <dossier des artefacts>`.

## Prochaines étapes

1. **J34 T4 (Kevin) :** première utilisation de la RC par un proche ; consignes dans `docs/tech/jalon-34-t4-consignes.md` sur `release/0.34`. Go technique donné le 2026-11-05.
2. **Johto, reste à peindre :** cartes de JOH6, JOH8, JOH9, des Ruines d'Alpha et de l'Antre. Ébènelle est peinte, intérieurs compris, pas encore vue sur téléphone (planche `docs/design/reference/ebenelle-peinture-v1.webp`).
3. **Johto, reste à vérifier sur téléphone :** combats complets contre Dante, le rival final et Cenere à l'autel ; sortie du labo après le générique ; Celebi ; scène du vol avec la joueuse.
4. **Johto, reporté au JOH9 :** musiques HeartGold / SoulSilver et textes [D] encore en `draft` (voir `docs/tech/jalon-joh9.md`).
5. **Suite de Kanto :** J35 à J40, plans dans `docs/tech/`.

## Questions ouvertes

- Canal de retours des testeurs (J34).
- Remise du dépôt en privé : public temporairement depuis le 2026-10-26 pour la CI GitHub, alors que la décision de diffusion prévoit un dépôt privé.

Remarques de rendu et points reportés : registre unique [`reportes.md`](reportes.md) (identifiants `RP-NNN`).

## Décisions de Kevin en vigueur

- **Validation déléguée (2026-11-04) :** les sessions Kanto et Johto avancent sans lui. Tests ciblés, CI verte (« Conclusion : success ») et auto-validation sur téléphone suffisent pour fusionner dans `main`, avec un compte rendu. Seules les vraies décisions de game design et les décisions juridiques lui remontent.
- **Diffusion (2026-10-24) :** jeu privé, pour Kevin et un cercle restreint de proches. Jamais de store, de lien ouvert ni de page publique.
- **RC :** Kanto seul pour les proches (2026-11-04). Toute nouvelle RC part de `release/0.34`, en version 0.34.2 ou plus.
- **Son (2026-10-24) :** musiques de Let's Go Pikachu / Évoli, cris PokeAPI. Arbitrages : `docs/design/passes/son-arbitrages-kevin.md`.
- **Art :** option B de `docs/design/phase-da-cadrage.md`, arbitrages DA-1 à DA-9. Une maquette validée par Kevin se reproduit à l'identique.
- **Entrée des combats de Dresseur (2026-11-02) :** deux niveaux, jamais sautée ; `docs/design/dossier-05-combat.md` §3.
- **Difficulté :** première tentative gagnée à 80 % au plus, grands combats autour de 35 à 60 %. Ne pas adoucir au-delà de 80 % sans Kevin.
- **Nom :** le jeu s'appelle Pokemake ; dépôt, dossier et package gardent « kanto2026 ».

Les décisions propres à un jalon restent dans son dossier et son plan.
