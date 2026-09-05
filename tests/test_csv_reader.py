from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_employees_csv_present():
    path = ROOT / "data" / "input" / "employees.csv"
    assert path.exists()
    header = path.read_text(encoding="utf-8").splitlines()[0]
    assert "employee_id" in header
    assert "email" in header
