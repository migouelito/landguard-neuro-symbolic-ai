% LANDGUARD - REGLES DE DETECTION DE FRAUDES
% Partie 2: Raisonnement Symbolique
% Fichier: rules.pl

:- [knowledge_base].

% ================================================================
% CATEGORIE A - ACCAPAREMENT (4 regles)
% ================================================================

% A1: Multipropriete excessive (plus de 5 parcelles)
regle_a1_multipropriete(X) :-
    citoyen(X),
    findall(P, possede(X, P), Liste),
    length(Liste, N),
    N > 5.

% A2: Accaparement familial (famille possede plus de 8 parcelles)
regle_a2_accaparement_familial(X) :-
    citoyen(X),
    findall(P, (lien_familial(X, Y), possede(Y, P)), ParcellesFamille),
    findall(P, possede(X, P), ParcellesX),
    append(ParcellesX, ParcellesFamille, Toutes),
    sort(Toutes, Uniques),
    length(Uniques, N),
    N >= 8.

% A3: Concentration urbaine (toutes parcelles dans meme zone)
regle_a3_concentration_urbaine(X) :-
    citoyen(X),
    findall(P, (possede(X, P), parcelle_urbaine(P)), Urbaines),
    length(Urbaines, N),
    N >= 3.

% A4: Monopole foncier (possede plus de 30% des parcelles d'une zone)
regle_a4_monopole_foncier(X, Zone) :-
    citoyen(X),
    findall(P, (parcelle_zone(P, Zone)), TotalZone),
    length(TotalZone, Total),
    findall(P, (possede(X, P), parcelle_zone(P, Zone)), MesParcelles),
    length(MesParcelles, N),
    Total > 0,
    N / Total > 0.3.

% Parcelle par zone (fait auxiliaire)
parcelle_zone(p1, 'Dakar-Nord').
parcelle_zone(p2, 'Dakar-Nord').
parcelle_zone(p3, 'Dakar-Nord').
parcelle_zone(p4, 'Dakar-Sud').
parcelle_zone(p_pissy_01, 'Ouagadougou-Pissy').
parcelle_zone(p_pissy_02, 'Ouagadougou-Pissy').
parcelle_zone(p_pissy_03, 'Ouagadougou-Pissy').
parcelle_zone(p_pissy_04, 'Ouagadougou-Pissy').
parcelle_zone(p_pissy_05, 'Ouagadougou-Pissy').
parcelle_zone(p_ouaga2000_01, 'Ouagadougou-2000').
parcelle_zone(p_ouaga2000_02, 'Ouagadougou-2000').
parcelle_zone(p_ouaga2000_03, 'Ouagadougou-2000').
parcelle_zone(p_ouaga2000_04, 'Ouagadougou-2000').
parcelle_zone(p_somgande_01, 'Ouagadougou-Somgande').
parcelle_zone(p_somgande_02, 'Ouagadougou-Somgande').
parcelle_zone(p_somgande_03, 'Ouagadougou-Somgande').
parcelle_zone(p_somgande_04, 'Ouagadougou-Somgande').
parcelle_zone(p_somgande_05, 'Ouagadougou-Somgande').

% ================================================================
% CATEGORIE B - SPECULATION (4 regles)
% ================================================================

% B1: Revente ultra-rapide (moins de 90 jours)
regle_b1_revente_ultra_rapide(X) :-
    ( citoyen(X) ; agent_public(X) ; promoteur(X) ; notaire(X) ),
    vendA(X, _, Parcelle, DateVente, _),
    achete(X, Parcelle, DateAchat, _),
    Duree is DateVente - DateAchat,
    Duree < 90,
    Duree > 0.

% B2: Plus-value anormale (superieure a 100%)
regle_b2_plus_value_anormale(X) :-
    ( citoyen(X) ; agent_public(X) ; promoteur(X) ; notaire(X) ),
    vendA(X, _, Parcelle, DateVente, PrixVente),
    achete(X, Parcelle, DateAchat, PrixAchat),
    DateVente > DateAchat,
    PlusValue is (PrixVente - PrixAchat) / PrixAchat,
    PlusValue > 1.0.

% B3: Non-mise en valeur (achat sans construction depuis 3 ans)
regle_b3_non_mise_en_valeur(X) :-
    ( citoyen(X) ; agent_public(X) ; promoteur(X) ; notaire(X) ),
    achete(X, Parcelle, DateAchat, _),
    \+ a_construit(X, Parcelle),
    annee_courante(Annee),
    Annee - DateAchat > 3.

a_construit(_, _) :- fail.
annee_courante(2026).

% B4: Transaction suspecte (montant > 1 million sans valeur marchande)
regle_b4_transaction_suspecte(X) :-
    ( citoyen(X) ; agent_public(X) ; promoteur(X) ; notaire(X) ),
    vendA(X, _, Parcelle, _, Montant),
    Montant > 1000000,
    valeur_marche(Parcelle, Valeur),
    Montant > Valeur * 2.

valeur_marche(p1, 300000).
valeur_marche(p2, 250000).
valeur_marche(p3, 200000).
valeur_marche(p4, 400000).
valeur_marche(p_pissy_01, 350000).
valeur_marche(p_kossodo_01, 180000).
valeur_marche(p_somgande_01, 250000).

% ================================================================
% CATEGORIE C - CONFLITS D'INTERETS (4 regles)
% ================================================================

% C1: Auto-attribution (agent traite son propre dossier)
regle_c1_auto_attribution(Agent) :-
    agent_public(Agent),
    traite(Agent, Dossier),
    beneficiaire(Agent, Dossier).

% C2: Traitement de dossier familial
regle_c2_traitement_familial(Agent) :-
    agent_public(Agent),
    traite(Agent, Dossier),
    beneficiaire(Benef, Dossier),
    lien_familial(Agent, Benef).

% C3: Favoritisme repetitif (plus de 3 dossiers pour meme beneficiaire)
regle_c3_favoritisme_repetitif(Agent, Beneficiaire) :-
    agent_public(Agent),
    findall(D, (traite(Agent, D), beneficiaire(Beneficiaire, D)), Dossiers),
    length(Dossiers, N),
    N > 3.

% C4: Conflit d'interet indirect (via lien professionnel)
regle_c4_conflit_indirect(Agent) :-
    agent_public(Agent),
    traite(Agent, Dossier),
    beneficiaire(Benef, Dossier),
    lien_professionnel(Agent, Benef).

% ================================================================
% CATEGORIE D - RESEAUX & PRETE-NOMS (4 regles)
% ================================================================

% D1: Prete-nom par telephone partage
regle_d1_prete_nom_telephone(X, Y) :-
    partage_telephone(X, Y),
    X \= Y,
    X @< Y,
    possede(X, Parcelle),
    possede(Y, Parcelle).

% D2: Prete-nom par adresse partagee
regle_d2_prete_nom_adresse(X, Y) :-
    partage_adresse(X, Y),
    X \= Y,
    X @< Y,
    possede(X, Parcelle),
    possede(Y, Parcelle).

% D3: Structure transactionnelle circulaire
regle_d3_transaction_circulaire(X, Y, Z) :-
    vendA(X, Y, Parcelle, Date1, _),
    vendA(Y, Z, Parcelle, Date2, _),
    vendA(Z, X, Parcelle, Date3, _),
    Date1 < Date2,
    Date2 < Date3.

% D4: Partage d'IBAN suspect
regle_d4_partage_iban_suspect(X, Y) :-
    partage_iban(X, Y),
    X \= Y,
    X @< Y,
    possede(X, Parcelle),
    possede(Y, Parcelle).


% ================================================================
% REGLE GLOBALE DE FRAUDE
% ================================================================
fraude_detectee(X) :-
    (   regle_a1_multipropriete(X)
    ;   regle_a2_accaparement_familial(X)
    ;   regle_a3_concentration_urbaine(X)
    ;   regle_a4_monopole_foncier(X, _)
    ;   regle_b1_revente_ultra_rapide(X)
    ;   regle_b2_plus_value_anormale(X)
    ;   regle_b3_non_mise_en_valeur(X)
    ;   regle_b4_transaction_suspecte(X)
    ;   regle_c1_auto_attribution(X)
    ;   regle_c2_traitement_familial(X)
    ;   regle_c3_favoritisme_repetitif(X, _)
    ;   regle_c4_conflit_indirect(X)
    ;   regle_d1_prete_nom_telephone(X, _)
    ;   regle_d2_prete_nom_adresse(X, _)
    ;   regle_d3_transaction_circulaire(X, _, _)
    ;   regle_d4_partage_iban_suspect(X, _)
    ).

% ================================================================
% REGLES SUPPLEMENTAIRES POUR LES TESTS UNITAIRES
% ================================================================

% Score de suspicion (0-100)
score_suspicion(X, Score) :-
    findall(1, (
        accapareur_urbain(X);
        prete_nom(X);
        conflit_interet_direct(X);
        ci_max_parcelles(X)
    ), Alertes),
    length(Alertes, N),
    Score is min(100, N * 25).

% Niveau de criticite base sur le score.
niveau_criticite(Score, faible) :- Score < 30.
niveau_criticite(Score, moyen) :- Score >= 30, Score < 60.
niveau_criticite(Score, eleve) :- Score >= 60, Score < 80.
niveau_criticite(Score, critique) :- Score >= 80.

% Fraude composite simple (pour test)
fraude_composite_simple(X, Prob) :-
    (   partage_telephone(X, Y), X \= Y -> P1 = 0.8 ; P1 = 0.0 ),
    (   agent_public(X), traite(X, D), beneficiaire(X, D) -> P2 = 0.6 ; P2 = 0.0 ),
    (   accapareur_urbain(X) -> P3 = 0.5 ; P3 = 0.0 ),
    Sum is P1 + P2 + P3,
    (   (P1 > 0 ; P2 > 0 ; P3 > 0)
    ->  Prob is min(1.0, Sum / 1.5)
    ;   Prob = 0.0 ).

% ================================================================
% REGLES SUR LE DATASET BURKINA
% ================================================================

cas_dataset_risque_eleve(Nom) :-
    cas_analyse(Nom, _, Score),
    Score >= 0.70.

cas_dataset_risque_critique(Nom) :-
    cas_analyse(Nom, NbParcelles, Score),
    (   Score >= 0.90
    ;   NbParcelles >= 8
    ).

% Alias utilise par le pipeline et les scripts de demonstration.
cas_dataset_critique(Nom) :-
    cas_dataset_risque_critique(Nom).

cas_dataset_speculation(Nom) :-
    cas_analyse(Nom, NbParcelles, Score),
    NbParcelles =< 5,
    Score >= 0.55,
    Score < 0.90.

cas_dataset_accaparement(Nom) :-
    cas_analyse(Nom, NbParcelles, Score),
    NbParcelles >= 8,
    Score >= 0.60.

cas_dataset_limite(Nom) :-
    cas_analyse(Nom, _, Score),
    Score >= 0.40,
    Score < 0.70.
