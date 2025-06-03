# use_model.py

import torch
from models.pomodoro_model import load_pomodoro_model, IDX_TO_PATTERN

device = 'cuda' if torch.cuda.is_available() else 'cpu'
device = 'cpu'
model = load_pomodoro_model("models/pomodoro_model.pth", device=device)

def predict(duration_minutes: float) -> dict:
    x = torch.tensor([[duration_minutes]], dtype=torch.float32).to(device)
    with torch.no_grad():
        pat_logits, sess_pred, break_pred = model(x)
        pattern_idx = torch.argmax(pat_logits, dim=1).item()
        pattern = IDX_TO_PATTERN[pattern_idx]
        sessions = sess_pred[0].cpu().round().clamp(min=0).int().tolist()
        needed = pattern.count('W')
        sessions = sessions[:needed]
        breaks = break_pred[0].cpu().round().clamp(min=0).int().tolist()
        short_break = breaks[0]
        long_break = breaks[1] if 'L' in pattern else None
        # Enforce: long_break > short_break if long_break exists
        if long_break is not None and long_break <= short_break:
            long_break = short_break + 5
    return {
        "duration_minutes": duration_minutes,
        "pattern": pattern,
        "work_sessions": sessions,
        "short_break": short_break,
        "long_break": long_break
    }

# Example usage:
print(predict(115))