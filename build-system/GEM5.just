setup:
  #!/usr/bin/env zsh
  cd ext/dramsim3
  git clone https://github.com/umd-memsys/DRAMsim3.git DRAMsim3
  cd DRAMsim3 && mkdir -p build
  cd build
  cmake ..
  make -j 48

build:
  scons build/RISCV/gem5.opt --gold-linker -j $NIX_BUILD_CORES
  mkdir -p $XS_PROJECT_ROOT/install/bin
  cp $GEM5_HOME/build/RISCV/gem5.opt $XS_PROJECT_ROOT/install/bin/xs-gem5

build-debug:
  scons build/RISCV/gem5.debug --gold-linker -j $NIX_BUILD_CORES
  mkdir -p $XS_PROJECT_ROOT/install/bin
  cp $GEM5_HOME/build/RISCV/gem5.debug $XS_PROJECT_ROOT/install/bin/xs-gem5-debug

only-install:
  mkdir -p $XS_PROJECT_ROOT/install/bin
  cp $GEM5_HOME/build/RISCV/gem5.opt $XS_PROJECT_ROOT/install/bin/xs-gem5

prepare:
  nemujust riscv64-gem5-ref_defconfig
  nemujust -j100
  cd $NEMU_HOME/resource/gcpt_restore && make clean && make

xs-run workload:
  #!/usr/bin/env zsh
  mkdir -p $XS_PROJECT_ROOT/out
  export workloadname=$(basename -s .zstd {{workload}})
  export tag=single-$(date +%F)-$(cd $GEM5_HOME && git rev-parse --short HEAD)
  mkdir -p $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname/ref
  # should not hardcode the path here like `nfs`
  xs-gem5 -d $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname $GEM5_HOME/configs/example/kmhv3.py --enable-bp-db tage --bp-type=DecoupledBPUWithBTB --ideal-kmhv3 --difftest-ref-so $NEMU_HOME/build/riscv64-nemu-interpreter-so --gcpt-restore /nfs/share/gem5_ci/tools/normal-gcb-restorer.bin --generic-rv-cpt {{workload}}
  xs-gem5-ref -d $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname/ref $GEM5_HOME/configs/example/kmhv3.py --enable-bp-db tage --bp-type=DecoupledBPUWithBTB --ideal-kmhv3 --difftest-ref-so $NEMU_HOME/build/riscv64-nemu-interpreter-so --gcpt-restore /nfs/share/gem5_ci/tools/normal-gcb-restorer.bin --generic-rv-cpt {{workload}}

xs-run-debug workload:
  #!/usr/bin/env zsh
  mkdir -p $XS_PROJECT_ROOT/out
  export workloadname=$(basename -s .zstd {{workload}})
  export tag=single-$(date +%F)-$(cd $GEM5_HOME && git rev-parse --short HEAD)
  mkdir -p $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname/debug
  # should not hardcode the path here like `nfs`
  gdb --args xs-gem5-debug -d $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname/debug $GEM5_HOME/configs/example/xiangshan.py --enable-bp-db tage --bp-type=DecoupledBPUWithBTB --disable-mgsc --ideal-kmhv3 --difftest-ref-so $NEMU_HOME/build/riscv64-nemu-interpreter-so --gcpt-restore /nfs/share/gem5_ci/tools/normal-gcb-restorer.bin --generic-rv-cpt {{workload}}

xs-parallel-run workload:
  echo "Please use OpenXiangShan/GEM5 CI to run parallel simulations."

xs-run-raw workload:
  #!/usr/bin/env zsh
  mkdir -p $XS_PROJECT_ROOT/out
  export workloadname=$(basename -s .bin {{workload}})
  export tag=single-raw-$(date +%F)-$(cd $GEM5_HOME && git rev-parse --short HEAD)
  mkdir -p $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname/ref
  xs-gem5 -d $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname $GEM5_HOME/configs/example/kmhv3.py --enable-bp-db tage --bp-type=DecoupledBPUWithBTB --ideal-kmhv3 --difftest-ref-so $NEMU_HOME/build/riscv64-nemu-interpreter-so --raw-cpt --generic-rv-cpt {{workload}}
  xs-gem5-ref -d $XS_PROJECT_ROOT/out/gem5/$tag/$workloadname/ref $GEM5_HOME/configs/example/kmhv3.py --enable-bp-db tage --bp-type=DecoupledBPUWithBTB --ideal-kmhv3 --difftest-ref-so $NEMU_HOME/build/riscv64-nemu-interpreter-so --raw-cpt --generic-rv-cpt {{workload}}

