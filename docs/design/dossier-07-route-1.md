# Dossier 07 — Route 1 : première exploration

> Conçu par Kevin (avec ChatGPT), reçu le 2026-09-26. **Source de vérité** pour la Route 1 (jalon 5). Les répliques sont **définitives**. Le tracé ASCII donne la logique, **pas à reproduire littéralement**.

## Intention
La Route 1 est le premier endroit où le joueur ressent : **« Mon aventure commence. »** Ni long couloir, ni immense zone ouverte : une route **relativement courte, mais plus large et beaucoup plus riche que celle de Rouge/Bleu**, avec assez de petits recoins pour apprendre tout de suite que quitter le chemin principal peut être récompensé. Tout droit, on atteint Jadielle vite ; en explorant, on y passe bien plus de temps.

**Consigne de production** : ne pas surcharger graphiquement la Route 1 tout de suite. Valider d'abord **géométrie, rythme, rencontres, raccourcis et exploration** avec des assets provisoires ; la vraie passe 2D HD atmosphérique transformera ensuite cette même géométrie.

## 1. Taille et ambiance
**Route A+ compacte.** Trajet direct : **2–3 minutes** ; première exploration attentive : **8–12 minutes**. Campagne paisible entre Bourg Palette et Jadielle, avec une vraie transition géographique :
- **sud** : encore très proche de Bourg Palette — végétation entretenue, clôtures, fleurs, arbres espacés ;
- **centre** : nature plus présente — hautes herbes, petit relief, arbres plus nombreux ;
- **nord** : davantage de traces humaines qui annoncent Jadielle.

DA (plus tard) : 2D HD atmosphérique — herbes animées subtilement, fleurs, feuilles, ombres, vent léger, oiseaux/Pokémon d'ambiance, variations naturelles du terrain.

## 2. Tracé
Pas de ligne droite verticale : **le chemin serpente légèrement.**

```text
                  JADIELLE
                     ↑
              ┌────────────┐
              │ prairie N  │
              │   🌿🌿     │
        ┌─────┘            │
        │                   │
        │   petit relief    │
        │      ╲            │
        │       ╲ chemin    │
        │        ╲          │
        │ 🌿🌿🌿 ╲         │
        │         ╲         │
        │    arbres ╲       │
        │            ╲      │
        └───────┐     │
                │     │
          🌿🌿  │     │
                │     │
             BOURG PALETTE
```

**Trois ensembles de hautes herbes :**
- **Zone 1 — initiation** : petite, **contournable** ; le joueur peut y entrer volontairement pour ses premières rencontres.
- **Zone 2 — exploration** : plus grande, plusieurs passages ; **un petit recoin y cache quelque chose**.
- **Zone 3 — passage obligatoire** : vers la moitié / deuxième moitié de la route, **une courte bande impossible à contourner** (quelques cases, pas 30) : le joueur peut expérimenter les rencontres au début, mais doit en comprendre le principe avant Jadielle.

## 3. Les rebords
**Oui, absolument** : petits rebords franchissables **uniquement vers le sud**. À l'aller on suit la route ; au retour, *hop* → raccourci. Version 2026 : pas de téléportation d'une case à l'autre — **petite animation de saut, ombre, atterrissage, petit retour haptique**. Le level design doit faire comprendre visuellement **« je peux descendre par là, mais pas remonter »**.

## 4. Pokémon
**Rencontres sauvages** : **Roucool Nv. 2–5**, **Rattata Nv. 2–4**.
**Pokémon d'ambiance ≠ rencontre de combat** : parfois un Roucool posé sur une clôture ou au sol ; un Rattata qui traverse brièvement une zone avant de disparaître dans les herbes. Ils ne déclenchent pas nécessairement de combat. *Les Pokémon vivent ici. Ils n'attendent pas uniquement que le joueur marche sur leur case.*

## 5. Un seul PNJ significatif
Un jeune homme / employé venant de Jadielle, avec un sac. Pas cinq personnes plantées sur la route.
> **Voyageur** — « Tu viens de Bourg Palette ? »
> « Alors Jadielle est juste devant toi. »
> « Fais attention dans les hautes herbes. Elles sont plus agitées aujourd'hui. »

(Plus tard : il pourra travailler à la Boutique Pokémon de Jadielle, petit rappel quand on le revoit.)

**Routine du Voyageur** (Kevin, 2026-09-26) : il **marche** plutôt que de rester planté, avec une routine très simple — petite zone de déplacement prédéfinie près du chemin (quelques cases), marche lente, s'arrête parfois quelques secondes, **ne va jamais dans les hautes herbes**, **ne bloque jamais le passage principal**, **ne sort pas de sa zone**. Quand on lui parle, il s'arrête et se tourne vers le joueur ; après le dialogue, il attend un court instant puis reprend naturellement sa marche.

**Règle générale des PNJ, à partir de la Route 1** : quand cela a du sens, un PNJ a une petite activité ou une routine plutôt que de rester immobile en permanence. Pas de système complexe d'horaires ou de routines quotidiennes pour l'instant : quelques déplacements locaux suffisent.

