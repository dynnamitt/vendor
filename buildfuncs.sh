#!/bin/bash



# HOWTO USE THIS FILE? 
# ... source it , then call one of these top functions:
#
#   prep
#  fontawesome
#  epub30schemas


WORKING_DIR=work


function prep() 
{
    echo installing debian packs needed for debianization now...
    sudo apt-get install wget build-essential autoconf automake autotools-dev \
        dh-make debhelper devscripts fakeroot xutils lintian pbuilder
}

function _makeOrigTarFromGit()
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

function _dhMakeIndep()
{
    (
    cd $WORKING_DIR/$1
    echo $PWD is curr dir.
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
function fontawesome()
{

    local fontawesomeVer=$(_makeOrigTarFromGit fontawesome https://github.com/FortAwesome/Font-Awesome.git)
    local faSrcDir="$WORKING_DIR/fontawesome-$fontawesomeVer"
    local instFile="$faSrcDir/debian/fontawesome.install"

    _dhMakeIndep fontawesome-$fontawesomeVer gpl 
    echo  ---- POSTFIX STEPs for fontawesome $fontawesomeVer ----

  
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
}


#-------------------#
#  epub3.0 schemas  #
#-------------------#
function epub30schemas()
{
    local rev=301
    local debRev=3.0.1
    local ep3SrcDir=$WORKING_DIR/epub30schemas-$debRev
    local srcTar=epub30schemas'_'$debRev.orig.tar.gz
    local instFile="$ep3SrcDir/debian/epub30schemas.install"
    local extFilename=epub30-schemas.tar.gz

    (
    cd $WORKING_DIR
    wget http://epub-revision.googlecode.com/svn/trunk/build/$rev/schema/$extFilename
    mv $extFilename $srcTar
    )

    mkdir -p $ep3SrcDir
    tar -xf $WORKING_DIR/$srcTar -C $ep3SrcDir
    
    _dhMakeIndep epub30schemas-$debRev lgpl 

    echo  ---- POSTFIX STEPs for epub30schemas ----


    #inject .install file
    cat << __STOP__ > $instFile
* usr/share/epub30/schemas/$debRev
__STOP__
    cat $instFile

    echo "---- final STEP .. packing epub30schemas ----"
    (cd $ep3SrcDir; dpkg-buildpackage -us -uc)

}
echo
echo
echo
echo Now call one of : 'prep', 'epub30schemas' , 'fontawesome'

