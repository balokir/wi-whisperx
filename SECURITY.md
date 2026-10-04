# Security Policy

## Supported versions

Security fixes are provided for the latest published version of `wi-whisperx`.

Older releases may not receive security fixes.

## Reporting a vulnerability

Please do not report security vulnerabilities through public GitHub issues.

Use GitHub's private vulnerability reporting for this repository instead.

Examples of security issues include:

- exposure or unintended logging of credentials or tokens;
- unsafe handling of downloaded artifacts;
- integrity-check bypasses;
- command or argument injection;
- unsafe PowerShell, CMD, or installer behavior;
- release or bootstrap integrity issues;
- vulnerabilities introduced by local compatibility patches.

When reporting a vulnerability, please include:

- the affected version;
- the affected file or component;
- steps to reproduce the issue;
- the expected and actual behavior;
- any relevant logs with secrets removed.

Do not include real Hugging Face tokens, credentials, or other secrets in a report.

## Security model

`wi-whisperx` downloads third-party software and model artifacts from their upstream sources.

Where implemented, executable/archive downloads are pinned and verified using cryptographic hashes before use.

GitHub release packages are distributed as immutable release assets and are verified by the bootstrap installer using the published SHA-256 checksum.

Third-party software and model vulnerabilities should normally be reported to their respective upstream projects unless the issue is specific to how `wi-whisperx` installs, configures, or invokes them.
