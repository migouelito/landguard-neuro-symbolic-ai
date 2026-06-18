% LANDGUARD - MOTEUR D'INFERENCE
% Partie 2: Moteur de detection de fraudes
% Fichier: inference_engine.pl

:- [rules].
:- [explainability].

:- if(exists_file('dataset_facts.pl')).
:- [dataset_facts].
:- elif(exists_file('prolog/dataset_facts.pl')).
:- ['prolog/dataset_facts.pl'].
:- endif.

% Lancer la detection sur toutes les personnes
lancer_detection :-
    init_traces,
    write('=== LANCEMENT DE LA DETECTION DE FRAUDES ==='), nl,
    findall(X, citoyen(X), Citoyens),
    findall(X, agent_public(X), Agents),
    findall(X, promoteur(X), Promoteurs),
    findall(Nom, cas_analyse(Nom, _, _), CasDataset),
    
    write('Detection sur les citoyens...'), nl,
    detection_sur_liste(Citoyens),
    
    write('Detection sur les agents publics...'), nl,
    detection_sur_liste(Agents),
    
    write('Detection sur les promoteurs...'), nl,
    detection_sur_liste(Promoteurs),

    write('Detection sur le dataset Burkina...'), nl,
    detection_dataset_resume(CasDataset),
    
    write('Detection sur les relations...'), nl,
    detection_relations,
    
    write('=== FIN DE LA DETECTION ==='), nl.

% Detection sur une liste d'individus
detection_sur_liste([]).
detection_sur_liste([X|Rest]) :-
    detecter_fraudes_personne(X),
    detection_sur_liste(Rest).

detection_sur_dataset([]).
detection_sur_dataset([Nom|Rest]) :-
    detecter_cas_dataset(Nom),
    detection_sur_dataset(Rest).

detection_dataset_resume(CasDataset) :-
    length(CasDataset, Total),
    findall(N, (member(N, CasDataset), cas_dataset_critique(N)), Critiques),
    findall(N, (member(N, CasDataset), cas_dataset_accaparement(N)), Accaparements),
    findall(N, (member(N, CasDataset), cas_dataset_speculation(N)), Speculations),
    findall(N, (member(N, CasDataset), cas_dataset_limite(N)), Limites),
    length(Critiques, NbCritiques),
    length(Accaparements, NbAccaparements),
    length(Speculations, NbSpeculations),
    length(Limites, NbLimites),
    format('  - Cas analyses: ~w~n', [Total]),
    format('  - Cas critiques: ~w~n', [NbCritiques]),
    format('  - Accaparements dataset: ~w~n', [NbAccaparements]),
    format('  - Speculations dataset: ~w~n', [NbSpeculations]),
    format('  - Cas limites: ~w~n', [NbLimites]).

% Detection de toutes les fraudes pour une personne
detecter_fraudes_personne(X) :-
    personne_avec_alerte(X),
    !,
    format('~nAnalyse de ~w:~n', [X]),
    
    (   regle_a1_multipropriete_xai(X) -> writeln('  - [ALERTE A1] Multipropriete excessive') ; true),
    (   regle_a2_accaparement_familial_xai(X) -> writeln('  - [ALERTE A2] Accaparement familial') ; true),
    (   regle_b1_revente_ultra_rapide_xai(X) -> writeln('  - [ALERTE B1] Revente ultra-rapide') ; true),
    (   regle_b2_plus_value_anormale_xai(X) -> writeln('  - [ALERTE B2] Plus-value anormale') ; true),
    (   regle_c1_auto_attribution_xai(X) -> writeln('  - [ALERTE C1] Auto-attribution') ; true),
    (   regle_c2_traitement_familial_xai(X) -> writeln('  - [ALERTE C2] Traitement familial') ; true).
detecter_fraudes_personne(_).

personne_avec_alerte(X) :-
    (   regle_a1_multipropriete(X)
    ;   regle_a2_accaparement_familial(X)
    ;   regle_b1_revente_ultra_rapide(X)
    ;   regle_b2_plus_value_anormale(X)
    ;   regle_c1_auto_attribution(X)
    ;   regle_c2_traitement_familial(X)
    ).

detecter_cas_dataset(Nom) :-
    cas_analyse(Nom, NbParcelles, Score),
    format('~nAnalyse dataset de ~w:~n', [Nom]),
    (   cas_dataset_critique(Nom) -> format('  - [ALERTE DATA] Cas critique (parcelles=~w, score=~2f)~n', [NbParcelles, Score]) ; true),
    (   cas_dataset_accaparement(Nom) -> format('  - [ALERTE DATA] Accaparement dataset~n') ; true),
    (   cas_dataset_speculation(Nom) -> format('  - [ALERTE DATA] Speculation dataset~n') ; true),
    (   cas_dataset_limite(Nom) -> format('  - [INFO DATA] Cas limite a surveiller~n') ; true).

% Detection sur les relations
detection_relations :-
    nl,
    writeln('Analyse des relations:'),
    
    % Prete-nom par telephone
    forall(regle_d1_prete_nom_telephone_xai(X,Y),
           format('  - [ALERTE D1] Prete-nom detecte entre ~w et ~w (telephone partage)~n', [X,Y])),
    forall(regle_d2_prete_nom_adresse_xai(A,B),
           format('  - [ALERTE D2] Prete-nom detecte entre ~w et ~w (adresse partagee)~n', [A,B])),
    forall(regle_d3_transaction_circulaire_xai(C,D,E),
           format('  - [ALERTE D3] Transaction circulaire: ~w -> ~w -> ~w~n', [C,D,E])),
    forall(regle_d4_partage_iban_suspect_xai(F,G),
           format('  - [ALERTE D4] IBAN suspect partage entre ~w et ~w~n', [F,G])).

% Generer un resume pour une personne
resume_personne(X) :-
    score_suspicion(X, Score),
    niveau_criticite(Score, Niveau),
    format('~n=== RESUME POUR ~w ===~n', [X]),
    format('Score de suspicion: ~w/100~n', [Score]),
    format('Niveau de criticite: ~w~n', [Niveau]),
    (   Score >= 60 -> write('RECOMMANDATION: Audit approfondi requis') ;
        Score >= 30 -> write('RECOMMANDATION: Surveillance renforcee') ;
        write('RECOMMANDATION: Aucune action immediate') ).

% Point d'entree principal
main :-
    lancer_detection,
    nl,
    write('=== SCORES DE SUSPICION ==='), nl,
    forall(citoyen(X), (score_suspicion(X, S), format('~w: ~w/100~n', [X, S]))),
    nl,
    write('Generation du rapport...'), nl,
    exporter_rapport_json('rapport_xai.json'),
    write('Rapport exporte dans rapport_xai.json').

% Alias compatible avec la commande:
%   swipl -q -s inference_engine.pl -g run -t halt
run :-
    main.
