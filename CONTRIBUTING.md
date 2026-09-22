# Contributing

Keep changes small and focused. Include the problem, resulting behavior and how you
checked the directly affected feature. Interface changes should include a screenshot.

Preserve Drop's reference-only behavior: removing or clearing an item must never delete
or move the original file. Do not add global event monitoring, analytics or network access
as an incidental change. Discuss product-scope changes in an issue first.

Tests must use isolated temporary files and unique pasteboards. Do not use real user
folders, the general clipboard, system preferences or other apps' data as fixtures.

Report issues with the macOS version, a short reproduction and expected/actual behavior.
Remove personal file paths and private content before posting logs or screenshots.
