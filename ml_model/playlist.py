from typing import Union, Dict, List, Tuple
from rich.console import Console
from rich.table import Table


def round_to_nearest_5(x: float) -> int:
    """Round a float x to the nearest multiple of 5."""
    return int((x + 2.5) // 5) * 5


def parse_duration(duration_str: str) -> float:
    """
    Convert a duration string in "MM:SS" (or "HH:MM:SS") format to a total number of minutes.
    For example, "115:00" returns 115.0.
    """
    parts = duration_str.split(":")
    if len(parts) == 2:
        minutes = int(parts[0])
        seconds = int(parts[1])
        return minutes + seconds / 60.0
    elif len(parts) == 3:
        hours = int(parts[0])
        minutes = int(parts[1])
        seconds = int(parts[2])
        return hours * 60 + minutes + seconds / 60.0
    else:
        raise ValueError("Invalid duration string format.")


def format_minutes_to_mmss(minutes: float) -> str:
    """
    Convert a float number of minutes to a formatted "MM:SS" string.
    """
    total_seconds = round(minutes * 60)
    mm = total_seconds // 60
    ss = total_seconds % 60
    return f"{mm:02}:{ss:02}"


# Candidate patterns to consider.
candidate_patterns = [
    {"pattern": "WSW", "w": 2, "s": 1, "l": 0},
    {"pattern": "WSWSWL", "w": 3, "s": 2, "l": 1},
    {"pattern": "WSWSWSWL", "w": 4, "s": 3, "l": 1},
    {"pattern": "WSWSWSWL+WSWS", "w": 6, "s": 4, "l": 1},
    {"pattern": "2×WSWSWL", "w": 6, "s": 4, "l": 2},
    {"pattern": "2×WSWSWSWL", "w": 8, "s": 6, "l": 2},
]


def compute_schedule_for_pattern(
    pattern: Dict,
    T: float,
    work_default: int,
    short_break_default: int,
    long_break_default: int,
    max_work_allowed: int = 35,
    penalty_weight: float = 1.0,
) -> Tuple[Dict, float]:
    """
    For a given candidate pattern and input duration T (in minutes),
    compute the schedule and a combined loss value.

    Steps:
      1. Scale the default durations and round them to the nearest multiple of 5.
      2. Compute the candidate total (schedule_sum).
      3. Calculate the difference (diff) between T and schedule_sum, and round it in 5-min increments.
      4. Distribute this adjustment evenly among work sessions.
      5. Compute the final scheduled sum and a loss value, where:
             loss = |T - final_sum| + penalty,
         and penalty = sum(max(0, work_session - max_work_allowed) for each work session).
    """
    w_count = pattern["w"]
    s_count = pattern["s"]
    l_count = pattern["l"]

    base_total = (
        w_count * work_default +
        s_count * short_break_default +
        l_count * long_break_default
    )
    scaling = T / base_total

    work_candidate = round_to_nearest_5(work_default * scaling)
    short_candidate = round_to_nearest_5(short_break_default * scaling)
    long_candidate = (
        round_to_nearest_5(long_break_default * scaling) if l_count > 0 else 0
    )

    schedule_sum = (
        w_count * work_candidate + s_count * short_candidate + l_count * long_candidate
    )
    diff = T - schedule_sum
    diff_rounded = round(diff / 5) * 5  # adjust in 5-minute increments

    # Distribute diff_rounded among work sessions.
    work_sessions: List[int] = []
    if w_count > 0:
        num_chunks = diff_rounded // 5
        extra_chunks_per_session, remainder = divmod(abs(num_chunks), w_count)
        for i in range(w_count):
            extra = extra_chunks_per_session * 5
            if i < remainder:
                extra += 5
            if num_chunks < 0:
                extra = -extra
            work_sessions.append(work_candidate + extra)
    else:
        work_sessions = []

    final_sum = schedule_sum + diff_rounded
    loss_base = abs(T - final_sum)
    # Penalty for work sessions exceeding max_work_allowed.
    penalty = sum(max(0, ws - max_work_allowed) for ws in work_sessions)
    total_loss = loss_base + penalty_weight * penalty

    schedule = {
        "total_duration": T,
        "sequence": pattern["pattern"],
        "work_sessions": work_sessions,
        "short_break": short_candidate,
        "long_break": long_candidate if l_count > 0 else None,
        "final_sum": final_sum,
        "loss": total_loss,
    }
    return schedule, total_loss


def optimized_pomodoro_playlist(
    total_duration_str: str,
    work_default: int = 25,
    short_break_default: int = 5,
    long_break_default: int = 10,
    max_work_allowed: int = 35,
    penalty_weight: float = 1.0,
    code_format: bool = False,
) -> Union[Dict, str]:
    """
    Generate an optimized Pomodoro schedule given a total duration in "MM:SS" (or "HH:MM:SS") format.

    The algorithm iterates over candidate patterns and selects the one that minimizes
    the combined loss (|input duration - final scheduled time| plus penalty for oversized work sessions).

    If code_format is True, returns a colon-separated string in the format:
      input_duration:sequence:session1:session2:...:sessionN:loss=<MM:SS>
    Otherwise, returns a dictionary with schedule details.
    """
    T = parse_duration(total_duration_str)
    best_schedule = None
    best_loss = float("inf")
    for pattern in candidate_patterns:
        schedule, loss = compute_schedule_for_pattern(
            pattern,
            T,
            work_default,
            short_break_default,
            long_break_default,
            max_work_allowed,
            penalty_weight,
        )
        if loss < best_loss:
            best_loss = loss
            best_schedule = schedule

    best_schedule["input_duration_str"] = total_duration_str
    best_schedule["loss"] = best_loss

    if code_format:
        parts = [total_duration_str, best_schedule["sequence"]]
        work_index = 0
        for ch in best_schedule["sequence"]:
            if ch == "W":
                parts.append(str(best_schedule["work_sessions"][work_index]))
                work_index += 1
            elif ch == "S":
                parts.append(str(best_schedule["short_break"]))
            elif ch == "L":
                parts.append(str(best_schedule["long_break"]))
        # Append loss formatted as MM:SS.
        parts.append(f"loss={format_minutes_to_mmss(best_loss)}")
        return ":".join(parts)
    else:
        # Also include a formatted loss in the returned dictionary.
        best_schedule["loss_formatted"] = format_minutes_to_mmss(best_loss)
        return best_schedule


def test_all_rich() -> None:
    """
    Run tests on a variety of total durations and display the results in a formatted table using rich.
    The "Loss" column now shows the loss in MM:SS format.
    """
    durations = [
        "45:30",
        "50:45",
        "55:20",
        "60:00",
        "62:15",
        "67:33",
        "70:10",
        "72:05",
        "75:15",
        "78:40",
        "80:00",
        "83:47",
        "85:30",
        "90:00",
        "92:15",
        "95:45",
        "100:20",
        "105:45",
        "110:00",
        "115:30",
        "120:00",
        "125:15",
        "130:00",
        "135:22",
        "140:15",
        "145:50",
        "150:15",
        "155:00",
        "160:45",
        "165:30",
        "175:00",
        "180:33",
        "185:10",
        "190:00",
        "200:30",
        "210:12",
        "220:00",
        "240:00",
        "255:45",
        "275:45",
        "300:00",
        "330:30",
        "360:00",
    ]
    results = []

    for i, duration in enumerate(durations, start=1):
        res = optimized_pomodoro_playlist(duration)
        work_sessions_str = ", ".join(str(x) for x in res["work_sessions"])
        short_break_str = f'{res["short_break"]} mins'
        long_break_str = (
            f'{res["long_break"]} mins' if res["long_break"] is not None else "-"
        )

        count_S = res["sequence"].count("S")
        count_L = res["sequence"].count("L")
        total_work = sum(res["work_sessions"])
        total_short = res["short_break"] * count_S
        total_long = res["long_break"] * \
            count_L if res["long_break"] is not None else 0
        total_session_time = total_work + total_short + total_long

        results.append(
            {
                "Example": str(i),
                "Input Duration": res["input_duration_str"],
                "Sequence": res["sequence"],
                "Work Sessions": f'{len(res["work_sessions"])} sessions: {work_sessions_str}',
                "Short Breaks": short_break_str,
                "Long Break": long_break_str,
                "Total Session Time": f"{total_session_time} mins",
                "Loss": format_minutes_to_mmss(res["loss"]),
            }
        )

    table = Table(show_header=True, header_style="bold blue", show_lines=True)
    table.add_column("Example", style="dim", width=8)
    table.add_column("Input Duration", justify="center", width=16)
    table.add_column("Sequence", justify="center", width=15)
    table.add_column("Work Sessions", justify="center", width=35)
    table.add_column("Short Breaks", justify="center", width=15)
    table.add_column("Long Break", justify="center", width=15)
    table.add_column("Total Session Time", justify="center", width=20)
    table.add_column("Loss", justify="center", width=15)

    for result in results:
        table.add_row(
            result["Example"],
            result["Input Duration"],
            result["Sequence"],
            result["Work Sessions"],
            result["Short Breaks"],
            result["Long Break"],
            result["Total Session Time"],
            result["Loss"],
        )

    console = Console()
    console.print(table)


# --- Example usage ---
if __name__ == "__main__":
    # Coded output using a total duration string as input.
    result_code_str = optimized_pomodoro_playlist("115:00", code_format=True)
    print("Coded Output:")
    print(result_code_str)
    print("\n------------------------------------------------\n")

    # Dictionary output.
    result_dict = optimized_pomodoro_playlist("115:00", code_format=False)
    print("Dictionary Output:")
    print(result_dict)
    print("\n------------------------------------------------\n")

    # Display all test results using the rich table.
    test_all_rich()
