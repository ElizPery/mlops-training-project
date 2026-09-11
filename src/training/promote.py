import logging
import os

from mlflow.exceptions import MlflowException
from mlflow.tracking import MlflowClient

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("model_promotion")

MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
MODEL_NAME = os.getenv("MODEL_REGISTRY_NAME", "iris-model")


def promote_staging_to_production():
    client = MlflowClient(tracking_uri=MLFLOW_TRACKING_URI)

    # 1. Get current staging version
    try:
        staging_version = client.get_model_version_by_alias(MODEL_NAME, "staging")
    except MlflowException:
        raise RuntimeError(
            f"No active version found with alias '@staging' for model '{MODEL_NAME}'."
        )

    # 2. Archive current production version if it exists
    try:
        prod_version = client.get_model_version_by_alias(MODEL_NAME, "production")
        client.set_registered_model_alias(MODEL_NAME, "archived", prod_version.version)
        logger.info(
            f"Previous production model v{prod_version.version} demoted to '@archived'."
        )
    except MlflowException:
        logger.info("No active production version found. Skipping archiving step.")

    # 3. Promote staging model to production
    client.set_registered_model_alias(MODEL_NAME, "production", staging_version.version)
    client.delete_registered_model_alias(MODEL_NAME, "staging")

    logger.info(
        f"Successfully promoted model '{MODEL_NAME}' v{staging_version.version} to '@production'."
    )


if __name__ == "__main__":
    promote_staging_to_production()
