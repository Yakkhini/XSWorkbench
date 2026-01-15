prepare:
  make -C $NEMU_HOME menuconfig CC=gcc # Currently there may appears compiler error. See https://github.com/OpenXiangShan/NEMU/pull/931

build-gem5-ref:
  make -C $NEMU_HOME riscv64-gem5-ref_defconfig
  make -j

clean:
  make -C $NEMU_HOME clean

clean-all:
  make -C $NEMU_HOME clean-all
