import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

from logs.logger import log


def read_csv(file_path):
    """Read a CSV file and return it as a pandas DataFrame."""
    log.info("Reading CSV file: %s", file_path)
    data = pd.read_csv(file_path)
    log.info("Read %d rows", len(data))
    return data


if __name__ == "__main__":
    file_path = BASE_DIR / "data" / "input" / "employees.csv"
    data = read_csv(file_path)
    print(data)
