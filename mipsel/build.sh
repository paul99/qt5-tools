compile() {
    echo "mipsel specific bulit script called, skip_qtbase: $skip_qtbase; skip_modules: $skip_modules"

    if [ -z $skip_git ]; then
        # Mips patch for qt3d
        cd qt3d
        patch -p 1 < ../../qt5-tools/cross-tools/qt3d_assimp_mips_fix.diff || exit 1
        cd ..
    fi

    mkdir qtbase/mkspecs/linux-mipsel-g++
    cp qtbase/mkspecs/linux-arm-gnueabi-g++/qplatformdefs.h qtbase/mkspecs/linux-mipsel-g++
    cp ../qt5-tools/$ARCH/qmake.conf qtbase/mkspecs/linux-mipsel-g++/
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
}
