# Climate Commons Repository Structure

```text
prediction-data-workflow/
│
├── workflows/               # Scripts organized by dataset/experiment
│   ├── EN4/
│   ├── ERA5_HRES/
│   └── ORAS5/
│       ├── <script>.sh      # Original script
│       ├── metadata.yaml    # Machine-readable contract
│       └── README.md        # Auto-generated docs
│
├── docs/                    # Generated documentation
│   ├── _workflows/          # Workflow-specific docs
│   └── index.md             # Registry (auto-generated)
│
├── tests/                   # Validation tests
│   ├── lint.sh              # ShellCheck for bash scripts
│   ├── <workflow>_smoke.sh  # Smoke tests
│   └── infrastructure/      # HPC compatibility tests
│
├── infrastructure/          # Infrastructure manifests
│   └── mn5.yaml             # MareNostrum5 modules/versions
│
├── .github/
│   └── workflows/           # GitHub Actions
│       ├── intake.yml       # Intake Agent
│       ├── validate.yml     # Validation Agent
│       └── docs.yml         # Librarian Agent
│
├── AGENTS.md                # Agent definitions
├── WORKFLOWS.md             # Auto-generated workflow registry
└── README.md                # Project overview
```