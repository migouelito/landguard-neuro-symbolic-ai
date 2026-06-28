

:- discontiguous citoyen/1.
:- dynamic citoyen/1. % donné qu''on peut injecter

:- discontiguous agent_public/1.
:- dynamic agent_public/1.  % donné qu''on peut injecter

:- discontiguous promoteur/1.
:- discontiguous notaire/1.
:- discontiguous dossier_actif/1.

:- discontiguous parcelle_urbaine/1.
:- dynamic parcelle_urbaine/1. % donné qu''on peut injecter

:- discontiguous parcelle_rurale/1.
:- dynamic parcelle_rurale/1.% donné qu''on peut injecter

:- discontiguous possede/2.
:- dynamic possede/2. % donné qu''on peut injecter

:- discontiguous traite/2.
:- dynamic traite/2. % donné qu''on peut injecter

:- discontiguous beneficiaire/2.
:- dynamic beneficiaire/2. % donné qu''on peut injecter

:- discontiguous lien_familial/2.
:- discontiguous lien_professionnel/2.
:- discontiguous lien_financier/2.
:- discontiguous partage_telephone/2.
:- discontiguous partage_adresse/2.
:- discontiguous partage_iban/2.

:- discontiguous vendA/5.
:- dynamic vendA/5. % donné qu''on peut injecter

:- discontiguous achete/4.
:- dynamic achete/4. % donné qu''on peut injecter

:- discontiguous valeur_marche/2.

% Concepts principaux
concept(acteur).
concept(parcelle).
concept(affectation).
concept(dossier).
concept(lien_social).

% Sous-concepts des Acteurs
concept(citoyen).
concept(agent_public).
concept(promoteur).
concept(notaire).

% Sous-concepts des Parcelles
concept(parcelle_urbaine).
concept(parcelle_rurale).

% Sous-concepts des Affectations
concept(attribution).
concept(revente).
concept(heritage).

% Sous-concepts des Dossiers
concept(dossier_actif).
concept(dossier_suspect).

% Sous-concepts des Liens Sociaux
concept(lien_familial).
concept(lien_professionnel).
concept(lien_financier).

% Hierarchie (subsomption)
subsume(acteur, citoyen).
subsume(acteur, agent_public).
subsume(acteur, promoteur).
subsume(acteur, notaire).
subsume(parcelle, parcelle_urbaine).
subsume(parcelle, parcelle_rurale).
subsume(affectation, attribution).
subsume(affectation, revente).
subsume(affectation, heritage).
subsume(dossier, dossier_actif).
subsume(dossier, dossier_suspect).
subsume(lien_social, lien_familial).
subsume(lien_social, lien_professionnel).
subsume(lien_social, lien_financier).

% SECTION 2: DECLARATION DES ROLES

% Roles principaux
role(possede).           % possede(acteur, parcelle)
role(traite).            % traite(agent, dossier)
role(beneficiaire).      % beneficiaire(acteur, affectation)
role(vendA).             % vendA(vendeur, acheteur, parcelle, date, prix)
role(achete).            % achete(acheteur, parcelle, date, prix)

% Roles de partage d'informations
role(partage_telephone). % partage_telephone(personne1, personne2)
role(partage_adresse).   % partage_adresse(personne1, personne2)
role(partage_iban).      % partage_iban(personne1, personne2)

% Roles de liens sociaux
role(lien_familial).     % lien_familial(personne1, personne2)
role(lien_professionnel).% lien_professionnel(personne1, personne2)
role(lien_financier).    % lien_financier(personne1, personne2)

% Roles temporels et financiers
role(date_transaction).  % date_transaction(acte, date)
role(montant).           % montant(transaction, valeur)

% SECTION 3: AXIOMES DL (10 axiomes)

% Axiome 1: Accapareur Urbain
% Citoyen qui possede au moins 4 parcelles urbaines
% Formel: AccapareurUrbain ≡ Citoyen ⊓ (≥4 possede.ParcelleUrbaine)
accapareur_urbain(X) :-
    citoyen(X),
    findall(P, (possede(X, P), parcelle_urbaine(P)), Liste),
    length(Liste, N),
    N >= 4.

% Axiome 2: Conflit d'Interet Direct
% Agent public qui traite son propre dossier
% Formel: ConflitInterest ≡ AgentPublic ⊓ ∃traite.Dossier ⊓ ∃beneficiaire.Affectation
conflit_interet_direct(Agent) :-
    agent_public(Agent),
    traite(Agent, Dossier),
    beneficiaire(Agent, Dossier).

