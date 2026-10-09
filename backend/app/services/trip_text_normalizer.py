from __future__ import annotations

import re
import unicodedata
from typing import Any

_NUMBER_WORDS = {
    "mot": 1,
    "hai": 2,
    "ba": 3,
    "bon": 4,
    "tu": 4,
    "nam": 5,
    "sau": 6,
    "bay": 7,
    "tam": 8,
    "chin": 9,
    "muoi": 10,
}

_INTEREST_KEYWORDS = {
    "nature": ("thien nhien", "ngam canh", "canh dep"),
    "cafe": ("ca phe", "cafe", "coffee"),
    "food": ("am thuc", "an uong", "mon ngon"),
    "culture": ("van hoa", "tham quan"),
    "checkin": ("check-in", "checkin", "song ao", "chup anh"),
    "relax": ("thich thu gian", "nghi duong", "lang man"),
    "adventure": ("kham pha", "phieu luu"),
    "family": ("gia dinh", "tre em"),
}

_TRANSPORT_KEYWORDS = {
    "motorbike": ("xe may",),
    "car": ("o to", "oto", "xe hoi"),
    "taxi": ("taxi",),
    "walking": ("di bo",),
}

_PACE_KEYWORDS = {
    "relaxed": ("thu gian", "chill", "nhe nhang"),
    "balanced": ("can bang", "vua phai"),
    "packed": ("di nhieu", "cang nhieu cang tot", "kin lich"),
}


def extract_explicit_trip_facts(message: str) -> dict[str, Any]:
    """Extract only facts that are explicitly supported by the current text."""
    text = _fold(message)
    facts: dict[str, Any] = {}

    days = _number_before_unit(text, "ngay")
    if days is not None:
        facts["days"] = days

    people = _number_before_unit(text, "nguoi")
    if people is not None:
        facts["people"] = people
    elif any(
        phrase in text
        for phrase in ("voi nguoi yeu", "cung nguoi yeu", "hai dua")
    ):
        facts["people"] = 2

    budget = _extract_budget(text)
    if budget is not None:
        facts["totalBudget"] = budget

    interests = [
        category
        for category, keywords in _INTEREST_KEYWORDS.items()
        if any(_contains_phrase(text, keyword) for keyword in keywords)
    ]
    if interests:
        facts["interests"] = interests

    transport = _first_keyword_value(text, _TRANSPORT_KEYWORDS)
    if transport is not None:
        facts["transport"] = transport

    pace = _first_keyword_value(text, _PACE_KEYWORDS)
    if pace is not None:
        facts["pace"] = pace

    return facts


def keep_only_explicit_required_fields(
    extracted: dict[str, Any],
    explicit: dict[str, Any],
    required_fields: tuple[str, ...],
) -> dict[str, Any]:
    """Prevent plausible-looking Gemini values without evidence in the text."""
    safe = {
        key: value
        for key, value in extracted.items()
        if key not in required_fields
    }
    safe.update(explicit)
    return safe


def _fold(value: str) -> str:
    normalized = unicodedata.normalize("NFD", value.lower().replace("đ", "d"))
    without_accents = "".join(
        character
        for character in normalized
        if unicodedata.category(character) != "Mn"
    )
    return re.sub(r"\s+", " ", without_accents).strip()


def _number_before_unit(text: str, unit: str) -> int | None:
    number_pattern = "|".join(_NUMBER_WORDS)
    match = re.search(rf"\b(\d+|{number_pattern})\s*{unit}\b", text)
    if match is None:
        return None
    value = match.group(1)
    return int(value) if value.isdigit() else _NUMBER_WORDS[value]


def _extract_budget(text: str) -> int | None:
    match = re.search(
        r"\b(\d+(?:[.,]\d+)?)\s*(trieu|tr|nghin|ngan|k)\b",
        text,
    )
    if match is None:
        return None
    amount = float(match.group(1).replace(",", "."))
    multiplier = 1_000_000 if match.group(2) in {"trieu", "tr"} else 1_000
    return round(amount * multiplier)


def _first_keyword_value(
    text: str,
    mapping: dict[str, tuple[str, ...]],
) -> str | None:
    for value, keywords in mapping.items():
        if any(_contains_phrase(text, keyword) for keyword in keywords):
            return value
    return None


def _contains_phrase(text: str, phrase: str) -> bool:
    return re.search(rf"(?<!\w){re.escape(phrase)}(?!\w)", text) is not None
