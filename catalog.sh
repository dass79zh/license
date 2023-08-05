#!/bin/sh
[ $# -ne 1 ] && { echo "Usage: $0 <package>" >&2; exit 1; }
package="$1"

function pkg_parse {

    index_file_name="Packages.xz"
    #index_file_name="p.txt"

    pkg_filename=`
      xzcat "$index_file_name" |
      sed -nE '/^Package: '"$1"'$/{
        :loop
        $!{
          n
          /^$/q
          /^Source:/p
          /^Filename: /s/.*:\s*//p
          b loop
        }
      }'
    `
}

pkg_parse "$package"

pkg_src1="${pkg_filename}"
#pkg_src1="${pkg_src1%pool*}"
echo ${pkg_src1}
pkg_src1=`echo ${pkg_src1} | sed -e s/"^Source: "// -e s/.pool.*//`

pkg_src="${pkg_filename%:*}"
 if [ "$pkg_src" == "Source" ]; then
   pkg_parse "${pkg_src1}"
 fi

pkg_ver="${pkg_filename%_*.deb}"
pkg_ver="${pkg_ver#*_}"
license_path="${pkg_filename#*pool/}"
echo $license_path

license_path="${license_path%_*.deb}"
#license_path="${license_path%+*}"
pkg_name="${package%%_*}"
[ -z "$pkg_name" ] && { echo "Package name not provided" >&2; exit 1; }
web_prefix="https://metadata.ftp-master.debian.org/changelogs"
pkg_url="${web_prefix}/${license_path}_copyright"
echo $pkg_url
#exit
( 
 echo -n "$pkg_name,"
 echo -n "$pkg_ver,"
 echo "Getting $pkg_url" >&2
 curl -f "$pkg_url" |
 sed -ne '/^License/s/^.*:\s*//p' |
 sort |
 uniq |
 tr '\n' ',' |
 sed -e 's/,$//'
 echo
) >>license.txt