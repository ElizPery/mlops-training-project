import os

import mlflow
import pandas as pd
from evidently.metric_preset import DataDriftPreset
from evidently.report import Report
from sklearn import datasets


def run_drift_detection():
    # 1. Setup MLflow Tracking
    mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000"))

    print("Loading reference dataset (Iris baseline)...")
    # Load standard Iris dataset as a clean Pandas DataFrame
    iris = datasets.load_iris(as_frame=True)
    reference_data = iris.frame  # Contains sepal/petal features + target

    print("Loading current production prediction logs...")
    # In a real environment, load from your production inference logs or database.
    # For simulation or fallback, we can read a CSV or query recent predictions:
    if os.path.exists("src/monitoring/production_logs.csv"):
        current_data = pd.read_csv("src/monitoring/production_logs.csv")
    else:
        # Fallback simulation: split a portion of iris data to mimic incoming production data
        print("Production logs CSV not found. Simulating current production sample...")
        current_data = reference_data.sample(n=50, random_state=42)

    # Ensure column names align if your inference logs use simplified names
    # e.g., 'sepal length (cm)' -> 'sepal_length'
    reference_data.columns = [
        c.replace(" (cm)", "").replace(" ", "_") for c in reference_data.columns
    ]
    if "target" in current_data.columns:
        current_data.columns = [
            c.replace(" (cm)", "").replace(" ", "_") for c in current_data.columns
        ]

    # 2. Run Evidently Data Drift Report
    print("Running Evidently AI Data Drift Preset...")
    drift_report = Report(
        metrics=[
            DataDriftPreset(),
        ]
    )

    drift_report.run(
        reference_data=reference_data, current_data=current_data, column_mapping=None
    )

    # 3. Extract metrics and log to MLflow
    report_dict = drift_report.as_dict()
    dataset_drift = report_dict["metrics"][0]["result"]["dataset_drift"]
    drift_share = report_dict["metrics"][0]["result"]["share_of_drifted_columns"]

    print(f"Dataset Drift Detected: {dataset_drift}")
    print(f"Share of Drifted Columns: {drift_share * 100}%")

    with mlflow.start_run(run_name="evidently-iris-drift-check"):
        mlflow.log_metric("dataset_drift", 1.0 if dataset_drift else 0.0)
        mlflow.log_metric("share_of_drifted_columns", drift_share)

        report_path = "iris_drift_report.html"
        drift_report.save_html(report_path)
        mlflow.log_artifact(report_path)

    print("Iris drift check completed and successfully pushed to MLflow.")


if __name__ == "__main__":
    run_drift_detection()
