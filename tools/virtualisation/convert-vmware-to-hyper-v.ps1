Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"

C:\Hyper-V\dsfok\dsfo.exe "Ubuntu-18-04.vmdk" 512 1024 descriptor1.txt

C:\Hyper-V\dsfok\dsfi.exe "Ubuntu-18-04.vmdk" 512 1024 descriptor1.txt

ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath "Ubuntu-18-04.vmdk" -DestinationLiteralPath "..\" -VhdType DynamicHardDisk -VhdFormat Vhd

