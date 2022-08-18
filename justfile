################################################################################
# Use 'run-vm' to launch a docker container
################################################################################

run-vm: build-vm
    #!/usr/bin/env bash
    set -euxo pipefail
    docker run -it -p 2222:22 -v "$(pwd):/home/brian.myers/lib/prez" vm:latest

build-vm:
    docker build -f docker/Dockerfile -t vm:latest ./docker

################################################################################
# Use the following rules inside the docker container
################################################################################

clean:
    #!/usr/bin/env bash
    rm -rf build
    rm -rf lib

run: build
    ./build/main/main-pie-dynamic

build-simple: clean
    #!/usr/bin/env bash

    mkdir -p build/main
    cd build/main
    gcc ../../src/main.c -lm -lz -save-temps -Wall -std=c99 -g0   -O0 -fno-pie -no-pie         -o main-no-pie-dynamic
    objdump -D main-no-pie-dynamic > main-no-pie-dynamic.dump

build: clean
    #!/usr/bin/env bash

    mkdir -p build/main
    cd build/main
    gcc ../../src/main.c -lm -lz -save-temps -Wall -std=c99 -g0   -O0 -pie                     -o main-pie-dynamic
    gcc ../../src/main.c -lm -lz -save-temps -Wall -std=c99 -g0   -O0 -static-pie              -o main-pie-static
    gcc ../../src/main.c -lm -lz -save-temps -Wall -std=c99 -g0   -O0 -fno-pie -no-pie         -o main-no-pie-dynamic
    gcc ../../src/main.c -lm -lz -save-temps -Wall -std=c99 -g0   -O0 -fno-pie -no-pie -static -o main-no-pie-static
    gcc ../../src/main.c -lm -lz             -Wall -std=c99 -ggdb -O0 -fno-pie -no-pie         -o main-gdb
    objdump -D main-pie-dynamic > main-pie-dynamic.dump
    objdump -D main-pie-static > main-pie-static.dump
    objdump -D main-no-pie-dynamic > main-no-pie-dynamic.dump
    objdump -D main-no-pie-static > main-no-pie-static.dump


# TODO
file: build
    @echo "*************************"
    @echo "* intermediate files    *"
    @echo "*************************"
    file build/main/main-pie-dynamic-main.i
    @echo ""
    file build/main/main-pie-dynamic-main.s
    @echo ""
    file build/main/main-pie-dynamic-main.o
    @echo ""
    @echo "*************************"
    @echo "* exe: pie & dynamic    *"
    @echo "*************************"
    file build/main/main-pie-dynamic
    @echo ""
    @echo "*************************"
    @echo "* exe: no-pie & dynamic *"
    @echo "*************************"
    file build/main/main-no-pie-dynamic
    @echo ""
    @echo "*************************"
    @echo "* exe: pie & static     *"
    @echo "*************************"
    file build/main/main-pie-static
    @echo ""
    @echo "*************************"
    @echo "* exe: no-pie & static  *"
    @echo "*************************"
    file build/main/main-no-pie-static

needed: build
    @echo "**************"
    @echo "* dynamic    *"
    @echo "**************"
    readelf -a build/main/main-pie-dynamic | grep interpreter || exit 0
    readelf -a build/main/main-pie-dynamic | grep NEEDED || exit 0
    @echo ""
    @echo "**************"
    @echo "* static     *"
    @echo "**************"
    readelf -a build/main/main-pie-static | grep interpreter || exit 0
    readelf -a build/main/main-pie-static | grep NEEDED || exit 0

program-headers: build
    @echo ""
    @echo "*************************"
    @echo "* the .o file           *"
    @echo "*************************"
    readelf -lW ./build/main/main-pie-static-main.o
    readelf -SW ./build/main/main-pie-static-main.o
    @echo ""
    @echo "*************************"
    @echo "* exe: pie & dynamic    *"
    @echo "*************************"
    readelf -l -W build/main/main-pie-dynamic
    @echo ""
    @echo "*************************"
    @echo "* exe: no-pie & dynamic *"
    @echo "*************************"
    readelf -l -W build/main/main-no-pie-dynamic
    @echo ""
    @echo "*************************"
    @echo "* exe: pie & static     *"
    @echo "*************************"
    readelf -l -W build/main/main-pie-static
    @echo ""
    @echo "*************************"
    @echo "* exe: no-pie & static  *"
    @echo "*************************"
    readelf -l -W build/main/main-no-pie-static

run-gdb: build
    gdb ./build/main/main-gdb

run2: clean
    #!/usr/bin/env bash
    mkdir -p build/foo
    mkdir -p build/main2
    mkdir -p lib
    (
        cd build/foo
        # Note: Need -fpic or -fPIC
        gcc -c ../../src/foo/foo.c -I../../include/ -fpic -Wall -std=c99 -g0 -O0 -o foo.o
        gcc -shared foo.o -lm -lz -Wall -std=c99 -g0 -O0 -o libfoo.so
        mv libfoo.so ../../lib/libfoo.so
    )
    (
        cd build/main2
        gcc ../../src/main2.c -I../../include/ -L../../lib/ -lfoo -Wall -std=c99 -g0 -O0 -o main2
    )
    set -x
    LD_LIBRARY_PATH=./lib build/main2/main2
    readelf -a build/main2/main2 | grep NEEDED
    readelf -a lib/libfoo.so | grep NEEDED

run3: clean
    #!/usr/bin/env bash
    mkdir -p build/foo
    mkdir -p build/main3
    mkdir -p lib
    (
        cd build/foo
        # Note: Don't need -fpic (I think???)
        gcc -c ../../src/foo/foo.c -I../../include/ -Wall -std=c99 -g0 -O0 -o foo.o
        ar cr libfoo.a foo.o
        mv libfoo.a ../../lib/libfoo.a
    )
    (
        cd build/main3
        # Note: Order of libraries matters
        gcc ../../src/main2.c -I../../include/ -L../../lib/ -lfoo -lm -lz -Wall -std=c99 -g0 -O0 -o main3
    )
    set -x
    ar t lib/libfoo.a
    ./build/main3/main3
    readelf -a build/main3/main3 | grep NEEDED
