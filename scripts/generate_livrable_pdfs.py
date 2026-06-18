"""Generate lightweight PDF deliverables without external dependencies."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def pdf_escape(text):
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def make_text_page(title, lines):
    commands = [
        "BT",
        "/F1 18 Tf",
        "50 790 Td",
        f"({pdf_escape(title)}) Tj",
        "/F1 10 Tf",
        "0 -28 Td",
    ]
    for line in lines:
        commands.append(f"({pdf_escape(line[:105])}) Tj")
        commands.append("0 -14 Td")
    commands.append("ET")
    return "\n".join(commands)


def make_diagram_page():
    boxes = [
        (210, 760, 180, 32, "LandGuard Neuro-Symbolic AI"),
        (45, 675, 125, 32, "Description Logic"),
        (235, 675, 125, 32, "SWI-Prolog"),
        (425, 675, 125, 32, "ProbLog"),
        (135, 575, 125, 32, "PyTorch"),
        (335, 575, 125, 32, "DeepProbLog"),
        (210, 465, 180, 32, "XAI / Rapport consolide"),
    ]
    commands = [
        "BT /F1 18 Tf 170 815 Td (Diagramme conceptuel LandGuard AI) Tj ET",
        "0.1 0.1 0.1 RG",
    ]
    for x, y, w, h, label in boxes:
        commands.append("0.92 0.96 1 rg")
        commands.append(f"{x} {y} {w} {h} re B")
        commands.append("0 0 0 rg")
        commands.append("BT /F1 10 Tf")
        commands.append(f"{x + 8} {y + 13} Td ({pdf_escape(label)}) Tj")
        commands.append("ET")
    commands.extend(
        [
            "0 0 0 RG",
            "300 760 m 108 707 l S",
            "300 760 m 298 707 l S",
            "300 760 m 488 707 l S",
            "298 675 m 198 607 l S",
            "488 675 m 398 607 l S",
            "198 575 m 300 497 l S",
            "398 575 m 300 497 l S",
            "0 0 0 rg",
            "BT /F1 10 Tf 50 405 Td (Flux: dataset.csv -> modele neuronal -> regles symboliques/probabilistes -> decision explicable.) Tj ET",
            "BT /F1 10 Tf 50 383 Td (Concepts: Acteur, Parcelle, Affectation, Dossier, LienSocial.) Tj ET",
            "BT /F1 10 Tf 50 363 Td (Relations: possede, traite, beneficiaire, vendA, partageTelephone, partageAdresse.) Tj ET",
        ]
    )
    return "\n".join(commands)


def write_pdf(path, pages):
    objects = []
    page_ids = []

    def add_object(body):
        objects.append(body)
        return len(objects)

    catalog_id = add_object("<< /Type /Catalog /Pages 2 0 R >>")
    pages_id = add_object("PLACEHOLDER")
    font_id = add_object("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

    for content in pages:
        stream = content.encode("latin-1", errors="replace")
        content_id = add_object(
            f"<< /Length {len(stream)} >>\nstream\n{content}\nendstream"
        )
        page_id = add_object(
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
            f"/Resources << /Font << /F1 {font_id} 0 R >> >> "
            f"/Contents {content_id} 0 R >>"
        )
        page_ids.append(page_id)

    objects[pages_id - 1] = (
        f"<< /Type /Pages /Kids [{' '.join(f'{pid} 0 R' for pid in page_ids)}] "
        f"/Count {len(page_ids)} >>"
    )

    output = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for index, body in enumerate(objects, start=1):
        offsets.append(len(output))
        output.extend(f"{index} 0 obj\n{body}\nendobj\n".encode("latin-1"))
    xref_offset = len(output)
    output.extend(f"xref\n0 {len(objects) + 1}\n".encode("latin-1"))
    output.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        output.extend(f"{offset:010d} 00000 n \n".encode("latin-1"))
    output.extend(
        (
            "trailer\n"
            f"<< /Size {len(objects) + 1} /Root {catalog_id} 0 R >>\n"
            "startxref\n"
            f"{xref_offset}\n"
            "%%EOF\n"
        ).encode("latin-1")
    )
    path.write_bytes(output)


REPORT_SECTIONS = [
    (
        "1. Introduction",
        [
            "LandGuard vise la detection explicable de fraudes foncieres dans un contexte administratif.",
            "Le systeme combine modelisation symbolique, probabilites et prediction neuronale.",
            "La priorite est de produire une decision justifiable et exploitable par une institution.",
        ],
    ),
    (
        "2. Contexte et problematique",
        [
            "Les risques couverts sont l'accaparement, la speculation, les conflits d'interets et les reseaux de prete-noms.",
            "Une approche purement statistique manque d'explicabilite; une approche purement symbolique gere mal l'incertitude.",
            "Le projet assemble donc plusieurs couches de raisonnement complementaires.",
        ],
    ),
    (
        "3. Logique de Description",
        [
            "La TBox formalise Acteur, Citoyen, AgentPublic, Promoteur, Notaire, ParcelleUrbaine et ParcelleRurale.",
            "Les roles principaux sont possede, traite, beneficiaire, lienFamilial, vendA, partageTelephone et partageAdresse.",
            "Dix axiomes structurent les profils de risque, dont AccapareurUrbain et ConflitInteret.",
        ],
    ),
    (
        "4. Contraintes d'integrite",
        [
            "Huit contraintes encadrent les violations critiques: auto-traitement, maximum de parcelles et double propriete.",
            "Les contraintes servent a produire des alertes deterministes et des justifications normees.",
        ],
    ),
    (
        "5. Base Prolog",
        [
            "La base de connaissances declare les concepts, roles, faits terrain et predicats de verification.",
            "Les regles Prolog materialisent les axiomes DL et les controles metier.",
        ],
    ),
    (
        "6. Moteur symbolique",
        [
            "Seize regles sont reparties en quatre familles: accaparement, speculation, conflits d'interets, reseaux/prete-noms.",
            "Les fichiers principaux sont prolog/knowledge_base.pl, prolog/rules.pl, prolog/inference_engine.pl et prolog/explainability.pl.",
            "Le moteur d'inference orchestre l'analyse par individu, relation et cas de dataset.",
        ],
    ),
    (
        "7. Explicabilite XAI",
        [
            "Chaque regle critique possede une variante XAI qui journalise l'identifiant de regle, les variables et la justification.",
            "Les traces peuvent etre exportees vers JSON pour audit et restitution.",
        ],
    ),
    (
        "8. ProbLog",
        [
            "Les clauses incertaines utilisent la syntaxe p::predicate afin de quantifier les soupcons non certains.",
            "Les requetes evaluent prete_nom, speculateur, conflit_interet, blanchiment_foncier et fraude_composite.",
        ],
    ),
    (
        "9. Classification du risque",
        [
            "Les probabilites sont interpretees sur quatre niveaux: faible, moyen, eleve et critique.",
            "Cette echelle simplifie la priorisation administrative des dossiers.",
        ],
    ),
    (
        "10. Module neuronal",
        [
            "Le modele PyTorch prend sept caracteristiques: parcelles, reventes, plus-value, liens reseau, telephone, age et dossiers.",
            "Il predit quatre classes: standard, atypique, speculateur et fraudeur.",
        ],
    ),
    (
        "11. Couche DeepProbLog",
        [
            "La specification DeepProbLog introduit nn(fraud_model, [X], Y, [standard, atypique, speculateur, fraudeur]).",
            "Les predictions neuronales sont combinees avec les contraintes symboliques pour produire fraude(X).",
        ],
    ),
    (
        "12. Pipeline",
        [
            "main.py charge le dataset, genere les faits Prolog, lance les analyses disponibles et produit rapport_final.json.",
            "Le pipeline degrade proprement si SWI-Prolog ou PyTorch sont absents de l'environnement local.",
            "La plateforme Streamlit streamlit_app.py facilite la demonstration: KPI, filtres, fiches XAI, pipeline et livrables.",
        ],
    ),
    (
        "13. Dataset",
        [
            "Le dataset final contient 200 cas synthetiques repartis en cinq categories de risque.",
            "Les categories couvrent standards, speculation, accaparement, cas limites et fraudes sophistiquees.",
        ],
    ),
    (
        "14. Tests et validation",
        [
            "Les tests couvrent les regles Prolog, les requetes ProbLog et un parcours end-to-end Python.",
            "Les tests dependants de SWI-Prolog ou ProbLog sont ignores proprement si les outils ne sont pas installes.",
            "Le pipeline genere 60 alertes elevees/critiques et 20 detections moyennes dans rapport_final.json.",
        ],
    ),
    (
        "15. Limites et perspectives",
        [
            "La qualite finale dependra d'un entrainement neuronal plus realiste et de donnees institutionnelles annotees.",
            "Les prochaines ameliorations concernent la calibration probabiliste et l'integration DeepProbLog complete.",
        ],
    ),
]


def main():
    write_pdf(ROOT / "diagramme_concepts.pdf", [make_diagram_page()])
    pages = [make_text_page(title, lines) for title, lines in REPORT_SECTIONS]
    write_pdf(ROOT / "rapport_projet.pdf", pages)
    print("Generated diagramme_concepts.pdf and rapport_projet.pdf")


if __name__ == "__main__":
    main()
