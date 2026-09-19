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
    0) printf 'Hasta luego.\n'; exit 0 ;;
    *) printf 'Opción no válida.\n' ;;
  esac
done