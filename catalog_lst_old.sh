#!/bin/sh
#[ $# -ne 1 ] && { echo "Usage: $0 <package>" >&2; exit 1; }

pkglist="pkg.lst"

while read line; do

package="$line"

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

function get_copyright {

( 
 echo -n "$pkg_name,"
 echo -n "$pkg_ver,"
 echo "Getting $pkg_url" >&2
 wget -O - "$1" |
 sed -ne '/^License/s/^.*:\s*//p' |
 sort |
 uniq |
 tr '\n' ',' |
 sed -e 's/,$//'
 echo
) >>license.txt

}


pkg_parse "$package"
pkg_ver="${pkg_filename%_*.deb}"
pkg_ver="${pkg_ver#*_}"
pkg_ver="${pkg_ver%+*}"
#echo "$pkg_ver"
license_path="${pkg_filename#*pool/}"
#echo $license_path
license_path1="${license_path%/*.deb}"
license_path="${license_path%_*.deb}"
#echo $license_path1
#license_path="${license_path%+*}"
pkg_name="${package%%_*}"
[ -z "$pkg_name" ] && { echo "Package name not provided" >&2; exit 1; }
web_prefix="https://metadata.ftp-master.debian.org/changelogs"


pkg_src1="${pkg_filename}"
#echo ${pkg_src1}
pkg_src1=`echo ${pkg_src1} | sed -e s/"^Source: "// -e s/.pool.*// -e s/" .*$"//`

echo  "${pkg_src1}"
#echo "${pkg_src1:0:1}/${pkg_src1}/${pkg_src1}_${pkg_ver}"

pkg_src="${pkg_filename%:*}"
 if [ "$pkg_src" == "Source" ]; then
    license_path="${license_path1}/${pkg_src1}_${pkg_ver}"
    echo ${license_path}
    pkg_url="${web_prefix}/${license_path}_copyright"
    #echo "${pkg_url}" 
    get_copyright "$pkg_url"
    #exit
  else
  pkg_url="${web_prefix}/${license_path}_copyright"
  #echo $pkg_url
  get_copyright "$pkg_url"  
 fi

done < $pkglist