from pydantic import BaseModel, Field, field_validator

class IrisInferenceInput(BaseModel):
    sepal_length: float = Field(..., gt=0, lt=15, description="Sepal length in cm")
    sepal_width: float = Field(..., gt=0, lt=15, description="Sepal width in cm")
    petal_length: float = Field(..., gt=0, lt=15, description="Petal length in cm")
    petal_width: float = Field(..., gt=0, lt=15, description="Petal width in cm")

    @field_validator('*')
    def check_not_nan(cls, v: float) -> float:
        if v != v:  # NaN check
            raise ValueError("Input feature value cannot be NaN")
        return v


class InferenceResponse(BaseModel):
    prediction: str = Field(..., description="Predicted class name")
    model_version: str = Field(..., description="Version of the model serving predictions")
    checksum_verified: bool = Field(..., description="Whether SHA256 integrity check passed")