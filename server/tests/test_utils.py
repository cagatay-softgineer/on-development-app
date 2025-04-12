from util.utils import ms2FormattedDuration, obfuscate
import os
import sys
import pytest

# Ensure repository root is in sys.path so that the 'util' module is importable.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


def test_ms2FormattedDuration():
    # 0 ms => "00:00:00"
    assert ms2FormattedDuration(0) == "00:00:00"
    # 3661000 ms => 1 hour, 1 minute, 1 second
    assert ms2FormattedDuration(3661000) == "01:01:01"


def test_obfuscate():
    # Ensure the obfuscate function returns a string of 12 uppercase characters.
    result = obfuscate("test")
    assert isinstance(result, str)
    assert len(result) == 12
    assert result == result.upper()


if __name__ == "__main__":
    pytest.main()
