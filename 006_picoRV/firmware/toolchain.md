mkdir -p ~/opt/riscv-rv32i

./configure --prefix=$HOME/opt/riscv-rv32i \
  --with-arch=rv32i \
  --with-abi=ilp32 \
  --with-newlib

make newlib
make install

echo 'export PATH=$HOME/opt/riscv-rv32i/bin:$PATH' >> ~/.bashrc