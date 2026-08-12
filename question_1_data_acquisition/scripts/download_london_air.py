#!/usr/bin/env python3
"""Download reproducible hourly London Air Quality Network observations."""

from __future__ import annotations

import argparse
import csv
import json
import logging
import re
import sys
import time
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import quote

import requests


LOGGER = logging.getLogger("london_air_download")
API_ROOT = "https://api.erg.ic.ac.uk/AirQuality"
SITES_ENDPOINT = f"{API_ROOT}/Information/MonitoringSites/GroupName=London/Json"
SITE_SPECIES_ENDPOINT = f"{API_ROOT}/Information/MonitoringSiteSpecies/GroupName=London/Json"
SITE_FIELDS = [
    "SiteCode",
    "SiteName",
    "SiteType",
    "Latitude",
    "Longitude",
    "DateOpened",
    "DateClosed",
    "IsActive",
    "SpeciesCodes",
    "WindowSpeciesCodes",
]
HOURLY_FIELDS = [
    "SiteCode",
    "SiteName",
    "SiteType",
    "Latitude",
    "Longitude",
    "MeasurementDateGMT",
    "NO2",
]


class ApiRequestError(RuntimeError):
    """A request failed after the configured retry policy."""


def clean_text(value: Any) -> str | None:
    """Convert API empty strings and null-like values to None."""
    if value is None:
        return None
    text = str(value).strip()
    if not text or text.lower() in {"null", "none", "nan", "n/a"}:
        return None
    return text


