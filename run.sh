#!/usr/bin/env bash

set -u

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EVENTS_DIR="$ROOT_DIR/_events"
CV_DIR="$ROOT_DIR/files/cv"
CV_DEST="$CV_DIR/javier-orduz-cv.pdf"

pause() {
  printf '\nPresiona Enter para continuar...'
  read -r _ || exit 0
}

open_in_editor() {
  file_path=$1

  if [ -n "${VISUAL:-}" ]; then
    "$VISUAL" "$file_path"
  elif [ -n "${EDITOR:-}" ]; then
    "$EDITOR" "$file_path"
  elif command -v code >/dev/null 2>&1; then
    code --wait "$file_path"
  else
    nano "$file_path"
  fi
}

list_events() {
  printf '\nEventos disponibles:\n'
  found=0

  for event_file in "$EVENTS_DIR"/*.md; do
    [ -f "$event_file" ] || continue
    found=1
    title=$(sed -n 's/^title: *"\(.*\)"/\1/p' "$event_file" | head -n 1)
    event_date=$(sed -n 's/^date: *//p' "$event_file" | head -n 1)
    event_type=$(sed -n 's/^type: *"\(.*\)"/\1/p' "$event_file" | head -n 1)
    printf '  %-28s %-10s %-12s %s\n' "$(basename "$event_file")" "${event_date:-sin fecha}" "${event_type:-sin tipo}" "${title:-sin título}"
  done

  [ "$found" -eq 1 ] || printf '  No hay eventos todavía.\n'
}

choose_event() {
  list_events
  printf '\nEscribe el nombre del archivo del evento: '
  if ! read -r event_name; then
    return 1
  fi

  case "$event_name" in
    *.md) ;;
    *) event_name="$event_name.md" ;;
  esac

  event_path="$EVENTS_DIR/$event_name"
  if [ ! -f "$event_path" ]; then
    printf 'No existe: %s\n' "$event_name" >&2
    return 1
  fi

}

update_cv() {
  printf '\nRuta del nuevo PDF [files/cv/JO_CV_Full.pdf]: '
  if ! read -r source_pdf; then
    return 1
  fi
  source_pdf=${source_pdf:-$CV_DIR/JO_CV_Full.pdf}

  case "$source_pdf" in
    /*) ;;
    *) source_pdf="$ROOT_DIR/$source_pdf" ;;
  esac

  if [ ! -f "$source_pdf" ]; then
    printf 'No existe el PDF: %s\n' "$source_pdf" >&2
    return 1
  fi

  if ! file "$source_pdf" | grep -q 'PDF document'; then
    printf 'El archivo no parece ser un PDF válido.\n' >&2
    return 1
  fi

  mkdir -p "$CV_DIR"
  cp "$source_pdf" "$CV_DEST"
  printf 'CV actualizado en files/cv/javier-orduz-cv.pdf\n'
}

create_event() {
  printf '\nNombre del archivo nuevo (sin .md): '
  if ! read -r event_name; then
    return 1
  fi
  event_name=${event_name%.md}

  case "$event_name" in
    ""|*/*|*..*)
      printf 'Nombre inválido. Usa solo letras, números, guiones y guiones bajos.\n' >&2
      return 1
      ;;
  esac

  event_path="$EVENTS_DIR/$event_name.md"
  if [ -e "$event_path" ]; then
    printf 'Ya existe: %s\n' "$event_path" >&2
    return 1
  fi

  cat > "$event_path" <<'EOF'
---
title: "Título del evento"
collection: events
layout: single
permalink: /events/YYYY/slug
date: YYYY-MM-DD
venue: "Lugar u organización"
location: "Ciudad, país"
type: "Organizing"
excerpt: "Resumen breve para la página de eventos."
author_profile: true
cta_label: "Visitar sitio oficial"
# external_url: "https://example.com"
image: "/images/event-image.jpg"
tags: ["Research", "Science"]
---

## Overview

Describe aquí el evento, su propósito y tu participación.
EOF

  open_in_editor "$event_path"
  printf 'Evento creado: %s\n' "$event_path"
}

edit_event() {
  choose_event || return 1
  open_in_editor "$event_path"
  printf 'Evento actualizado: %s\n' "$(basename "$event_path")"
}

delete_event() {
  choose_event || return 1
  printf '¿Borrar %s? Esta acción no se puede deshacer desde el menú [y/N]: ' "$(basename "$event_path")"
  if ! read -r confirmation; then
    return 1
  fi
  case "$confirmation" in
    y|Y|s|S)
      rm "$event_path"
      printf 'Evento borrado.\n'
      ;;
    *)
      printf 'Operación cancelada.\n'
      ;;
  esac
}

