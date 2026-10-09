from __future__ import annotations

import csv
import json
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = BACKEND_ROOT.parent
MANIFEST_PATH = BACKEND_ROOT / "config" / "featured_place_image_ids.json"
DATASET_PATH = PROJECT_ROOT / "assets" / "data" / "dalat_places.json"
IMAGE_DIR = BACKEND_ROOT / "static" / "place-images"
REPORT_PATH = BACKEND_ROOT / "static" / "place-images-report.csv"


def main() -> None:
    selected_ids: list[str] = json.loads(MANIFEST_PATH.read_text("utf-8"))
    if len(selected_ids) != 50 or len(set(selected_ids)) != 50:
        raise SystemExit("Manifest must contain exactly 50 unique place IDs")

    places: list[dict[str, object]] = json.loads(DATASET_PATH.read_text("utf-8"))
    known_ids = {str(place["id"]) for place in places}
    selected = set(selected_ids)
    unknown = selected - known_ids
    if unknown:
        raise SystemExit(f"Unknown place IDs: {sorted(unknown)}")

    missing_files = [
        place_id
        for place_id in selected_ids
        if not (IMAGE_DIR / f"{place_id}.webp").is_file()
    ]
    if missing_files:
        raise SystemExit(f"Missing selected WebP files: {missing_files}")

    for place in places:
        place_id = str(place["id"])
        if place_id in selected:
            place["image_url"] = f"/media/places/{place_id}.webp"
        elif str(place.get("image_url") or "").startswith("/media/places/"):
            place["image_url"] = None

    removed = 0
    for image_path in IMAGE_DIR.glob("*.webp"):
        if image_path.stem not in selected:
            image_path.unlink()
            removed += 1

    DATASET_PATH.write_text(
        json.dumps(places, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    if REPORT_PATH.exists():
        with REPORT_PATH.open(encoding="utf-8-sig", newline="") as source:
            rows = [row for row in csv.DictReader(source) if row["id"] in selected]
        with REPORT_PATH.open("w", encoding="utf-8-sig", newline="") as target:
            writer = csv.DictWriter(
                target,
                fieldnames=[
                    "id",
                    "name",
                    "status",
                    "query",
                    "bytes",
                    "source_page",
                    "photographer",
                ],
            )
            writer.writeheader()
            writer.writerows(rows)

    print(f"Selected {len(selected)} images; removed {removed} unused WebP files")


if __name__ == "__main__":
    main()
