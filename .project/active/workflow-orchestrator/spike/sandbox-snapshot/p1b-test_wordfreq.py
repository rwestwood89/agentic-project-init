import pytest

from wordfreq import main, top_words


def test_counts_and_order():
    r = top_words("the cat sat. The CAT ran! a dog.", n=3)
    assert ("cat", 2) in r
    assert "the" not in dict(r)   # stopword excluded


def test_ties_deterministic():
    assert top_words("bb aa bb aa", n=2) == [("aa", 2), ("bb", 2)]


def test_missing_file_exits_nonzero(capsys, tmp_path):
    missing = tmp_path / "does-not-exist.txt"

    with pytest.raises(SystemExit) as exc_info:
        main([str(missing)])

    assert exc_info.value.code != 0
    assert str(missing) in capsys.readouterr().err
