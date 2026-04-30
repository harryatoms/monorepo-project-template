from __future__ import annotations

from pathlib import Path


def write_failure_review(
    *, call_name: str, items: list[dict], output_dir: Path | None = None
) -> Path:
    target_dir = output_dir or Path("evals/reviews") / call_name
    target_dir.mkdir(parents=True, exist_ok=True)
    path = target_dir / "latest.md"
    lines = [f"# {call_name} Eval Review", ""]
    for item in items:
        lines.append(f"- {item.get('id')}: {', '.join(item.get('failures', []))}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path
