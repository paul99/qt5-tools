compile() {
    echo "mipsel specific bulit script called, skip_qtbase: $skip_qtbase; skip_modules: $skip_modules"

    if [ -z $skip_git ]; then
        # Mips patch for qt3d
        cd qt3d
        patch -p 1 < ../../qt5-tools/mipsel/qt3d_assimp_mips_fix.diff || exit 1
        cd ..
    fi

    mkdir qtbase/mkspecs/linux-mipsel-g++
    cp qtbase/mkspecs/linux-arm-gnueabi-g++/qplatformdefs.h qtbase/mkspecs/linux-mipsel-g++
    cp ../qt5-tools/$ARCH/qmake.conf qtbase/mkspecs/linux-mipsel-g++/

    export PKG_CONFIG_LIBDIR=/usr/mipsel-linux-gnu/lib/pkgconfig
    if [ -z $skip_qtbase ]; then
        ./configure -arch mipsel -xplatform linux-mipsel-g++ -opensource -confirm-license -no-pch -nomake examples -nomake demos -nomake tests -no-gtkstyle -nomake translations -qt-zlib -qt-libpng -qt-libjpeg -qt-sql-sqlite -release -prefix $QTDIR -v -I /usr/mipsel-linux-gnu/include/dbus-1.0 -force-pkg-config

        cd qtbase && make $THREADS && make install && cd ..
        if [ $? -ne 0 ] ; then
            echo FAIL: building qtbase
            exit 1
        fi
    fi

    if [ -z $skip_modules ]; then
        for module in $QT5_MODULES $NON_QT5_MODULES
        do
            cd $module && qmake && make $THREADS && make install && cd ..
            if [ $? -ne 0 ] ; then
                echo FAIL: building $module.
                exit 1
            fi
        done
    fi

    cp ../qt5-tools/build-qt5-env $QTDIR_PATH/newest_version
    unlink $QTDIR_PATH/Qt5-mipsel
    ln -sf $NEW_QTDIR $QTDIR_PATH/Qt5-mipsel
}
