#!/bin/bash
function prep() {
    sudo apt-get install build-essential autoconf automake autotools-dev \
        dh-make debhelper devscripts fakeroot xutils lintian pbuilder
}

function fontsync() {

    PACK_PREFIX=font-awesome
    REPO=https://github.com/FortAwesome/Font-Awesome.git

    if [ ! -d clones/$PACK_PREFIX-git/.git ];then
        git clone $REPO clones/$PACK_PREFIX-git
    else
        (cd clones/$PACK_PREFIX-git;git fetch)
    fi

    cd clones/$PACK_PREFIX-git

    local latest=$( git tag -l | tail -n1)
    echo Latest tag is $latest

    # checkout latest tag
    git checkout tags/$latest

    RESULT=
    for file in *
    do
        if [ -d $file ] && [ $file != "src" ];then
            RESULT="$RESULT $file"
        fi
    done

    # tar it
    PACK=$PACK_PREFIX-${latest#v}
    echo packing $PACK ..
    
    tar -czf ../$PACK.tar.gz *
    cd ..
    mkdir -p $PACK
    cd $PACK
    tar -xf ../$PACK.tar.gz

    rm debian -rf
   dh_make -e kf@docstream.no -f ../$PACK.tar.gz -indep --createorig 

    #inject Makefile
    cat << __STOP__ >> debian/rules

all: # nothing to build

install:;mkdir -p \$(DESTDIR)/var/opt/www/$PACK_PREFIX/${latest#v};\
    cp -r $RESULT \$(DESTDIR)/var/opt/www/$PACK_PREFIX/${latest#v}
__STOP__

    }

mkdir -p clones
prep
fontsync
echo $PWD
