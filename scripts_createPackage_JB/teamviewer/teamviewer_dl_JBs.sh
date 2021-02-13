#!/bin/bash
#
# Autor= João Batista Ribeiro
# Bugs, Agradecimentos, Críticas "construtivas"
# Mande me um e-mail. Ficarei Grato!
# e-mail: joao42lbatista@gmail.com
#
# Este programa é um software livre; você pode redistribui-lo e/ou
# modifica-lo dentro dos termos da Licença Pública Geral GNU como
# publicada pela Fundação do Software Livre (FSF); na versão 2 da
# Licença, ou (na sua opinião) qualquer versão.
#
# Este programa é distribuído na esperança que possa ser útil,
# mas SEM NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO a
# qualquer MERCADO ou APLICAÇÃO EM PARTICULAR.
#
# Veja a Licença Pública Geral GNU para mais detalhes.
# Você deve ter recebido uma cópia da Licença Pública Geral GNU
# junto com este programa, se não, escreva para a Fundação do Software
#
# Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# Script: Script to build a Slackware package of teamviewer
# Based in: http://slackbuilds.org/repository/14.2/network/teamviewer/
#
# Last update: 13/02/2021
#
echo "This script create a txz version from teamviewer_arch.deb"

if [ "$USER" != "root" ]; then
    echo -e "\\nNeed to be superuser (root)\\nExiting\\n"
else
    progName="teamviewer" # last tested: "15.15.2"
    tag="1_JB"

    folderDest=$(pwd)
    folderTmp="$folderDest/${progName}_tmp"

    arch=$(uname -m)
    case "$arch" in
        i?86 )
            archDl="i386" ;;
        x86_64 )
            arch="x86_64"
            archDl="amd64" ;;
        * )
            echo "$arch is not supported."
            exit 1 ;;
    esac

    linkVersion="https://www.teamviewer.com/en/download/linux/"
    wget "$linkVersion" -O "${progName}-latest"

    version=$(grep "deb package [/0-9./]" "${progName}-latest" | cut -d '*' -f2 | cut -d '<' -f1 | rev | cut -d ' ' -f1 | rev | head -n 1)
    rm "${progName}-latest"

    installedVersion=$(find /var/log/packages/$progName* | cut -d '-' -f2)
    echo -e "\\n   Latest version: $version\\nVersion installed: $installedVersion\\n"
    if [ "$installedVersion" != '' ]; then
        if [ "$version" == "$installedVersion" ]; then
            echo -e "Version installed ($installedVersion) is equal to latest version ($version)"

            continue=$1
            if [ "$continue" == '' ]; then
                echo -n "Want continue? (y)es - (n)o (hit enter to no): "
                read -r continue
            fi

            if [ "$continue" != 'y' ]; then
                echo -e "\\nJust exiting\\n"
                exit 0
            fi
        fi
    fi

    linkDl="https://download.teamviewer.com/download/linux"
    fileDl="teamviewer_${archDl}.deb"

    wget -c "$linkDl/$fileDl"

    rm -r "$folderTmp" 2> /dev/null
    mkdir -p "$folderTmp"
    cd "$folderTmp" || exit

    if [ -f "$folderDest/teamviewer_${archDl}.deb" ]; then
        ar p "$folderDest/teamviewer_${archDl}.deb" data.tar.xz | tar -xvJ
    else
        ar p "$folderDest/teamviewer_${version}_${archDl}.deb" data.tar.xz | tar -xvJ
    fi

    chown -R root:root .
    find -L . \
    \( -perm 777 -o -perm 775 -o -perm 750 -o -perm 711 -o -perm 555 \
    -o -perm 511 \) -exec chmod 755 {} \; -o \
    \( -perm 666 -o -perm 664 -o -perm 640 -o -perm 600 -o -perm 444 \
    -o -perm 440 -o -perm 400 \) -exec chmod 644 {} \;

    find "$folderTmp" -print0 | xargs -0 file | grep -e "executable" -e "shared object" | grep ELF \
    | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null || true

    # Remove the dangling symlink first
    rm -f $folderTmp/usr/bin/teamviewer

    # Re-create the generic executable
    ( cd $folderTmp/usr/bin; ln -s /opt/teamviewer/tv_bin/script/teamviewer teamviewer )

    # Link icon to /usr/share/pixmaps
    mkdir -p "$folderTmp/usr/share/pixmaps"
    ( ln -sf /opt/teamviewer/tv_bin/desktop/teamviewer.png "$folderTmp/usr/share/pixmaps/teamviewer.png" )

    # Delete deb "legacy" from apt
    rm -r "$folderTmp/etc/apt"

    # Move docs to official place
    mkdir -p "$folderTmp/usr/doc/$progName/"
    mv "$folderTmp"/opt/teamviewer/doc/*txt "$folderTmp/usr/doc/$progName/"
    rm -r "$folderTmp/opt/teamviewer/doc/"

    mkdir -p $folderTmp/etc/rc.d/
    install -m 0644 $folderDest/rc.teamviewerd $folderTmp/etc/rc.d/rc.teamviewerd

    mkdir -p "$folderTmp/install"
    echo "# HOW TO EDIT THIS FILE:
# The \"handy ruler\" below makes it easier to edit a package description.
# Line up the first '|' above the ':' following the base package name, and
# the '|' on the right side marks the last column you can put a character in.
# You must make exactly 11 lines for the formatting to be correct. It's also
# customary to leave one space after the ':' except on otherwise blank lines.

          |-----handy-ruler------------------------------------------------------|
teamviewer: teamviewer (remote control application)
teamviewer:
teamviewer: TeamViewer is a remote control application. TeamViewer provides easy,
teamviewer: fast, and secure remote access to Linux, Windows PCs, and Macs.
teamviewer:
teamviewer: TeamViewer is free for personal use. You can use TeamViewer completely
teamviewer: free of charge to access your private computers or to help your
teamviewer: friends with their computer problems.
teamviewer:
teamviewer: Homepage: https://www.teamviewer.com/
teamviewer:" > "$folderTmp/install/slack-desc"

echo "if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database -q usr/share/applications >/dev/null 2>&1
fi
chmod 753 /etc/teamviewer/" > "$folderTmp/install/doinst.sh"

    cd "$folderTmp" || exit
    /sbin/makepkg -l y -c n "$folderDest/${progName}-${version}-${arch}-${tag}.txz"

    cd "$folderDest" || exit
    rm -r "$folderTmp" "$fileDl"
fi
