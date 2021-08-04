# I don't know what I'm doing, I just want to get a release out.

if [[ "$#" != 2 ]]; then
   echo "usage: $0 <prev-version> <version>"
   echo "ex: $0 2.0.3 2.0.4"
   exit 1
fi

PREV="$1"
VERSION="$2"

GITDIR="$(dirname "$0")"
PREVDIR="icdiff-$PREV"
OUTDIR="icdiff-$VERSION"
OUTTAR="$OUTDIR.tar.gz"

rm -r "$OUTDIR" || true
cp -r "$PREVDIR" "$OUTDIR"

for x in icdiff.py README.md git-icdiff LICENSE; do
  cp "$GITDIR/$x" "$OUTDIR/$x"
done

sed "s/Version: $PREV/Version: $VERSION/" "$OUTDIR/PKG-INFO" \
    > "$OUTDIR/PKG-INFO.2"
mv "$OUTDIR/PKG-INFO.2" "$OUTDIR/PKG-INFO"
cp "$OUTDIR/PKG-INFO" "$OUTDIR/icdiff.egg-info/"
tar -cvzf "$OUTTAR" "$OUTDIR/"*