## 6. Premier secret
**Un objet caché, sans gros scintillement**, dans un petit recoin hors du chemin principal (par ex. près d'un arbre isolé / petite souche). **Examiner** :
> *Quelque chose est coincé entre les racines.*

→ **Potion ×1**, avec un petit toast **« Potion ×1 — Ajoutée au Sac »** (bible UI §6). Enseigne : **explorer et observer peut être récompensé.**

## 7. Pas de Dresseur sur la Route 1
Aucun combat de Dresseur : le rival vient d'introduire le système. La Route 1 sert à apprendre tranquillement combat sauvage, XP, niveaux, capture et exploration. Les vrais Dresseurs arrivent ensuite.

## 8. Les premières Poké Balls (fin du jalon 4, labo)
**Chen en donne 5**, intégré naturellement : après le premier combat et les dernières paroles de Chen, avant que le joueur parte :
> **Prof. Chen** — « Une dernière chose. »
> (il remet quelque chose au joueur) **Poké Balls ×5**
> « Observer les Pokémon t'apprendra beaucoup. Mais parfois, le meilleur moyen de les comprendre est encore de voyager avec eux. »
> « Utilise-les avec discernement. »

Pas de tutoriel de capture. La première rencontre sauvage pourra faire apparaître subtilement **SAC** et la catégorie Poké Balls.

## 9. Première capture
Le joueur est libre : **pas de Roucool scripté obligatoire**. Il peut combattre, fuir, capturer, continuer. À la **première ouverture des Poké Balls**, une micro-indication UI, **une seule fois** :
> *Affaiblir un Pokémon facilite sa capture.*

## 10. XP et niveaux commencent ici
Le combat du rival était narratif ; **la Route 1 marque le début de la progression réelle** : combat gagné → XP ; capture → XP à décider selon le système ; niveau supérieur → petit feedback propre ; apprentissage des capacités → le système progressif commence réellement ici.

## 11. Défaite sauvage
Si toute l'équipe est K.O. : court fondu, puis réveil **dans la maison familiale** ; Maman a soigné les Pokémon. **La première fois** :
> **Maman** — « Tu m'as fait une de ces peurs... »
> « Tes Pokémon vont bien. Repose-toi un peu avant de repartir. »

Aux défaites suivantes (texte définitif, Kevin 2026-09-26) :
> **Maman** — « Tes Pokémon vont bien maintenant. »
> « Fais attention à toi, d'accord ? »

Elle reste chaleureuse et maternelle : **jamais** de remarque culpabilisante ou moqueuse sur le fait que le joueur soit encore tombé K.O. **Tant qu'aucun Centre Pokémon n'est découvert, Maman = point de récupération.**

## 12. Jadielle
**L'entrée vers Jadielle doit déjà fonctionner** : pas de mur artificiel au bout de la route. Si la ville n'est pas implémentée au premier build du jalon 5, une transition provisoire **« JADIELLE — À venir »**, uniquement dans le build de développement. Structure finale : la Route 1 débouche naturellement sur Jadielle.

## 13. Sauvegarde — avant le reste
**La sauvegarde doit être implémentée avant que le jalon 5 soit considéré comme terminé**, idéalement **avant l'implémentation finale de la capture**. À sauvegarder au minimum : position / zone du joueur ; starter choisi ; équipe ; Pokémon capturés ; niveau et XP ; PV / statuts ; capacités connues ; inventaire ; Poké Balls ; événements narratifs terminés ; état des dialogues importants ; objets récupérés ; progression générale.
**Autosave** après événement important, capture, changement de zone, soin, etc. Le joueur n'a pas à penser à sauvegarder. Sauvegarde manuelle éventuellement plus tard.

## 14. Ce que la Route 1 doit enseigner
Sans gros tutoriel, en arrivant à Jadielle : 🌿 hautes herbes → rencontres · ⚔️ combat sauvage · ❤️ PV · ✨ XP · ⬆️ niveaux · 🔴 capture · 🎒 objets · 🔎 exploration · ↘️ rebords = raccourcis. Et idéalement : *« Attends... qu'est-ce qu'il y avait dans le petit chemin que je n'ai pas pris ? »*

## Décisions verrouillées
| Élément | Décision |
|---|---|
| Taille | A+ compacte |
| Trajet direct | 2–3 min |
| Exploration | 8–12 min |
| Hautes herbes | 3 zones |
| Zone obligatoire | oui, courte |
| Rebords | oui |
| Roucool | Nv. 2–5 |
| Rattata | Nv. 2–4 |
| Pokémon d'ambiance | oui |
| PNJ | 1 (Voyageur), petite routine de marche locale |
| Objet caché | Potion |
| Dresseurs | aucun |
| Poké Balls | 5 données par Chen |
| Capture obligatoire | non |
| Défaite | maison + Maman |
| XP réelle | commence ici |
| Jadielle | connexion prévue |
| Autosave | **oui, avant validation du jalon 5** |
