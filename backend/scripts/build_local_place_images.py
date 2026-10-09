from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = BACKEND_ROOT.parent
MANIFEST_PATH = BACKEND_ROOT / "config" / "featured_place_image_ids.json"
DATASET_PATH = PROJECT_ROOT / "assets" / "data" / "dalat_places.json"
SOURCE_DIR = BACKEND_ROOT / "static" / "place-images"
ASSET_DIR = PROJECT_ROOT / "assets" / "images" / "places"

FALLBACK_POOLS = {
    "waterfall": ["thac_datanla", "thac_pongour", "thac_voi"],
    "lake": ["ho_tuyen_lam", "doi_thong_da_phu", "doi_che_cau_dat"],
    "garden": ["cau_dat_farm", "vuon_hoa_da_lat", "doi_che_cau_dat"],
    "nature": [
        "ho_tuyen_lam",
        "doi_che_cau_dat",
        "vuon_hoa_da_lat",
        "doi_thong_da_phu",
        "cau_dat_farm",
    ],
    "cafe": ["la_viet_coffee", "cau_dat_farm", "vuon_hoa_da_lat"],
    "food": ["cho_dem_da_lat", "la_viet_coffee", "ga_da_lat"],
    "culture": ["ga_da_lat", "chua_linh_phuoc", "cho_dem_da_lat"],
    "general": [
        "ho_tuyen_lam",
        "doi_che_cau_dat",
        "vuon_hoa_da_lat",
        "ga_da_lat",
        "doi_thong_da_phu",
    ],
}


def pool_for(place: dict[str, object]) -> list[str]:
    name = str(place["name"]).lower()
    categories = str(place.get("categories") or "").lower()
    if "thác" in name:
        return FALLBACK_POOLS["waterfall"]
    if name.startswith("hồ ") or " hồ " in name:
        return FALLBACK_POOLS["lake"]
    if any(word in name for word in ("farm", "vườn", "hoa", "nông trại")):
        return FALLBACK_POOLS["garden"]
    if any(word in name for word in ("cafe", "coffee", "cà phê")):
        return FALLBACK_POOLS["cafe"]
    if "ẩm thực" in categories:
        return FALLBACK_POOLS["food"]
    if "văn hóa" in categories or any(
        word in name for word in ("chùa", "thiền viện", "nhà thờ", "dinh ")
    ):
        return FALLBACK_POOLS["culture"]
    if "thiên nhiên" in categories or any(
        word in name for word in ("đồi", "núi", "rừng", "vườn", "farm")
    ):
        return FALLBACK_POOLS["nature"]
    return FALLBACK_POOLS["general"]


def stable_index(place_id: str, length: int) -> int:
    digest = hashlib.sha256(place_id.encode("utf-8")).digest()
    return int.from_bytes(digest[:4], "big") % length


def main() -> None:
    selected_ids: list[str] = json.loads(MANIFEST_PATH.read_text("utf-8"))
    selected = set(selected_ids)
    places: list[dict[str, object]] = json.loads(DATASET_PATH.read_text("utf-8"))

    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    for old_asset in ASSET_DIR.glob("*.webp"):
        old_asset.unlink()

    for place_id in selected_ids:
        source = SOURCE_DIR / f"{place_id}.webp"
        if not source.is_file():
            raise SystemExit(f"Missing selected image: {source}")
        shutil.copy2(source, ASSET_DIR / source.name)

    previous_url: str | None = None
    fallback_count = 0
    for index, place in enumerate(places):
        place_id = str(place["id"])
        if place_id in selected:
            chosen_id = place_id
        else:
            pool = pool_for(place)
            start = stable_index(place_id, len(pool))
            chosen_id = pool[start]
            next_selected_url: str | None = None
            if index + 1 < len(places):
                next_id = str(places[index + 1]["id"])
                if next_id in selected:
                    next_selected_url = f"assets/images/places/{next_id}.webp"
            for offset in range(len(pool)):
                candidate = pool[(start + offset) % len(pool)]
                candidate_url = f"assets/images/places/{candidate}.webp"
                if (
                    candidate_url != previous_url
                    and candidate_url != next_selected_url
                ):
                    chosen_id = candidate
                    break
            fallback_count += 1

        image_url = f"assets/images/places/{chosen_id}.webp"
        place["image_url"] = image_url
        previous_url = image_url

    DATASET_PATH.write_text(
        json.dumps(places, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"Bundled {len(selected)} unique images; assigned rotating local "
        f"images to {fallback_count} places"
    )


if __name__ == "__main__":
    main()
