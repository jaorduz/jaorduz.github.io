from pathlib import Path
import csv
import bibtexparser

BASE_DIR = Path(__file__).resolve().parent
BIB_FILE = BASE_DIR / "pubs.bib"
CSV_FILE = BASE_DIR / "publications.csv"

FIELDS = [
    "id",
    "entry_type",
    "title",
    "author",
    "year",
    "journal",
    "booktitle",
    "publisher",
    "doi",
    "url",
    "pdf",
    "abstract",
]

def clean(value):
    if value is None:
        return ""
    return " ".join(str(value).replace("\n", " ").split())

with open(BIB_FILE, encoding="utf-8") as bibtex_file:
    bib_database = bibtexparser.load(bibtex_file)

with open(CSV_FILE, "w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=FIELDS)
    writer.writeheader()

    for entry in bib_database.entries:
        row = {
            "id": entry.get("ID", ""),
            "entry_type": entry.get("ENTRYTYPE", ""),
        }

        for field in FIELDS:
            if field not in row:
                row[field] = clean(entry.get(field, ""))

        writer.writerow(row)

print(f"Created: {CSV_FILE}")
print(f"Entries converted: {len(bib_database.entries)}")
