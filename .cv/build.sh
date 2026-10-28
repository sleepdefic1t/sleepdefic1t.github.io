#!/usr/bin/env bash

set -eo pipefail

cd "$(dirname "$0")"

# HTML
pandoc ../docs/cv/downey_simon_engineer_cv.md -o ../docs/cv/index.html \
  --template=template.html \
  --metadata title="Simon Downey - CV" \
  -f markdown-citations \
  --lua-filter=external-links.lua \
  --wrap=none

tidy -i -w 0 -q -m --tidy-mark no ../docs/cv/index.html 2>/dev/null || true

# PDF
pandoc ../docs/cv/downey_simon_engineer_cv.md \
  -t html5 \
  --template=pdf.html \
  --metadata title="Simon Downey - CV" \
  --metadata author="Simon Downey" \
  -f markdown-citations-smart \
  --lua-filter=pdf.lua \
  --wrap=none \
  -o - \
  | weasyprint --base-url . - ../docs/cv/downey_simon_engineer_cv.pdf
