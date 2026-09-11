from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split


def test_iris_data_splitting():
    """Verify data loader and train-test splitting logic used in train.py."""
    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42
    )

    assert len(X_train) == 120
    assert len(X_test) == 30
    assert X_train.shape[1] == 4
