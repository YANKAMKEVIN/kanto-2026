# RC 0.35.0 — jeu complet (Kanto et Johto)

> Préparée le 2026-11-06 depuis `main` @ `748e82de`. **La RC finale n'est pas construite et `project.godot` reste en 0.34.1.**
> Décision de Kevin du 2026-11-06 : jeu complet depuis `main`, qui remplace « RC Kanto seul depuis `release/0.34` ».
> Ordre retenu : partie complète de Kevin et vérifications d'abord, RC finale ensuite. Diffusion inchangée : moins de dix
> proches de sa maison, par adb ou fichier signé, jamais de store.

## 1. Ce qui est prêt

| Point | État | Preuve |
|---|---|---|
| APK de test | Construits depuis `main` @ `748e82de`, CI verte (run 42264411372) | `~/.pokemake/test-main-748e82de/`, §4 |
| Mise à jour par-dessus la 0.34.1 | **Conforme** sur l'A17 | §2 |
| Accès à Johto depuis une partie de Kanto | **Conforme** jusqu'à la grotte marine | §2 |
| Signature, manifeste | Même clé que la 0.34.1, `VIBRATE` seule, `debuggable` absent | `jalon-34-34e.md` §15.3 |
| Poids | 778,7 Mo, envoi par fichier praticable sous conditions | §3 |
| Inventaire juridique de Johto | Écrit, factuel | `jalon-34-34e.md` §15 |

## 2. Mise à jour 0.34.1 vers `main`, sur l'A17 (2026-11-06)

**Parcours réel.** RC 0.34.1 installée telle quelle (SHA-256 `b96e5dab…`), nouvelle partie jouée au doigt : Red, rival Blue,
Bulbizarre, combat du labo gagné, sortie à Bourg Palette. Puis `pm install -r` de l'APK release signé de `main`, sans désinstaller.
L'installation réussit à code Android égal (3401) et `firstInstallTime` ne bouge pas.

| Vérification | Avant (0.34.1) | Après (`main`) |
|---|---|---|
| Écran titre | — | « Continuer — Red, Bourg Palette, 0 h 10 », `sauvegarde VALID` |
| Position | devant le labo | identique à l'image, `pallet_town (22, 23)` |
| Équipe | Bulbizarre N5, 20 / 20 | identique, lien 50 |
| Argent | 3 000 | 3 000 |
| Fiche Dresseur, grands moments | Premier Pokémon | identiques |
| Sac | — | 5 Poké Balls |
| Pokédex | — | 2 entrées (Bulbizarre capturé, Salamèche vu), dates et lieux gardés |
| Drapeaux | — | 11, cohérents avec le parcours |
| Fichier | v9 | **v10**, réécrit à la reprise, sans erreur dans le journal |

La RC n'étant pas débogable, le fichier a été relu après coup en installant par-dessus l'APK debug de `main` re-signé avec la
même clé. Les colonnes « avant » viennent de l'écran, pas du fichier.

**Fin de Kanto.** Une partie neuve ne va pas jusqu'à Johto. Sauvegarde **v9 fabriquée** depuis `tests/fixtures/save/v9_fin_kanto.json`
(Ligue finie, Stockage, Pension, compagnon ; CS03 et Surf ajoutés), posée dans l'APK debug re-signé de `main` :
`[qa] sauvegarde v9 → v10`, Pension relue, lien 50 sur l'équipe, le Stockage et la Pension. Puis au doigt : cadeaux de Chen,
**lettre d'Orme** (`johto_letter`), Surf à Bourg Palette, **bouche de grotte** (`pallet_cave_mouth`), entrée dans **`sea_cave_1`**.

**Limites.**
- Cette seconde partie n'est pas passée par le binaire 0.34.1 : son fichier v9 est fabriqué.
- Le trajet s'arrête dans la grotte marine. La suite jusqu'à Oliville a été vue par les QA Johto, pas depuis cette sauvegarde.
- Un seul téléphone, l'A17. Le S24 n'a pas été touché.
- Mise à jour faite par adb, à code égal. **L'installation depuis un fichier n'a toujours jamais été essayée.** La vraie RC aura le code 3500 : le test est à refaire sur elle (§6, étape 5).

L'A17 est revenu à son état d'avant le test : application debug, `files/` restauré, empreintes des sauvegardes identiques, Ne pas déranger actif.
Seul écart : l'APK debug est celui de `748e82de`, plus récent que celui de 17 h 07.

