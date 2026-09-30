import sys

import torch


def main() -> int:
    # Exercise the real WhisperX runtime entry paths used by transcription
    # and diarization, not just top-level package imports.
    from whisperx.transcribe import transcribe_task  # noqa: F401
    from whisperx.diarize import DiarizationPipeline  # noqa: F401

    # TorchCodec must be able to discover the local FFmpeg DLLs through
    # sitecustomize.py without relying on an external/global FFmpeg.
    import torchcodec  # noqa: F401

    # Verify the local pyannote StatsPool single-frame fix functionally.
    from pyannote.audio.models.blocks.pooling import StatsPool

    sample = torch.ones((1, 2, 1), dtype=torch.float32)
    pooled = StatsPool()(sample)

    if not torch.isfinite(pooled).all():
        print("ERROR: pyannote StatsPool single-frame output contains NaN/Inf.", file=sys.stderr)
        return 1

    # mean=[1,1], std must be [0,0] for a single frame.
    if not torch.equal(pooled[:, 2:], torch.zeros_like(pooled[:, 2:])):
        print("ERROR: pyannote StatsPool single-frame std is not zero.", file=sys.stderr)
        return 1

    print("[OK] WhisperX functional runtime smoke")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
