import pandas as pd
import pytest

from nexacommerce.data_loader import CSVLoader


def test_load_valid_csv(tmp_path):
    file_path = tmp_path / "sample.csv"
    file_path.write_text("Col A,Col B\n1,2\n3,4", encoding="utf-8")

    loader = CSVLoader(file_path)
    df = loader.load()

    assert isinstance(df, pd.DataFrame)
    assert df.shape == (2, 2)


def test_load_missing_file_raises_error():
    loader = CSVLoader("file_that_does_not_exist.csv")

    with pytest.raises(FileNotFoundError):
        loader.load()


def test_columns_are_normalized(tmp_path):
    file_path = tmp_path / "sample.csv"
    file_path.write_text(" Col A , Col B \n1,2", encoding="utf-8")

    loader = CSVLoader(file_path)
    df = loader.load()

    assert list(df.columns) == ["col a", "col b"]