events_menu() {
  while true; do
    printf '\n=== Gestión de eventos ===\n'
    printf '1) Listar eventos\n'
    printf '2) Crear evento\n'
    printf '3) Modificar evento\n'
    printf '4) Borrar evento\n'
    printf '0) Volver\n'
    printf 'Selecciona una opción: '
    if ! read -r option; then
      return 0
    fi

    case "$option" in
      1) list_events; pause ;;
      2) create_event; pause ;;
      3) edit_event; pause ;;
      4) delete_event; pause ;;
      0) return ;;
      *) printf 'Opción no válida.\n' ;;
    esac
  done
}

validate_site() {
  if ! command -v bundle >/dev/null 2>&1; then
    printf 'Bundler no está instalado.\n' >&2
    return 1
  fi

  (cd "$ROOT_DIR" && bundle exec jekyll build --config _config.yml --trace)
}

show_status() {
  (cd "$ROOT_DIR" && git status --short)
}

add_or_update_publication() {
  printf '\nDOI o URL del paper: '
  if ! read -r publication_identifier; then
  return 1
  fi
  if [ -z "$publication_identifier" ]; then
  printf 'Debes proporcionar un DOI o una URL.\n' >&2
  return 1
  fi

  publication_path=$(python3 - "$publication_identifier" "$ROOT_DIR" <<'PY'
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

identifier, root = sys.argv[1:]
identifier = identifier.strip()
if identifier.startswith(("http://", "https://")):
  parsed = urllib.parse.urlparse(identifier)
  doi_match = re.search(r"10\.\d{4,9}/[-._;()/:A-Z0-9]+", identifier, re.IGNORECASE)
  doi = doi_match.group(0) if doi_match else parsed.path.strip("/")
else:
  doi = identifier
doi = urllib.parse.unquote(doi).strip().rstrip(".")
if doi.lower().startswith("doi:"):
  doi = doi[4:].strip()

if not doi or "/" not in doi:
  print("No parece un DOI válido.", file=sys.stderr)
  sys.exit(1)

api_url = "https://api.crossref.org/works/" + urllib.parse.quote(doi, safe="/")
request = urllib.request.Request(api_url, headers={"User-Agent": "jaorduz.github.io publication manager"})
try:
  with urllib.request.urlopen(request, timeout=20) as response:
    metadata = json.load(response)["message"]
except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, KeyError, json.JSONDecodeError) as error:
  print(f"No se pudo consultar Crossref: {error}", file=sys.stderr)
  sys.exit(1)

def first_value(values, default=""):
  return values[0] if values else default

title = first_value(metadata.get("title"), "Untitled publication").strip()
venue = first_value(metadata.get("container-title"), metadata.get("publisher", "")).strip()
authors = []
for author in metadata.get("author", []):
  name = " ".join(part for part in (author.get("given", ""), author.get("family", "")) if part).strip()
  if name:
    authors.append(name)

date_parts = []
for key in ("published-print", "published-online", "issued", "created"):
  date_parts = metadata.get(key, {}).get("date-parts", [])
  if date_parts:
    date_parts = date_parts[0]
    break
if date_parts:
  publication_date = "-".join(str(value).zfill(2) for value in date_parts)
  if len(date_parts) == 1:
    publication_date += "-01-01"
  elif len(date_parts) == 2:
    publication_date += "-01"
else:
  publication_date = str(date.today())

slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:120]
filename = f"{publication_date}-{slug}.md"
publications_dir = Path(root) / "_publications"
publications_dir.mkdir(parents=True, exist_ok=True)
doi_marker = doi.lower()
target = None
for candidate in publications_dir.glob("*.md"):
  if doi_marker in candidate.read_text(encoding="utf-8").lower():
    target = candidate
    break
if target is None:
  target = publications_dir / filename

def yaml_string(value):
  return json.dumps(value, ensure_ascii=False)

citation_authors = ", ".join(authors) if authors else "Unknown author"
citation = f"{citation_authors}. \"{title}.\""
if venue:
  citation += f" {venue},"
citation += f" {publication_date[:4]}."
doi_url = f"https://doi.org/{doi}"
scholar_url = "https://scholar.google.com/scholar?q=" + urllib.parse.quote(title)
content = "\n".join([
  "---",
  f"title: {yaml_string(title)}",
  "collection: publications",
  f"permalink: /publication/{publication_date}-{slug}",
  f"excerpt: {yaml_string('DOI: ' + doi)}",
  f"date: {publication_date}",
  f"venue: {yaml_string(venue)}",
  f"paperurl: {yaml_string(doi_url)}",
  f"citation: {yaml_string(citation)}",
  "---",
  "",
  f"[Access paper via DOI]({doi_url}){{:target=\"_blank\"}}",
  "",
  f"Use [Google Scholar]({scholar_url}){{:target=\"_blank\"}} for related citations.",
  "",
])
target.write_text(content, encoding="utf-8")
print(target)
PY
  ) || return 1

  printf 'Publicación generada en %s\n' "${publication_path#$ROOT_DIR/}"
  open_in_editor "$publication_path"
}