def strip_at_keys(value: Any) -> Any:
    """Recursively remove the LAQN API's leading @ from field names."""
    if isinstance(value, dict):
        return {
            (key[1:] if isinstance(key, str) and key.startswith("@") else key): strip_at_keys(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [strip_at_keys(item) for item in value]
    return value


def as_list(value: Any) -> list[Any]:
    """Normalise an API list/single-dictionary/empty value to a list."""
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        return [] if not value else [value]
    return []


def find_first_key(value: Any, wanted: str) -> Any:
    """Find the first case-insensitive key in a nested JSON-compatible value."""
    if isinstance(value, dict):
        for key, item in value.items():
            if str(key).casefold() == wanted.casefold():
                return item
        for item in value.values():
            found = find_first_key(item, wanted)
            if found is not None:
                return found
    elif isinstance(value, list):
        for item in value:
            found = find_first_key(item, wanted)
            if found is not None:
                return found
    return None


def describe_json(value: Any, depth: int = 0, max_depth: int = 2) -> dict[str, Any]:
    """Return a compact, data-free description of a JSON response's shape."""
    if isinstance(value, dict):
        result: dict[str, Any] = {"type": "dict", "keys": list(value.keys())}
        if depth < max_depth:
            result["children"] = {
                str(key): describe_json(item, depth + 1, max_depth)
                for key, item in value.items()
            }
        return result
    if isinstance(value, list):
        result = {"type": "list", "length": len(value)}
        if value and depth < max_depth:
            result["item"] = describe_json(value[0], depth + 1, max_depth)
        return result
    return {"type": type(value).__name__}


@dataclass
class ApiClient:
    """A rate-limited requests.Session client with bounded retries."""

    timeout: float = 30.0
    max_retries: int = 3
    request_delay: float = 0.5
    session: requests.Session = field(default_factory=requests.Session)
    _last_request_started: float | None = field(default=None, init=False)

    def __post_init__(self) -> None:
        if not 0 <= self.max_retries <= 3:
            raise ValueError("max_retries must be between 0 and 3")
        if self.timeout <= 0 or self.request_delay < 0:
            raise ValueError("timeout must be positive and request_delay non-negative")
        self.session.headers.update(
            {
                "Accept": "application/json",
                "User-Agent": "MATH70076-London-Air-Assessment/1.0",
            }
        )

    def close(self) -> None:
        self.session.close()

    def _throttle(self) -> None:
        if self._last_request_started is not None:
            elapsed = time.monotonic() - self._last_request_started
            if elapsed < self.request_delay:
                time.sleep(self.request_delay - elapsed)
        self._last_request_started = time.monotonic()

    def get_json(self, url: str) -> tuple[int, Any]:
        total_attempts = self.max_retries + 1
        last_error: Exception | None = None

        for attempt in range(1, total_attempts + 1):
            self._throttle()
            try:
                response = self.session.get(url, timeout=self.timeout)
                LOGGER.info("GET %s -> HTTP %s (attempt %s/%s)", url, response.status_code, attempt, total_attempts)

                if response.status_code == 429 or response.status_code >= 500:
                    response.raise_for_status()
                if 400 <= response.status_code < 500:
                    response.raise_for_status()

                try:
                    payload = response.json()
                except ValueError as exc:
                    preview = response.text[:160].replace("\n", " ")
                    raise ApiRequestError(
                        f"HTTP {response.status_code} returned invalid JSON; body starts with {preview!r}"
                    ) from exc
                return response.status_code, payload
            except (requests.RequestException, ApiRequestError) as exc:
                last_error = exc
                retriable = not (
                    isinstance(exc, requests.HTTPError)
                    and exc.response is not None
                    and 400 <= exc.response.status_code < 500
                    and exc.response.status_code != 429
                )
                if attempt >= total_attempts or not retriable:
                    break
                backoff = min(2 ** (attempt - 1), 4)
                LOGGER.warning("Request failed: %s; retrying in %.1f seconds", exc, backoff)
                time.sleep(backoff)

        raise ApiRequestError(
            f"Request failed after {attempt} attempt(s): {url}; last error: {last_error}"
        ) from last_error


def extract_site_records(payload: Any) -> list[dict[str, Any]]:
    normalised = strip_at_keys(payload)
    site_node = find_first_key(normalised, "Site")
    records = as_list(site_node)
    return [record for record in records if isinstance(record, dict)]


def extract_species_records(site: dict[str, Any]) -> list[dict[str, Any]]:
    species_node = site.get("Species")
    if isinstance(species_node, dict) and "SpeciesCode" not in species_node:
        nested = find_first_key(species_node, "Species")
        if nested is not None:
            species_node = nested

    return [species for species in as_list(species_node) if isinstance(species, dict)]


def species_overlaps_window(
    species: dict[str, Any],
    window_start: date | None,
    window_end: date | None,
) -> bool:
    measurement_start = parse_api_date(species.get("DateMeasurementStarted"))
    measurement_end = parse_api_date(species.get("DateMeasurementFinished"))
    starts_in_time = window_end is None or measurement_start is None or measurement_start <= window_end
    ends_in_time = window_start is None or measurement_end is None or measurement_end >= window_start
    return starts_in_time and ends_in_time


def extract_species_codes(
    site: dict[str, Any],
    window_start: date | None = None,
    window_end: date | None = None,
) -> list[str]:
    codes: set[str] = set()
    for species in extract_species_records(site):
        if not species_overlaps_window(species, window_start, window_end):
            continue
        code = clean_text(species.get("SpeciesCode"))
        if code:
            codes.add(code.upper())
    return sorted(codes)


def parse_api_date(value: Any) -> date | None:
    text = clean_text(value)
    if not text:
        return None
    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00")).date()
    except ValueError:
        try:
            return date.fromisoformat(text[:10])
        except ValueError:
            return None


def site_is_active(site: dict[str, Any], as_of: date | None = None) -> bool:
    closed_text = clean_text(site.get("DateClosed"))
    if closed_text is None:
        return True
    closed_date = parse_api_date(closed_text)
    return bool(closed_date and closed_date > (as_of or datetime.now(timezone.utc).date()))


def build_site_rows(
    payload: Any,
    active_as_of: date | None = None,
    window_start: date | None = None,
    window_end: date | None = None,
    species_payload: Any = None,
) -> list[dict[str, Any]]:
    sites = extract_site_records(payload)
    if species_payload is not None:
        species_sites = {
            clean_text(site.get("SiteCode")): site
            for site in extract_site_records(species_payload)
            if clean_text(site.get("SiteCode"))
        }
        enriched_sites = []
        for site in sites:
            enriched = dict(site)
            species_site = species_sites.get(clean_text(site.get("SiteCode")))
            if species_site is not None and "Species" in species_site:
                enriched["Species"] = species_site["Species"]
            enriched_sites.append(enriched)
        sites = enriched_sites

    rows: list[dict[str, Any]] = []
    for site in sites:
        species_codes = extract_species_codes(site)
        window_species_codes = extract_species_codes(site, window_start, window_end)
        row = {
            "SiteCode": clean_text(site.get("SiteCode")),
            "SiteName": clean_text(site.get("SiteName")),
            "SiteType": clean_text(site.get("SiteType")),
            "Latitude": clean_text(site.get("Latitude")),
            "Longitude": clean_text(site.get("Longitude")),
            "DateOpened": clean_text(site.get("DateOpened")),
            "DateClosed": clean_text(site.get("DateClosed")),
            "IsActive": site_is_active(site, active_as_of),
            "SpeciesCodes": ";".join(species_codes),
            "WindowSpeciesCodes": ";".join(window_species_codes),
        }
        if not row["SiteCode"]:
            LOGGER.warning("Skipping monitoring-site record without SiteCode")
            continue
        rows.append(row)
    return rows


def select_sites(site_rows: Iterable[dict[str, Any]], species: str) -> list[dict[str, Any]]:
    wanted = species.upper()
    selected = []
    for site in site_rows:
        available_text = (
            site.get("WindowSpeciesCodes")
            if "WindowSpeciesCodes" in site
            else site.get("SpeciesCodes", "")
        )
        available = {code for code in str(available_text).upper().split(";") if code}
        if site.get("IsActive") and wanted in available:
            selected.append(site)
    return sorted(selected, key=lambda row: str(row["SiteCode"]))


def parse_numeric(value: Any) -> float | None:
    text = clean_text(value)
    if text is None:
        return None
    try:
        return float(text)
    except (TypeError, ValueError):
        return None


def extract_hourly_rows(
    payload: Any,
    site: dict[str, Any],
    species: str,
) -> list[dict[str, Any]]:
    normalised = strip_at_keys(payload)
    data_node = find_first_key(normalised, "Data")
    records = as_list(data_node)
    rows: list[dict[str, Any]] = []
    for record in records:
        if not isinstance(record, dict):
            continue
        raw_value = record.get("Value")
        if raw_value is None:
            raw_value = record.get(species.upper())
        rows.append(
            {
                "SiteCode": site.get("SiteCode"),
                "SiteName": site.get("SiteName"),
                "SiteType": site.get("SiteType"),
                "Latitude": site.get("Latitude"),
                "Longitude": site.get("Longitude"),
                "MeasurementDateGMT": clean_text(record.get("MeasurementDateGMT")),
                "NO2": parse_numeric(raw_value),
            }
        )
    return rows


def site_species_endpoint(site_code: str, species: str, start_date: str, end_date: str) -> str:
    return (
        f"{API_ROOT}/Data/SiteSpecies/"
        f"SiteCode={quote(site_code, safe='')}/"
        f"SpeciesCode={quote(species.upper(), safe='')}/"
        f"StartDate={quote(start_date, safe='-')}/"
        f"EndDate={quote(end_date, safe='-')}/Json"
    )


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def write_csv(path: Path, rows: Iterable[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def safe_site_code(site_code: str) -> str:
    return re.sub(r"[^A-Za-z0-9_-]+", "_", site_code)


def valid_iso_date(value: str) -> str:
    try:
        date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"Invalid ISO date: {value}") from exc
    return value


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--start-date", type=valid_iso_date, default="2025-07-01")
    parser.add_argument("--end-date", type=valid_iso_date, default="2025-07-08")
    parser.add_argument("--species", default="NO2")
    parser.add_argument("--max-sites", type=int, default=None)
    parser.add_argument("--request-delay", type=float, default=0.5)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--max-retries", type=int, choices=range(0, 4), default=3)
    parser.add_argument("--output-root", type=Path, default=project_root)
    parser.add_argument("--log-level", choices=("DEBUG", "INFO", "WARNING", "ERROR"), default="INFO")
    args = parser.parse_args(argv)
    if date.fromisoformat(args.start_date) > date.fromisoformat(args.end_date):
        parser.error("--start-date must not be after --end-date")
    if args.max_sites is not None and args.max_sites < 1:
        parser.error("--max-sites must be at least 1")
    if args.request_delay < 0 or args.timeout <= 0:
        parser.error("--request-delay must be non-negative and --timeout positive")
    return args


def run(args: argparse.Namespace) -> int:
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s %(levelname)s %(message)s",
    )
    raw_dir = args.output_root.resolve() / "data" / "raw"
    processed_dir = args.output_root.resolve() / "data" / "processed"
    client = ApiClient(args.timeout, args.max_retries, args.request_delay)

    try:
        try:
            status, sites_payload = client.get_json(SITES_ENDPOINT)
        except ApiRequestError as exc:
            LOGGER.error("Monitoring-sites request failed: %s", exc)
            return 1

        LOGGER.info("Monitoring-sites HTTP status: %s", status)
        LOGGER.info(
            "Monitoring-sites JSON structure: %s",
            json.dumps(describe_json(sites_payload), ensure_ascii=False),
        )
        write_json(raw_dir / "monitoring_sites.json", sites_payload)

        try:
            species_status, species_payload = client.get_json(SITE_SPECIES_ENDPOINT)
        except ApiRequestError as exc:
            LOGGER.error("Monitoring-site-species request failed: %s", exc)
            return 1
        LOGGER.info("Monitoring-site-species HTTP status: %s", species_status)
        LOGGER.info(
            "Monitoring-site-species JSON structure: %s",
            json.dumps(describe_json(species_payload), ensure_ascii=False),
        )
        write_json(raw_dir / "monitoring_site_species.json", species_payload)

        site_rows = build_site_rows(
            sites_payload,
            window_start=date.fromisoformat(args.start_date),
            window_end=date.fromisoformat(args.end_date),
            species_payload=species_payload,
        )
        write_csv(processed_dir / "monitoring_sites.csv", site_rows, SITE_FIELDS)
        selected = select_sites(site_rows, args.species)
        if args.max_sites is not None:
            selected = selected[: args.max_sites]
        LOGGER.info(
            "Parsed %s sites; selected %s active site(s) providing %s",
            len(site_rows),
            len(selected),
            args.species.upper(),
        )

        all_hourly: list[dict[str, Any]] = []
        failures: list[dict[str, str]] = []
        successful_sites = 0
        for index, site in enumerate(selected, start=1):
            site_code = str(site["SiteCode"])
            url = site_species_endpoint(site_code, args.species, args.start_date, args.end_date)
            LOGGER.info("Downloading site %s/%s: %s", index, len(selected), site_code)
            try:
                site_status, site_payload = client.get_json(url)
                LOGGER.debug("%s HTTP status %s; structure %s", site_code, site_status, describe_json(site_payload))
                write_json(raw_dir / f"{safe_site_code(site_code)}_{args.species.upper()}.json", site_payload)
                site_hourly = extract_hourly_rows(site_payload, site, args.species)
                all_hourly.extend(site_hourly)
                successful_sites += 1
                LOGGER.info("Site %s: %s hourly record(s)", site_code, len(site_hourly))
            except ApiRequestError as exc:
                failures.append({"SiteCode": site_code, "Reason": str(exc)})
                LOGGER.error("Site %s failed; continuing: %s", site_code, exc)

        all_hourly.sort(
            key=lambda row: (str(row.get("SiteCode") or ""), str(row.get("MeasurementDateGMT") or ""))
        )
        write_csv(processed_dir / "london_no2_hourly.csv", all_hourly, HOURLY_FIELDS)
        missing_no2 = sum(row["NO2"] is None for row in all_hourly)

        LOGGER.info(
            "SUMMARY selected_sites=%s successful_sites=%s failed_sites=%s total_records=%s missing_NO2=%s",
            len(selected),
            successful_sites,
            len(failures),
            len(all_hourly),
            missing_no2,
        )
        for failure in failures:
            LOGGER.error("FAILED SiteCode=%s Reason=%s", failure["SiteCode"], failure["Reason"])

        if selected and successful_sites == 0:
            return 2
        return 0
    finally:
        client.close()


def main(argv: list[str] | None = None) -> int:
    return run(parse_args(argv))


if __name__ == "__main__":
    sys.exit(main())
