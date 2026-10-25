#!/usr/bin/env python3
"""Summarize raw per-render-frame wall intervals in CSV column frame_ms."""

import argparse
import csv
import json
import math
from pathlib import Path
import statistics


def summarize(values):
    if not values or any(not math.isfinite(value) or value <= 0 for value in values):
        raise ValueError("frame_ms deve conter somente números finitos positivos e ao menos uma amostra")
    ordered = sorted(values)
    count = len(ordered)
    slow_count = max(1, math.ceil(count * 0.01))
    return {
        "frames": count,
        "duration_seconds": sum(values) / 1000.0,
        "average_fps": 1000.0 / statistics.mean(values),
        "frame_ms_mean": statistics.mean(values),
        "frame_ms_p95": ordered[math.ceil(count * 0.95) - 1],
        "frame_ms_p99": ordered[math.ceil(count * 0.99) - 1],
        "frame_ms_max": ordered[-1],
        "one_percent_low_fps": 1000.0 / statistics.mean(ordered[-slow_count:]),
        "one_percent_low_frames": slow_count,
        "method": "p95/p99: nearest rank ceil(p*N); 1% low: 1000 / média dos "
                  "ceil(N*0.01) maiores frametimes; FPS médio: 1000 / frametime médio. "
                  "Nenhuma amostra removida; inclui stutters presentes no CSV."
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        with args.csv.open(newline="") as source:
            rows = csv.DictReader(source)
            if not rows.fieldnames or "frame_ms" not in rows.fieldnames:
                raise ValueError("CSV sem coluna frame_ms")
            result = summarize([float(row["frame_ms"]) for row in rows])
        result["source"] = str(args.csv)
        encoded = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(encoded)
        print(encoded, end="")
    except (OSError, ValueError, TypeError) as error:
        parser.exit(1, f"Erro: {error}\n")


if __name__ == "__main__":
    main()
