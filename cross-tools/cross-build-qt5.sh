#!/bin/bash

usage() {
    echo -e "usage: $0 [-d <path to compile in> | -g | -b | -m] | [-h]\n\
-g : skip git fetch\n-b : skip compiling qt5 base\n-m : skip compilng qt modules" 
    exit 1
}

while [ $# -gt 0 ] ; do
    case $1 in
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
    d=`dirname $d`
    d=`dirname $d`
    QTDIR_PATH=$d/qt5
    unset d
fi

. qt5-tools/build-qt5-env

#QTDIR_PATH="/data/buildbot/qt5"

d=`diff qt5-tools/build-qt5-env $QTDIR_PATH/newest_version 2>&1 | wc -l`
if [ "$d" = "0" ]
then
  echo "The newest working version is already installed."
  echo "Hash: $WEEKLY_QT5_HASH"
  exit 0
fi

NEW_QTDIR="$QTDIR_PATH/Qt-5.0.0-$QT_WEEKLY_REV"

export QTDIR=$NEW_QTDIR
export PATH=$QTDIR/bin:$PATH

if [ -z $skip_git ]; then
    rm -rf qt5
    #git clone git@gitorious.org:+qt-developers/qt/qt5.git || exit 1
    git clone git://gitorious.org/qt/qt5.git || exit 1
fi

cd qt5

if [ -z $skip_git ]; then
    git submodule foreach "git clean -dxf" || exit 1
    git submodule foreach "git checkout master" || exit 1
    git submodule foreach "git reset --hard HEAD" || exit 1
    git fetch || exit 1
    git reset --hard $WEEKLY_QT5_HASH || exit 1
    # --mirror removed
    ./init-repository --module-subset=qtbase,`echo $QT5_MODULES | tr " " ","` -f || exit 1
    git submodule foreach "git fetch" || exit 1
    git submodule update --recursive || exit 1
    echo ==========================================================
    git submodule status
    echo ==========================================================

    # Mips patch for qt3d
    cd qt3d
    patch -p 1 < ../../qt5-tools/cross-tools/qt3d_assimp_mips_fix.diff
    cd ..
fi

mkdir qtbase/mkspecs/linux-mipsel-g++
cp qtbase/mkspecs/linux-arm-gnueabi-g++/qplatformdefs.h qtbase/mkspecs/linux-mipsel-g++
cp ../qt5-tools/cross-tools/qmake.conf qtbase/mkspecs/linux-mipsel-g++/
#git apply ../qt5-tools/cross-tools/qtjsbackend.patch --directory=qtjsbackend

if [ -z $skip_qtbase ]; then
    ./configure -arch mipsel -xplatform linux-mipsel-g++ -opensource -confirm-license -no-pch -nomake examples -nomake demos -nomake tests -no-gtkstyle -nomake translations -qt-zlib -qt-libpng -qt-libjpeg -qt-sql-sqlite -release -prefix $QTDIR -v

    cd qtbase && make $THREADS && make install && cd ..
    if [ $? -ne 0 ] ; then
        echo FAIL: building qtbase
        exit 1
    fi
fi

if [ -z $skip_modules ]; then
    for module in $QT5_MODULES
    do
        cd $module && qmake && make $THREADS && make install && cd ..
        if [ $? -ne 0 ] ; then
            echo FAIL: building $module.
            exit 1
        fi
    done
fi

cp ../qt5-tools/build-qt5-env $QTDIR_PATH/newest_version
unlink $QTDIR_PATH/Qt-5.0.0-mipsel
ln -sf $NEW_QTDIR $QTDIR_PATH/Qt-5.0.0-mipsel

# rm -rf ../WebKitBuild

echo
echo Build Completed.