xs-run-raw-debug workload:
  #!/usr/bin/env zsh
  mkdir -p $XS_PROJECT_ROOT/out
  export tag=single-raw-$(date +%F)-$(cd $GEM5_HOME && git rev-parse --short HEAD)
  mkdir -p $XS_PROJECT_ROOT/out/gem5/$tag/debug
  gdb --args xs-gem5-debug -d $XS_PROJECT_ROOT/out/gem5/$tag/debug $GEM5_HOME/configs/example/idealkmhv3.py --enable-bp-db tage --bp-type=DecoupledBPUWithBTB --disable-mgsc --ideal-kmhv3 --difftest-ref-so $NEMU_HOME/build/riscv64-nemu-interpreter-so --raw-cpt --generic-rv-cpt {{workload}}

copy-result path ref-path:
  #!/usr/bin/env nu
  let tag = $"parallel-(date now | format date "%Y-%m-%d")-(git log -1 --pretty=%B | split row ' ' | select 1 2 3 4 | str join '-')"
  mkdir ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref)
  print "Copying results to ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)"
  cp {{path}}/* ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)
  cp {{ref-path}}/* ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/)
  print $"Extracting spec_all.tar.gz to ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)"
  tar -xzf {{path}}/spec_all.tar.gz -C ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)
  print $"Extracting ref/spec_all.tar.gz to ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/)"
  tar -xzf {{ref-path}}/spec_all.tar.gz -C ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/)
  print "Computing weighted IPC and performance counters..."
  let jsonPath = "/nfs/share/zyy/spec06_rv64gcb_O3_20m_gcc12.2.0-intFpcOff-jeMalloc/zstd-checkpoint-0-0-0/cluster-0-0.json"
  cd ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all)
  mkdir results
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/batch.py) -s ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all) --branch -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf.csv) -j $jsonPath -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf-weighted.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf.csv) -j $jsonPath --score ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf-score.csv)
  cd ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all)
  mkdir results
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/batch.py) -s ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all) --branch -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all/perf.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all/perf.csv) -j $jsonPath -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all/perf-weighted-ref.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all/perf.csv) -j $jsonPath --score ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/ref/spec_all/perf-score-ref.csv)
  cd ($env.XS_PROJECT_ROOT + /out/gem5/($tag))
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/compare_weighted.py) ref/spec_all/perf-weighted-ref.csv spec_all/perf-weighted.csv

copy-result-rtl path rtl-path:
  #!/usr/bin/env nu
  let tag = $"parallel-(date now | format date "%Y-%m-%d")-(git log -1 --pretty=%B | split row ' ' | select 1 2 3 4 | str join '-')"
  mkdir ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl)
  print "Copying results to ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)"
  cp {{path}}/* ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)
  cp {{rtl-path}}/* ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/)
  print $"Extracting spec_all.tar.gz to ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)"
  tar -xzf {{path}}/spec_all.tar.gz -C ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/)
  print "Computing weighted IPC and performance counters..."
  let jsonPath = "/nfs/share/zyy/spec06_rv64gcb_O3_20m_gcc12.2.0-intFpcOff-jeMalloc/zstd-checkpoint-0-0-0/cluster-0-0.json"
  cd ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all)
  mkdir results
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/batch.py) -s ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all) --branch -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf.csv) -j $jsonPath -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf-weighted.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf.csv) -j $jsonPath --score ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/spec_all/perf-score.csv)
  cd ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl)
  mkdir results
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/batch.py) -s ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/) --branch -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/perf.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/perf.csv) -j $jsonPath -o ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/perf-weighted-rtl.csv)
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/simpoint_cpt/compute_weighted.py) -r ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/perf.csv) -j $jsonPath --score ($env.XS_PROJECT_ROOT + /out/gem5/($tag)/rtl/perf-score-rtl.csv)
  cd ($env.XS_PROJECT_ROOT + /out/gem5/($tag))
  python3 ($env.XS_PROJECT_ROOT + /DataProcess/compare_weighted.py) rtl/perf-weighted-rtl.csv perf-weighted.csv

run-dot8coverage:
  # should not hardcode the path here like `nfs`
  bash $GEM5_HOME/util/xs_scripts/parallel_sim.sh /nfs/share/gem5_ci/spec06_cpts/spec_0.8c_int.lst /nfs/home/share/jiaxiaoyu/simpoint_checkpoint_zstd_format/spec06_rv64gcb_O3_20m_gcc12.2.0-intFpcOff-jeMalloc

clean:
  rm -r $GEM5_HOME/build
