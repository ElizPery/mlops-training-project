import hashlib
import json
import logging
import os

import joblib
import mlflow
import mlflow.sklearn
from mlflow.tracking import MlflowClient
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("model_training")

MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
EXPERIMENT_NAME = os.getenv("MLFLOW_EXPERIMENT_NAME", "iris-classification-prod")
MODEL_REGISTRY_NAME = os.getenv("MODEL_REGISTRY_NAME", "iris-model")

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "minio")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "minio123")
MLFLOW_S3_ENDPOINT_URL = os.getenv("MLFLOW_S3_ENDPOINT_URL", "http://localhost:9000")

os.environ["AWS_ACCESS_KEY_ID"] = AWS_ACCESS_KEY_ID
os.environ["AWS_SECRET_ACCESS_KEY"] = AWS_SECRET_ACCESS_KEY
os.environ["MLFLOW_S3_ENDPOINT_URL"] = MLFLOW_S3_ENDPOINT_URL


def calculate_sha256(file_path: str) -> str:
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()


def train():
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    mlflow.set_experiment(EXPERIMENT_NAME)
    logger.info(f"Connected to MLflow Tracking URI: {MLFLOW_TRACKING_URI}")

    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42
    )

    params = {"n_estimators": 100, "max_depth": 4, "random_state": 42}

    with mlflow.start_run() as run:
        logger.info(f"MLflow Run ID: {run.info.run_id}")
        mlflow.log_params(params)

        clf = RandomForestClassifier(**params)
        clf.fit(X_train, y_train)

        predictions = clf.predict(X_test)
        metrics = {
            "accuracy": accuracy_score(y_test, predictions),
            "precision": precision_score(y_test, predictions, average="macro"),
            "recall": recall_score(y_test, predictions, average="macro"),
            "f1_score": f1_score(y_test, predictions, average="macro"),
        }
        mlflow.log_metrics(metrics)
        logger.info(f"Model Metrics: {json.dumps(metrics)}")

        os.makedirs("outputs", exist_ok=True)
        local_model_path = "outputs/model.pkl"
        joblib.dump(clf, local_model_path)

        sha256_checksum = calculate_sha256(local_model_path)
        mlflow.log_param("sha256_checksum", sha256_checksum)
        logger.info(f"Artifact SHA256 Checksum: {sha256_checksum}")

        # Register model in MLflow Registry
        model_info = mlflow.sklearn.log_model(
            sk_model=clf,
            artifact_path="model",
            registered_model_name=MODEL_REGISTRY_NAME,
        )

        # Set `@staging` alias
        client = MlflowClient(tracking_uri=MLFLOW_TRACKING_URI)
        model_version = model_info.registered_model_version
        client.set_registered_model_alias(
            name=MODEL_REGISTRY_NAME, alias="staging", version=model_version
        )

        logger.info(
            f"Successfully registered model '{MODEL_REGISTRY_NAME}' v{model_version} with alias '@staging'."
        )


if __name__ == "__main__":
    train()
