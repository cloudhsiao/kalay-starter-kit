# Kalay Platform

* Kalay Platform is an extremely flexible and scalable IoT platform designed to enable retailers, service providers, user electronics OEMs, and system integrators to quickly and easily deploy their own connected device ecosystems to maximize business opportunities with IoT. 

* Kalay Platform makes this possible by addressing, at all levels, the challenges inherent in the fast-developing IoT environment, and providing innovative solutions designed with the future in mind. At the forefront of these challenges is solving the problem of multiple protocols, brands, and data sources providing users with app overload when attempting to control different devices. Kalay unifies these disparate elements in one platform, easing your product's adoption. In addition, a strong focus on the technology builds intelligent relationships and communication between devices, creating the structure to more easily expand your family of devices.

* Kalay Platform also addresses time-to-market and mass deployment challenges, simplifying and accelerating chipset enablement and application development, providing solutions that improve video streaming integration in the smart home.

# Kalay Kit - Starter Version

The Kalay Kit - Starter Version (or Kalay Starter Kit) supports establishment of connections of device to device, device to client and client to device. It assists devices in setting up tunnel connections to provide private pathways for transmission via a public network.

The Kalay Starter Kit content includes:

* Library files (./Lib)
* API definition and declaration (./Include)
* Sample codes (./Sample)

## Basic Concept

### Terminology

#### Server
 A machine, maintained by ThroughTek, to handle connection among devices and clients using Kalay Platform P2P or relay service.

#### Device
An equipment made by a vendor that is capable of Kalay Platform integration to enable clients to build connection, even if the device is put behind NAT.

#### Client
A terminal connecting to devices for in-between data to be communicated.

#### UID
A twenty-byte unique identification issued by ThroughTek for each device that requires P2P tunnel connection build.

> Devic will use the UID to login to Server and wait for client connection;
> Client will use the UID to connect to the device. 

### Penetration Capability
There are four types of network address translation (NAT) mechanism that are commonly used in current network environment (please refer to "https://en.wikipedia.org/wiki/Network_address_translation" for more details).

By using this SDK, devices and clients can leverage P2P communication using the following NAT combination:

 CASE  | NAT Type in Device          | NAT Type in Client
:----: | --------------------------- | ----------------------------
  1    | Full-cone NAT               | Full-cone NAT
  2    | Full-cone NAT               | Address-restricted cone NAT
  3    | Full-cone NAT               | Port-restricted cone NAT
  4    | Full-cone NAT               | Symmetric NAT
  5    | Address-restricted cone NAT | Full-cone NAT
  6    | Address-restricted cone NAT | Address-restricted cone NAT
  7    | Address-restricted cone NAT | Port-restricted cone NAT
  8    | Address-restricted cone NAT | Symmetric NAT
  9    | Port-restricted cone NAT    | Full-cone NAT
 10    | Port-restricted cone NAT    | Address-restricted cone NAT
 11    | Port-restricted cone NAT    | Port-restricted cone NAT
 12    | Symmetric NAT               | Full-cone NAT
 13    | Symmetric NAT               | Address-restricted cone NAT

However, if P2P connection cannot be established between devices and clients, relay mode will be used for communication between devices and clients, using the following NAT combination:

 CASE  | NAT Type in Device       | NAT Type in Client
:----: | ------------------------ | -------------------
  1    | Port-restricted cone NAT | Symmetric NAT
  2    | Symmetric NAT            | Port-restricted cone NAT
  3    | Symmetric NAT            | Symmetric NAT

The relay service will work as long as both devices and clients can connect to the server. When considering the robustness of the connection, relay service is an efficient and reliable method for using NAT technique.

## Usage

### Apply your UID
You may go to our [website](^http://www.tutk.com/dev_kalay_kit.html), tell us who you are, what kind of product you want to build, we will reply you the testing UID as soon as possible.
Normally, the UID will expire in a year after activating.

### Device
Kalay Starter Kit supports several popular open-source development boards, including Raspberry Pi, Arduino Yun, WRTnode, BeagleBone Black, Intel Edison/Galileo and LinkIt 7688.

Board name       | Library folder
---------------- | -----------------------------
Raspberry Pi 2/3 | Lib/Linux/ARM_BCM2835_4.8.3
Arduino Yun      | Lib/Linux/MIPS_AR9331_4.3.3
WRTnode          | Lib/Linux/MIPS_MT7620N_4.8.3
BeagleBone Black | Lib/Linux/ARM_AM335x_4.6.3
Intel Edison     | Lib/Linux/x86_Edison_4.9.1
Intel Galileo    | Lib/Linux/x86_Galileo_4.7.2
LinkIt 7688      | Lib/Linux/MIPS_MT7688_4.6.3

For example, if you are using the Raspberry Pi, please use the command below.

```bash
$ cd %KALAY_SDK%
$ gcc YOUR_C_FILE -I'./Include' -L'./Lib/Linux/ARM_BCM2835_4.8.3' -lP2PTunnelAPIs -lRDTAPIs -lIOTCAPIs -lpthread -o YOUR_PROGRAM
$ LD_LIBRARY_PATH=./Lib/Linux/ARM_BCM2835_4.8.3 ./YOUR_PROGRAM
```

#### Android
For programming Android apps, you need to copy library files of Kalay SDK to your project folder `app/src/main/jniLibs` and the wrapper class files of Kalay SDK to your project folder `app/src/main/java`.

#### iOS
Drag the library and header files of Kalay SDK to the project in Xcode directly.

**To import Kalay SDK into your Swift project**

* In your Objective-C bridging header file, import the Kalay SDK header you want to expose to Swift. For example:

```swift
#import "P2PTunnelAPIs.h"
```

* In Build Settings, in Swift Compiler - Code Generation, make sure the Objective-C Bridging Header build setting under has a path to the bridging header file.

> Refer to the link to get more details. (https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html)

## License
Copyright (C) 2016, ThroughTek Co., Ltd.
ThroughTek Co., Ltd., 9F, No. 364, Sec. 1, Nangang Rd., Nangang District, Taipei City 115, Taiwan.

### The sample code (./Sample)

* This program is a free software; you can redistribute it and/or modify it under the terms of The BSD 3-Clause License as approved by Open Source Initiative.(See The BSD 3-Clause License for more details)

* This program is provided “as is” with all faults, defects and errors, and without warranty of any kind. In no event shall ThroughTek Co., Ltd. be liable for any direct, indirect, incidental, special, exemplary, or consequential damages however caused and on any theory of liability, whether in contract, strict liability, or tort arising in any way out the use of this program, even if advised of the possibility of such damage.

### The library file (./Lib and ./Include)

* This program is a free software; you can redistribute it and/or modify it under the terms of The BSD 3-Clause License as approved by Open Source Initiative. (See The BSD 3-Clause License for more details) But you may not decompile, disassemble, reverse-engineer, or use this program for commercial purposes.

* This program is provided “as is” with all faults, defects and errors, and without warranty of any kind. In no event shall ThroughTek Co., Ltd. be liable for any direct, indirect, incidental, special, exemplary, or consequential damages however caused and on any theory of liability, whether in contract, strict liability, or tort arising in any way out the use of this program, even if advised of the possibility of such damage.


> The license for the Kalay Starter Kit can be found in the `LICENSE` file parallel to this `README.md`.