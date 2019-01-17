ARG TARGET_TRIPLE=arm-linux-gnueabihf
ARG LLVM_VERSION=70
ARG BASE_BUILDER_IMAGE=git-registry.mittelab.org/5p4k/rpi-build-tools/llvm-7-arm

FROM alpine AS builder-sources
ARG LLVM_VERSION
WORKDIR /root
COPY fetch-llvm-src.sh ./
RUN apk add --no-cache --update \
        curl \
        file \
        unzip \
    && ash fetch-llvm-src.sh --no-llvm --projects "libcxx libcxxabi" --tools "" --version "${LLVM_VERSION}"


FROM $BASE_BUILDER_IMAGE AS builder-base
RUN dpkg --add-architecture armhf \
    && apt-get -qq update \
    && apt-get install -yy --no-install-recommends \
        cmake \
        make \
        binutils \
        libc6-dev:armhf \
        libgcc-6-dev:armhf \
        libstdc++-6-dev:armhf
COPY --from=builder-sources /root /root/
WORKDIR /root/build
RUN mkdir /root/prefix


FROM builder-base AS builder-libcxxabi
ARG TARGET_TRIPLE
RUN LD_FLAGS="-fuse-ld=lld" \
    && ARCH_FLAGS="--target=${TARGET_TRIPLE} -march=armv6 -mfloat-abi=hard -mfpu=vfp" \
    && cmake \
        -DCMAKE_CROSSCOMPILING=True \
        -DCMAKE_CXX_FLAGS="${ARCH_FLAGS}" \
        -DCMAKE_C_FLAGS="${ARCH_FLAGS}" \
        -DCMAKE_C_COMPILER_TARGET="${TARGET_TRIPLE}" \
        -DCMAKE_CXX_COMPILER_TARGET="${TARGET_TRIPLE}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${LD_FLAGS}" \
        -DCMAKE_MODULE_LINKER_FLAGS="${LD_FLAGS}" \
        -DCMAKE_EXE_LINKER_FLAGS="${LD_FLAGS}" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/root/prefix \
        /root/llvm/projects/libcxxabi \
    && echo "Compiling libc++abi using $(nproc) parallel jobs." \
    && make -j $(nproc) \
    && make install \
    && rm -rf *


FROM builder-base AS builder-libcxx
ARG TARGET_TRIPLE
COPY --from=builder-libcxxabi /root/prefix/lib /usr/lib/$TARGET_TRIPLE/
RUN LD_FLAGS="-fuse-ld=lld" \
    && ARCH_FLAGS="--target=${TARGET_TRIPLE} -march=armv6 -mfloat-abi=hard -mfpu=vfp" \
    && cmake \
        -DCMAKE_CROSSCOMPILING=True \
        -DCMAKE_CXX_FLAGS="${ARCH_FLAGS}" \
        -DCMAKE_C_FLAGS="${ARCH_FLAGS}" \
        -DCMAKE_C_COMPILER_TARGET="${TARGET_TRIPLE}" \
        -DCMAKE_CXX_COMPILER_TARGET="${TARGET_TRIPLE}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${LD_FLAGS}" \
        -DCMAKE_MODULE_LINKER_FLAGS="${LD_FLAGS}" \
        -DCMAKE_EXE_LINKER_FLAGS="${LD_FLAGS}" \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/root/prefix \
        -DLIBCXX_CXX_ABI=libcxxabi \
        -DLIBCXX_CXX_ABI_INCLUDE_PATHS=/root/llvm/projects/libcxxabi/include \
        /root/llvm/projects/libcxx \
    && echo "Compiling libc++ using $(nproc) parallel jobs." \
    && make -j $(nproc) \
    && make install \
    && rm -rf *


FROM $BASE_BUILDER_IMAGE
ARG TARGET_TRIPLE
RUN dpkg --add-architecture armhf \
    && apt-get -qq update \
    && apt-get install -yy --no-install-recommends \
        cmake \
        make \
        binutils \
        libc6-dev:armhf \
        libgcc-6-dev:armhf \
        libstdc++-6-dev:armhf
COPY --from=builder-libcxxabi /root/prefix/lib /usr/lib/$TARGET_TRIPLE/
COPY --from=builder-libcxx    /root/prefix/lib /usr/lib/$TARGET_TRIPLE/
COPY --from=builder-libcxx    /root/prefix/include /usr/lib/include/