#!/bin/bash


WORKING_DIR=work


function prep() {
    echo installing debian packs needed for debianization now...
    sudo apt-get install build-essential autoconf automake autotools-dev \
        dh-make debhelper devscripts fakeroot xutils lintian pbuilder
}

function makeOrigTarFromGit
{
    local prefix=$1
    local repo=$2

    if [ ! -d $WORKING_DIR/$prefix-git/.git ];then
        git clone $repo $WORKING_DIR/$prefix-git
    else
        (cd $WORKING_DIR/$prefix-git;git fetch)
    fi

    latestTag=$( cd $WORKING_DIR/$prefix-git; git tag -l | tail -n1 )
    latestVer=${latestTag#[a-zA-Z]}

    (
    cd $WORKING_DIR/$prefix-git
    git archive --format=tar.gz \
        --prefix="$prefix-$latestVer/" $latestTag \
        > ../$prefix'_'$latestVer.orig.tar.gz
    cd ..
    tar -xf $prefix'_'$latestVer.orig.tar.gz
    )

    echo "$latestVer"

}

function dhMakeIndep
{
    (
    cd $WORKING_DIR/$1
    dh_make --copyright $2 --indep
    )
}


mkdir -p $WORKING_DIR
prep
export EMAIL=${EMAIL=kfm@docstream.no}
export DEBFULLNAME=${DEBFULLNAME=Kjetil F-M}



#---------------#
#  fontawesome  #
#---------------#

fontawesomeVer=$(makeOrigTarFromGit fontawesome https://github.com/FortAwesome/Font-Awesome.git)
dhMakeIndep fontawesome-$fontawesomeVer gpl 
echo  ---- POSTFIX STEPs for fontawesome ----

faSrcDir="$WORKING_DIR/fontawesome-$fontawesomeVer"
instFile="$faSrcDir/debian/fontawesome.install"

#inject .install file
cat << __STOP__ > $instFile
less/* usr/share/Font-Awesome/$fontawesomeVer/less
css/* usr/share/Font-Awesome/$fontawesomeVer/css
font/* usr/share/Font-Awesome/$fontawesomeVer/font
scss/* usr/share/Font-Awesome/$fontawesomeVer/scss  
__STOP__
cat $instFile
echo "---- final STEP .. packing fontawesome .. ----"
(cd $faSrcDir; dpkg-buildpackage -us -uc)