list_publications() {
  printf '\nPublicaciones disponibles:\n'
  found=0

  for publication_file in "$ROOT_DIR/_publications"/*.md; do
    [ -f "$publication_file" ] || continue
    found=1
    title=$(sed -n 's/^title: *"\(.*\)"/\1/p' "$publication_file" | head -n 1)
    publication_date=$(sed -n 's/^date: *//p' "$publication_file" | head -n 1)
    venue=$(sed -n 's/^venue: *"\(.*\)"/\1/p' "$publication_file" | head -n 1)
    printf '  %-72s %-10s %s (%s)\n' "$(basename "$publication_file")" "${publication_date:-sin fecha}" "${title:-sin título}" "${venue:-sin revista}"
  done

  [ "$found" -eq 1 ] || printf '  No hay publicaciones todavía.\n'
}

choose_publication() {
  list_publications
  printf '\nEscribe el nombre del archivo de la publicación: '
  if ! read -r publication_name; then
    return 1
  fi

  case "$publication_name" in
    *.md) ;;
    *) publication_name="$publication_name.md" ;;
  esac

  case "$publication_name" in
    ""|*/*|*..*)
      printf 'Nombre inválido.\n' >&2
      return 1
      ;;
  esac

  publication_path="$ROOT_DIR/_publications/$publication_name"
  if [ ! -f "$publication_path" ]; then
    printf 'No existe: %s\n' "$publication_name" >&2
    return 1
  fi
}

edit_publication() {
  choose_publication || return 1
  open_in_editor "$publication_path"
  printf 'Publicación actualizada: %s\n' "$(basename "$publication_path")"
}

delete_publication() {
  choose_publication || return 1
  printf '¿Borrar %s? Esta acción no se puede deshacer desde el menú [y/N]: ' "$(basename "$publication_path")"
  if ! read -r confirmation; then
    return 1
  fi
  case "$confirmation" in
    y|Y|s|S)
      rm "$publication_path"
      printf 'Publicación borrada.\n'
      ;;
    *)
      printf 'Operación cancelada.\n'
      ;;
  esac
}

publications_menu() {
  while true; do
    printf '\n=== Gestión de publicaciones ===\n'
    printf '1) Listar publicaciones\n'
    printf '2) Agregar o actualizar desde DOI/URL\n'
    printf '3) Modificar publicación manualmente\n'
    printf '4) Borrar publicación\n'
    printf '0) Volver\n'
    printf 'Selecciona una opción: '
    if ! read -r option; then
      return 0
    fi

    case "$option" in
      1) list_publications; pause ;;
      2) add_or_update_publication; pause ;;
      3) edit_publication; pause ;;
      4) delete_publication; pause ;;
      0) return ;;
      *) printf 'Opción no válida.\n' ;;
    esac
  done
}

import_orcid_publications() {
  printf '\nORCID [0000-0003-0279-7458]: '
  if ! read -r orcid; then
    return 1
  fi
  orcid=${orcid:-0000-0003-0279-7458}

  python3 "$ROOT_DIR/scripts/import_openalex_publications.py" \
    --orcid "$orcid" \
    --output-dir "$ROOT_DIR/_publications"
}

update_impact_metrics() {
  python3 "$ROOT_DIR/scripts/update_openalex_metrics.py" \
    --output "$ROOT_DIR/_data/metrics.yml"
}

list_teaching() {
  printf '\nCursos disponibles:\n'
  found=0

  for course_file in "$ROOT_DIR/_teaching"/*.md; do
    [ -f "$course_file" ] || continue
    found=1
    title=$(sed -n 's/^title: *"\(.*\)"/\1/p' "$course_file" | head -n 1)
    course_date=$(sed -n 's/^date: *//p' "$course_file" | head -n 1)
    course_type=$(sed -n 's/^type: *"\(.*\)"/\1/p' "$course_file" | head -n 1)
    printf '  %-34s %-10s %-20s %s\n' "$(basename "$course_file")" "${course_date:-sin fecha}" "${course_type:-sin tipo}" "${title:-sin título}"
  done

  [ "$found" -eq 1 ] || printf '  No hay cursos todavía.\n'
}

