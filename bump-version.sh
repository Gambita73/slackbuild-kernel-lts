#!/bin/bash
#
# Update system/kernel-lts to a new 6.1.y release.
#
#   ./bump-version.sh            # newest 6.1.y listed on kernel.org
#   ./bump-version.sh 6.1.193    # a specific version
#
# Downloads the tarball from kernel.org, checks its PGP signature against
# the kernel.org release keys (Linus Torvalds / Greg Kroah-Hartman, fetched
# by WKD), then writes the new VERSION and MD5SUM into the .info file and
# the SlackBuild. Set VERIFY=no to skip the signature check, FORCE=yes to
# redo the current version, SERIES=6.6 (etc.) to follow another branch.
#
# Needs: bash, curl, xz, GnuPG 2 (set GPG=gpg2 if "gpg" is GnuPG 1.x),
# md5sum, sed, grep, sort -V.

set -euo pipefail

SERIES=${SERIES:-6.1}
VERIFY=${VERIFY:-yes}
GPG=${GPG:-gpg}
FORCE=${FORCE:-no}

cd "$(dirname "$0")"
PKGDIR=system/kernel-lts
INFO=$PKGDIR/kernel-lts.info
SB=$PKGDIR/kernel-lts.SlackBuild

if [ $# -ge 1 ]; then
  NEW=$1
else
  SERIES_RE=${SERIES//./\\.}
  NEW=$(curl -fsSL https://www.kernel.org/releases.json \
        | grep -oE "\"version\": *\"${SERIES_RE}\.[0-9]+\"" \
        | grep -oE '[0-9]+(\.[0-9]+)+' | sort -V | tail -n 1 || true)
  if [ -z "$NEW" ]; then
    echo "kernel.org no longer lists a $SERIES.y release (end of life?)." >&2
    exit 1
  fi
fi

case "$NEW" in
  "$SERIES".[0-9]*) ;;
  *) echo "Version $NEW is not in the $SERIES series." >&2 ; exit 1 ;;
esac

CUR=$(sed -n 's/^VERSION="\(.*\)"/\1/p' "$INFO")
CURMD5=$(sed -n 's/^MD5SUM="\(.*\)"/\1/p' "$INFO")
if [ "$NEW" = "$CUR" ] && [ -n "$CURMD5" ] && [ "$FORCE" != "yes" ]; then
  echo "kernel-lts is already at $NEW."
  exit 0
fi

MAJOR=${NEW%%.*}
URL=https://cdn.kernel.org/pub/linux/kernel/v$MAJOR.x/linux-$NEW.tar.xz

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "Downloading $URL"
curl -fL --retry 3 -o "$WORK/linux-$NEW.tar.xz" "$URL"

if [ "$VERIFY" = "yes" ]; then
  echo "Checking PGP signature"
  curl -fsSL --retry 3 -o "$WORK/linux-$NEW.tar.sign" "${URL%.xz}.sign"
  export GNUPGHOME="$WORK/gnupg"
  mkdir -m 700 "$GNUPGHOME"
  "$GPG" --batch --quiet --auto-key-locate clear,wkd \
      --locate-keys torvalds@kernel.org gregkh@kernel.org
  xz -cd "$WORK/linux-$NEW.tar.xz" \
    | "$GPG" --batch --verify "$WORK/linux-$NEW.tar.sign" -
fi

MD5=$(md5sum "$WORK/linux-$NEW.tar.xz" | cut -d' ' -f1)

sed -i \
  -e "s|^VERSION=\".*\"|VERSION=\"$NEW\"|" \
  -e "s|^DOWNLOAD=\".*\"|DOWNLOAD=\"$URL\"|" \
  -e "s|^MD5SUM=\".*\"|MD5SUM=\"$MD5\"|" \
  "$INFO"
sed -i "s|^VERSION=\${VERSION:-.*}|VERSION=\${VERSION:-$NEW}|" "$SB"

# A new upstream version starts again at BUILD 1.
if [ "$NEW" != "$CUR" ]; then
  sed -i "s|^BUILD=\${BUILD:-.*}|BUILD=\${BUILD:-1}|" "$SB"
fi

echo "kernel-lts: $CUR -> $NEW (md5 $MD5)"
