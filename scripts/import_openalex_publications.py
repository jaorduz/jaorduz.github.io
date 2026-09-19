#!/usr/bin/env python3
"""Import an author's DOI-indexed works from OpenAlex into Jekyll."""

import argparse
import json
import re
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path


def get_json(url):
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "jaorduz.github.io publication importer"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def yaml_string(value):
    return json.dumps(value, ensure_ascii=False)


def slugify(title):
    normalized = unicodedata.normalize("NFKD", title)
    ascii_title = normalized.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "-", ascii_title.lower()).strip("-")[:120]


def find_author(orcid):
    encoded_orcid = urllib.parse.quote("Javier Orduz", safe="")
    data = get_json(
        f"https://api.openalex.org/authors?search={encoded_orcid}&per-page=25"
    )
    for author in data.get("results", []):
        if author.get("orcid", "").rstrip("/").endswith(orcid):
            return author["id"].rsplit("/", 1)[-1], author["display_name"]
    raise RuntimeError(f"OpenAlex author not found for ORCID {orcid}")


def publication_date(work):
    return work.get("publication_date") or "1900-01-01"


def venue_name(work):
    source = (work.get("primary_location") or {}).get("source") or {}
    return source.get("display_name") or ""


def authors_text(work):
    names = []
    for authorship in work.get("authorships", []):
        author = authorship.get("author") or {}
        if author.get("display_name"):
            names.append(author["display_name"])
    return ", ".join(names) if names else "Unknown author"


def render_publication(work, doi):
    title = (work.get("title") or "Untitled publication").strip()
    date = publication_date(work)
    venue = venue_name(work)
    authors = authors_text(work)
    doi_url = f"https://doi.org/{doi}"
    scholar_url = "https://scholar.google.com/scholar?q=" + urllib.parse.quote(title)
    citation = f'{authors}. "{title}."'
    if venue:
        citation += f" {venue},"
    citation += f" {date[:4]}. DOI: {doi}."
    slug = slugify(title)
    return "\n".join(
        [
            "---",
            f"title: {yaml_string(title)}",
            "collection: publications",
            f"permalink: /publication/{date}-{slug}",
            f"excerpt: {yaml_string('DOI: ' + doi)}",
            f"date: {date}",
            f"venue: {yaml_string(venue)}",
            f"paperurl: {yaml_string(doi_url)}",
            f"citation: {yaml_string(citation)}",
            "---",
            "",
            f"[Access paper via DOI]({doi_url}){{:target=\"_blank\"}}",
            "",
            f"Use [Google Scholar]({scholar_url}){{:target=\"_blank\"}} for related citations.",
            "",
        ]
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--orcid", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    author_id, author_name = find_author(args.orcid)
    works_url = (
        "https://api.openalex.org/works?filter="
        f"author.id:{author_id},has_doi:true&sort=publication_date:desc&per-page=100"
    )
    works = get_json(works_url).get("results", [])
    args.output_dir.mkdir(parents=True, exist_ok=True)
    imported = 0

    for work in works:
        doi_url = work.get("doi") or ""
        doi = doi_url.rsplit("doi.org/", 1)[-1].strip().rstrip(".")
        if not doi:
            continue
        doi_marker = doi.lower()
        target = next(
            (
                path
                for path in args.output_dir.glob("*.md")
                if doi_marker in path.read_text(encoding="utf-8").lower()
            ),
            None,
        )
        title = (work.get("title") or "Untitled publication").strip()
        date = publication_date(work)
        if target is None:
            target = args.output_dir / f"{date}-{slugify(title)}.md"
        target.write_text(render_publication(work, doi), encoding="utf-8")
        imported += 1
        print(f"{date}\t{target.name}\t{doi}")

    print(f"Imported {imported} DOI-indexed works for {author_name} ({author_id}).")


if __name__ == "__main__":
    main()