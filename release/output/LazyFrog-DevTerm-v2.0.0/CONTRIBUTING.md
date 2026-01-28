# Contributing to LazyFrog DevTerm

Thanks for considering a contribution! This project is small and focused, so guidelines are simple.

---

## How to Contribute

### Reporting Bugs
1. Check existing [issues](https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm/issues) first
2. Open a new issue with:
   - Steps to reproduce
   - Expected vs actual behavior
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Windows version

### Feature Requests
1. Open an issue describing the feature
2. Explain the use case and why it fits LazyFrog's goals

### Pull Requests
1. Fork the repo and create a feature branch
2. Keep changes focused and minimal
3. Test your changes locally
4. Submit a PR with a clear description

---

## Development Setup

```powershell
# Clone the repo
git clone https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm.git
cd LazyFrog-Kindware-DevTerm

# Run from source
pwsh -NoProfile -ExecutionPolicy Bypass -File .\src\main.ps1
```

---

## Code Style

- Use PowerShell approved verbs (Get-, Set-, Show-, etc.)
- Keep functions focused and readable
- Add comments for complex logic
- Test on PowerShell 7+ before submitting

---

## Project Structure

```
src/
├── main.ps1           # Entry point and render loop
├── lib/               # Core modules (config, input, UI)
└── tools/             # Feature modules (github, tasks, system, help)
```

---

## What We're Looking For

- **Bug fixes** — Always welcome
- **UI improvements** — Better layouts, accessibility
- **New task templates** — Useful default tasks
- **Documentation** — Clearer explanations

---

## What We're Not Looking For

- Major architectural changes without discussion
- Features that add complexity without clear benefit
- Dependencies on external services

---

## Code of Conduct

Be respectful, constructive, and helpful. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

Thanks for helping make LazyFrog better! 🐸
