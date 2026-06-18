% LANDGUARD - REGLES PROBLOG
% Partie 3: Raisonnement probabiliste reel avec ProbLog.
%
% Executions recommandees:
%   problog prolog/probabilistic_rules.pl
%   problog prolog/queries.pl

% ----------------------------------------------------------------
% Faits terrain minimaux utilises par l'inference probabiliste
% ----------------------------------------------------------------

citoyen(abdou).
citoyen(ousmane).
citoyen(fatou).
agent_public(modou).

possede(abdou, p1).
possede(abdou, p2).
possede(abdou, p3).
possede(abdou, p4).
possede(ousmane, p1).

partage_telephone(abdou, ousmane).
partage_adresse(abdou, ousmane).
lien_familial(modou, fatou).
traite(modou, d1).
beneficiaire(modou, d1).
beneficiaire(fatou, d2).

revente_rapide(abdou).
plus_value_anormale(abdou).
document_falsifie(doc_123).
transaction_circulaire(abdou, ousmane, fatou).

% ----------------------------------------------------------------
% Clauses incertaines
% ----------------------------------------------------------------

0.80::prete_nom(X, Y) :-
    partage_telephone(X, Y),
    X \= Y.

0.65::prete_nom(X, Y) :-
    partage_adresse(X, Y),
    X \= Y.

0.70::speculateur(X) :-
    revente_rapide(X),
    plus_value_anormale(X).

0.75::conflit_interet(X) :-
    agent_public(X),
    traite(X, Dossier),
    beneficiaire(X, Dossier).

0.55::conflit_interet_indirect(X) :-
    agent_public(X),
    lien_familial(X, Beneficiaire),
    beneficiaire(Beneficiaire, _).

0.90::fraude_documentaire(Doc) :-
    document_falsifie(Doc).

0.85::blanchiment_foncier(X) :-
    transaction_circulaire(X, _, _).

% ----------------------------------------------------------------
% Fraudes complexes par propagation probabiliste
% ----------------------------------------------------------------

risque_fraude(X) :-
    prete_nom(X, _).

risque_fraude(X) :-
    speculateur(X).

risque_fraude(X) :-
    conflit_interet(X).

risque_fraude(X) :-
    conflit_interet_indirect(X).

risque_fraude(X) :-
    blanchiment_foncier(X).

risque_documentaire(Doc) :-
    fraude_documentaire(Doc).

fraude_composite(X) :-
    prete_nom(X, _),
    speculateur(X).

fraude_composite(X) :-
    conflit_interet(X).

fraude_composite(X) :-
    blanchiment_foncier(X),
    speculateur(X).

% ----------------------------------------------------------------
% Echelle de criticite demandee dans l'enonce
% ----------------------------------------------------------------

niveau_risque(P, faible) :-
    P < 0.30.

niveau_risque(P, moyen) :-
    P >= 0.30,
    P < 0.60.

niveau_risque(P, eleve) :-
    P >= 0.60,
    P < 0.80.

niveau_risque(P, critique) :-
    P >= 0.80.

% ----------------------------------------------------------------
% Requetes par defaut pour execution directe du fichier.
% ----------------------------------------------------------------

query(prete_nom(abdou, ousmane)).
query(speculateur(abdou)).
query(conflit_interet(modou)).
query(conflit_interet_indirect(modou)).
query(blanchiment_foncier(abdou)).
query(risque_fraude(abdou)).
query(risque_fraude(modou)).
query(risque_fraude(ousmane)).
query(fraude_composite(abdou)).
query(fraude_composite(modou)).
query(risque_documentaire(doc_123)).
