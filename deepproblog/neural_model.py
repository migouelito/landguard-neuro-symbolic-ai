"""
LANDGUARD - MODULE NEURONAL POUR DEEPPROBLOG
Partie 4: Réseau de neurones pour la détection de fraude foncière
Fichier: neural_model.py
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import pandas as pd
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT_DIR / "data" / "dataset.csv"
MODEL_FILE = Path(__file__).resolve().parent / "model_weights.pth"

class FraudDetectorNet(nn.Module):
    """
    Réseau de neurones pour la détection de fraude foncière
    
    Entrées (7 caractéristiques):
    - nb_parcelles: nombre de parcelles possédées
    - frequence_revente: nombre de reventes par an
    - ratio_plus_value: (prix_vente - prix_achat) / prix_achat
    - nb_liens_reseau: nombre de connexions suspectes
    - partage_telephone: 0 ou 1
    - age_premier_achat: âge lors du premier achat
    - nb_dossiers_traites: nombre de dossiers traités (pour agents)
    
    Sorties (4 classes):
    - STANDARD (0): comportement normal
    - ATYPIQUE (1): comportement inhabituel
    - SPECULATEUR (2): spéculation foncière
    - FRAUDEUR (3): fraude probable
    """
    
    def __init__(self, input_dim=7, hidden_dim=64, output_dim=4):
        super(FraudDetectorNet, self).__init__()
        
        self.fc1 = nn.Linear(input_dim, hidden_dim)
        self.bn1 = nn.BatchNorm1d(hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, hidden_dim // 2)
        self.bn2 = nn.BatchNorm1d(hidden_dim // 2)
        self.fc3 = nn.Linear(hidden_dim // 2, output_dim)
        
        self.dropout = nn.Dropout(0.2)
        
    def forward(self, x):
        # Première couche
        x = F.relu(self.fc1(x))
        x = self.bn1(x)
        x = self.dropout(x)
        
        # Deuxième couche
        x = F.relu(self.fc2(x))
        x = self.bn2(x)
        x = self.dropout(x)
        
        # Couche de sortie (softmax pour distribution de probabilité)
        x = self.fc3(x)
        x = F.softmax(x, dim=-1)
        
        return x


class SimpleFraudNet(nn.Module):
    """
    Version simplifiée pour un entraînement plus rapide
    """
    
    def __init__(self, input_dim=7, output_dim=4):
        super(SimpleFraudNet, self).__init__()
        self.net = nn.Sequential(
            nn.Linear(input_dim, 32),
            nn.ReLU(),
            nn.Linear(32, 16),
            nn.ReLU(),
            nn.Linear(16, output_dim),
            nn.Softmax(dim=-1)
        )
    
    def forward(self, x):
        return self.net(x)


# Dictionnaire des classes
CLASSES = ['standard', 'atypique', 'speculateur', 'fraudeur']
CLASS_TO_ID = {c: i for i, c in enumerate(CLASSES)}
TYPE_TO_CLASS = {
    'standard': 'standard',
    'limite': 'atypique',
    'speculation': 'speculateur',
    'accaparement': 'fraudeur',
    'fraude_sophistiquee': 'fraudeur',
}
FEATURE_COLUMNS = [
    'nb_parcelles',
    'frequence_revente',
    'plus_value',
    'nb_liens_reseau',
    'partage_telephone',
    'age_premier_achat',
    'nb_dossiers_traites',
]


def extract_features(person_data):
    """
    Extrait les caractéristiques d'une personne sous forme de tenseur
    
    Args:
        person_data: dict avec les clés:
            - nb_parcelles
            - frequence_revente  
            - ratio_plus_value
            - nb_liens_reseau
            - partage_telephone
            - age_premier_achat
            - nb_dossiers_traites
    
    Returns:
        torch.Tensor de shape (1, 7)
    """
    features = [
        person_data.get('nb_parcelles', 0.0),
        person_data.get('frequence_revente', 0.0),
        person_data.get('ratio_plus_value', 0.0),
        person_data.get('nb_liens_reseau', 0.0),
        float(person_data.get('partage_telephone', 0)),
        person_data.get('age_premier_achat', 0.0),
        person_data.get('nb_dossiers_traites', 0.0)
    ]
    
    return torch.tensor(features, dtype=torch.float32).unsqueeze(0)


def predict(model, features):
    """
    Effectue une prédiction avec le modèle
    
    Returns:
        tuple: (classe_predite, probabilités)
    """
    model.eval()
    with torch.no_grad():
        output = model(features)
        prob = output[0]
        classe_id = torch.argmax(prob).item()
        return CLASSES[classe_id], prob.numpy()


def load_dataset_training_data(dataset_path=DATA_FILE):
    """Charge data/dataset.csv et le transforme en tenseurs d'entraînement."""
    df = pd.read_csv(dataset_path)
    missing = [column for column in FEATURE_COLUMNS + ['type'] if column not in df.columns]
    if missing:
        raise ValueError(f"Colonnes manquantes dans {dataset_path}: {missing}")

    labels = df['type'].map(TYPE_TO_CLASS)
    if labels.isna().any():
        unknown = sorted(df.loc[labels.isna(), 'type'].unique())
        raise ValueError(f"Types inconnus pour l'entraînement neuronal: {unknown}")

    features = df[FEATURE_COLUMNS].astype('float32').copy()
    means = features.mean()
    stds = features.std().replace(0, 1)
    features = (features - means) / stds

    x_train = torch.tensor(features.values, dtype=torch.float32)
    y_train = torch.tensor([CLASS_TO_ID[label] for label in labels], dtype=torch.long)
    return x_train, y_train, df


def train_model(dataset_path=DATA_FILE, epochs=300):
    """Entraîne le modèle sur data/dataset.csv."""
    print("=== ENTRAÎNEMENT DU MODÈLE NEURONAL SUR dataset.csv ===")
    X_train, y_train, df = load_dataset_training_data(dataset_path)
    print(f"Cas d'entraînement: {len(df)}")
    print(df['type'].value_counts().to_string())

    model = SimpleFraudNet(input_dim=7, output_dim=4)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

    for epoch in range(epochs):
        optimizer.zero_grad()
        output = model(X_train)
        loss = criterion(output, y_train)
        loss.backward()
        optimizer.step()

        if epoch % 50 == 0:
            print(f"Epoch {epoch}, Loss: {loss.item():.4f}")

    print("Entraînement terminé !")
    torch.save(model.state_dict(), MODEL_FILE)
    print(f"Modèle sauvegardé dans {MODEL_FILE}")

    with torch.no_grad():
        predictions = torch.argmax(model(X_train), dim=1)
        accuracy = (predictions == y_train).float().mean().item()
    print(f"Exactitude sur dataset.csv: {accuracy:.2%}")

    print("\n=== EXEMPLES DU DATASET ===")
    for _, row in df.head(5).iterrows():
        raw = row[FEATURE_COLUMNS].astype('float32')
        normalized = (raw - df[FEATURE_COLUMNS].astype('float32').mean()) / df[FEATURE_COLUMNS].astype('float32').std().replace(0, 1)
        tensor = torch.tensor([normalized.values], dtype=torch.float32)
        pred = model(tensor)
        classe_id = torch.argmax(pred[0]).item()
        prob = pred[0][classe_id].item()
        print(f"{row['nom']}: {CLASSES[classe_id]} (probabilité: {prob:.2f})")

    return model


if __name__ == "__main__":
    train_model()
