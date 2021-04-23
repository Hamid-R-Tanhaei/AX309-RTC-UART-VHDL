setmode -bs
setcable -p auto
identify -inferir
identifympm
attachflash -p 1 -spi "M25P16"
assignfiletoattachedflash -p 1 -file "spi_flash.mcs"
program -e -p 1 -spionly -v -loadfpga
quit
