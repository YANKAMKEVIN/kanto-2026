# Pokemake 0.38.0 — notes de version

Version **0.38.0** (code Android 3800), le 2026-11-27. Elle s'installe **par-dessus la 0.37.4**
(ou une 0.37.x ou 0.36) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **PC de Johto :** le réseau de Kanto reste coupé, mais les PC de Johto ont leur propre
  stockage, la **Boîte de Johto**. Tu peux y déposer et y reprendre des Pokémon, et une capture
  avec l'équipe pleine y part au lieu d'être refusée. Tes Pokémon rangés à Kanto reviennent avec
  ton équipe à la Tour Radio.
- **Pêcher ou surfer :** face à une eau où l'on peut faire les deux, deux boutons s'affichent
  l'un au-dessus de l'autre (PÊCHER et SURFER), sans appui long.
- **Ligue après le titre :** le Conseil des Quatre, le rival et Maman ont de nouvelles répliques
  quand tu es déjà Champion.
- **Interface :** équipe visible en pastilles en combat, crans de statistiques sur les cartes,
  PP en ambre quand ils baissent, nom du lieu à la première visite, carte « Nouveautés » au
  premier lancement, et d'autres retouches.
- **Céladopole :** l'hôtesse du grand magasin se tient derrière son comptoir.
- **Johto, trois blocages corrigés :**
  - Tour Cendrée : la poutre ouest effondrée laisse redescendre vers le sud après la scène des
    chiens (on pouvait rester coincé au nord) ;
  - Antre du Dragon : l'escalier ne mène au Sanctuaire qu'après les trois Gardiens ;
  - poste de la Route 28 : on ne peut plus s'y retrouver enfermé entre les deux contrôles.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.37.4, `3cd57000` |
| Contenu | PC de Johto (PR #4) ; bot de parcours de Johto et trois défauts de progression corrigés (PR #3 : Tour Cendrée, Antre du Dragon, poste de la Route 28) ; boutons PÊCHER / SURFER ; répliques post-titre de la Ligue ; lot UI/UX `ux15` ; hôtesse de Céladopole ; découpage de `boot.gd` en modules (PR #2, sans changement de comportement) |
| Contrôles | CI GitHub verte sur `main` |
| Essais | tests sur le Mac et dans le cloud ; partie complète de Johto jouée par le bot (123 actions) ; **rien n'a été joué sur téléphone** |
| Sauvegarde | **v11** (migration automatique depuis la v10 ; une build plus ancienne refuse ensuite le fichier : pas de retour à la 0.37.x sans perdre la partie) |

Paquet : `~/.pokemake/rc/0.38.0/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