% Axiome 3: Speculateur Foncier
% Personne qui revend en moins d'un an avec plus-value > 50%
speculateur(X) :-
    ( citoyen(X) ; agent_public(X) ; promoteur(X) ; notaire(X) ),
    vendA(X, _, Parcelle, DateVente, PrixVente),
    achete(X, Parcelle, DateAchat, PrixAchat),
    Duree is DateVente - DateAchat,
    Duree < 365,
    Duree > 0,
    PlusValue is (PrixVente - PrixAchat) / PrixAchat,
    PlusValue > 0.5.

% Axiome 4: Prete-Nom
% Personne qui possede une parcelle et partage telephone avec le vrai proprietaire
prete_nom(X) :-
    citoyen(X),
    possede(X, Parcelle),
    partage_telephone(X, Y),
    X \= Y,
    possede(Y, Parcelle).

% Axiome 5: Reseau de Corruption
% Agent public dont le beneficiaire a un lien financier avec lui
reseau_corruption(Agent) :-
    agent_public(Agent),
    traite(Agent, Dossier),
    beneficiaire(Benef, Dossier),
    lien_financier(Agent, Benef).

% Axiome 6: Promoteur Fantome
% Promoteur sans parcelle mais avec transactions suspectes
promoteur_fantome(X) :-
    promoteur(X),
    \+ possede(X, _),
    transaction_suspecte(X).

transaction_suspecte(X) :-
    vendA(X, _, _, _, Montant),
    Montant > 1000000.

% Axiome 7: Dossier Suspect
% Dossier actif avec au moins 3 alertes de fraude
dossier_suspect(Dossier) :-
    dossier_actif(Dossier),
    findall(Alerte, alerte_sur_dossier(Dossier, Alerte), Alertes),
    length(Alertes, N),
    N >= 3.

alerte_sur_dossier(Dossier, alerte_conflit) :- conflit_interet_direct(Agent), traite(Agent, Dossier).
alerte_sur_dossier(Dossier, alerte_prete_nom) :- prete_nom(X), beneficiaire(X, Dossier).

% Axiome 8: Accaparement Familial
% Famille possedant plus de 8 parcelles urbaines
accaparement_familial(X) :-
    citoyen(X),
    findall(P, (lien_familial(X, Y), possede(Y, P)), ParcellesFamille),
    findall(P, possede(X, P), ParcellesX),
    append(ParcellesX, ParcellesFamille, Toutes),
    sort(Toutes, Uniques),
    length(Uniques, N),
    N >= 8.

% Axiome 9: Blanchiment Circulaire
% Cycle de transactions entre 3 personnes sur une meme parcelle
blanchiment_circulaire(X, Y, Z) :-
    vendA(X, Y, Parcelle, Date1, _),
    vendA(Y, Z, Parcelle, Date2, _),
    vendA(Z, X, Parcelle, Date3, _),
    Date1 < Date2,
    Date2 < Date3.

% Axiome 10: Notaire Complice
% Notaire qui traite au moins 5 dossiers suspects
notaire_complice(Notaire) :-
    notaire(Notaire),
    findall(D, (traite(Notaire, D), dossier_suspect(D)), DossiersSuspects),
    length(DossiersSuspects, N),
    N >= 5.

% SECTION 4: CONTRAINTES D'INTEGRITE (8 contraintes)

% CI-1: Un agent public ne peut traiter son propre dossier
ci_auto_traitement(Agent, Dossier) :-
    agent_public(Agent),
    traite(Agent, Dossier),
    beneficiaire(Agent, Dossier).

% CI-2: Maximum 3 parcelles urbaines par citoyen
ci_max_parcelles(Citoyen) :-
    citoyen(Citoyen),
    findall(P, (possede(Citoyen, P), parcelle_urbaine(P)), Liste),
    length(Liste, N),
    N > 3.

% CI-3: Une parcelle ne peut avoir deux propriétaires differents
ci_double_propriete(Parcelle) :-
    findall(X, possede(X, Parcelle), Proprietaires),
    length(Proprietaires, N),
    N > 1.

% CI-4: Un notaire ne peut pas etre beneficiaire d'un dossier qu'il traite
ci_notaire_beneficiaire(Notaire, Dossier) :-
    notaire(Notaire),
    traite(Notaire, Dossier),
    beneficiaire(Notaire, Dossier).

