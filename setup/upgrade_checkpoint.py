import os
import shutil
import sys
from pathlib import Path

import torch
from lightning.pytorch.utilities.migration import migrate_checkpoint, pl_legacy_patch


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: upgrade_checkpoint.py <checkpoint>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1]).resolve()
    if not path.is_file():
        print(f"ERROR: checkpoint does not exist: {path}", file=sys.stderr)
        return 1

    backup = Path(str(path) + ".bak")
    if not backup.exists():
        shutil.copy2(path, backup)

    # The checkpoint is a fixed asset from the locally installed WhisperX
    # package. Legacy Lightning checkpoints can contain Python objects such as
    # OmegaConf ListConfig, so PyTorch 2.6+ needs weights_only=False here.
    with pl_legacy_patch():
        checkpoint = torch.load(
            path,
            map_location=torch.device("cpu"),
            weights_only=False,
        )

    old_version = checkpoint.get("pytorch-lightning_version", "unknown")
    migrate_checkpoint(checkpoint)
    new_version = checkpoint.get("pytorch-lightning_version", "unknown")

    tmp = path.with_name(path.name + ".upgrade.tmp")
    try:
        torch.save(checkpoint, tmp)
        os.replace(tmp, path)
    finally:
        if tmp.exists():
            tmp.unlink()

    print(f"Checkpoint upgraded: {old_version} -> {new_version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
