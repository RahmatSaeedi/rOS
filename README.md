
# Requirements
rOS was built and tested on Ubuntu 20.04 LTS via [WLS](https://docs.microsoft.com/en-us/windows/wsl/faq). Programs needed to build and mount on a virtual machine are:
- nasm, version 2.14.02
- as, GNU assembler 2.34
- ld, GNU ld 2.34
- make, GNU 4.2.1
- gcc-10
- g++-10
- Virtualbox


_[`NASM`](https://www.nasm.us/)_ may be substituted for _[`as`](https://en.wikipedia.org/wiki/GNU_Assembler)_ to build assembly files. [MinGW](http://www.mingw.org/) or [Cygwin](http://www.cygwin.com/) could be used and configured on windows operating sytems if `WLS` is not available. 

Pointer to the location programs may be changed in the header portion of the [`Makefile`](Makefile#Header).



# Environment Setup
1. [Ubuntu 20.04](https://ubuntu.com/#download) OR [Windows 10, Update 2004](https://www.microsoft.com/en-ca/software-download/windows10ISO) or higher with [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel)
    - Open Command prompt to enable `WSL` and  `Virtual Machine Platform`
        ```bash
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        ```
    - You also need to  update the `WSL` to [`WSL 2 Linux kernel`](https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel)
    - Set WLS 2 as the default version
        ```bash
        wsl --set-default-version 2
        ```
    - Install [Ubuntu 20.04](https://www.microsoft.com/en-gb/p/ubuntu-2004-lts/9n6svws3rx71) or higher

    - To check your version of `WSL` run `wsl -l -v`, and possibly run `wsl --set-version {MACHINE_NAME} 2` to change the version to _2_.
2. Alternativly [Ubuntu 20.04](https://ubuntu.com/#download) or higher
3. Install required software, and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
    ```bash
    sudo apt-get update -y
    sudo apt-get install -y nasm binutils gcc-10 g++-10
    ```

# Build & Test
1. Ensure the path to the VirtualBox is correct in the [Makefile](Makefile#Programs)
2. Build and Run the VM
    ```bash
    make VMSetup
    make startVM
    ```



