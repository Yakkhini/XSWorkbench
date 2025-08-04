setup:
  git submodule update --init --recursive DRAMsim3 NEMU NutShell nexus-am GEM5
  git submodule update --init XiangShan && make -C XiangShan init;

