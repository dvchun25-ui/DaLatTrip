from __future__ import annotations

import argparse
import csv
import io
import json
import os
import sys
import time
import unicodedata
from pathlib import Path
from typing import Any

import httpx
from PIL import Image, ImageOps


BACKEND_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = BACKEND_ROOT.parent
DATASET_PATH = PROJECT_ROOT / "assets" / "data" / "dalat_places.json"
OUTPUT_DIR = BACKEND_ROOT / "static" / "place-images"
REPORT_PATH = BACKEND_ROOT / "static" / "place-images-report.csv"
PIXABAY_ENDPOINT = "https://pixabay.com/api/"


CATEGORY_QUERIES = {
    "thiên nhiên": "Da Lat Vietnam mountain lake nature",
    "cà phê": "Da Lat Vietnam coffee shop",
    "ẩm thực": "Vietnamese food restaurant",
    "văn hóa": "Da Lat Vietnam architecture temple",
    "check-in": "Da Lat Vietnam travel landscape",
}


def fold(value: str) -> str:
    normalized = unicodedata.normalize("NFD", value)
    return "".join(
        character
        for character in normalized
        if unicodedata.category(character) != "Mn"
    ).replace("đ", "d").replace("Đ", "D")


def query_for(place: dict[str, Any]) -> str:
    name = str(place["name"]).lower()
    folded_name = fold(name)
    categories = str(place.get("categories") or "")

    # Pixabay thường hiểu tên riêng tiếng Việt như một tập từ khóa rời, dẫn
    # tới ảnh không liên quan. Với thumbnail mẫu, ưu tiên đúng *loại cảnh*
    # của địa điểm để giao diện nhất quán và đáng tin cậy hơn.
    if "thác" in name:
        return "Vietnam tropical waterfall nature"
    if name.startswith("hồ ") or " hồ " in name:
        return "Vietnam mountain lake landscape"
    if any(word in name for word in ("cà phê", "cafe", "coffee")):
        return "cozy coffee shop cafe interior"
    if any(word in name for word in ("chùa", "thiền viện", "cổ sát")):
        return "Vietnam pagoda buddhist temple"
    if "nhà thờ" in name:
        return "Vietnam church architecture"
    if any(word in name for word in ("đồi", "núi", "đèo", "rừng")):
        return "Vietnam mountain pine forest landscape"
    if any(word in name for word in ("vườn hoa", "cánh đồng hoa", "lavender")):
        return "colorful flower garden field"
    if any(word in name for word in ("farm", "nông trại")):
        return "green farm countryside landscape"
    if "chợ" in name:
        return "Vietnam local night market"
    if any(word in name for word in ("ga ", "hỏa xa")):
        return "vintage railway station train"
    if any(word in name for word in ("dinh i", "dinh ii", "dinh iii")):
        return "French colonial villa architecture"
    if "ẩm thực" in categories:
        return "Vietnamese food restaurant"
    if "cà phê" in categories:
        return "cozy coffee shop cafe interior"
    if "thiên nhiên" in categories:
        return "Da Lat Vietnam mountain nature landscape"
    if "văn hóa" in categories:
        return "Vietnam cultural landmark architecture"
    if "check-in" in categories or "checkin" in folded_name:
        return "Da Lat Vietnam travel landscape"
    return "Da Lat Vietnam travel landscape"


def fallback_query(place: dict[str, Any]) -> str:
    categories = str(place.get("categories") or "").split(";")
    for category in categories:
        if category in CATEGORY_QUERIES:
            return CATEGORY_QUERIES[category]
    return "Da Lat Vietnam travel landscape"


def search(
    client: httpx.Client,
    *,
    api_key: str,
    query: str,
    per_page: int = 20,
) -> list[dict[str, Any]]:
    for attempt in range(3):
        response = client.get(
            PIXABAY_ENDPOINT,
            params={
                "key": api_key,
                "q": query,
                "image_type": "photo",
                "orientation": "horizontal",
                "safesearch": "true",
                "per_page": str(per_page),
                "min_width": "960",
            },
        )
        if response.status_code < 500:
            response.raise_for_status()
            payload = response.json()
            return list(payload.get("hits") or [])
        time.sleep(1.5 * (attempt + 1))
    response.raise_for_status()
    return []


