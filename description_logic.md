# LandGuard Neuro-Symbolic AI

## Partie 1 - Modelisation en logique de description

Domaine: regulation fonciere et detection de fraudes au Burkina Faso.  
Cette modelisation sert de base conceptuelle aux predicats Prolog de
`prolog/knowledge_base.pl` et aux regles de detection de `prolog/rules.pl`.

---

## 1. Taxonomie des concepts

### 1.1 Acteurs

```text
Acteur ⊑ ⊤
Citoyen ⊑ Acteur
AgentPublic ⊑ Acteur
Promoteur ⊑ Acteur
Notaire ⊑ Acteur
```

Les acteurs representent les personnes ou entites impliquees dans les
transactions foncieres: citoyens, agents publics, promoteurs et notaires.

### 1.2 Parcelles

```text
Parcelle ⊑ ⊤
ParcelleUrbaine ⊑ Parcelle
ParcelleRurale ⊑ Parcelle
ParcelleUrbaine ⊓ ParcelleRurale ⊑ ⊥
```

### 1.3 Affectations et dossiers

```text
Affectation ⊑ ⊤
Attribution ⊑ Affectation
Revente ⊑ Affectation
Heritage ⊑ Affectation

Dossier ⊑ ⊤
DossierActif ⊑ Dossier
DossierSuspect ⊑ Dossier
```

### 1.4 Liens sociaux

```text
LienSocial ⊑ ⊤
LienFamilial ⊑ LienSocial
LienProfessionnel ⊑ LienSocial
LienFinancier ⊑ LienSocial
```

---

## 2. Roles et relations

Les roles sont traduits en predicats Prolog:

```text
possede(Acteur, Parcelle)
traite(AgentPublic, Dossier)
beneficiaire(Acteur, Dossier)
vendA(Vendeur, Acheteur, Parcelle, Date, Prix)
achete(Acheteur, Parcelle, Date, Prix)
partageTelephone(Acteur, Acteur)
partageAdresse(Acteur, Acteur)
partageIBAN(Acteur, Acteur)
lienFamilial(Acteur, Acteur)
lienProfessionnel(Acteur, Acteur)
lienFinancier(Acteur, Acteur)
```

Proprietes attendues:

```text
partageTelephone, partageAdresse, partageIBAN : roles symetriques
lienFamilial : role symetrique
vendA : role irreflexif
traite : role controle par les contraintes d'integrite
```

---

## 3. Axiomes de detection

### A1 - Accaparement urbain

```text
Citoyen ⊓ (≥4 possede.ParcelleUrbaine) ⊑ AccapareurUrbain
```

Un citoyen possedant plusieurs parcelles urbaines est classe comme acteur a
surveiller pour concentration fonciere.

### A2 - Multipropriete excessive

```text
Citoyen ⊓ (≥6 possede.Parcelle) ⊑ MultiproprietaireSuspect
```

Cette regle correspond a `regle_a1_multipropriete/1`.

### A3 - Accaparement familial

```text
Citoyen ⊓ ∃lienFamilial.(≥1 possede.Parcelle) ⊓
(≥8 possedeFamille.Parcelle) ⊑ AccaparementFamilial
```

Les possessions directes et celles des proches sont cumulees.

### A4 - Monopole foncier local

```text
Acteur ⊓ (partZone(Acteur, Zone) > 0.30) ⊑ MonopoleFoncier
```

L'acteur detient plus de 30% des parcelles connues dans une zone.

### B1 - Revente ultra-rapide

```text
Acteur ⊓ ∃vendA.Parcelle ⊓ delaiRevente < 90 ⊑ ReventeUltraRapide
```

### B2 - Plus-value anormale

```text
Acteur ⊓ ∃vendA.Parcelle ⊓ ratioPlusValue > 1.0 ⊑ Speculation
```

### B3 - Non-mise en valeur

```text
Acteur ⊓ ∃achete.Parcelle ⊓ ¬MiseEnValeur ⊓ dureePossession > 3 ans
⊑ NonMiseEnValeurSuspecte
```

### B4 - Transaction suspecte

```text
Acteur ⊓ ∃vendA.Parcelle ⊓ prixVente > 2 × valeurMarche
⊑ TransactionSuspecte
```

### C1 - Auto-attribution

```text
AgentPublic ⊓ ∃traite.Dossier ⊓ beneficiaire(AgentPublic, Dossier)
⊑ ConflitInteretDirect
```

### C2 - Traitement familial

```text
AgentPublic ⊓ ∃traite.Dossier ⊓ ∃lienFamilial.Beneficiaire
⊑ ConflitInteretFamilial
```

### C3 - Favoritisme repetitif

```text
AgentPublic ⊓ (≥4 traite.DossierPourMemeBeneficiaire)
⊑ FavoritismeRepetitif
```

### C4 - Conflit indirect professionnel

```text
AgentPublic ⊓ ∃traite.Dossier ⊓ ∃lienProfessionnel.Beneficiaire
⊑ ConflitInteretIndirect
```

### D1 - Prete-nom par telephone

```text
Acteur ⊓ ∃partageTelephone.Acteur ⊓ ∃possede.ParcelleCommune
⊑ SuspectPreteNom
```

### D2 - Prete-nom par adresse

```text
Acteur ⊓ ∃partageAdresse.Acteur ⊓ ∃possede.ParcelleCommune
⊑ SuspectPreteNom
```

### D3 - Transaction circulaire

```text
ActeurA vendA ActeurB ∧ ActeurB vendA ActeurC ∧ ActeurC vendA ActeurA
⊑ TransactionCirculaire
```

### D4 - Partage d'IBAN suspect

```text
Acteur ⊓ ∃partageIBAN.Acteur ⊓ ∃possede.ParcelleCommune
⊑ ReseauFinancierSuspect
```

---

## 4. Contraintes d'integrite

```text
CI-1  AgentPublic ne traite pas son propre dossier.
CI-2  Un citoyen ordinaire ne depasse pas 3 parcelles urbaines.
CI-3  Une parcelle ne doit pas avoir plusieurs proprietaires non justifies.
CI-4  Un notaire ne doit pas etre beneficiaire d'un dossier qu'il traite.
CI-5  Telephone partage + parcelle commune implique suspicion de prete-nom.
CI-6  DateVente doit etre posterieure a DateAchat.
CI-7  Un promoteur doit posseder au moins une parcelle declaree.
CI-8  Un dossier suspect ne doit pas rester actif sans controle.
```

---

## 5. Correspondance avec le projet

| Element DL | Predicat Prolog |
| --- | --- |
| AccapareurUrbain | `accapareur_urbain/1`, `regle_a3_concentration_urbaine/1` |
| MultiproprietaireSuspect | `regle_a1_multipropriete/1` |
| AccaparementFamilial | `regle_a2_accaparement_familial/1` |
| MonopoleFoncier | `regle_a4_monopole_foncier/2` |
| ReventeUltraRapide | `regle_b1_revente_ultra_rapide/1` |
| Speculation | `regle_b2_plus_value_anormale/1` |
| ConflitInteretDirect | `regle_c1_auto_attribution/1` |
| ConflitInteretFamilial | `regle_c2_traitement_familial/1` |
| PreteNom | `regle_d1_prete_nom_telephone/2`, `regle_d2_prete_nom_adresse/2` |
| TransactionCirculaire | `regle_d3_transaction_circulaire/3` |
| ReseauFinancierSuspect | `regle_d4_partage_iban_suspect/2` |