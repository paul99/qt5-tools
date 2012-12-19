#!/bin/bash

usage() {
    echo -e "usage: $0 -c <arch> [-d <path to compile in> | -g | -b | -m] | [-h]\n\
-c <arch> : set the architecture to (cross) build\n\
-d <path> : set path of q5 build directory\n\
-g : skip git fetch\n\
-b : skip compiling qt5 base\n\
-m : skip compilng qt modules" 
    exit 1
}

while [ $# -gt 0 ] ; do
    case $1 in
        -c)
            shift 1
            ARCH=$1
            ;;
        -d)
            shift 1
            QTDIR_PATH=$1
            ;;
        -g)
            skip_git=1
            ;;
        -b)
            skip_qtbase=1
            ;;
        -m)
            skip_modules=1
            ;;
        *) 
            usage
            ;;
    esac
    shift 1
done

if [ -z $QTDIR_PATH ]; then
    d=`dirname $PWD/$0`
    #d=`dirname $d`
    QTDIR_PATH=`dirname $d`
    unset d
fi

if [ -z $ARCH ]; then
    usage
fi

. qt5-tools/build-qt5-env

echo "QTDIR_PATH: $QTDIR_PATH"

d=`diff qt5-tools/build-qt5-env $QTDIR_PATH/newest_version 2>&1 | wc -l`
if [ "$d" = "0" ]; then
  echo "The newest working version is already installed."
  echo "Hash: $WEEKLY_QT5_HASH"
  exit 0
fi

NEW_QTDIR="$QTDIR_PATH/Qt-5.0.0-$QT_WEEKLY_REV"

export QTDIR=$NEW_QTDIR
export PATH=$QTDIR/bin:$PATH

if [ -z $skip_git ]; then
    #rm -rf $QTDIR_PATH/qt5
    #git clone git@gitorious.org:+qt-developers/qt/qt5.git || exit 1
    #git clone git://gitorious.org/qt/qt5.git || exit 1
    cd $QTDIR_PATH/qt5
    git checkout stable
    git clean -dxf
    git reset --hard HEAD
else
    cd $QTDIR_PATH/qt5
fi

if [ -z $skip_git ]; then
    git submodule foreach "git clean -dxf" || exit 1
    git submodule foreach "git checkout master" || exit 1
    git submodule foreach "git reset --hard HEAD" || exit 1
    git fetch || exit 1
    git reset --hard $WEEKLY_QT5_HASH || exit 1
    ./init-repository --module-subset=qtbase,`echo $QT5_MODULES | tr " " ","` -f || exit 1
    git submodule foreach "git fetch" || exit 1
    git submodule update --recursive || exit 1

    for module in $NON_QT5_MODULES; do
        module_hash="${module}_HASH"
        cd $module && git checkout master && git clean -dxf && git reset --hard HEAD && git fetch && git checkout ${!module_hash} && cd ..
        if [ $? -ne 0 ] ; then
            echo FAIL: updating $module
            exit 1
        fi
    done

    echo ==========================================================
    git submodule status
    echo ==========================================================
fi

echo "sourcing $ARCH specific script file."
source ../qt5-tools/$ARCH/build.sh
echo "calling compile func."
compile

echo
echo Build Completed.