def select_unique(
    hits: list[dict[str, Any]],
    used_image_ids: set[int],
) -> dict[str, Any] | None:
    for hit in hits:
        image_id = int(hit.get("id") or 0)
        if image_id and image_id not in used_image_ids:
            used_image_ids.add(image_id)
            return hit
    return None


def make_webp(content: bytes, destination: Path) -> int:
    with Image.open(io.BytesIO(content)) as source:
        image = ImageOps.exif_transpose(source).convert("RGB")
        image = ImageOps.fit(
            image,
            (960, 540),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
        # Bắt đầu ở chất lượng cao để thumbnail thường nằm trong khoảng
        # 80–150 KB; chỉ giảm chất lượng khi vượt mức trần 150 KB.
        quality = 96
        while True:
            buffer = io.BytesIO()
            image.save(buffer, "WEBP", quality=quality, method=6)
            data = buffer.getvalue()
            if len(data) <= 150 * 1024 or quality <= 60:
                destination.write_bytes(data)
                return len(data)
            quality -= 3


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(
        description="Prepare fixed WebP thumbnails for DALATTRIP places."
    )
    parser.add_argument("--limit", type=int, default=120)
    parser.add_argument("--api-key", default=os.getenv("PIXABAY_API_KEY"))
    parser.add_argument("--delay", type=float, default=0.7)
    args = parser.parse_args()
    if not args.api_key:
        raise SystemExit("PIXABAY_API_KEY or --api-key is required")

    places: list[dict[str, Any]] = json.loads(DATASET_PATH.read_text("utf-8"))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    used_image_ids: set[int] = set()
    report: list[dict[str, Any]] = []

    with httpx.Client(timeout=25, follow_redirects=True) as client:
        for index, place in enumerate(places[: args.limit], start=1):
            place_id = str(place["id"])
            output = OUTPUT_DIR / f"{place_id}.webp"
            query = query_for(place)
            hit: dict[str, Any] | None = None
            status = "ok"
            try:
                hit = select_unique(
                    search(client, api_key=args.api_key, query=query),
                    used_image_ids,
                )
                if hit is None:
                    query = fallback_query(place)
                    time.sleep(args.delay)
                    hit = select_unique(
                        search(
                            client,
                            api_key=args.api_key,
                            query=query,
                            per_page=100,
                        ),
                        used_image_ids,
                    )
                if hit is None:
                    status = "needs_manual_review"
                else:
                    image_url = hit.get("webformatURL") or hit.get("largeImageURL")
                    image_response = client.get(str(image_url))
                    image_response.raise_for_status()
                    byte_count = make_webp(image_response.content, output)
                    place["image_url"] = f"/media/places/{place_id}.webp"
                    report.append(
                        {
                            "id": place_id,
                            "name": place["name"],
                            "status": status,
                            "query": query,
                            "bytes": byte_count,
                            "source_page": hit.get("pageURL", ""),
                            "photographer": hit.get("user", ""),
                        }
                    )
            except Exception as error:  # noqa: BLE001 - report and continue batch
                # Không ghi URL lỗi vì query string có chứa API key.
                if output.exists():
                    # Lượt tải mới lỗi nhưng thumbnail hợp lệ từ lượt trước vẫn
                    # dùng được; không xóa ảnh đang phục vụ cho ứng dụng.
                    status = "ok_existing"
                    place["image_url"] = f"/media/places/{place_id}.webp"
                else:
                    status = f"error: {type(error).__name__}"
            if hit is None or status != "ok":
                report.append(
                    {
                        "id": place_id,
                        "name": place["name"],
                        "status": status,
                        "query": query,
                        "bytes": output.stat().st_size if output.exists() else 0,
                        "source_page": "",
                        "photographer": "",
                    }
                )
            print(
                f"[{index:03d}/{args.limit}] {place['name']}: {status}",
                flush=True,
            )
            time.sleep(args.delay)

    DATASET_PATH.write_text(
        json.dumps(places, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    with REPORT_PATH.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.DictWriter(
            file,
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
        writer.writerows(report)

    successful = sum(1 for row in report if row["status"] == "ok")
    print(f"Prepared {successful}/{args.limit} thumbnails in {OUTPUT_DIR}")
    print(f"Review report: {REPORT_PATH}")


if __name__ == "__main__":
    main()
