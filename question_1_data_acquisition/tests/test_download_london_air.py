import unittest
from datetime import date
from unittest.mock import Mock, patch

import requests

from scripts.download_london_air import (
    ApiClient,
    build_site_rows,
    describe_json,
    extract_hourly_rows,
    select_sites,
    strip_at_keys,
)


class ParsingTests(unittest.TestCase):
    def setUp(self):
        self.sites_payload = {
            "Sites": {
                "Site": [
                    {
                        "@SiteCode": "AA1",
                        "@SiteName": "Alpha",
                        "@SiteType": "Urban Background",
                        "@Latitude": "51.50",
                        "@Longitude": "-0.10",
                        "@DateOpened": "2020-01-01",
                        "@DateClosed": "",
                        "Species": [
                            {"@SpeciesCode": "NO2"},
                            {"@SpeciesCode": "PM10"},
                        ],
                    },
                    {
                        "@SiteCode": "BB2",
                        "@SiteName": "Beta",
                        "@SiteType": "Roadside",
                        "@Latitude": "",
                        "@Longitude": None,
                        "@DateOpened": "2010-01-01",
                        "@DateClosed": "2024-12-31",
                        "Species": {"@SpeciesCode": "NO2"},
                    },
                ]
            }
        }

    def test_strip_at_keys_is_recursive(self):
        result = strip_at_keys({"@Outer": [{"@Inner": "x"}]})
        self.assertEqual(result, {"Outer": [{"Inner": "x"}]})

    def test_site_parsing_and_selection(self):
        rows = build_site_rows(self.sites_payload, active_as_of=date(2025, 7, 1))
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["SpeciesCodes"], "NO2;PM10")
        self.assertIsNone(rows[1]["Latitude"])
        self.assertFalse(rows[1]["IsActive"])
        selected = select_sites(rows, "NO2")
        self.assertEqual([row["SiteCode"] for row in selected], ["AA1"])

    def test_species_measurement_period_must_overlap_requested_window(self):
        payload = {
            "Sites": {
                "Site": {
                    "@SiteCode": "AA1",
                    "@DateClosed": "",
                    "Species": {
                        "@SpeciesCode": "NO2",
                        "@DateMeasurementStarted": "2010-01-01",
                        "@DateMeasurementFinished": "2024-12-31",
                    },
                }
            }
        }
        rows = build_site_rows(
            payload,
            active_as_of=date(2025, 7, 1),
            window_start=date(2025, 7, 1),
            window_end=date(2025, 7, 8),
        )
        self.assertEqual(rows[0]["SpeciesCodes"], "NO2")
        self.assertEqual(rows[0]["WindowSpeciesCodes"], "")
        self.assertEqual(select_sites(rows, "NO2"), [])

    def test_species_metadata_is_merged_without_dropping_sites(self):
        base = {
            "Sites": {
                "Site": [
                    {"@SiteCode": "AA1", "@DateClosed": ""},
                    {"@SiteCode": "CC3", "@DateClosed": ""},
                ]
            }
        }
        species = {
            "Sites": {
                "Site": {
                    "@SiteCode": "AA1",
                    "Species": {"@SpeciesCode": "NO2"},
                }
            }
        }
        rows = build_site_rows(base, species_payload=species)
        self.assertEqual([row["SiteCode"] for row in rows], ["AA1", "CC3"])
        self.assertEqual(rows[0]["SpeciesCodes"], "NO2")
        self.assertEqual(rows[1]["SpeciesCodes"], "")

    def test_hourly_data_list(self):
        site = build_site_rows(self.sites_payload)[0]
        payload = {
            "RawAQData": {
                "Data": [
                    {"@MeasurementDateGMT": "2025-07-01 00:00:00", "@Value": "42.5"},
                    {"@MeasurementDateGMT": "2025-07-01 01:00:00", "@Value": ""},
                ]
            }
        }
        rows = extract_hourly_rows(payload, site, "NO2")
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["NO2"], 42.5)
        self.assertIsNone(rows[1]["NO2"])

    def test_hourly_data_single_dictionary(self):
        site = build_site_rows(self.sites_payload)[0]
        payload = {"RawAQData": {"Data": {"@MeasurementDateGMT": "2025-07-01", "@Value": "7"}}}
        rows = extract_hourly_rows(payload, site, "NO2")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["NO2"], 7.0)

    def test_hourly_data_empty_values(self):
        site = build_site_rows(self.sites_payload)[0]
        for value in (None, "", {}):
            with self.subTest(value=value):
                self.assertEqual(extract_hourly_rows({"RawAQData": {"Data": value}}, site, "NO2"), [])

    def test_describe_json_reports_shape_not_values(self):
        shape = describe_json(self.sites_payload)
        self.assertEqual(shape["type"], "dict")
        self.assertIn("Sites", shape["keys"])


class ClientTests(unittest.TestCase):
    @patch("scripts.download_london_air.time.sleep")
    def test_retries_connection_errors_then_succeeds(self, _sleep):
        session = Mock(spec=requests.Session)
        session.headers = {}
        successful = Mock(status_code=200, text='{"ok": true}')
        successful.json.return_value = {"ok": True}
        session.get.side_effect = [requests.ConnectionError("temporary"), successful]
        client = ApiClient(timeout=30, max_retries=3, request_delay=0, session=session)

        status, payload = client.get_json("https://example.test/data")

        self.assertEqual(status, 200)
        self.assertEqual(payload, {"ok": True})
        self.assertEqual(session.get.call_count, 2)
        session.get.assert_called_with("https://example.test/data", timeout=30)


if __name__ == "__main__":
    unittest.main()
