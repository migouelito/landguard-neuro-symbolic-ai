:- begin_tests(landguard_symbolic).

:- consult('../prolog/knowledge_base.pl').
:- consult('../prolog/rules.pl').

test(dl_accapareur_urbain) :-
    accapareur_urbain(abdou).

test(ci_auto_traitement) :-
    ci_auto_traitement(modou, d1).

test(ci_max_parcelles) :-
    ci_max_parcelles(abdou).

test(ci_double_propriete) :-
    ci_double_propriete(p1).

test(ci_partage_telephone, [nondet]) :-
    ci_partage_telephone_suspect(abdou, ousmane).

test(regle_a3_concentration_urbaine) :-
    regle_a3_concentration_urbaine(abdou).

test(regle_a4_monopole_foncier) :-
    regle_a4_monopole_foncier(abdou, 'Dakar-Nord').

test(regle_c1_auto_attribution) :-
    regle_c1_auto_attribution(modou).

test(regle_d1_prete_nom_telephone, [nondet]) :-
    regle_d1_prete_nom_telephone(abdou, ousmane).

test(fraude_detectee_abdou, [nondet]) :-
    fraude_detectee(abdou).

test(fraude_detectee_modou, [nondet]) :-
    fraude_detectee(modou).

test(score_suspicion_abdou) :-
    score_suspicion(abdou, Score),
    Score > 0.

test(niveau_criticite_faible, [nondet]) :-
    niveau_criticite(10, faible).

test(niveau_criticite_moyen, [nondet]) :-
    niveau_criticite(45, moyen).

test(niveau_criticite_critique) :-
    niveau_criticite(90, critique).

test(burkina_accaparement_familial_traore, [nondet]) :-
    regle_a2_accaparement_familial(adama_traore).

test(burkina_conflit_familial, [nondet]) :-
    regle_c2_traitement_familial(lassina_yameogo).

test(burkina_transaction_circulaire, [nondet]) :-
    regle_d3_transaction_circulaire(adama_traore, fatoumata_traore, ibrahim_traore).

test(burkina_iban_suspect, [nondet]) :-
    regle_d4_partage_iban_suspect(adama_traore, fatoumata_traore).

:- end_tests(landguard_symbolic).

:- run_tests.
