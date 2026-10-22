# Jalon 40 — Audit final et clôture du cycle

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j40-v1-chatgpt.md` (7 décisions verrouillées). Décisions et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif : **établir, preuves à l'appui, ce qui existe réellement.** Quatre questions : le jeu
> prévu par J0–J39 est-il implémenté ? Peut-on finir l'aventure du Bourg Palette à Mewtwo sans
> blocage ni perte ? L'application Android est-elle stable, reproductible et maintenable ? Que
> reste-t-il avant de déclarer le cycle terminé ? **Un jalon validé dans nos échanges n'est pas un
> jalon réalisé dans le dépôt.** Aucune nouvelle région, espèce, quête ni mécanique.
>
> **Note de coordination (2026-10-19, reprise)** : le J40 n'a de sens qu'une fois le code au niveau
> des dossiers. Aujourd'hui `main` contient J0 à J20 ; J21 à J25 sont sur leurs branches ; J26 à J40
> n'existent qu'en conception. Lancer le 40.0 maintenant ne donnerait que des « Absent » attendus.
> **Seul l'outillage de l'audit peut commencer.**

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Plans techniques | `docs/tech/jalon-01.md` … `jalon-20.md` (+ variantes), critères d'acceptation par jalon | Source des exigences à tracer (T1) |
| Tests | ≈ 6 050 tests, 544 scripts ; `tools/test.sh` | Preuves de niveau « automatique » |
| Preuves de QA | Rapports dans `build/qa/` (non suivis) et sections de `etat-projet.md` | À **copier en preuve** au moment de l'audit (T2) |
| Android | Un APK debug ; pas de version ni de signature (voir J34) | « Non vérifiable » tant que J34 n'est pas fait |
| Dépôt | Branches `jalon-*` non fusionnées ; un seul tag | L'inventaire doit nommer les branches et leurs commits |

### 0.1 Ce qui peut commencer tout de suite
- **T1** outil d'extraction des exigences (lecture des `docs/tech/jalon-*.md`) et schéma de la
  matrice ; **T6** gabarits du dossier de clôture ; **T2** définition du format de preuve.
- L'**exécution** de l'audit : **attend** que J26 à J39 existent dans `main`.

### 0.2 Règle de décision sur la date
Lancer le 40.0 seulement quand Kevin confirme que le code a rejoint les dossiers (ou accepte un
audit partiel, annoncé comme tel dans le rapport).

## 1. Contrats

### 1.1 États d'une exigence
| État | Définition |
|---|---|
| Implémenté | Code et ressources présents, comportement vérifié par une preuve adaptée |
| Partiel | Présent mais incomplet ou insuffisamment validé |
| Absent | Éléments nécessaires non trouvés après inspection suffisante |
| Non vérifiable | Preuves insuffisantes, accès manquant ou test inexécutable |

Un script présent ne prouve pas qu'une fonction marche ; l'absence de test ne prouve pas son
absence. **Sans appareil physique : « Non vérifiable sur appareil », jamais « Test réussi ».**

### 1.2 Priorité des écarts
P0 (perte de données, corruption, défaut critique : blocage immédiat) ; P1 (progression impossible
ou fonction essentielle inutilisable : blocage de clôture) ; P2 (significatif, sans blocage général) ;
P3 (mineur). « Non vérifiable » n'est pas P0 d'office, mais une exigence **critique** non vérifiée
peut empêcher un Go. Aucune correction n'est close sans preuve de retest.

### 1.3 Deux décisions indépendantes
**Go technique** (gameplay, stabilité, Android, sauvegardes, tests, maintenance) et **Go de
diffusion** (droits sur les ressources, licences, autorisations, périmètre). Statut de diffusion :
droits non déterminés / diffusion autorisée pour un périmètre documenté / diffusion non autorisée
ou suspendue.

## 2. Tâches

### T1 — Inventaire et matrice (40.0 et 40A, Sonnet)
`tools/audit_requirements.py` [D] : lit `docs/tech/jalon-*.md` et les passes, extrait les critères
d'acceptation en lignes `ID, exigence, jalon, source`. Colonnes à remplir à la main ou par script :
état, preuve (chemin ou commit, puis test, capture ou journal), priorité. Pour J0–J15 : reprendre
les **dossiers d'origine** (`docs/design/dossier-*.md`), pas des résumés.
Critère : la matrice couvre chaque jalon ; aucune ligne « implémenté » sans chemin de preuve.

### T2 — Format de preuve (Sonnet)
Dossier `evidence/` : un fichier par exigence critique, avec commit, commande, résultat, date.
Pas de secret ni de donnée personnelle (la sauvegarde réelle de Kevin n'y entre pas telle quelle).

### T3 — Audit fonctionnel et parcours de bout en bout (40B, Kevin et Opus)
Huit parcours : 1 nouvelle partie ; 2 villes et Arènes du début ; 3 Parmanie, Safari, Surf, Force ;
4 Îles Écume, Cramois'Île, Manoir ; 5 Sylphe SARL, Safrania, Giovanni ; 6 huit Badges, Route 22,
Route Victoire ; 7 Conseil des Quatre, Champion, Panthéon ; 8 Grotte Azurée, Mewtwo, sauvegarde
finale. Variantes : trois starters ; choix exclusifs ; défaites ; interruptions. **Vraies
sauvegardes** pour le parcours principal.
Régressions obligatoires : défaite à la Ligue ; interruption pendant une sauvegarde ; capture
légendaire puis rechargement ; échange local ; mise à jour Android ; retour au monde après le
Panthéon ; migration d'une ancienne sauvegarde.

### T4 — Android, performances, sauvegardes (40C)
Preuves : journal d'export, APK avec SHA-256, installation réelle, mise à jour avec conservation de
la sauvegarde, signature cohérente, commandes tactiles, FPS / chargement / mémoire mesurés,
résilience, résultats **par appareil réellement disponible**.

### T5 — Sécurité, archives, conformité (40D)
Secrets, dépendances, permissions, licences, ressources et droits (reprise de l'inventaire du J34),
archives de release (J37), documentation.

### T6 — Écarts, plan correctif, rapport, Go/No-Go (40E, 40F)
Registre : exigence, preuve, attendu, observé, gravité, correctif, coût, dépendances, test de
validation. Dossier de clôture (proposé sous `docs/tech/audit-j40/` [D]) : `00-executive-summary.md`,
`01-repository-inventory.md`, `02-requirements-matrix.csv`, `03-functional-regression.md`,
`04-android-qa.md`, `05-save-integrity.md`, `06-security-and-dependencies.md`,
`07-assets-and-rights.md`, `08-open-defects.md`, `09-corrective-roadmap.md`, `10-go-no-go.md`,
`evidence/`. **Un audit peut finir en No-Go avec un plan correctif.**

## 3. Textes
Validés par Kevin le 2026-10-21 : les quatre états, les priorités P0–P3, le plan du dossier de
clôture et la règle « Non vérifiable sur appareil ». Texte manquant : aucun (documents d'audit).

## 4. Critères d'acceptation (« J40 achevé »)
Toutes les exigences accessibles couvertes ; non-vérifiables recensés ; tests exécutés documentés ;
écarts classés ; deux décisions écrites. Clôture de l'audit ≠ clôture du développement.

## 5. QA téléphone
Le parcours 1 à 8 sur le S24 avec l'APK de la version auditée, appareil et version d'Android notés.

## 6. Risques
Auditer trop tôt (rapport rempli d'« Absent » sans valeur) ; fabriquer un rapport si J35 à J37 n'ont
pas eu lieu ; confondre « document validé » et « fonction livrée ».

## 7. Points ouverts pour Kevin
1. Date de lancement du 40.0 : après la fusion de J39 seulement, ou un audit partiel plus tôt ?
2. Emplacement du dossier de clôture : `docs/tech/audit-j40/` ? [D : oui]
3. Qui prend la décision finale Go de diffusion, et sur quel avis ? (voir J34)
4. Suites possibles après un No-Go : plan correctif en jalons J41+ ? [D : oui, un jalon par lot d'écarts]
