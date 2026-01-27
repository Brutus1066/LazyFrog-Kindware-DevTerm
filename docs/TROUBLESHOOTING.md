# Troubleshooting

Most issues are quick fixes. This section lists the common ones and how to recover fast.

---

## App does not start

**Likely cause:** PowerShell 7 not installed or blocked by policy.

- Install PowerShell 7: https://github.com/PowerShell/PowerShell/releases
- Try a direct run:
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\src\main.ps1
  ```

---

## GitHub search fails

**Likely cause:** network issue or API rate limit.

- Check connectivity and retry.
- If rate limited, wait a few minutes and try again.

---

## Git tasks fail (exit code 128)

**Likely cause:** Task Runner was started outside a Git repo.

- Open LazyFrog from a folder that contains a `.git` directory.
- Re-run the task.

---

## Output files not found

- GitHub results are stored in the **results/** folder.
- Task history is stored in **history/task-history.json**.

---

## Logs

Logs are saved to:
%LOCALAPPDATA%\LazyFrog-DevTerm\logs

If something fails unexpectedly, check the latest log for a clear error message.
