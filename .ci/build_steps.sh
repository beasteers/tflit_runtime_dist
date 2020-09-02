# TF_BRANCH: ${{ matrix.branch }}
# VERSION_SUFFIX: ${{ matrix.version_suffix }}
# PKG_NAME: ${{ matrix.package_name }}
# TWINE_USERNAME: ${{ secrets.pypi_user }}
# TWINE_PASSWORD: ${{ secrets.pypi_password }}

# clone tensorflow

TFDIR=../tensorflow
TFLITEDIR=$TFDIR/tensorflow/lite/tools

clone_tensorflow() {
    if [ ! -d $TFDIR ]; then
        git clone https://github.com/tensorflow/tensorflow.git $TFDIR
        git -C $TFDIR checkout $TF_BRANCH
    else
        git -C $TFDIR checkout $TF_BRANCH
        git -C $TFDIR pull
    fi
}
# install

install_tflite_build_deps() {
    if [[ ! -z $(which apt-get) ]]; then
        sudo apt-get install swig libjpeg-dev zlib1g-dev -y
    else
        brew install swig libjpeg
    fi
    pip3 install numpy pybind11 wheel
}
# build

build_tflite_runtime() {
    sed -i -e "s/  name=PACKAGE_NAME/  name=\"${PKG_NAME}\"/" \
        $TFLITEDIR/pip_package/setup.py

    /bin/bash $TFLITEDIR/make/download_dependencies.sh
    /bin/bash $TFLITEDIR/pip_package/build_pip_package.sh
}


# gather files

gather_tflite_wheels() {
    FILES=$(find /tmp/tflite_pip $TFLITEDIR -name "tflite_runtime*.whl" 2>/dev/null || :)
    echo 'Found:' $FILES

    mkdir -p dist
    for f in $FILES; do
      f2=dist/$(basename "$f" | sed -e 's/linux/manylinux2014/g')
      mv "$f" "$f2"
    done

    ls -lah
    ls -lah dist/
}

# pypi

# push_wheels_to_github() {
#     git config --global user.email "bea.steers@gmail.com"
#     git config --global user.name "Bea Steers"
#     git add dist/
#     git commit -m 'adding whl for $OS_NAME:$PY_VERSION'
#
#     #  https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${REPOSITORY}.git
#     for i in {1..5}; do
#        git pull && git push && break
#        sleep $((1 + $RANDOM % 4))
#     done
# }

upload_to_pypi() {
    pip3 install twine
    twine check dist/*
    twine upload --skip-existing dist/*
}

upload_to_testpypi() {
    pip3 install twine
    twine check dist/*
    twine upload --skip-existing --repository testpypi dist/*
}


# test


test_tflite_runtime() {
    pip3 install tflite-runtime-alt==$TFRUNTIME_VERSION
    python3 test/test.py
}


# main

run_full_tflite_build() {
    clone_tensorflow && install_tflite_build_deps && build_tflite_runtime \
        && gather_tflite_wheels && upload_to_testpypi
}

run_tflite_build_setup() {
    clone_tensorflow && install_tflite_build_deps
}

run_tflite_setup_and_build() {
    clone_tensorflow && install_tflite_build_deps && build_tflite_runtime \
        && gather_tflite_wheels
}

run_tflite_build_and_upload() {
    build_tflite_runtime && gather_tflite_wheels && upload_to_testpypi
}
