"""Run explicitly named expensive diagnostics; never invoked by routine verification."""
from regression_support import main

if __name__ == "__main__":
    raise SystemExit(main(diagnostic=True))
