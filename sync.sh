#!/bin/sh
function prep {
    sudo apt-get install build-essential autoconf automake autotools-dev \
        dh-make debhelper devscripts fakeroot xutils lintian pbuilder
}

function font {

    if [ ! -d font-awesome/.git ];then
        git clone https://github.com/FortAwesome/Font-Awesome.git font-awesome
    else
        (cd font-awesome;git fetch)
    fi

    local latest=$(cd font-awesome; git tag -l | tail -n1)


    # checkout latest tag
    (cd font-awesome; git checkout tags/$latest)
}

prep
font
