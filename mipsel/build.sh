compile() {
    echo "mipsel specific build script called, skip_qtbase: $skip_qtbase; skip_modules: $skip_modules"

#    if [ -z $skip_git ]; then
        # Mips patch for qtjsbackend
#        cd qtjsbackend
#        patch -p 1 < ../../qt5-tools/mipsel/v8_mips.diff || exit 1
#        cd ..
#    fi

    mkdir qtbase/mkspecs/linux-mipsel-g++
    cp qtbase/mkspecs/linux-arm-gnueabi-g++/qplatformdefs.h qtbase/mkspecs/linux-mipsel-g++
    cp ../qt5-tools/$ARCH/qmake.conf qtbase/mkspecs/linux-mipsel-g++/

    export PKG_CONFIG_LIBDIR=/usr/mipsel-linux-gnu/lib/pkgconfig
    export PKG_CONFIG_PATH=/usr/mipsel-linux-gnu/share/pkgconfig

    make $THREADS && if [ ! $DEVELOPER_BUILD ]; then make install

    cp ../qt5-tools/build-qt5-env $QTDIR_PATH/newest_version
    unlink $QTDIR_PATH/Qt5-mipsel
    ln -sf $NEW_QTDIR $QTDIR_PATH/Qt5-mipsel
}
