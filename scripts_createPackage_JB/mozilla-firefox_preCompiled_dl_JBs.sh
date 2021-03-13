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
# Script: Script to create a Slackware package from the mozilla-firefox stable pre-compiled
#
# Last update: 13/03/2021
#
echo -e "\\n# Script to create a Slackware package from the mozilla-firefox stable pre-compiled #\\n"

if [ "$USER" != "root" ]; then
    echo -e "\\nNeed to be superuser (root)\\nExiting\\n"
else
    languageDl=$2

    case "$(uname -m)" in
        "x86_64" ) archDL="Linux 64-bit in"
            archFinal="x86_64"
            ;;
        "i?86" ) archDL="Linux in"
            archFinal="i586"
            ;;
    esac

    progName="mozilla-firefox" # last tested: "86.0.1"
    tag="1_JB"
    folderDest=$(pwd)

    if [ "$languageDl" == '' ]; then
        echo -en "Which language you want? (e.g. en-US, en-GB, pt-BR) (hit enter to insert en-GB): "
        read -r languageDl
    fi

    if [ "$languageDl" == '' ]; then
        languageDl="en-GB"
    fi
    taglanguageDl="${tag}_${languageDl//-/_}"

    echo
    wget "https://www.mozilla.org/firefox/all/" -O "${progName}_latest"
    linkDl=$(grep "$archDL" "${progName}_latest" | grep "$languageDl" | cut -d '"' -f2 | head -n 1)

    version=$(grep "latest-firefox" "${progName}_latest" | cut -d '"' -f8- | cut -d '"' -f1)

    countChar=${#version}
    if [ "$countChar" == '4' ]; then
        version="${version}.0"
    fi

    rm "${progName}_latest"
    echo -e "Link to download: $linkDl"

    if [ "$linkDl" == '' ]; then
        echo "Error: Link to download is empty. Not found version with \"$languageDl\" language"
        exit
    fi

    fileName="firefox-$version.tar.bz2"
    echo -e "\\nLatest Firefox stable version: $fileName"

    installedVersion=$(find /var/log/packages/ | grep "firefox" | cut -d '-' -f3)
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

    echo
    wget -c "$linkDl" -O "$fileName"

    tar -xvf "$fileName"
    rm "$fileName"

    fileNameFinal="${progName}-$version-$archFinal"
    mv firefox "$fileNameFinal"

    cd "$fileNameFinal" || exit

    if [ "$archFinal" == "x86_64" ]; then
        libFolder="lib64"
    else
        libFolder="lib"
    fi
    firefoxFolder="usr/$libFolder/firefox"

    mkdir -p "$firefoxFolder"
    mv ./* "$firefoxFolder" 2> /dev/null

    mkdir -p "$libFolder/mozilla/plugins/"

    mkdir -p usr/bin/
    ln -s "../$libFolder/firefox/firefox" usr/bin/firefox

    mkdir -p install
    echo "# HOW TO EDIT THIS FILE:
# The \"handy ruler\" below makes it easier to edit a package description. Line
# up the first '|' above the ':' following the base package name, and the '|' on
# the right side marks the last column you can put a character in. You must make
# exactly 11 lines for the formatting to be correct. It's also customary to
# leave one space after the ':'.

               |-----handy-ruler------------------------------------------------------|
mozilla-firefox: mozilla-firefox (Mozilla Firefox Web browser)
mozilla-firefox:
mozilla-firefox: This project is a redesign of the Mozilla browser component written
mozilla-firefox: using the XUL user interface language. Firefox empowers you to
mozilla-firefox: browse faster, more safely and more efficiently than with any other
mozilla-firefox: browser.
mozilla-firefox:
mozilla-firefox: Visit the Mozilla Firefox project online:
mozilla-firefox: http://www.mozilla.org/projects/firefox/
mozilla-firefox:
mozilla-firefox:" > install/slack-desc

    mkdir -p usr/share/applications/
    echo "[Desktop Entry]
Exec=firefox %u
Icon=firefox
Type=Application
Categories=Network;
Name=Firefox
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
X-KDE-StartupNotify=true" > "usr/share/applications/${progName}.desktop"

    mkdir -p usr/share/icons/hicolor/16x16/apps/
    mkdir -p usr/share/icons/hicolor/32x32/apps/
    mkdir -p usr/share/icons/hicolor/48x48/apps/

    cp "$firefoxFolder/browser/chrome/icons/default/default16.png" usr/share/icons/hicolor/16x16/apps/firefox.png
    cp "$firefoxFolder/browser/chrome/icons/default/default32.png" usr/share/icons/hicolor/32x32/apps/firefox.png
    cp "$firefoxFolder/browser/chrome/icons/default/default48.png" usr/share/icons/hicolor/48x48/apps/firefox.png

    /sbin/makepkg -l y -c n "$folderDest/${fileNameFinal}-${taglanguageDl}.txz"

    cd .. || exit
    rm -r "$fileNameFinal"
fi
