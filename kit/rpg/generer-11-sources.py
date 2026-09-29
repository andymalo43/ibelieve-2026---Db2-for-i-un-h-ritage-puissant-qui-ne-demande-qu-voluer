"""Régénère 11-sources.sql à partir des fichiers de sources/ (kit iBelieve 2026, partie RPG).

    python generer-11-sources.py

Pourquoi : charger les sources dans des fichiers source physiques par de simples INSERT
SQL, depuis ACS, sans rien téléverser dans l'IFS. Le RPG III impose de toute façon un
fichier source (CRTRPGPGM ne lit pas l'IFS), et ses colonnes sont signifiantes :
chaque ligne est recopiée telle quelle, espaces compris.
"""
from pathlib import Path

ICI = Path(__file__).resolve().parent
# (fichier source, type de membre) ; le RPG III va dans KITRPGSRC (80 col.), le reste dans KITRPGLSRC
SOURCES = [
    ("CALCTAR3.rpg", "KITRPGSRC", "RPG"),
    ("CALCTARIF.rpgle", "KITRPGLSRC", "RPGLE"),
    ("CTLENCOURS.rpgle", "KITRPGLSRC", "RPGLE"),
    ("CALCTARA.rpgle", "KITRPGLSRC", "RPGLE"),
    ("CALCDEVIS.rpgle", "KITRPGLSRC", "SQLRPGLE"),
    ("VALDEVIS.rpgle", "KITRPGLSRC", "SQLRPGLE"),
    ("GENFACT.rpgle", "KITRPGLSRC", "SQLRPGLE"),
]


def litteral(ligne: str) -> str:
    return "'" + ligne.replace("'", "''") + "'"


def main() -> None:
    sortie = [
        "-- =====================================================================",
        "-- Kit iBelieve 2026 — RPG — 11. Charger les sources dans des fichiers source",
        "-- GÉNÉRÉ par generer-11-sources.py à partir de sources/ : ne pas modifier à la main.",
        "-- ÉCRIT dans votre bibliothèque : fichiers source KITRPGSRC (RPG III) et KITRPGLSRC (RPG IV),",
        "-- un membre par programme. Noms propres au kit : vos QRPGSRC / QRPGLESRC ne sont pas touchés.",
        "-- =====================================================================",
        "",
        "SET SCHEMA VOTREBIB;",
        "",
        "-- Les deux fichiers source (ignorés s'ils existent déjà)",
        "BEGIN",
        "  DECLARE V_EXISTE INTEGER DEFAULT 0;",
        "  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET V_EXISTE = 1;",
        "  CALL QSYS2.QCMDEXC('CRTSRCPF FILE(' CONCAT CURRENT SCHEMA CONCAT '/KITRPGSRC) RCDLEN(92)"
        " TEXT(''Kit iBelieve 2026 - RPG III'')');",
        "  CALL QSYS2.QCMDEXC('CRTSRCPF FILE(' CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC) RCDLEN(112)"
        " TEXT(''Kit iBelieve 2026 - RPG IV'')');",
        "END;",
    ]
    for nom, fichier, type_ in SOURCES:
        membre = nom.split(".")[0]
        lignes = (ICI / "sources" / nom).read_text(encoding="utf-8").rstrip("\n").split("\n")
        sortie += [
            "",
            f"-- {membre} ({type_}, {len(lignes)} lignes)",
            "BEGIN",
            "  DECLARE V_ABSENT INTEGER DEFAULT 0;",
            "  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET V_ABSENT = 1;",
            f"  CALL QSYS2.QCMDEXC('RMVM FILE(' CONCAT CURRENT SCHEMA CONCAT '/{fichier}) MBR({membre})');",
            "END;",
            f"CALL QSYS2.QCMDEXC('ADDPFM FILE(' CONCAT CURRENT SCHEMA CONCAT '/{fichier}) MBR({membre})"
            f" SRCTYPE({type_})');",
            f"CREATE OR REPLACE ALIAS KIT_MEMBRE FOR {fichier} ({membre});",
            "INSERT INTO KIT_MEMBRE (SRCSEQ, SRCDAT, SRCDTA) VALUES",
        ]
        valeurs = [f"  ({i}.00, 0, {litteral(l)})" for i, l in enumerate(lignes, 1)]
        sortie.append(",\n".join(valeurs) + ";")
        sortie.append("DROP ALIAS KIT_MEMBRE;")
    sortie += [
        "",
        "-- Vérification : un membre par programme, avec son nombre de lignes",
        "SELECT SYSTEM_TABLE_NAME AS FICHIER, SYSTEM_TABLE_MEMBER AS MEMBRE, SOURCE_TYPE, NUMBER_ROWS",
        "  FROM QSYS2.SYSPARTITIONSTAT",
        " WHERE SYSTEM_TABLE_SCHEMA = CURRENT SCHEMA",
        "   AND SYSTEM_TABLE_NAME IN ('KITRPGSRC', 'KITRPGLSRC')",
        " ORDER BY FICHIER, MEMBRE;",
        "",
    ]
    (ICI / "11-sources.sql").write_text("\n".join(sortie), encoding="utf-8")


main()
