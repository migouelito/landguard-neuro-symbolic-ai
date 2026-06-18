% LANDGUARD - Specification DeepProbLog conforme
% Ce fichier montre la couche neuro-symbolique attendue par l'enonce.
% Execution dans un environnement DeepProbLog, pas directement dans SWI-Prolog.

% Le reseau PyTorch fraud_model prend les features d'un acteur et predit
% l'une des quatre classes: standard, atypique, speculateur, fraudeur.
nn(fraud_model, [X], Y, [standard, atypique, speculateur, fraudeur]) :: neural_prediction(X, Y).

% Faits structurels minimaux.
citoyen(abdou).
agent_public(modou).
possede(abdou, p1).
possede(abdou, p2).
possede(abdou, p3).
possede(abdou, p4).
parcelle_urbaine(p1).
parcelle_urbaine(p2).
parcelle_urbaine(p3).
parcelle_urbaine(p4).
partage_telephone(abdou, ousmane).
traite(modou, d1).
beneficiaire(modou, d1).

% Contraintes symboliques.
accaparement_urbain(X) :-
    citoyen(X),
    possede(X, p1),
    possede(X, p2),
    possede(X, p3),
    possede(X, p4).

conflit_interet(X) :-
    agent_public(X),
    traite(X, D),
    beneficiaire(X, D).

reseau_prete_nom(X) :-
    partage_telephone(X, _).

% Fusion neuro-symbolique.
fraude(X) :-
    neural_prediction(X, fraudeur),
    accaparement_urbain(X).

fraude(X) :-
    neural_prediction(X, speculateur),
    reseau_prete_nom(X).

fraude(X) :-
    neural_prediction(X, fraudeur),
    conflit_interet(X).

decision_explicable(X, alerte_fraude) :-
    fraude(X).

query(fraude(abdou)).
query(fraude(modou)).
query(decision_explicable(abdou, alerte_fraude)).