choose_teaching() {
  list_teaching
  printf '\nEscribe el nombre del archivo del curso: '
  if ! read -r course_name; then
    return 1
  fi

  case "$course_name" in
    *.md) ;;
    *) course_name="$course_name.md" ;;
  esac

  case "$course_name" in
    ""|*/*|*..*)
      printf 'Nombre inválido.\n' >&2
      return 1
      ;;
  esac

  course_path="$ROOT_DIR/_teaching/$course_name"
  if [ ! -f "$course_path" ]; then
    printf 'No existe: %s\n' "$course_name" >&2
    return 1
  fi
}

create_teaching() {
  printf '\nNombre del archivo nuevo (sin .md): '
  if ! read -r course_name; then
    return 1
  fi
  course_name=${course_name%.md}

  case "$course_name" in
    ""|*/*|*..*)
      printf 'Nombre inválido. Usa letras, números, guiones y guiones bajos.\n' >&2
      return 1
      ;;
  esac

  course_path="$ROOT_DIR/_teaching/$course_name.md"
  if [ -e "$course_path" ]; then
    printf 'Ya existe: %s\n' "$course_path" >&2
    return 1
  fi

  cat > "$course_path" <<'EOF'
---
title: "Course title"
collection: teaching
type: "Graduate course"
permalink: /teaching/YYYY/term-course-name
date: YYYY-MM-DD
venue: "Department and institution"
location: "City, country"
---

Course description, learning goals, and relevant resources.

## Course materials

- [Course website](https://example.com){:target="_blank"}
- Add syllabus, bibliography, software, or project links here.
EOF

  open_in_editor "$course_path"
  printf 'Curso creado: %s\n' "$course_path"
}

edit_teaching() {
  choose_teaching || return 1
  open_in_editor "$course_path"
  printf 'Curso actualizado: %s\n' "$(basename "$course_path")"
}

delete_teaching() {
  choose_teaching || return 1
  printf '¿Borrar %s? Esta acción no se puede deshacer desde el menú [y/N]: ' "$(basename "$course_path")"
  if ! read -r confirmation; then
    return 1
  fi
  case "$confirmation" in
    y|Y|s|S)
      rm "$course_path"
      printf 'Curso borrado.\n'
      ;;
    *)
      printf 'Operación cancelada.\n'
      ;;
  esac
}

teaching_menu() {
  while true; do
    printf '\n=== Gestión de cursos ===\n'
    printf '1) Listar cursos\n'
    printf '2) Crear curso\n'
    printf '3) Modificar curso\n'
    printf '4) Borrar curso\n'
    printf '0) Volver\n'
    printf 'Selecciona una opción: '
    if ! read -r option; then
      return 0
    fi

    case "$option" in
      1) list_teaching; pause ;;
      2) create_teaching; pause ;;
      3) edit_teaching; pause ;;
      4) delete_teaching; pause ;;
      0) return ;;
      *) printf 'Opción no válida.\n' ;;
    esac
  done
}

update_git_repo() {
  cd "$ROOT_DIR"

  printf '\nCambios pendientes:\n'
  git status --short

  if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    printf 'No hay cambios para publicar.\n'
    return 0
  fi

  printf '\nMensaje del commit: '
  if ! read -r commit_message; then
    return 1
  fi
  if [ -z "$commit_message" ]; then
    printf 'El mensaje del commit no puede estar vacío.\n' >&2
    return 1
  fi

  printf '¿Confirmas agregar todos los cambios, crear el commit y hacer push? [y/N]: '
  if ! read -r confirmation; then
    return 1
  fi
  case "$confirmation" in
    y|Y|s|S) ;;
    *) printf 'Operación cancelada.\n'; return 0 ;;
  esac

  git add -A || return 1
  printf '\nCambios preparados para el commit:\n'
  git status --short
  git commit -m "$commit_message" || return 1
  git push || return 1
  printf 'Repositorio actualizado correctamente.\n'
}

while true; do
  printf '\n=== Herramientas del sitio de Javier Orduz ===\n'
  printf '1) Actualizar PDF del CV\n'
  printf '2) Gestionar eventos\n'
  printf '3) Validar build de Jekyll\n'
  printf '4) Ver estado de Git\n'
  printf '5) Actualizar repositorio en Git\n'
  printf '6) Gestionar publicaciones\n'
  printf '7) Importar publicaciones desde ORCID\n'
  printf '8) Actualizar métricas de impacto\n'
  printf '9) Gestionar cursos de Teaching\n'
  printf '0) Salir\n'
  printf 'Selecciona una opción: '
  if ! read -r option; then
    exit 0
  fi

  case "$option" in
    1) update_cv; pause ;;
    2) events_menu ;;
    3) validate_site; pause ;;
    4) show_status; pause ;;
    5) update_git_repo; pause ;;
    6) publications_menu ;;
    7) import_orcid_publications; pause ;;
    8) update_impact_metrics; pause ;;
    9) teaching_menu ;;
    0) printf 'Hasta luego.\n'; exit 0 ;;
    *) printf 'Opción no válida.\n' ;;
  esac
done