## 3. Poids

| APK | Octets | Mio |
|---|---|---|
| RC 0.34.1 (Kanto seul) | 646 055 267 | 616 |
| **Release de `main`** | **778 695 547** | **743** |

Soit + 132,6 Mo (+ 20 %), surtout l'art et 27 Mo de musiques de Johto (`jalon-34-34e.md` §15.2).

**Avis : l'envoi par fichier reste praticable, sans marge de confort.** Par adb : 37 s à 21 Mo/s, par morceaux de 100 Mo.
Par clé USB ou Quick Share entre téléphones proches : à l'aise. Par messagerie : possible seulement si l'application accepte ce poids,
à essayer avec un seul proche, en Wi-Fi. **Pas de lien de stockage ouvert** : la décision de diffusion l'interdit.
Prévoir environ 2 Go libres sur le téléphone pendant l'installation (fichier et copie installée, valeur estimée).

## 4. APK de test pour Kevin

Dans `~/.pokemake/test-main-748e82de/`, avec `SHA256SUMS`. **Hors dépôt, à ne pas diffuser : ce ne sont pas des RC.**

| Fichier | Quand s'en servir |
|---|---|
| `pokemake-main-748e82de-debug.apk` | **Sur le S24**, par-dessus l'application debug : la partie est gardée |
| `pokemake-main-748e82de-release.apk` | Sur un téléphone qui a la RC 0.34.1, ou aucune installation |

Les deux affichent **v0.34.1 (3401)** à l'écran titre, comme la RC Kanto : pour reconnaître la version, se fier à la présence de Johto, pas au numéro.
L'APK release ne s'installe **pas** sur une application debug : il faudrait la désinstaller, et la sauvegarde partirait avec.

```bash
adb -s <série> push ~/.pokemake/test-main-748e82de/pokemake-main-748e82de-debug.apk /data/local/tmp/pokemake-test.apk
```

```bash
adb -s <série> shell pm install -r /data/local/tmp/pokemake-test.apk
```

```bash
adb -s <série> shell rm /data/local/tmp/pokemake-test.apk
```

Si le serveur adb tombe pendant l'envoi, passer par morceaux (`release.md` §5).

## 5. Ce qui bloque

| N° | Blocage | Qui |
|---|---|---|
| B1 | ~~Go juridique pour Johto~~ : **étendu par Kevin le 2026-11-06** au cercle de la maison (`jalon-34-34e.md` §15.5, Q1) | Fait |
| B2 | **Dépôt GitHub encore public**, contraire à une condition du Go ; les musiques HeartGold / SoulSilver y sont depuis le 2026-11-06 (§15.5, Q2) | Kevin |
| B3 | **Partie complète et écoute des musiques** : personne n'a joué Johto d'un bout à l'autre | Kevin |
| B4 | **T4** : première utilisation par un proche jamais faite. Choisir s'il se fait sur la 0.35.0 plutôt que sur la 0.34.1 | Kevin |

Points ouverts, non bloquants sauf avis contraire de Kevin :
- relecture de deux objectifs ajoutés (JOH9) ;
- 8 thèmes absents de l'album, remplacés par un repli (`johto-musiques.md` §8), à juger à l'écoute ;
- générique : « jamais diffusé » et bloc `KANTO 2026` (D4 de la fiche 34E) ;
- RP-099 et RP-160 à reproduire (`jalon-34-rapport.md` §3).

## 6. Étapes restantes

1. Kevin : Q2 de la fiche 34E (dépôt), partie complète, écoute des musiques.
2. Corrections trouvées pendant sa partie, sur `main`, CI verte.
3. `tools/version.py set 0.35.0` (code 3500), commit, push, `tools/ci_wait.sh` jusqu'à « success ».
4. `tools/build_rc.sh`, avec les variables de la clé (`release.md` §2) ; paquet dans `~/.pokemake/rc/0.35.0/`.
5. Sur l'A17 : refaire le §2 avec la RC finale, **plus l'installation depuis un fichier** ; relire `debuggable`, permissions et exclusions.
6. Nouvelles consignes T4 : nouvelle empreinte, texte du §8.4 inchangé, limitations à jour.
7. Kevin : Go technique, puis T4, puis le reste du cercle.

`release/0.34` n'est plus la branche des RC mais reste telle quelle : elle garde la source de la 0.34.1.
