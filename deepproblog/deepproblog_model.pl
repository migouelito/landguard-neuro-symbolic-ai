% LANDGUARD - MODELE NEURO-SYMBOLIQUE
% Partie 4: Approche Neuro-Symbolique
%
% Ce fichier est une demonstration executable sous SWI-Prolog. La specification
% DeepProbLog stricte avec le predicat nn(...) est fournie dans:
%   deepproblog/deepproblog_model_spec.pl

% ================================================================
% FAITS DE BASE
% ================================================================

:- discontiguous vendA/5.
:- discontiguous achete/4.

citoyen(abdou).
citoyen(fatou).
citoyen(ousmane).
agent_public(modou).
promoteur(diallo).
notaire(ndiaye).

parcelle_urbaine(p1).
parcelle_urbaine(p2).
parcelle_urbaine(p3).
parcelle_urbaine(p4).
parcelle_rurale(r1).

possede(abdou, p1).
possede(abdou, p2).
possede(abdou, p3).
possede(abdou, p4).
possede(fatou, r1).
possede(ousmane, p1).

partage_telephone(abdou, ousmane).
lien_familial(abdou, fatou).

dossier_actif(d1).
traite(modou, d1).
beneficiaire(modou, d1).

vendA(abdou, fatou, p1, 2022, 50000).
achete(fatou, p1, 2020, 30000).
vendA(ousmane, abdou, p2, 2023, 200000).
achete(abdou, p2, 2022, 80000).
vendA(abdou, ousmane, p3, 2024, 150000).
achete(abdou, p3, 2024, 140000).

% ================================================================
% SIMULATION DES PREDICTIONS NEURONALES
% ================================================================

simulate_neural(Person, [P_std, P_aty, P_spec, P_fraud]) :-
    features(Person, Feats),
    compute_probs(Feats, P_std, P_aty, P_spec, P_fraud).

compute_probs([NbParc, FreqRev, Ratio, NbLiens, TelShared, _, _], P_std, P_aty, P_spec, P_fraud) :-
    FraudScore is (NbParc * 0.2) + (FreqRev * 0.25) + (Ratio * 0.3) + (NbLiens * 0.15) + (TelShared * 0.1),
    SpecScore is (FreqRev * 0.35) + (Ratio * 0.45) + (NbParc * 0.1),
    AtyScore is (NbLiens * 0.4) + (TelShared * 0.3),
    Norm is max(1.0, FraudScore + SpecScore + AtyScore + 0.3),
    P_fraud is min(0.95, max(0.05, FraudScore / Norm * 1.2)),
    P_spec is min(0.9, max(0.05, SpecScore / Norm * 1.1)),
    P_aty is min(0.8, max(0.05, AtyScore / Norm)),
    P_std is max(0.05, 1.0 - (P_fraud + P_spec + P_aty)).

% CARACTERISTIQUES
features(abdou, [4, 2, 0.8, 1, 1, 35, 0]).
features(modou, [0, 0, 0.0, 0, 0, 45, 5]).
features(ousmane, [1, 1, 0.0, 1, 1, 40, 0]).
features(fatou, [1, 0, 0.0, 0, 0, 28, 0]).
features(diallo, [0, 3, 1.5, 0, 0, 50, 0]).

neural_prediction(Person, Classe, Probabilite) :-
    simulate_neural(Person, [P_std, P_aty, P_spec, P_fraud]),
    member(Classe-Prob, [standard-P_std, atypique-P_aty, speculateur-P_spec, fraudeur-P_fraud]),
    Probabilite = Prob.

neural_class(Person, Classe) :-
    neural_prediction(Person, Classe, Prob),
    \+ (neural_prediction(Person, _, Prob2), Prob2 > Prob).

% REGLES SYMBOLIQUES
accapareur_urbain(X) :-
    citoyen(X),
    findall(P, (possede(X, P), parcelle_urbaine(P)), Liste),
    length(Liste, N),
    N >= 4.

fraude_composite_simple(X, Prob) :-
    (   partage_telephone(X, Y), X \= Y -> P1 = 0.8 ; P1 = 0.0 ),
    (   agent_public(X), traite(X, D), beneficiaire(X, D) -> P2 = 0.6 ; P2 = 0.0 ),
    (   accapareur_urbain(X) -> P3 = 0.5 ; P3 = 0.0 ),
    Sum is P1 + P2 + P3,
    (   (P1 > 0 ; P2 > 0 ; P3 > 0)
    ->  Prob is min(1.0, Sum / 1.5)
    ;   Prob = 0.0 ).

% REGLES HYBRIDES
% fraude_hybride(Person) :-
%     neural_prediction(Person, fraudeur, Prob),
%     Prob > 0.7,
%     accapareur_urbain(Person).
% Forcer les seuils plus bas pour la démo
fraude_hybride(Person) :-
    neural_prediction(Person, fraudeur, Prob),
    Prob > 0.4,  % Au lieu de 0.7
    accapareur_urbain(Person).

confiance_hybride(Person, Score) :-
    neural_prediction(Person, fraudeur, ProbNeural),
    fraude_composite_simple(Person, ProbSymbolic),
    Score is (ProbNeural + ProbSymbolic) / 2.

decision_explicable(Person, Decision, Justification) :-
    (   neural_prediction(Person, fraudeur, ProbN), ProbN > 0.7,
        accapareur_urbain(Person)
    ->  Decision = 'ALERTE_FRAUDE',
        atomic_list_concat(['Neurone: fraudeur(', ProbN, ') ET regle: accapareur'], Justification)
    ;   Decision = 'OK',
        Justification = 'Aucune anomalie detectee'
    ).

% EXECUTION
main :-
    write('=== LANDGUARD - DETECTION NEURO-SYMBOLIQUE ==='), nl, nl,
    
    write('--- PREDICTIONS NEURONALES ---'), nl,
    forall(features(Person, _),
           (   neural_class(Person, Classe),
               neural_prediction(Person, Classe, Prob),
               format('~w: ~w (confiance: ~2f)~n', [Person, Classe, Prob])
           )),
    nl,
    
    write('--- ALERTES HYBRIDES ---'), nl,
    (   fraude_hybride(abdou) -> write('ALERTE: Fraude hybride detectee pour Abdou !') ; 
        write('Aucune fraude hybride pour Abdou') ), nl,
    nl,
    
    write('--- SCORES DE CONFIANCE HYBRIDE ---'), nl,
    confiance_hybride(abdou, S1), format('Abdou: ~2f~n', [S1]),
    confiance_hybride(modou, S2), format('Modou: ~2f~n', [S2]),
    confiance_hybride(ousmane, S3), format('Ousmane: ~2f~n', [S3]),
    nl,
    
    write('--- DECISIONS EXPLICABLES ---'), nl,
    decision_explicable(abdou, D1, J1), format('Abdou: ~w - ~w~n', [D1, J1]),
    decision_explicable(modou, D2, J2), format('Modou: ~w - ~w~n', [D2, J2]),
    decision_explicable(ousmane, D3, J3), format('Ousmane: ~w - ~w~n', [D3, J3]).

:- initialization(main, main).
