% LANDGUARD - EXPLICABILITE (XAI)
% Partie 2: Journalisation des regles
% Fichier: explainability.pl

:- dynamic trace/4.
:- dynamic alerte_log/4.
:- dynamic compteur_alerte/1.

compteur_alerte(0).

% Initialiser la base de traces
init_traces :-
    retractall(trace(_, _, _, _)),
    reset_log_silencieux.

reset_log_silencieux :-
    retractall(alerte_log(_, _, _, _)),
    retractall(compteur_alerte(_)),
    assertz(compteur_alerte(0)).

% Enregistrer le declenchement d'une regle
enregistrer_regle(IdRegle, Variables, Justification) :-
    get_time(Timestamp),
    assertz(trace(IdRegle, Timestamp, Variables, Justification)),
    assertz(alerte_log(IdRegle, Variables, Variables, Justification)),
    format('~n[TRACE] Regle ~w declenchee~n', [IdRegle]),
    format('        Variables: ~w~n', [Variables]),
    format('        Justification: ~w~n', [Justification]).

% Interface XAI compatible avec les modules plus riches proposes pour LandGuard.
log_regle(IdRegle, Acteur, Variables, Justification) :-
    get_time(Timestamp),
    retract(compteur_alerte(N)),
    N1 is N + 1,
    assertz(compteur_alerte(N1)),
    assertz(trace(IdRegle, Timestamp, [Acteur|Variables], Justification)),
    assertz(alerte_log(IdRegle, Acteur, Variables, Justification)),
    format('~n[ALERTE ~w] ~w~n', [IdRegle, Acteur]),
    format('        Variables: ~w~n', [Variables]),
    format('        Justification: ~w~n', [Justification]).

% Regle A1 avec explication
regle_a1_multipropriete_xai(X) :-
    regle_a1_multipropriete(X),
    findall(P, possede(X, P), Liste),
    length(Liste, N),
    format(atom(Justif), 'La personne ~w possede ~w parcelles, ce qui depasse la limite de 5', [X, N]),
    enregistrer_regle('A1-Multipropriete', [X, N], Justif).

% Regle A2 avec explication
regle_a2_accaparement_familial_xai(X) :-
    regle_a2_accaparement_familial(X),
    findall(P, (lien_familial(X, Y), possede(Y, P)), ParcellesFamille),
    findall(P, possede(X, P), ParcellesX),
    append(ParcellesX, ParcellesFamille, Toutes),
    sort(Toutes, Uniques),
    length(Uniques, N),
    format(atom(Justif), 'La famille de ~w possede ~w parcelles, depassant le seuil de 8', [X, N]),
    enregistrer_regle('A2-AccaparementFamilial', [X, N], Justif).

% Regle B1 avec explication
regle_b1_revente_ultra_rapide_xai(X) :-
    regle_b1_revente_ultra_rapide(X),
    vendA(X, _, Parcelle, DateVente, _),
    achete(X, Parcelle, DateAchat, _),
    Duree is DateVente - DateAchat,
    format(atom(Justif), '~w a revendu la parcelle ~w apres ~w jours (seuil < 90 jours)', [X, Parcelle, Duree]),
    enregistrer_regle('B1-ReventeUltraRapide', [X, Parcelle, Duree], Justif).

% Regle B2 avec explication
regle_b2_plus_value_anormale_xai(X) :-
    regle_b2_plus_value_anormale(X),
    vendA(X, _, Parcelle, _, PrixVente),
    achete(X, Parcelle, _, PrixAchat),
    PlusValue is (PrixVente - PrixAchat) / PrixAchat * 100,
    format(atom(Justif), '~w a realise une plus-value de ~w%% sur la parcelle ~w (seuil > 100%%)', [X, PlusValue, Parcelle]),
    enregistrer_regle('B2-PlusValueAnormale', [X, Parcelle, PlusValue], Justif).

% Regle C1 avec explication
regle_c1_auto_attribution_xai(Agent) :-
    regle_c1_auto_attribution(Agent),
    traite(Agent, Dossier),
    format(atom(Justif), 'L agent public ~w a traite son propre dossier ~w', [Agent, Dossier]),
    enregistrer_regle('C1-AutoAttribution', [Agent, Dossier], Justif).

% Regle C2 avec explication
regle_c2_traitement_familial_xai(Agent) :-
    regle_c2_traitement_familial(Agent),
    traite(Agent, Dossier),
    beneficiaire(Benef, Dossier),
    format(atom(Justif), 'L agent ~w a traite un dossier dont le beneficiaire ~w est un parent', [Agent, Benef]),
    enregistrer_regle('C2-TraitementFamilial', [Agent, Dossier, Benef], Justif).

