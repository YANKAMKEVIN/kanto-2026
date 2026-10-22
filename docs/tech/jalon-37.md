# Jalon 37 — Version 1.0 personnelle, maintenance et support

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j37-v1-chatgpt.md` (7 décisions verrouillées). Décisions et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> **Réécrit le 2026-10-22 : décision de Kevin, le projet reste personnel, pas de diffusion.** La
> 1.0 est une **version personnelle** : identifiée, archivée et maintenue pour Kevin seul, sur ses
> appareils. **Aucune publication** (ni publique, ni à un cercle). Plus de « Go de distribution » ni
> de rapport de conformité de diffusion ; le support est celui d'un utilisateur unique.

> Objectif : **une version 1.0 personnelle identifiable, reproductible et maintenable**, sans
> nouveau contenu, avec ses correctifs 1.0.x, son suivi et son archive. Une seule décision écrite :
> le **Go technique**.
>
> Pas de tag final « pour respecter le numéro du jalon » : la 1.0 dépend d'un Go réel au J36.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Tags et branches | Un tag (`j9-t3-base`), aucune branche `release/*` | Les conventions du §1 ne remplacent rien |
| Version | Aucune dans `project.godot` ni dans `export_presets.cfg` | Posée au J34 (T1), reprise ici |
| Schéma de sauvegarde | `SaveSystem.VERSION = 7`, distinct de la version de l'appli | Conforme au contrat du §5 de la passe |
| CI | `godot-tests.yml` (GUT en 8 lots, Godot 4.7.2 vérifié par SHA-256, `contents: read`) | Base du pipeline de tag (J38) |
| Suivi des anomalies | `etat-projet.md` ; dépôt GitHub privé `YANKAMKEVIN/kanto-2026` | Tickets GitHub retenus : backlog unique (T5) |
| Dossier de release | N'existe pas | Voir §2.1 |

### 0.1 Ce qui peut commencer tout de suite
- **T1** conventions de versions, de tags et de branches (document, 0 code) ; **T5** gabarits de FAQ
  et de ticket ; **T3** politique de correctifs 1.0.x (document).

### 0.2 Ce qui attend
- Tag, build, archive, validation : **un Go technique réel au J36**. Tests de mise à jour :
  deux builds signées successives.

## 1. Contrats

| Élément | Convention proposée (à confronter au dépôt) |
|---|---|
| Version applicative | `1.0.0` |
| Tag Git | `v1.0.0` |
| Branche de maintenance | `release/1.0` |
| Correctifs | `1.0.1`, `1.0.2`… |
| Code Android | Entier croissant, jamais réutilisé |
| Identifiant Android | Inchangé : `dev.kevin.kanto2026` |
| Signature | Même identité pour toutes les mises à jour |
| Manifeste | Commit, Godot, SDK, export, signature, SHA-256 |

- **Reproductibilité** : un second environnement reproduit un APK **fonctionnellement équivalent** ;
  l'identité octet pour octet est à vérifier, jamais présumée.
- **Secrets** : clés, mots de passe et jetons de CI **jamais archivés** avec les artefacts.
- **1.0.x autorisé** : crash, perte de sauvegarde (priorité absolue), collision bloquante, problème
  tactile, optimisation sans changement fonctionnel. **Interdit** : région, espèce, refonte du
  combat, rupture volontaire du format de sauvegarde.
- **Version de schéma** distincte de la version de l'appli ; 1.0.0 → 1.0.1 n'implique pas de
  migration ; tout changement de schéma est explicite, testé et sécurisé.

## 2. Tâches

### T1 — Versionnement et tags (37A, Sonnet)
Pose du tag `v1.0.0` sur le commit du J36 accepté ; création de `release/1.0` ; `tools/release_manifest.py`
[D] qui écrit le manifeste. Critère : le manifeste se relit et reconduit au commit.

### 2.1 Où ranger l'archive (décision de structure)
La passe décrit `releases/1.0.0/` (APK, `manifest.json`, `SHA256SUMS`, `release-notes.md`,
`known-issues.md`, `qa-report.md`, `compatibility.md`, `migration-report.md`, `go-no-go.md`).
**Proposition [D]** : les documents texte dans `docs/releases/1.0.0/` (suivis par Git) ; l'APK et
`SHA256SUMS` hors dépôt, sur le Mac de Kevin avec sauvegarde (décision du J34), car un binaire
n'a pas sa place dans l'historique. Aucune publication, y compris en release GitHub.

### T2 — Pipeline reproductible (37B, Opus)
`tools/build_release.sh` [D] fondé sur `tools/build_rc.sh` du J34 : mêmes garde-fous, tag exigé,
journal complet. Seconde construction sur un autre environnement (Mac propre ou CI) pour comparer.

### T3 — Politique de correctifs 1.0.x (37C, Sonnet)
Cycle : ticket reproductible → correction minimale → tests unitaires et ciblés → régression des
dépendances → build signée → installation et migration → installation sur les appareils de Kevin (aucune publication). Une
correction de sauvegarde déclenche une régression plus large.

### T4 — Compatibilité des sauvegardes et récupération (37D, Opus — sauvegarde : validé seul)
Mise à jour réelle d'APK 1.0.0 → 1.0.1 avec sauvegarde (pas seulement des tests unitaires) ; guide
de récupération (reconnaître une sauvegarde illisible, ce qu'il ne faut pas faire, quelle copie
chercher, quoi transmettre au support). Aucune promesse de récupération après désinstallation.

### T5 — Support, FAQ, suivi (37E, Sonnet)
Suivi par tickets GitHub, ticket minimal (version et appareil, description, étapes, attendu/observé, fréquence, gravité) ;
états Nouveau, À reproduire, Confirmé, En correction, À retester, Résolu, Reporté. FAQ personnelle (aide-mémoire
de Kevin) : installer, mettre à jour, perdre sa sauvegarde ?, APK qui ne s'installe pas, après un
crash, déclarer un bug, revenir à une ancienne version. **La FAQ n'affirme jamais qu'une restauration existe si elle n'est
pas implémentée.**

### T6 — Dossier 1.0 et décisions finales (37F)
Checklist ci-dessous ; **une** décision écrite (Go technique), avec preuves et limites. Le dossier référence
**une seule** version.

## 3. Textes
Validés par Kevin le 2026-10-21 : la liste des questions de la FAQ ; le contenu du ticket minimal ;
les états de ticket ; la checklist de livraison. Propositions **[D]** : réponses de la FAQ (rédigées
au T5 une fois les procédures réelles connues, pas avant).

## 4. Critères d'acceptation (« J37 terminé »)
- [ ] Go technique J36 confirmé
- [ ] Version 1.0 identifiée par un commit et un tag
- [ ] APK signé et installation vérifiée
- [ ] Manifeste et SHA-256 disponibles
- [ ] Mises à jour et sauvegardes validées
- [ ] Tests critiques exécutés sur le build final
- [ ] Procédure de correctifs 1.0.x documentée
- [ ] FAQ personnelle et suivi par tickets GitHub opérationnels
- [ ] Mention « usage personnel, aucune diffusion » inscrite dans le dossier
- [ ] Décision Go technique enregistrée

## 5. QA téléphone
Installation de la 1.0.0 ; mise à jour par-dessus avec une sauvegarde de partie avancée ;
vérification du numéro de version affiché dans le jeu [D : dans le menu options].

## 6. Décisions de Kevin (2026-10-22)
1. **Le projet reste personnel, pas de diffusion** : 1.0 = version personnelle, sans publication.
2. Backlog et suivi : **tickets GitHub** (dépôt privé).
3. Clé de signature et archive des versions : sur le Mac de Kevin, avec sauvegarde (voir J34).
4. Emplacement de l'archive : proposition du §2.1 (documents suivis par Git, binaire sur le Mac).
