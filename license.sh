#!/bin/sh
cat /dev/null > license.txt
for deb_name in *.deb; do
  pkg_name="${deb_name%%_*}"
  mkdir tmp
  #ar -p "${deb_name}" |
  7z e -so "${deb_name}" | tar -x -Ctmp/ --wildcards '*copyright'
  (
    echo -n "$pkg_name: "
    find tmp -type f -name copyright -exec sed -ne '/^License/s/^.*:\s*//p' {} + |
    sort |
    uniq |
    tr '\n' ',' |
    sed -e 's/,$//'
    echo
  ) >> license.txt
  rm -r tmp
done