% CI-5: Partage de telephone entre proprietaires distincts => alerte prete-nom
ci_partage_telephone_suspect(X, Y) :-
    partage_telephone(X, Y),
    X \= Y,
    possede(X, Parcelle),
    possede(Y, Parcelle).

% CI-6: Date de vente doit etre > date d'achat
ci_date_invalide(X, Parcelle) :-
    achete(X, Parcelle, DateAchat, _),
    vendA(X, _, Parcelle, DateVente, _),
    DateVente =< DateAchat.

% CI-7: Un promoteur doit posseder au moins une parcelle
ci_promoteur_sans_parcelle(Promoteur) :-
    promoteur(Promoteur),
    \+ possede(Promoteur, _).

% CI-8: Un dossier suspect doit etre marque inactif
:- dynamic dossier_actif/1.
ci_dossier_suspect_actif(Dossier) :-
    dossier_suspect(Dossier),
    dossier_actif(Dossier).

% section 5 prédicats auxilliarees
% Verifier toutes les contraintes d'integrite
verifier_toutes_ci :-
    write('Verification des contraintes d''integrite:'), nl,
    findall(1, ci_auto_traitement(_, _), L1), length(L1, N1), write('CI-1 violations: '), write(N1), nl,
    findall(1, ci_max_parcelles(_), L2), length(L2, N2), write('CI-2 violations: '), write(N2), nl,
    findall(1, ci_double_propriete(_), L3), length(L3, N3), write('CI-3 violations: '), write(N3), nl,
    findall(1, ci_notaire_beneficiaire(_, _), L4), length(L4, N4), write('CI-4 violations: '), write(N4), nl,
    findall(1, ci_partage_telephone_suspect(_, _), L5), length(L5, N5), write('CI-5 violations: '), write(N5), nl.

% Afficher la taxonomie complete
afficher_taxonomie :-
    write('Taxonomie des concepts:'), nl,
    forall(subsume(Super, Sub), format('~w ⊑ ~w~n', [Sub, Super])).

% SECTION 6: FAITS DE TEST
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

% Transactions de vente (ajoutees pour tester les regles B1 et B2)
% vendA(Vendeur, Acheteur, Parcelle, DateVente, PrixVente)
vendA(abdou, fatou, p1, 2022, 50000).
achete(fatou, p1, 2020, 30000).

vendA(ousmane, abdou, p2, 2023, 200000).
achete(abdou, p2, 2022, 80000).

vendA(abdou, ousmane, p3, 2024, 150000).
achete(abdou, p3, 2024, 140000).


% SECTION 7: EXTENSION BURKINA FASO POUR LA DEMONSTRATION

% Acteurs supplementaires issus de scenarios fonciers burkinabe.
citoyen(abdou_ouedraogo).
citoyen(fatima_traore).
citoyen(adama_traore).
citoyen(fatoumata_traore).
citoyen(ibrahim_traore).
citoyen(rasmata_sawadogo).
citoyen(boureima_sankara).
citoyen(aminata_diallo).

agent_public(moussa_compaore).
agent_public(lassina_yameogo).

promoteur(societe_immobf).
promoteur(seydou_kabore).
promoteur(yacouba_ilboudo).

notaire(not001_yameogo).

% Parcelles contextualisees Burkina Faso.
parcelle_urbaine(p_gounghin_01).
parcelle_urbaine(p_gounghin_02).
parcelle_urbaine(p_pissy_01).
parcelle_urbaine(p_pissy_02).
parcelle_urbaine(p_pissy_03).
parcelle_urbaine(p_pissy_04).
parcelle_urbaine(p_pissy_05).
parcelle_urbaine(p_tanghin_01).
parcelle_urbaine(p_tanghin_02).
parcelle_urbaine(p_tanghin_03).
parcelle_urbaine(p_ouaga2000_01).
parcelle_urbaine(p_ouaga2000_02).
parcelle_urbaine(p_ouaga2000_03).
parcelle_urbaine(p_ouaga2000_04).
parcelle_urbaine(p_somgande_01).
parcelle_urbaine(p_somgande_02).
parcelle_urbaine(p_somgande_03).
parcelle_urbaine(p_somgande_04).
parcelle_urbaine(p_somgande_05).
parcelle_urbaine(p_kossodo_01).

parcelle_rurale(p_koudougou_01).
parcelle_rurale(p_koudougou_02).
parcelle_rurale(p_koudougou_03).
parcelle_rurale(p_koudougou_04).
parcelle_rurale(p_koudougou_05).
parcelle_rurale(p_koudougou_06).

