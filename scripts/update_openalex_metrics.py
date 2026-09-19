#!/usr/bin/env python3
"""Update the OpenAlex metrics data consumed by the homepage."""

import argparse
import json
import urllib.request
from datetime import date
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--author-id", default="A5088072249")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    url = f"https://api.openalex.org/authors/{args.author_id}"
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "jaorduz.github.io metrics updater"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        author = json.load(response)

    stats = author.get("summary_stats", {})
    args.output.write_text(
        "\n".join(
            [
                'source: "OpenAlex"',
                f'profile_url: "https://openalex.org/{args.author_id}"',
                f"works: {author.get('works_count', 0)}",
                f"cited_by: {author.get('cited_by_count', 0)}",
                f"h_index: {stats.get('h_index', 0)}",
                f'updated: "{date.today().isoformat()}"',
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(f"Updated {args.output}")


if __name__ == "__main__":
    main()