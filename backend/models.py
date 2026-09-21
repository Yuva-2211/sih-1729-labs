"""
models.py — Model architecture definitions (must match training notebook exactly).
These classes are used to reconstruct the trained models from saved state_dicts.
"""

import numpy as np
import torch
import torch.nn as nn

N_QUBITS = 8
N_LAYERS = 3


# ---------------------------------------------------------------------------
# Classical Baseline
# ---------------------------------------------------------------------------

class ClassicalModel(nn.Module):
    def __init__(self, n_features: int = N_QUBITS):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_features, 16), nn.ReLU(),
            nn.Linear(16, 8),          nn.ReLU(),
            nn.Linear(8, 1)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return torch.sigmoid(self.net(x))


# ---------------------------------------------------------------------------
# Hybrid Quantum-Classical Model (VQC with PennyLane)
# ---------------------------------------------------------------------------

def is_pennylane_available() -> bool:
    """Check if PennyLane is installed and importable."""
    try:
        import pennylane
        return True
    except ImportError:
        return False


def build_hybrid_model(n_features: int = N_QUBITS, n_qubits: int = N_QUBITS, n_layers: int = N_LAYERS):
    """
    Build the Hybrid Quantum-Classical model using PennyLane.
    Returns None if PennyLane is not available.
    """
    try:
        import pennylane as qml

        dev = qml.device("default.qubit", wires=n_qubits)

        @qml.qnode(dev, interface="torch", diff_method="backprop")
        def quantum_circuit(inputs, weights):
            qml.AngleEmbedding(inputs, wires=range(n_qubits))
            qml.BasicEntanglerLayers(weights, wires=range(n_qubits))
            return [qml.expval(qml.PauliZ(i)) for i in range(n_qubits)]

        weight_shapes = {"weights": (n_layers, n_qubits)}

        class HybridQuantumModel(nn.Module):
            """Classical pre-processing -> angle encoding -> quantum circuit -> classical post-processing."""

            def __init__(self):
                super().__init__()
                self.pre = nn.Sequential(nn.Linear(n_features, n_qubits), nn.Tanh())
                self.quantum = qml.qnn.TorchLayer(quantum_circuit, weight_shapes)
                self.post = nn.Sequential(nn.Linear(n_qubits, 16), nn.ReLU(), nn.Linear(16, 1))

            def forward(self, x: torch.Tensor) -> torch.Tensor:
                x = self.pre(x) * np.pi   # scale Tanh output [-1,1] -> angle range [−π, π]
                x = self.quantum(x)
                x = self.post(x)
                return torch.sigmoid(x)

        return HybridQuantumModel()

    except ImportError:
        import logging
        logging.getLogger(__name__).warning(
            "PennyLane not installed — cannot instantiate HybridQuantumModel."
        )
        return None