% Possessions: cas standards, reseaux familiaux, promoteurs et fraude composite.
possede(abdou_ouedraogo, p_gounghin_01).
possede(abdou_ouedraogo, p_gounghin_02).

possede(adama_traore, p_pissy_01).
possede(adama_traore, p_pissy_02).
possede(adama_traore, p_pissy_03).
possede(adama_traore, p_pissy_04).
possede(adama_traore, p_pissy_05).

possede(fatoumata_traore, p_tanghin_01).
possede(fatoumata_traore, p_tanghin_02).
possede(fatoumata_traore, p_tanghin_03).
possede(fatoumata_traore, p_pissy_01).

possede(ibrahim_traore, p_pissy_01).
possede(ibrahim_traore, p_tanghin_01).

possede(moussa_compaore, p_ouaga2000_01).
possede(moussa_compaore, p_ouaga2000_02).
possede(moussa_compaore, p_ouaga2000_03).
possede(moussa_compaore, p_ouaga2000_04).

possede(societe_immobf, p_somgande_01).
possede(societe_immobf, p_somgande_02).
possede(societe_immobf, p_somgande_03).
possede(societe_immobf, p_somgande_04).
possede(societe_immobf, p_somgande_05).

possede(yacouba_ilboudo, p_koudougou_01).
possede(yacouba_ilboudo, p_koudougou_02).
possede(yacouba_ilboudo, p_koudougou_03).
possede(yacouba_ilboudo, p_koudougou_04).
possede(yacouba_ilboudo, p_koudougou_05).
possede(yacouba_ilboudo, p_koudougou_06).

possede(rasmata_sawadogo, p_pissy_01).
possede(rasmata_sawadogo, p_pissy_02).
possede(rasmata_sawadogo, p_tanghin_01).
possede(rasmata_sawadogo, p_ouaga2000_01).
possede(rasmata_sawadogo, p_kossodo_01).
possede(rasmata_sawadogo, p_somgande_01).

possede(boureima_sankara, p_kossodo_01).
possede(aminata_diallo, p_somgande_02).

% Dossiers et conflits d'interets.
dossier_actif(dos_bf_001).
dossier_actif(dos_bf_002).
dossier_actif(dos_bf_003).
traite(moussa_compaore, dos_bf_001).
beneficiaire(moussa_compaore, dos_bf_001).
traite(lassina_yameogo, dos_bf_002).
beneficiaire(adama_traore, dos_bf_002).
traite(lassina_yameogo, dos_bf_003).
beneficiaire(fatoumata_traore, dos_bf_003).

% Liens sociaux et professionnels.
lien_familial(adama_traore, fatoumata_traore).
lien_familial(fatoumata_traore, adama_traore).
lien_familial(adama_traore, ibrahim_traore).
lien_familial(ibrahim_traore, adama_traore).
lien_familial(fatoumata_traore, ibrahim_traore).
lien_familial(ibrahim_traore, fatoumata_traore).
lien_familial(lassina_yameogo, adama_traore).
lien_familial(adama_traore, lassina_yameogo).

lien_professionnel(lassina_yameogo, fatoumata_traore).
lien_professionnel(fatoumata_traore, lassina_yameogo).
lien_financier(moussa_compaore, seydou_kabore).

% Reseaux prete-nom: telephone, adresse et IBAN.
partage_telephone(adama_traore, fatoumata_traore).
partage_telephone(fatoumata_traore, adama_traore).
partage_telephone(rasmata_sawadogo, boureima_sankara).
partage_telephone(boureima_sankara, rasmata_sawadogo).

partage_adresse(adama_traore, fatoumata_traore).
partage_adresse(fatoumata_traore, adama_traore).
partage_adresse(rasmata_sawadogo, boureima_sankara).
partage_adresse(boureima_sankara, rasmata_sawadogo).

partage_iban(adama_traore, fatoumata_traore).
partage_iban(fatoumata_traore, adama_traore).
partage_iban(seydou_kabore, societe_immobf).
partage_iban(societe_immobf, seydou_kabore).

% Transactions supplementaires. Les dates sont des indices temporels
% synthetiques; elles permettent de tester les regles de revente rapide.
achete(adama_traore, p_pissy_01, 100, 200000).
vendA(adama_traore, fatoumata_traore, p_pissy_01, 150, 650000).
achete(fatoumata_traore, p_pissy_01, 150, 650000).
vendA(fatoumata_traore, ibrahim_traore, p_pissy_01, 210, 900000).
achete(ibrahim_traore, p_pissy_01, 210, 900000).
vendA(ibrahim_traore, adama_traore, p_pissy_01, 300, 1200000).

