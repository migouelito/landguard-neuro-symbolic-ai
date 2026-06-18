"""
LANDGUARD - SCRIPT D'ENTRAÎNEMENT ET DE TEST DEEPPROBLOG
Fichier: train_and_test.py
"""

import torch
import subprocess
import os
from neural_model import (
    CLASSES,
    FEATURE_COLUMNS,
    SimpleFraudNet,
    load_dataset_training_data,
    train_model,
)

def main():
    print("=" * 50)
    print("LANDGUARD - PARTIE 4: DEEPPROBLOG")
    print("=" * 50)
    
    # 1. Entraîner le modèle neuronal
    print("\n[1] Entraînement du modèle neuronal...")
    model = train_model()
    
    # 2. Tester les prédictions
    print("\n[2] Test des prédictions neuronales...")
    
    x_train, _, df = load_dataset_training_data()
    model.eval()
    for index, row in df.head(5).iterrows():
        tensor = x_train[index].unsqueeze(0)
        with torch.no_grad():
            pred = model(tensor)
            classe_id = torch.argmax(pred[0]).item()
            prob = pred[0][classe_id].item()
        print(f"  {row['nom']}: {CLASSES[classe_id]} (prob: {prob:.2f})")
    
    # 3. Lancer Prolog avec DeepProbLog
    print("\n[3] Exécution du raisonnement neuro-symbolique...")
    
    prolog_script = """
    :- [deepproblog_model].
    main.
    """
    
    # Sauvegarder le script temporaire
    with open("temp_run.pl", "w") as f:
        f.write(prolog_script)
    
    # Exécuter SWI-Prolog
    result = subprocess.run(
        ["swipl", "-q", "-s", "temp_run.pl", "-g", "main, halt"],
        capture_output=True,
        text=True
    )
    
    print(result.stdout)
    if result.stderr:
        print("Erreurs:", result.stderr)
    
    # Nettoyer
    os.remove("temp_run.pl")
    
    print("\n[4] Partie 4 terminée avec succès !")

if __name__ == "__main__":
    main()
