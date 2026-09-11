import os

import pytest

from src.training.train import train


@pytest.mark.integration
def test_full_training_run_local(monkeypatch, tmp_path):
    """Executes train.py on a local temporary MLflow tracking directory."""
    # Override environment variables to run locally without external MLflow server
    mlflow_dir = tmp_path / "mlruns"
    monkeypatch.setenv("MLFLOW_TRACKING_URI", f"file://{mlflow_dir}")
    monkeypatch.setenv("MODEL_REGISTRY_NAME", "test-iris-model")

    # Run train function
    train()

    # Check that outputs folder and pkl file were generated
    assert os.path.exists("outputs/model.pkl")
