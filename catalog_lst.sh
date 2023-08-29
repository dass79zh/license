#!/bin/sh
#[ $# -ne 1 ] && { echo "Usage: $0 <package>" >&2; exit 1; }

pkglist="pkg.lst"

pkg_regex=
while read filename; do
  pkg_regex="${pkg_regex:+$pkg_regex|}$filename"

done <"${pkglist}"

#done <<EOF
#bash
#samba
#libxxhash0
#libgdbm6
#libunistring2
#xrstools
#acme
#python3-xrstools

#EOF
pkg_regex="(${pkg_regex})"

echo $pkg_regex

index_file_name="Packages.xz"
#index_file_name="p.txt"

package=
filename=
version=
srcpkg=
postfix=

xzcat "$index_file_name" |
sed -nre '
  /^Package: '"$pkg_regex"'$/{
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
      echo "*** Package: $package"
      echo "*** Source package: $srcpkg"
      if [ -n "$srcpkg" ]; then
         postfix=1
      else
        srcpkg="$package"
        echo "*** Source package: $srcpkg"
      fi
      echo "*** filename: $filename"
      pkg_ver="${filename%_*.deb}"
      echo "*** pkg_ver: $pkg_ver"
      pkg_ver="${pkg_ver#*_}"
      echo "*** postfix: ${postfix}"

      if [ -n ${postfix} ]; then
         pkg_ver="${pkg_ver%+b[0-9]*}"
         postfix=
      echo "*** pkg_ver: $pkg_ver"

      else
        echo 111111111111111
      fi
      #pkg_ver="${pkg_ver#*+}"
      echo "*** pkg_ver: $pkg_ver"

      license_path="${filename#*pool/}"

      license_path="${license_path%/*.deb}"
      srcpkg="${license_path#*/*/}"
      #license_path="${license_path%+*}"
      echo "*** license_path: $license_path"
      echo "*** srcpkg: $srcpkg"
      
      pkg_name="${package%%_*}"
      [ -z "$pkg_name" ] && { echo "Package name not provided" >&2; exit 1; }
      web_prefix="https://metadata.ftp-master.debian.org/changelogs"
      pkg_url="${web_prefix}/${license_path}/${srcpkg}_${pkg_ver}_copyright"
      ( 
        echo -n "$pkg_name: "
        echo -n "$pkg_ver: "
        echo "Getting $pkg_url" >&2
        curl --no-progress-meter -f "$pkg_url" |
        sed -ne '/^License/s/^.*:\s*//p' |
        sort |
        uniq |
        tr '\n' ',' |
        sed -e 's/,$//'
        echo
      )>>license.txt
      
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
