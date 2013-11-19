#!/bin/bash



# HOWTO USE THIS FILE? 
# ... source it , then call one of the 'global' functions
#


WORKING_DIR=work
TOOLS=/opt/ds/tools

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
    local desc=$3
    shift;shift;shift

    (
    cd $WORKING_DIR/$srcDir
    echo -e "\n\n *** $(basename $PWD) is curr dir:\n"
    dh_make --copyright $copyright --indep $@
    echo -e "\n -- append data into 'control' file --\n"
    cd debian && \
    rm *ex && \
    head -n-1 control \
      | sed -r "s/^(Section:).*/\1 misc/" \
      | sed -r "s/^(Homepage:).*/\1 www.docstream.no/" \
      | sed -r "s/^(Description:).*/\1 $desc/" \
      > control.fixed && \
    echo -e "   $desc" >> control.fixed && \
    mv control.fixed control
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
        | awk "{print \$1 \" $dest\"}" \
        ) > $instFile

    cat $instFile

    echo ---- final STEP .. packing $project ----

    (cd $projectSrcDir; dpkg-buildpackage  -us -uc)
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
        xutils lintian pbuilder dupload maven
}



#---------------#
#  fontawesome  #
#---------------#
function fontawesome()
{
    clean_dirs 'fontawesome*'
    local fontawesomeVer=`_makeOrigTarFromGit fontawesome https://github.com/FortAwesome/Font-Awesome.git`
    local faSrcDir="$WORKING_DIR/fontawesome-$fontawesomeVer"
    local instFile="$faSrcDir/debian/fontawesome.install"

    _dhMakeIndep fontawesome-$fontawesomeVer gpl "v $fontawesomeVer of css+icon framework"
    

    echo  ---- POSTFIX STEPs for fontawesome $fontawesomeVer ----
    
    dirs=( $(cd $faSrcDir; ls -l | awk ' /^d/ {print $9}' | grep -v debian| grep -v src) )
    for d in ${dirs[@]}
    do 
      echo "$d/* usr/share/Font-Awesome/$fontawesomeVer/$d" >> $instFile
    done
    cat $instFile

    echo "---- final STEP .. packing fontawesome .. ----"
    (cd $faSrcDir; dpkg-buildpackage -us -uc)
}

#----------#
#  xopus4  #
#----------#
function xopus()
{
    clean_dirs 'xopus*'
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
    fi
    unzip -qo $zip
    )
    
    # tight with fontawesome
    # check if FA file is there..
    if stat -t $WORKING_DIR/fontawesome*dsc >/dev/null 2>&1; then
      fa_dsc_file=$(cd $WORKING_DIR && ls fontawesome*dsc)
      fa_ver=$(echo $fa_dsc_file | sed -e 's/.*_\([^-]\+\)-.*/\1/')

      echo -e "\n\n _____ using /font-awesome/$fa_ver ____ \n\n"

      (
      cd $WORKING_DIR/$topDirInZip
      # patch

      pf="xopus/xopus.html"
      sed -e '/<\/head>/r ../../xopus-html-patch.htm' -e 'x;$G' "$pf" \
        | sed -e "s%\(\\/font-awesome\\/\)\\[\\[v\\]\\]%\1$fa_ver%" \
        > "$pf".patched
      mv "$pf".patched "$pf"
      # tar it ALL into orig.
      tar -czf ../$xopusOrigTar *
      )

      rm -rf $WORKING_fonDIR/$topDirInZip 
      mkdir -p $xopusSrcDir
      tar -xf $WORKING_DIR/$xopusOrigTar -C $xopusSrcDir


      _dhMakeIndep xopus-$debRev blank "v $debRev of js+assets files"

      _postAdjustmentsForStaticProjects xopus "usr/share/xopus4/$debRev" $debRev 
    else
      echo Kjør fontawesome først
    fi

}

#-------------------#
#  epub3.0 schemas  #
#-------------------#
function epub30schemas()
{
    clean_dirs 'epub*'
    local rev=301
    local debRev=3.0.1
    local svn=http://epub-revision.googlecode.com
    local ep3SrcDir=$WORKING_DIR/epub30schemas-$debRev
    local epubOrigTar=epub30schemas_$debRev.orig.tar.gz
    local extFilename=epub-schemas.tar.gz

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
    
    _dhMakeIndep epub30schemas-$debRev lgpl \
      "v $debRev of schema-set from the standards body"

    _postAdjustmentsForStaticProjects epub30schemas "usr/share/epub30/$debRev" $debRev 

}


#------------#
#  saxon9ee  #
#------------#
function saxon9ee()
{
  clean_dirs 'saxon*'
  local name=saxon9ee
  local localm2repo=maven
  local unpack_dir=${name}_unpacked
  local jar=$unpack_dir/${name}.jar
  local SAXON_VER="9-5-1-2J"
  local zip="SaxonEE${SAXON_VER}.zip"
  local url="http://www.saxonica.com/download"
  local target_file=maven_vendor_all.tar.gz

  mkdir -p $WORKING_DIR/$localm2repo
  rm -f $WORKING_DIR/$target_file
  mkdir -p $unpack_dir
  (
  cd $WORKING_DIR 
  if [ ! -f $zip ]
  then
      wget "$url/$zip"
  fi
  
  unzip -q $zip -d $unpack_dir

  mvn install:install-file -Dmaven.repo.local=$localm2repo \
    -Dfile=$jar -DgroupId=vendor.$name \
    -DartifactId=vendor-$name -Dversion=$SAXON_VER -Dpackaging=jar

  tar -czf $target_file $localm2repo/vendor
  )

}

#---------#
#  solr4  #
#---------#
funcion solr4()
{

  clean_dirs 'solr*'
  local debRev=2
  local ver=4.5.1
  local url=http://apache.vianett.no/lucene/solr/$ver
  local tgz=solr-$ver.tgz
  local solrSrcDir=$WORKING_DIR/solr-$ver
  local solrOrigTar=solr_${ver}.orig.tar.gz
  local topDirInZip=solr-$ver

  (
  cd $WORKING_DIR && \
    if [ ! -f $tgz ]
    then
      wget "$url/$tgz" 
    fi
    tar -xzf $tgz
    )

    # silly but this is needed pga rights
    (cd $WORKING_DIR/$topDirInZip && \
      tar -czf ../$solrOrigTar *)

    rm -rf $WORKING_DIR/$topDirInZip
    mkdir -p $solrSrcDir

    tar -xf $WORKING_DIR/$solrOrigTar -C $solrSrcDir

    _dhMakeIndep solr-$ver apache "v $ver($debRev) of solr+jetty pack"

    _postAdjustmentsForStaticProjects solr 'opt/solr/4.x' $ver
}

function clean_dirs()
{
  (
  cd work
  ls -l $1 2>/dev/null | awk ' /^d/ {print $9}' | xargs rm -rf
  )
}


echo
echo Now call one of : 'prep', 'saxon9ee', 'xopus', 'epub30schemas' , 'fontawesome', 'solr4'
echo
echo  .. når pakker er ok , kjør : dupload work 

