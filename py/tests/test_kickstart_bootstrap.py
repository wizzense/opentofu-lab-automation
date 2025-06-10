from pathlib import Path


def test_kickstart_bootstrap_exists():
    script = Path(__file__).resolve().parents[2] / 'kickstart-bootstrap.sh'
    assert script.exists()
    content = script.read_text()
    assert 'kickstart.cfg' in content
