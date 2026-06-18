% Tests ProbLog de reference.
% Execution:
%   problog tests/test_probabilistic.pl

:- consult('../prolog/probabilistic_rules.pl').

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
