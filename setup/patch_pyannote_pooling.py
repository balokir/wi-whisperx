import argparse
import sys
from pathlib import Path


OLD = """\
        if weights is None:
            mean = sequences.mean(dim=-1)
            std = sequences.std(dim=-1, correction=1)
            return torch.cat([mean, std], dim=-1)
"""

FIXED = """\
        if weights is None:
            mean = sequences.mean(dim=-1)
            if sequences.size(dim=-1) > 1:
                std = sequences.std(dim=-1, correction=1)
            else:
                std = torch.zeros_like(mean)
            return torch.cat([mean, std], dim=-1)
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("path")
    args = parser.parse_args()

    if args.check == args.apply:
        print("ERROR: specify exactly one of --check or --apply", file=sys.stderr)
        return 2

    path = Path(args.path)
    if not path.is_file():
        print(f"ERROR: pyannote pooling file not found: {path}", file=sys.stderr)
        return 1

    text = path.read_text(encoding="utf-8")

    if FIXED in text:
        print("[OK] pyannote StatsPool single-frame fix")
        return 0

    if OLD not in text:
        print(
            "ERROR: pyannote pooling implementation is neither the expected "
            "unpatched form nor the known fixed form. Refusing to patch.",
            file=sys.stderr,
        )
        return 1

    if args.check:
        print("[BROKEN] pyannote StatsPool single-frame fix missing")
        return 1

    backup = Path(str(path) + ".pre-whisperx-local.bak")
    if not backup.exists():
        backup.write_text(text, encoding="utf-8", newline="\n")

    updated = text.replace(OLD, FIXED, 1)
    path.write_text(updated, encoding="utf-8", newline="\n")

    check = path.read_text(encoding="utf-8")
    if FIXED not in check:
        print("ERROR: pyannote pooling patch verification failed.", file=sys.stderr)
        return 1

    print("[FIX] pyannote StatsPool single-frame fix")
    print("[OK] pyannote StatsPool single-frame fix")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
