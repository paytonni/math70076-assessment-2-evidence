# Question 1: data acquisition

## Source and purpose

This folder contains the London Air Quality Network (LAQN) API workflow used for the Assessment 2 reflection. The script queries site metadata, pollutant-availability metadata and hourly site/species data, saves raw JSON before transformation, and writes processed CSV files.

The saved assessment run requested NO2 observations from 2025-07-01 to 2025-07-08 for the first 20 eligible site codes after deterministic sorting. It produced 3,360 hourly rows and 521 missing values. The returned timestamps ended at 2025-07-07 23:00, so the endpoint behaved like an exclusive upper date boundary in that run.

## Included evidence

- `scripts/download_london_air.py`: complete downloader.
- `tests/test_download_london_air.py`: parsing, site selection, response-shape and retry tests.
- `sample_outputs/saved_run_summary.csv`: concise numerical record of the completed run.

Large raw JSON responses and the full processed table are not included. The summary can be audited against the figures reported in the assessment, while a future live API run may return revised data.

## Reproduce

From the repository root:

```bash
python -m pip install -r requirements.txt
cd question_1_data_acquisition
python -m unittest discover -s tests -v
python scripts/download_london_air.py \
  --start-date 2025-07-01 --end-date 2025-07-08 \
  --species NO2 --max-sites 20 --request-delay 0.5
```

The final command makes live requests and creates `data/raw` and `data/processed`. It should be run sparingly. The script uses a session, a 30-second timeout, bounded retries, exponential backoff and a 0.5-second delay.
