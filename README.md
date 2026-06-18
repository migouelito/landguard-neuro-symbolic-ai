# LandGuard-Neuro-Symbolic-AI
LandGuard Neuro-Symbolic AI – Système intelligent de régulation foncière combinant Description Logic, Prolog, ProbLog, DeepProbLog et PyTorch pour détecter les fraudes foncières, quantifier les risques et fournir des explications automatiques des décisions.

## Exécution locale

Le projet utilise le fichier [data/dataset.csv](data/dataset.csv) comme source de données principale. Le dataset contient 200 cas synthétiques équilibrés autour des scénarios standards, de spéculation, d'accaparement, de dossiers limites et de fraude sophistiquée.

Pour lancer tout le pipeline localement, avec génération des rapports et vérification Prolog quand les moteurs sont installés, utiliser :

```bash
bash scripts/run_local_pipeline.sh
```

Prérequis minimal : `python3` avec les dépendances Python. `swipl` et `problog` sont recommandés pour exécuter les moteurs symbolique et probabiliste ; le pipeline les ignore proprement s'ils ne sont pas présents.

Le script exécute :
- [main.py](main.py) pour produire le rapport consolidé,
- un smoke test Prolog sur les faits du dataset,
- une vérification de la présence des artefacts générés.

## Tests et livrables de validation

Tests disponibles :

```bash
python3 -m unittest tests/test_endtoend.py
swipl -q -s tests/test_prolog.pl
problog tests/test_probabilistic.pl
```

La partie ProbLog est définie dans [prolog/probabilistic_rules.pl](prolog/probabilistic_rules.pl) avec des clauses pondérées `p::regle`.
La démo neuro-symbolique exécutable sous SWI-Prolog reste dans [deepproblog/deepproblog_model.pl](deepproblog/deepproblog_model.pl), tandis que la spécification DeepProbLog stricte avec `nn(fraud_model, ...)` est fournie dans [deepproblog/deepproblog_model_spec.pl](deepproblog/deepproblog_model_spec.pl).

## Entraînement neuronal

Le modèle PyTorch lit directement les 200 lignes de [data/dataset.csv](data/dataset.csv), extrait les variables numériques et catégorielles, puis sauvegarde les poids dans [deepproblog/model_weights.pth](deepproblog/model_weights.pth).

```bash
.venv/bin/python deepproblog/neural_model.py
```

Si l'environnement virtuel n'existe pas encore, installer d'abord les dépendances :

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## Interface de démonstration

Pour la soutenance ou une démonstration rapide, lancer la plateforme Streamlit :

```bash
streamlit run streamlit_app.py
```

Alternative équivalente :

```bash
python3 demo_interface.py
```

L'interface permet de :
- visualiser les indicateurs clés du dataset Burkina,
- filtrer et rechercher les dossiers par type de risque,
- consulter une fiche explicable par dossier avec indices XAI,
- afficher le résumé du rapport consolidé,
- lancer le pipeline complet depuis la fenêtre,
- télécharger le CSV, les rapports et le diagramme conceptuel.
