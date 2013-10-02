#!/bin/bash

N_THREADS=8

usage() {
    echo -e "usage: $0 -c <arch> [-d <path to compile in> | -g | -b | -m] | [-h]\n\
-c <arch> : set the architecture to (cross) build\n\
-d <path> : set path of q5 build directory\n\
-g : skip git fetch\n\
-b : skip compiling qt5 base\n\
-m : skip compilng qt modules\n\
-j # : builds with # threads (default is $N_THREADS)."
    exit 0
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
        -j)
            shift 1
            echo "[$0] Building with $1 threads."
            N_THREADS=$1
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

d=`diff qt5-tools/build-qt5-env $QTDIR_PATH/newest_version 2>&1 | wc -l`
if [ "$d" = "0" ]; then
  echo "The newest working version is already installed."
  echo "Hash: $WEEKLY_QT5_HASH"
  exit 0
fi

NEW_QTDIR="$QTDIR_PATH/$QT_WEEKLY_REV"

export QTDIR=$NEW_QTDIR
export PATH=$QTDIR/bin:$PATH

MIRROR_URL="git://gitorious.org"
BRANCH=stable
THREADS=
if [ $N_THREADS -gt 1 ]; then
    THREADS=-j$N_THREADS
fi

if [ -z $skip_git ]; then
    echo "removing: $NEW_QTDIR"
    rm -rf $NEW_QTDIR
    echo "cloning qt5..."
    if [ ! -d qt5 ]; then
        git clone -b $BRANCH $MIRROR_URL"/qt/qt5.git" qt5 || exit 1
    fi
fi

echo "entering: $QTDIR_PATH/qt5"
cd $QTDIR_PATH/qt5

if [ -z $skip_git ]; then
    echo "Setting up git"
    git checkout stable
    git clean -dxf
    git reset --hard HEAD
    git submodule foreach "git checkout stable"
    git submodule foreach "git clean -dxf"
    git submodule foreach "git reset --hard HEAD"
    git fetch || exit 1
    git reset --hard $WEEKLY_QT5_HASH || exit 1
    ./init-repository --module-subset=qtbase,`echo $QT5_MODULES | tr " " ","` -f || exit 1
    git submodule foreach "git fetch" || exit 1
    git submodule update --recursive || exit 1
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
