#!/bin/sh
function prep {
    sudo apt-get install build-essential autoconf automake autotools-dev \
        dh-make debhelper devscripts fakeroot xutils lintian pbuilder
}

function fontsync {

    if [ ! -d clones/font-awesome/.git ];then
        git clone https://github.com/FortAwesome/Font-Awesome.git clones/font-awesome
    else
        (cd clones/font-awesome;git fetch)
    fi

    cd clones/font-awesome

    local latest=$( git tag -l | tail -n1)
    echo Latest tag is $latest

    # checkout latest tag
    git checkout tags/$latest

    # move all dirs (not src) into a tar.gz
    #RESULT=
    #for file in *
    #do
    #    if [ -d $file ] && [ $file != "src" ];then
    #        RESULT="$RESULT $file"
    #    fi
    #done

    # tar it
    echo packing ..
    
    tar -czf ../font-awesome-$latest.tar.gz *
    cd ..

}

mkdir -p clones
prep
fontsync
echo $PWD
