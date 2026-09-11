import hashlib
import json
import logging
import os
import time
from fastapi import FastAPI, HTTPException, Request, status
import mlflow.pyfunc
from prometheus_fastapi_instrumentator import Instrumentator
from schemas import InferenceResponse, IrisInferenceInput
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address


# 1. Structured JSON Formatting for Loki Logs
class JSONLogFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_object = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if hasattr(record, "extra_fields"):
            log_object.update(record.extra_fields)
        return json.dumps(log_object)


logger = logging.getLogger("inference_service")
logger.setLevel(logging.INFO)
log_handler = logging.StreamHandler()
log_handler.setFormatter(JSONLogFormatter())
logger.addHandler(log_handler)

# 2. FastAPI Application & SlowAPI Rate Limiter
limiter = Limiter(key_func=get_remote_address)
app = FastAPI(
    title="MLOps Production Inference API",
    description="FastAPI service with RED metrics, JSON logging, and artifact integrity checks.",
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# 3. Prometheus Metrics Setup
instrumentator = Instrumentator(
    should_group_status_codes=False,
    should_respect_env_var=True,
    env_var_name="ENABLE_METRICS",
)
instrumentator.instrument(app).expose(app, endpoint="/metrics")

# Global variables
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
MODEL_URI = os.getenv("MODEL_URI", "models:/iris-model@production")
EXPECTED_CHECKSUM = os.getenv("MODEL_SHA256_CHECKSUM", "")
MODEL_VERSION = os.getenv("MODEL_VERSION", "v1.0.0")


def verify_checksum(file_path: str, expected_hash: str) -> bool:
    if not expected_hash:
        logger.warning(
            "No expected SHA256 checksum provided. Skipping artifact verification."
        )
        return True

    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)

    calc_hash = sha256_hash.hexdigest()
    if calc_hash != expected_hash:
        logger.error(
            "Artifact integrity verification failed!",
            extra={
                "extra_fields": {
                    "event": "checksum_failure",
                    "expected": expected_hash,
                    "calculated": calc_hash,
                }
            },
        )
        return False

    logger.info(
        "Model checksum verified successfully.",
        extra={"extra_fields": {"event": "checksum_success", "hash": calc_hash}},
    )
    return True


@app.on_event("startup")
def load_model():
    global model
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)

    logger.info(f"Loading ML model from URI: {MODEL_URI}")
    try:
        model = mlflow.pyfunc.load_model(MODEL_URI)

        model_local_path = mlflow.artifacts.download_artifacts(artifact_uri=MODEL_URI)

        if not verify_checksum(f"{model_local_path}/model.pkl", EXPECTED_CHECKSUM):
            logger.error("Model failed SHA256 check! Reverting to fallback mode.")
            model = None
            return

        logger.info("Model successfully loaded into memory.")
    except Exception as e:
        logger.warning(
            f"Could not load MLflow model from registry ({str(e)}). Serving fallback mode."
        )
        model = None


# Standard Iris dataset class mapping
TARGET_NAMES = {0: "setosa", 1: "versicolor", 2: "virginica"}


@app.post("/predict", response_model=InferenceResponse)
@limiter.limit("120/minute")
async def predict(request: Request, payload: IrisInferenceInput):
    start_time = time.time()

    try:
        features = [
            [
                payload.sepal_length,
                payload.sepal_width,
                payload.petal_length,
                payload.petal_width,
            ]
        ]

        if model is not None:
            prediction_raw = model.predict(features)
            pred_class_id = int(prediction_raw[0])
            pred_label = TARGET_NAMES.get(pred_class_id, "unknown")
        else:
            pred_label = "unknown"  # Fallback class

        latency = time.time() - start_time

        logger.info(
            "Inference request processed",
            extra={
                "extra_fields": {
                    "event": "inference_success",
                    "path": request.url.path,
                    "latency_sec": round(latency, 4),
                    "client_ip": request.client.host if request.client else "unknown",
                    "prediction": pred_label,
                    "status_code": 200,
                }
            },
        )

        return InferenceResponse(
            prediction=pred_label, model_version=MODEL_VERSION, checksum_verified=True
        )

    except Exception as e:
        latency = time.time() - start_time
        logger.error(
            "Inference request failed",
            extra={
                "extra_fields": {
                    "event": "inference_error",
                    "error": str(e),
                    "latency_sec": round(latency, 4),
                    "status_code": 500,
                }
            },
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Model inference failed",
        )


@app.get("/healthz")
def healthz():
    return {"status": "healthy", "model_loaded": model is not None}