achete(rasmata_sawadogo, p_kossodo_01, 50, 100000).
vendA(rasmata_sawadogo, boureima_sankara, p_kossodo_01, 95, 450000).








% %chargement du fichier knowledge_base pour faire des réquest :
% ?- [knowledge_base].
% % Résultat: true. (si tout va bien)


% % Vérifie si Abdou possède au moins 4 parcelles urbaines
% ?- accapareur_urbain(abdou).
% % Résultat attendu: true.
% % Explication: abdou a p1, p2, p3, p4 (4 parcelles urbaines)

% % Vérifie si Modou traite son propre dossier
% ?- conflit_interet_direct(modou).
% % Résultat attendu: true.
% % Explication: modou est agent_public, traite d1, beneficiaire d1


% % Vérifie si la parcelle p1 a plusieurs propriétaires
% ?- ci_double_propriete(p1).
% % Résultat attendu: true.
% % Explication: p1 possédée par abdou et ousmane


% % Vérifie si abdou et ousmane partagent le même téléphone ET la même parcelle
% ?- ci_partage_telephone_suspect(abdou, ousmane).
% % Résultat attendu: true.
% % Explication: ils partagent telephone et possedent tous deux p1


% % Vérifie si un citoyen dépasse la limite de 3 parcelles urbaines
% ?- ci_max_parcelles(abdou).
% % Résultat attendu: true.
% % Explication: abdou possède 4 parcelles > limite de 3



% % Vérifie si un agent traite son propre dossier
% ?- ci_auto_traitement(modou, d1).
% % Résultat attendu: true.
% % Explication: modou traite d1 et beneficiaire modou


% % Vérifie si abdou est un prête-nom
% ?- prete_nom(abdou).
% % Résultat attendu: true.
% % Explication: abdou partage telephone avec ousmane et ils possedent p1


% % Vérifie si la famille de abdou possède plus de 8 parcelles
% ?- accaparement_familial(abdou).
% % Résultat attendu: false (pour l'instant, pas assez de faits)
% % Explication: abdou + fatou (sa famille) ont 5 parcelles seulement



% % Affiche toute la hiérarchie des concepts (sous-classes)
% ?- afficher_taxonomie.
% % Résultat: affiche une liste comme:
% % citoyen ⊑ acteur
% % agent_public ⊑ acteur
% % promoteur ⊑ acteur
% % notaire ⊑ acteur
% % parcelle_urbaine ⊑ parcelle
% % parcelle_rurale ⊑ parcelle
% % ...



% % % Vérifie et compte toutes les violations des CI
% % ?- verifier_toutes_ci.
% % % Résultat: affiche des nombres comme:
% % % CI-1 violations: 1
% % % CI-2 violations: 1
% % % CI-3 violations: 1
% % % CI-4 violations: 0
% % % CI-5 violations: 1


% % % Trouve toutes les personnes qui sont accapareurs urbains
% % ?- findall(X, accapareur_urbain(X), Liste).
% % % Résultat: Liste = [abdou]


% % % Vérifie si abdou est un citoyen
% % ?- citoyen(abdou).
% % % Résultat: true.

% % % Vérifie si abdou possède p1
% % ?- possede(abdou, p1).
% % % Résultat: true.

% % % Vérifie si une relation de vente existe
% % ?- vendA(abdou, _, _, _, _).
% % % Résultat: false. (pas encore de faits de vente)


% % % Liste tous les citoyens
% % ?- findall(X, citoyen(X), Liste).
% % % Résultat: Liste = [abdou, fatou, ousmane]



% % % Liste toutes les parcelles possédées par abdou
% % ?- findall(P, possede(abdou, P), Parcelles).
% % % Résultat: Parcelles = [p1, p2, p3, p4]


% % % Compte combien de parcelles possède abdou
% % ?- findall(P, possede(abdou, P), L), length(L, N).
% % % Résultat: L = [p1, p2, p3, p4], N = 4


% % % Vérifie si abdou et fatou ont un lien familial
% % ?- lien_familial(abdou, fatou).
% % % Résultat: true.

% % % Trouve toutes les personnes qui partagent le téléphone d'abdou
% % ?- partage_telephone(abdou, X).
% % % Résultat: X = ousmane.
