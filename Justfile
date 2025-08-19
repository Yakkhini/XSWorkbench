setup:
  git submodule update --init --recursive DRAMsim3 NEMU NutShell nexus-am GEM5
  git submodule update --init XiangShan && make -C XiangShan init;

update-module:
  cd XiangShan; git fetch origin; git checkout origin/master; make init; cd ..
  cd GEM5; git checkout xs-dev; git pull; cd ..
  cd NEMU; git checkout master; git pull; cd ..
  cd nexus-am; git checkout master; git pull; cd ..

clean:
  rm -r ./install