% Regle D1 avec explication
regle_d1_prete_nom_telephone_xai(X, Y) :-
    regle_d1_prete_nom_telephone(X, Y),
    partage_telephone(X, Y),
    findall(P, (possede(X, P), possede(Y, P)), Parcelles),
    format(atom(Justif), '~w et ~w partagent le meme telephone et possedent ensemble les parcelles ~w', [X, Y, Parcelles]),
    enregistrer_regle('D1-PreteNomTelephone', [X, Y, Parcelles], Justif).

% Regle D2 avec explication
regle_d2_prete_nom_adresse_xai(X, Y) :-
    regle_d2_prete_nom_adresse(X, Y),
    partage_adresse(X, Y),
    findall(P, (possede(X, P), possede(Y, P)), Parcelles),
    format(atom(Justif), '~w et ~w partagent la meme adresse et les parcelles communes ~w', [X, Y, Parcelles]),
    enregistrer_regle('D2-PreteNomAdresse', [X, Y, Parcelles], Justif).

% Regle D3 avec explication
regle_d3_transaction_circulaire_xai(X, Y, Z) :-
    regle_d3_transaction_circulaire(X, Y, Z),
    format(atom(Justif), 'Cycle de revente detecte entre ~w, ~w et ~w sur une meme parcelle', [X, Y, Z]),
    enregistrer_regle('D3-TransactionCirculaire', [X, Y, Z], Justif).

% Regle D4 avec explication
regle_d4_partage_iban_suspect_xai(X, Y) :-
    regle_d4_partage_iban_suspect(X, Y),
    partage_iban(X, Y),
    findall(P, (possede(X, P), possede(Y, P)), Parcelles),
    format(atom(Justif), '~w et ~w partagent un IBAN et des parcelles communes ~w', [X, Y, Parcelles]),
    enregistrer_regle('D4-PartageIBANSuspect', [X, Y, Parcelles], Justif).

% Generer un rapport d'explication complet
generer_rapport_xai :-
    init_traces,
    write('=== RAPPORT D\'EXPLICABILITE LANDGUARD ==='), nl, nl,
    
    % Executer toutes les regles XAI
    findall(_, (regle_a1_multipropriete_xai(_)), _),
    findall(_, (regle_a2_accaparement_familial_xai(_)), _),
    findall(_, (regle_b1_revente_ultra_rapide_xai(_)), _),
    findall(_, (regle_b2_plus_value_anormale_xai(_)), _),
    findall(_, (regle_c1_auto_attribution_xai(_)), _),
    findall(_, (regle_c2_traitement_familial_xai(_)), _),
    findall(_, (regle_d1_prete_nom_telephone_xai(_,_)), _),
    findall(_, (regle_d2_prete_nom_adresse_xai(_,_)), _),
    findall(_, (regle_d3_transaction_circulaire_xai(_,_,_)), _),
    findall(_, (regle_d4_partage_iban_suspect_xai(_,_)), _),
    
    % Afficher les traces
    write('TRACES ENREGISTREES:'), nl,
    forall(trace(Id, Timestamp, Vars, Justif),
           format('~w [~w] ~w : ~w~n', [Timestamp, Id, Vars, Justif])),
    nl.


% Exporter le rapport en JSON - VERSION CORRIGEE
exporter_rapport_json(Fichier) :-
    tell(Fichier),
    write('{'),
    write('"rapport": {'),
    write('"date": "2026-06-12",'),
    write('"alertes": ['),
    findall(Id-Timestamp-Vars-Justif, trace(Id, Timestamp, Vars, Justif), Traces),
    ecrire_traces_json(Traces),
    write(']}'),
    told.

% Ecrit les traces sans virgule apres le dernier element
ecrire_traces_json([]).
ecrire_traces_json([Id-Timestamp-Vars-Justif]) :-
    format('{~n  "regle": "~w",~n  "timestamp": "~w",~n  "variables": "~w",~n  "justification": "~w"~n}', [Id, Timestamp, Vars, Justif]).
ecrire_traces_json([Id-Timestamp-Vars-Justif|Rest]) :-
    format('{~n  "regle": "~w",~n  "timestamp": "~w",~n  "variables": "~w",~n  "justification": "~w"~n},', [Id, Timestamp, Vars, Justif]),
    ecrire_traces_json(Rest).
