#!/bin/bash



# HOWTO USE THIS FILE? 
# ... source it , then call one of the 'global' functions
#


WORKING_DIR=work

#------------------#
#  private helper  #
#------------------#
function _makeOrigTarFromGit()
{
    local prefix=$1
    local repo=$2
    local gitWD=$prefix-git
    local dir=$WORKING_DIR/$gitWD

    if [ ! -d $dir/.git ]
    then
        (cd $WORKING_DIR && git clone $repo $gitWD >> /dev/null )
    else
        (cd $dir && git fetch >> /dev/null )
    fi

    latestTag=$( cd $dir && git tag -l | tail -n1 )
    latestVer=${latestTag#[a-zA-Z]}

    # tar.gz via git
    (
    cd $dir && \
        git archive --format=tar.gz \
        --prefix="$prefix-$latestVer/" $latestTag \
        > ../$prefix'_'$latestVer.orig.tar.gz
    )

    # untar
    (
    cd $WORKING_DIR && \
        tar -xf $prefix'_'$latestVer.orig.tar.gz
    )

    echo "$latestVer"

}

#------------------#
#  private helper  #
#------------------#
function _dhMakeIndep()
{
    local srcDir=$1
    local copyright=$2
    shift;shift

    (
    cd $WORKING_DIR/$srcDir
    echo $PWD is curr dir.
    dh_make --copyright $copyright --indep $@
    )
}

#---------------#
#  priv helper  #
#---------------#
function _postAdjustmentsForStaticProjects()
{
    local project=$1
    local dest=$2
    local ver=$3
    local lsParams=${4}
    local projectSrcDir=$WORKING_DIR/$project-$ver
    local instFile=$projectSrcDir/debian/$project.install

    echo ---- POSTFIX STEPs for $project ----

    #inject .install file
    cat <(cd $projectSrcDir; ls -1 $lsParams \
        | grep -v debian \
        | awk "{print \$1 \" $dest/$ver\"}" \
        ) > $instFile

    cat $instFile

    echo ---- final STEP .. packing $project ----

    (cd $projectSrcDir; dpkg-buildpackage -us -uc)
}



#-----------#
#  globals  #
#-----------#

mkdir -p $WORKING_DIR
export EMAIL=${EMAIL=kfm@docstream.no}
export DEBFULLNAME=${DEBFULLNAME=Kjetil F-M}

#--------#
#  prep  #
#--------#

function prep() 
{
    echo installing debian packs needed for debianization now...
    sudo apt-get install \
        unzip wget build-essential \
        autoconf automake autotools-dev \
        dh-make debhelper devscripts fakeroot \
        xutils lintian pbuilder
}



#---------------#
#  fontawesome  #
#---------------#
function fontawesome()
{

    local fontawesomeVer=`_makeOrigTarFromGit fontawesome https://github.com/FortAwesome/Font-Awesome.git`
    local faSrcDir="$WORKING_DIR/fontawesome-$fontawesomeVer"
    local instFile="$faSrcDir/debian/fontawesome.install"

    _dhMakeIndep fontawesome-$fontawesomeVer gpl 


    # TODO: make generic
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
    local svn=http://epub-revision.googlecode.com
    local ep3SrcDir=$WORKING_DIR/epub30schemas-$debRev
    local epubOrigTar=epub30schemas_$debRev.orig.tar.gz
    local extFilename=epub30-schemas.tar.gz

    (
    cd $WORKING_DIR && \
    if [ ! -f $epubOrigTar ]
    then
         wget $svn/svn/trunk/build/$rev/schema/$extFilename
         mv $extFilename $epubOrigTar
    fi
    )

    mkdir -p $ep3SrcDir
    tar -xf $WORKING_DIR/$epubOrigTar -C $ep3SrcDir
    
    _dhMakeIndep epub30schemas-$debRev lgpl 

    _postAdjustmentsForStaticProjects epub30schemas 'usr/share/epub30' $debRev 

}

#----------#
#  xopus4  #
#----------#
function xopus()
{
    local url=http://xopus.com/files/download
    local debRev=4.4.1
    local zip="Xopus $debRev.zip"
    local topDirInZip=Xopus
    local xopusSrcDir=$WORKING_DIR/xopus-$debRev
    local xopusOrigTar=xopus_$debRev.orig.tar.gz

    (
    cd $WORKING_DIR && \
    if [ ! -f $zip ]
    then
        wget "$url/$zip" 
        unzip -q $zip
    fi
    )
    
    (cd $WORKING_DIR/$topDirInZip && \
        tar -czf ../$xopusOrigTar *)

    rm -rf $WORKING_DIR/$topDirInZip 
    mkdir -p $xopusSrcDir
    tar -xf $WORKING_DIR/$xopusOrigTar -C $xopusSrcDir
    

    _dhMakeIndep xopus-$debRev blank

    _postAdjustmentsForStaticProjects xopus 'usr/share/xopus4' $debRev 

}

funcion solr4()
{
    local ver=4.4.0
    local debVer=$ver
    local url=http://apache.vianett.no/lucene/solr/$ver
    local tgz=solr-$ver.tgz
    local topDirInZip=solr-$ver

   (
    cd $WORKING_DIR && \
    if [ ! -f $tgz ]
    then
        wget "$url/$tgz" 
        tar -xzf $tgz
    fi
    )
}




echo
echo Now call one of : 'prep', 'xopus', 'epub30schemas' , 'fontawesome', 'solr4'

