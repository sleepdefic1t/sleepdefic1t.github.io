#!/usr/bin/env bash

set -eo pipefail

cd "$(dirname "$0")"

# HTML
pandoc ../cv/downey_simon_engineer_cv.md -o ../cv/index.html \
  --template=template.html \
  --metadata title="Simon Downey - CV" \
  -f markdown-citations \
  --lua-filter=external-links.lua \
  --wrap=none

tidy -i -w 0 -q -m --tidy-mark no ../cv/index.html 2>/dev/null || true

# PDF
pandoc ../cv/downey_simon_engineer_cv.md \
  --template=template.html \
  --metadata title="Simon Downey - CV" \
  -f markdown-citations \
  --lua-filter=external-links.lua \
  --lua-filter=two-column.lua \
  --wrap=none \
  -o - \
  | weasyprint -s pdf.css --base-url ../cv/ - ../cv/downey_simon_engineer_cv.pdf
