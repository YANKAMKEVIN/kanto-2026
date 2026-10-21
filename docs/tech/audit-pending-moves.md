# Audit des capacités incomplètes

78 espèces, 120 capacités, 5 capacités avec effets en attente.

Les niveaux ci-dessous sont des apprentissages déclarés dans les données ;
ils ne prouvent pas qu'une espèce est déjà rencontrable dans l'aventure.

| Capacité | Effets ignorés | Apprentissages déclarés |
|---|---|---|
| Métronome (`metronome`) | metronome | Mélodelfe N1, Mélofée N31 |
| Mimique (`mirror_move`) | mirror | Rapasdepic N25, Roucarnage N54, Roucoups N49, Roucool N44, Piafabec N22 |
| Danse Fleur (`petal_dance`) | rampage | Ortide N38, Mystherbe N33 |
| Frénésie (`rage`) | rage | Dardargnan N25, Dracaufeu N24, Salamèche N22, Reptincel N24, Osselait N46, Ossatueur N55, Onix N25 |
| Mania (`thrash`) | rampage | Osselait N38, Férosinge N39, Ossatueur N41, Nidoking N1, Nidoking N23, Colossinge N46 |

Généré par `python3 tools/audit_pending_moves.py`. Aucun effet n'est
activé ou remplacé par cet outil. Compléter les règles et leur présentation
avant de retirer un marqueur `pending_effects`.
