import sys
from pathlib import Path

import lightning
import torch
from lightning.pytorch.utilities.migration import pl_legacy_patch


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_checkpoint.py <checkpoint>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1]).resolve()
    if not path.is_file():
        print(f"MISSING: {path}")
        return 2

    try:
        with pl_legacy_patch():
            checkpoint = torch.load(
                path,
                map_location=torch.device("cpu"),
                weights_only=False,
            )
    except Exception as exc:
        print(f"BROKEN: cannot load checkpoint: {type(exc).__name__}: {exc}")
        return 1

    checkpoint_version = checkpoint.get("pytorch-lightning_version")
    runtime_version = lightning.__version__

    if checkpoint_version == runtime_version:
        print(f"OK: checkpoint={checkpoint_version} runtime={runtime_version}")
        return 0

    print(f"OUTDATED: checkpoint={checkpoint_version} runtime={runtime_version}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
