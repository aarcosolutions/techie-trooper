---
layout: post
title: "Converting VMWare to Microsoft Virtual Machine"
date: 2020-01-23
categories: virtualisation
tags: vmware hyperv
---

Converting virtual machines and disks from VMWare hosts to Hyper-V hosts and Windows Azure or convert computers and disks to Hyper-V hosts can be achieved by using Microsoft Virtual Machine Converter GUI or powershell cmdlet

# Pre-requisite
Download 
   1.   [Microsoft Virtual Machine Converter 3.0](https://www.microsoft.com/en-gb/download/details.aspx?id=42497)
   2. [dsfok toolset](http://sanbarrow.com/files/dsfok.zip)

VMWare virtual machines are in vmdk format which is not supported by Windows Hyper-V. Microsoft provide Microsoft Virtual Machine Converter for converting VMKD to VHD/VHDX format.

Microsoft Virtual Machine Converter (MVMC) provides native support for Windows PowerShell and can also be invoked through the Windows PowerShell command-line interface. 


# Converting VMDX to VHD/VHDX

1. Open a powershell command line console in the folder where VMWar vmdk file is stored
2. Execute following powershell command to import MVMC powershell commandlet
```powershell
Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"
```
3. Execute following command to begin the conversion process
```powershell
ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath "file-to-be-converted.vmdk" -DestinationLiteralPath "<destination-folder-path>" -VhdType DynamicHardDisk -VhdFormat Vhd
```

**Usage**
- **SourceLiteralPath**_ <path> is the path to a VMware virtual disk that should be converted.
- **DestinationLiteralPath**_ <path> is the path to a directory where the virtual disk of the Hyper-V format should be saved.
- **VhdType**_ <type> defines the type of the virtual disk – either dynamically expanding or fixed.
- **VhdFormat**_ defines the format of the Hyper-V virtual disk (VHD or VHDX).

Wait until the conversion process is finished. You will find the converted VHD/VHDX file in the folder path mentioned in **DestinationLiteralPath** parameter.

## Troubleshooting

You might encounter following error when ConvertTo-MvmcVirtualHardDisk is execute

>ConvertTo-MvmcVirtualHardDisk : The entry 4 is not a supported disk database entry for the descriptor.

Please note that the entry number can be any number.

To fix this, use dsfo and dsfi executables from dsfok toolset to update the vmdk descriptor information on the file. Use dsfo.exe to extract disk descriptor out of the VMDK file. 

```powershell
dsfo.exe "file-to-be-converted.vmdk" 512 1024 descriptor1.txt
```

The vmdk descriptore information is extracted into descriptor.txt. The content of this fill will be something like this:
```
# Disk DescriptorFile
version=1
encoding="windows-1252"
CID=5379bf0f
parentCID=ffffffff
isNativeSnapshot="no"
createType="monolithicSparse"

# Extent description
RW 209715200 SPARSE "00054_C8PHS1096_151216-disk2.vmdk"

# The Disk Data Base 
#DDB

ddb.adapterType = "lsilogic"
ddb.geometry.biosCylinders = "13054"
ddb.geometry.biosHeads = "255"
ddb.geometry.biosSectors = "63"
ddb.geometry.cylinders = "13054"
ddb.geometry.heads = "255"
ddb.geometry.sectors = "63"
ddb.longContentID = "64d4e008b7227bcce8aa54995379bf0f"
ddb.toolsInstallType = "4"
ddb.toolsVersion = "10241"
ddb.uuid = "60 00 C2 96 f7 70 f2 fd-b5 02 9e 46 6c df 00 2e"
ddb.virtualHWVersion = "10"
```
Pay attention to the following line in the descriptor1.txt file

>ddb.toolsInstallType = "4"

ConvertTo-MvmcVirtualHardDisk command fails as it doesn't like this line. To resolve this issue, edit the descriptio1.txt file and command this line by adding a **#** infront of _**ddb.toolsInstallType**_ line.

Now use dsfi.exe tool to reapply the descriptor to the vmdk file.

```powershell
dsfi.exe "file-to-be-converted.vmdk" 512 1024 descriptor1.txt
```
Finally execute ConvertTo-MvmcVirtualHardDisk to convert vmdx to vhd/vhdx.

```powershell
Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"

ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath "file-to-be-converted.vmdk" -DestinationLiteralPath "<destination-folder-path>" -VhdType DynamicHardDisk -VhdFormat Vhd
```

## Disclaimer:
I have created this guide based the experience I had gained while converting a VMware virtual machine to Hyper-V and various articles I have read on Google. Any action you take upon the information provided in this article is strictly at your own risk and I will not be liable for any losses and damages in connection with the use of this article.
