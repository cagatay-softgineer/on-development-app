# pomodoro_model.py

import torch
import torch.nn as nn

# You need these constants (set exactly as during training)
PATTERN_LIST = [
    "WSW", "WSWSWL", "WSWSWSWL", "WSWSWSWL+WSWS", "2×WSWSWL", "2×WSWSWSWL"
]
IDX_TO_PATTERN = {i: p for i, p in enumerate(PATTERN_LIST)}
MAX_SESSIONS = 8

class PomodoroNet(nn.Module):
    def __init__(self, num_patterns=len(PATTERN_LIST), max_sessions=MAX_SESSIONS):
        super().__init__()
        self.shared = nn.Sequential(
            nn.Linear(1, 64),
            nn.ReLU(),
            nn.Linear(64, 64),
            nn.ReLU()
        )
        self.pattern_head = nn.Linear(64, num_patterns)
        self.sessions_head = nn.Linear(64, max_sessions)
        self.breaks_head = nn.Linear(64, 2)
    def forward(self, x):
        features = self.shared(x)
        pattern_logits = self.pattern_head(features)
        sessions_pred = self.sessions_head(features)
        breaks_pred = self.breaks_head(features)
        return pattern_logits, sessions_pred, breaks_pred

def load_pomodoro_model(model_path, device='cpu'):
    model = PomodoroNet()
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.eval()
    return model