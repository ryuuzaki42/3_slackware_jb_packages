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
# Script: Script to create a Slackware package from the SkypeForLinux pre-compiled
#
# Last update: 19/02/2021
#
echo -e "\\n# Script to create a Slackware package from the SkypeForLinux pre-compiled #\\n"

if [ -z "$ARCH" ]; then
    case "$(uname -m)" in
        i?86) ARCH="i386" ;;
        arm*) ARCH="arm" ;;
        *) ARCH=$(uname -m) ;;
    esac
fi

if [ "$ARCH" != "x86_64" ]; then
    echo "# Only 64 bits, without 32 bits precompiled package in the $progName repository/release"
    exit 1
fi

if [ "$USER" != "root" ]; then
    echo -e "\\nNeed to be superuser (root)\\nExiting\\n"
else
    progName="skypeforlinux" # last tested: "8.69.76.76"
    linkProg="https://repo.skype.com/deb/pool/main/s/skypeforlinux"
    linkSlackbuilds142Prog="https://slackbuilds.org/slackbuilds/14.2/network/skypeforlinux.tar.gz"

    wget "$linkProg" -O "${progName}-latest"
    dlProgName=$(grep "deb" "${progName}-latest" | cut -d '"' -f8 | tail -n1)

    rm -r "${progName}-latest"
    version=$(echo "$dlProgName" | cut -d '_' -f2)

    installedVersion=$(find /var/log/packages/ | grep "$progName" | cut -d '-' -f2)
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

    mkdir "$progName"
    cd "$progName" || exit

    wget -c "$linkSlackbuilds142Prog"
    wget -c "$linkProg/$dlProgName"

    if [ -e "$progName.tar.gz" ] && [ -e "${progName}"_*"deb" ]; then
        tar zvxf "$progName.tar.gz"
        cp "${progName}"_*"deb" "$progName"
    else
        echo -e "Error: file not found"
        exit
    fi

    versaoProg=$(find "$progName"/"${progName}"_*"deb" | cut -d '_' -f2)
    sed -i "s/VERSION:-.*/VERSION:-$versaoProg}/g" $progName/$progName.SlackBuild
    sed -i "s/tgz/txz/g" $progName/$progName.SlackBuild

    cd "$progName" || exit
    ./"$progName.SlackBuild"

    cd ../../ || exit
    rm -r "$progName"

    mv /tmp/$progName-"$version"*txz .
    echo -e "File moved to: $(pwd)\\n"
fi
