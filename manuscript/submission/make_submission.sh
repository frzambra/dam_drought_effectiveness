#!/usr/bin/env bash
# Rebuild the self-contained LaTeX submission package for AGU Water Resources Research.
#
# Run from anywhere:  bash manuscript/submission/make_submission.sh
# Requires: quarto, an R library with the project packages, lualatex.
#
# The package is regenerated from scratch each time, so re-run it after ANY edit to the
# manuscript sources. Never hand-edit manuscript/submission/latex/manuscript.tex: it is a
# build artefact and the next run overwrites it.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MS="$(cd "$HERE/.." && pwd)"              # manuscript/
ROOT="$(cd "$MS/.." && pwd)"              # repo root
OUT="$HERE/latex"

export R_LIBS_USER="${R_LIBS_USER:-$ROOT/renv/library/linux-ubuntu-noble/R-4.6/x86_64-pc-linux-gnu}"

echo "==> rendering manuscript and supporting information"
( cd "$MS/paper"         && quarto render manuscript.qmd )
( cd "$MS/supplementary" && quarto render supplementary.qmd )

echo "==> assembling $OUT"
rm -rf "$OUT"; mkdir -p "$OUT/figures"

# main article: rewrite the figure paths so the package is self-contained
sed 's#\.\./\.\./results/figures/#figures/#g' "$MS/paper/manuscript.tex" > "$OUT/manuscript.tex"

# only the figures the article actually includes
grep -o 'figures/[A-Za-z0-9_.-]*\.\(png\|pdf\)' "$OUT/manuscript.tex" | sort -u | while read -r f; do
  cp "$ROOT/results/${f}" "$OUT/figures/"
done

cp "$MS/paper/agujournal2019.cls" "$OUT/"
cp "$MS/paper/trackchanges.sty"   "$OUT/"   # \usepackage'd by the AGU preamble
cp "$MS/paper/references.bib"     "$OUT/"   # not needed to compile; citations are pre-formatted
cp "$MS/supplementary/supplementary.pdf" "$OUT/supporting_information.pdf"
cp "$HERE/cover_letter.md" "$OUT/"

echo "==> test compile"
( cd "$OUT" && lualatex -interaction=nonstopmode -halt-on-error manuscript.tex >/dev/null \
            && lualatex -interaction=nonstopmode -halt-on-error manuscript.tex >/dev/null )
( cd "$OUT" && rm -f manuscript.aux manuscript.log manuscript.out manuscript.spl build*.log )

echo "==> done: $(pdfinfo "$OUT/manuscript.pdf" | awk '/^Pages/{print $2}') pages"
ls -1 "$OUT" "$OUT/figures"
