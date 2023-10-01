#!/bin/sh
#[ $# -ne 1 ] && { echo "Usage: $0 <package>" >&2; exit 1; }

set -o pipefail

debug=y

debug() {
  [ -n "$debug" ] && echo "$@" >&2
}

index_file_name="Packages.xz"
package=
filename=
version=
srcpkg=

xzcat "$index_file_name" |
sed -nre '
  /^Package: libeclipse-jem-util-java$/{
    s/.*:\s*/P	/p
    :loop
    $!{
      n
      /^$/b end
      /^Filename: /s/.*:\s*/F	/p
      /^Source: /s/.*:\s*/S	/p
      b loop
    }
    :end
    p
  }' |

while IFS='	' read tag value; do
  case "$tag" in 
    "")
      debug "*** Package: $package"
      debug "*** Source package: $srcpkg"
      if [ -n "$srcpkg" ]; then
        postfix=1
      else
        postfix=
        srcpkg="$package"
        debug "*** Source package: $srcpkg"
      fi
      debug "*** filename: $filename"
      pkg_ver="${filename%_*.deb}"
      debug "*** pkg_ver: $pkg_ver"
      pkg_ver="${pkg_ver#*_}"
      debug "*** postfix: ${postfix}"

      if [ -n ${postfix} ]; then
        pkg_ver="${pkg_ver%+b[0-9]*}"
        debug "*** pkg_ver: $pkg_ver"
      else
        debug "Version not changed"
      fi
      debug "*** pkg_ver: $pkg_ver"

      license_path="${filename#*pool/}"
      license_path="${license_path%/*.deb}"
      srcpkg="${license_path#*/*/}"
      #license_path="${license_path%+*}"
      debug "*** license_path: $license_path"
      debug "*** srcpkg: $srcpkg"
      
      pkg_name="${package%%_*}"
      [ -z "$pkg_name" ] && { echo "Package name not provided" >&2; exit 1; }
      web_prefix="https://metadata.ftp-master.debian.org/changelogs"
      pkg_url="${web_prefix}/${license_path}/${srcpkg}_${pkg_ver}_copyright"
      {
        echo -n "$pkg_name;"
        echo -n "$pkg_ver;"
        echo -n "$pkg_url;"
        curl -f "$pkg_url" |
        sed -ne '/^License/s/^.*:\s*//p' |
        sort |
        uniq |
        tr '\n' ',' |
        sed -e 's/,$//' || { echo "exit code = $?" >&2; echo "*err*"; }
        #status=$PIPESTATUS
        #if [ $status != 0 ]; then
        #  echo "status = $status" >&2
        #  echo "*err*"
        #fi
        echo 
      } >> license.txt
      
      package=
      filename=
      version=
      srcpkg=
      ;;
    "P")
      package="$value"
      ;;
    "F")
      filename="$value"
      ;;
    "S")
      srcpkg="$value"
      ;;
    *)
      echo "Unknown tag $tag" >&2
      ;;
  esac
done
