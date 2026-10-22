# Jalon 35 — Bêta interne et validation terrain

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j35-v1-chatgpt.md` (7 arbitrages verrouillés). Arbitrages et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.
>
> **Réécrit le 2026-10-22 : décision de Kevin, le projet reste personnel, aucune diffusion.**
> La « bêta privée » avec testeurs extérieurs devient une **bêta interne** : Kevin seul, sur ses
> appareils. Plus de recrutement, d'invitations, de formulaire à destination de tiers ni de
> question de droits de diffusion.

> Objectif : **savoir si Kanto 2026 est installable, compréhensible et jouable de bout en bout
> par Kevin seul, sur ses propres appareils**, avec le contrôle des versions et des retours.
> Aucune nouvelle région, espèce ni campagne.
>
> **Condition d'entrée** : une RC acceptée sans P0/P1 (J34). Aucune condition de conformité de
> diffusion : l'APK ne quitte pas les appareils de Kevin.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Manque |
|---|---|---|
| Build identifié | Rien (voir J34) | Version, commit, SHA-256 par build |
| Écran d'options / menu | Menu Dresseur et options existent (`game/ui/`) | Entrée « Signaler un problème » |
| Informations appareil | Disponibles via `OS` de Godot (modèle, version Android, version du jeu) | Rien d'envoyé : copie locale seulement |
| Canal de retours | Aucun | Tickets GitHub (décision de Kevin) |
| Cadre de diffusion | Projet personnel, **sans diffusion** (décision de Kevin) | Rien à décider |
| Suivi des anomalies | `docs/tech/etat-projet.md` (« Reportés ») | Source unique : tickets GitHub (§7) |

### 0.1 Ce qui peut commencer tout de suite
- **T1** protocole de bêta interne (documents) ; **T3** conception de l'écran « Signaler un
  problème » ; **T5** modèle de tri ; **T2** fiche de build (champs).

### 0.2 Ce qui attend
- Campagne et corrections (T4, T6) : la RC du J34 et les retours réels de Kevin. **Aucun résultat
  de bêta ne sera inventé.**

## 1. Contrats

- **Testeur** : Kevin seul. Appareils : ceux dont il dispose réellement (le S24, plus tout autre
  appareil réellement possédé, ex. le S21 ; aucune configuration inventée).
- **Chaque retour est lié à une version précise.** Un retour d'une ancienne bêta n'est pas présenté
  comme un défaut de la build corrigée.
- **Confidentialité** : aucune télémétrie, rien n'est envoyé. L'écran de rapport ne fait qu'une
  copie locale (modèle, version Android, version du jeu, description).
- **Pas de diffusion** : l'APK n'est ni publié, ni envoyé, ni mis en ligne ; aucun lien à retirer.
- **Gel** : aucune suggestion de fonctionnalité intégrée au J35 ; elles deviennent des tickets
  GitHub étiquetés « idée ».

## 2. Tâches

### T1 — Protocole de bêta interne (35A, Sonnet)
`docs/tech/beta/protocole.md` [D] : appareils utilisés, parcours à jouer, durée, conditions
d'arrêt, procédure de signalement par ticket GitHub.

### T2 — Contrôle des versions (35B)
Fiche par build : version (`0.35.0-beta.1` en exemple), commit, APK signé, SHA-256, date réelle,
appareil, notes. Critère : on sait toujours quelle build est installée sur quel appareil.

### T3 — Écran « Signaler un problème » (35C, Sonnet — code après J34)
Champs : type de retour (bug, difficulté d'utilisation, performance, impression générale) ; zone ;
appareil ; version ; impact (impossible de continuer / important / gênant / mineur) ; étapes pour
reproduire ; plaisir de jeu sur 5 ; bouton **« Copier le rapport »** (copie locale, **rien n'est
envoyé**), pour le coller dans un ticket GitHub. L'écran préremplit modèle, version Android,
version du jeu et zone courante.
Tests : `ReportBuilder` pur (texte de sortie, champs obligatoires) ; écran : boutons ≥ taille
tactile du reste du jeu.

### T4 — Campagne de tests (35D, Kevin)
Installation, premier lancement, première session, exploration, combats, sauvegarde et reprise,
sur ses appareils. Consolidation des mesures du §6.

### T5 — Tri et cycle correctif (35E, Sonnet puis Opus)
Ticket → reproduction → classification → correction ciblée → régression → nouvelle build
identifiée → confirmation sur l'appareil concerné puis sur le S24. P0 : arrêt des tests concernés.
P1 : correction avant poursuite.

### T6 — Rapport bêta et décision (35F)
Versions testées, appareils, parcours, résultats, incidents, corrections, problèmes ouverts,
décision de poursuite vers le J36.

## 3. Textes
Validés par Kevin le 2026-10-21 : champs et options du formulaire ; « Copier le rapport » sans
transmission. Propositions **[D]** :
- Titre de l'écran : « Signaler un problème » ; aide : « Rien n'est envoyé. Copie le rapport pour
  l'ajouter à un ticket. »
- Plus de message d'invitation ni de consentement pour journaux : il n'y a pas de tiers.

## 4. Critères d'acceptation (« J35 terminé »)
Protocole exécuté sur une build identifiée ; résultats documentés ; défauts critiques traités ;
décision explicite ; aucun P0/P1 ouvert sur la build candidate finale.

## 5. QA téléphone (S24)
Écran « Signaler un problème » : copie du rapport collée dans une note ; contenu relu ; lisibilité
et zones de contact.

## 6. Mesures de réussite (sans cible inventée)
Installations réussies / tentatives ; parcours initial terminé ; crashes reproductibles ; reprises
réussies après fermeture ; difficultés par écran ; problèmes par appareil ; note de plaisir ; P0/P1
ouverts, corrigés, retestés.

## 7. Décisions de Kevin (2026-10-22)
1. **Le projet reste personnel, pas de diffusion** : bêta interne, Kevin seul, ses appareils.
2. Canal de retour : **tickets GitHub**.
3. Registre unique des anomalies : **tickets GitHub**.

## 8. Points encore ouverts
1. Durée de la bêta interne (nombre de builds) ? [D : 2 semaines, 3 builds au plus]
