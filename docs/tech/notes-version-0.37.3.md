# Pokemake 0.37.3 — notes de version

Version **0.37.3** (code Android 3703), le 2026-11-19. Elle s'installe **par-dessus la 0.37.2**
(ou une 0.37.x ou 0.36) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **Attaques Glace refaites :** Onde Boréale, Laser Glace, Blizzard, Poing-Glace, Buée Noire et
  Brume ont de nouveaux effets peints. Blizzard couvre tout l'écran de neige.
- **Vol animé :** ton Pokémon sort de sa Ball, vous vous envolez, puis vous atterrissez à
  l'arrivée.
- **Carte :** toucher le nom d'une zone la choisit, et une ville se choisit plus facilement
  quand elle est sur une route.
- **Stockage :** les Pokémon au PC sont soignés, ceux qui y étaient déjà compris.
- **Légendaires :**
  - ils sont plus faciles à capturer ;
  - Artikodin, Électhor, Sulfura, Mewtwo et Mew mis K.O. sans être capturés reviennent dès
    que tu quittes la carte.
- **Chen et Maman** ont une réplique nouvelle après chaque badge de Kanto.
- **Route 23 :** les deux gardes postés sur l'eau sont debout sur un ponton en bois.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.37.2, `cc97441a` |
| Contenu | refonte des attaques Glace (`attaques-glace.md`) ; Vol animé et Carte (remarques de Kevin sur S24) ; stockage qui soigne, taux de capture 20 des légendaires, retour des légendaires de Kanto mis K.O. (décisions du 2026-11-19) ; répliques de Chen et Maman par badge ; pontons de la Route 23 |
| Contrôles | CI GitHub verte sur `main` ; attaques Glace validées en vidéo par Kevin |
| Essais | tests et captures sur le Mac ; **rien n'a été joué sur téléphone** |
| Sauvegarde | aucun changement de format (v10) ; les Pokémon du stockage d'une sauvegarde plus ancienne sont soignés au chargement (PV, PP, statut ; œufs inchangés) |

Paquet : `~/.pokemake/rc/0.37.3/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
