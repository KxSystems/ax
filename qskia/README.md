# qskia

## Building

The following repositories are required to build qskia

```Bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git deps/depot_tools
git -C deps/depot_tools checkout 33eb99bb23c5a7c26f85faa4e89020ab345b1c5d
git clone https://skia.googlesource.com/skia.git deps/skia
git -C deps/skia checkout fcad874e42553f65911022f53c7d04553c296609
```
### Linux
#### Skia
Launch an interactive container for the build.
```Bash
docker run -it --rm -v $(pwd):/workspace -w /workspace -e ME=$(id -un) ubuntu:20.04 bash -c "groupadd -g $(id -g) $(id -un); useradd -u $(id -u) -g $(id -g) $(id -un) -m -s /bin/bash; bash"
```
Install the following packages.
```Bash
apt update && DEBIAN_FRONTEND=noninteractive apt install -y git gnupg libfontconfig1-dev lsb-release software-properties-common wget
```
Install LLVM.
```Bash
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh 15
```
Switch to the non-root.
```Bash
su $ME
```
`depot_tools` requires Python 3.10, which can be installed on Ubuntu 20.04 using `uv`.
```Bash
wget -qO- https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
uv venv -p python3.10
source .venv/bin/activate
```
Run the Skia build script.
```Bash
./build-skia.sh 15
```
#### qskia
Launch an interactive container for the build.
```Bash
docker run -it --rm -v $(pwd):/workspace -w /workspace -e ME=$(id -un) ubuntu:20.04 bash -c "groupadd -g $(id -g) $(id -un); useradd -u $(id -u) -g $(id -g) $(id -un) -m -s /bin/bash; bash"
```
Install the following packages.
```Bash
apt update && DEBIAN_FRONTEND=noninteractive apt install -y build-essential libfontconfig1-dev
```
Switch to the non-root user and build.
```Bash
su $ME
make linux_x64
```

### macOS
#### Skia
Run the build script.
```Bash
./build-skia.sh
```
#### qskia
Invoke Make with the following target.
```Bash
make osx_arm64
```

### Windows
#### Skia
Install:
* [LLVM 18.0.0](https://releases.llvm.org/download.html#18.0.0)
* [Visual Studio 2017 Build Tools](https://aka.ms/vs/15/release/vs_buildtools.exe)

Run the build script.
```CMD
.\build-skia.bat
```
#### qskia
Launch a x64 Native Tools Command Prompt for VS 2017 and run MSBuild.
```CMD
msbuild
```

## Example
Running the `example.q` script should produce a `example.png` containing some text and a red circle. For fonts, either provide the path in `skia.init` to where the `fonts` folder exists, or install `libfontconfig1-dev`.
### Linux and macOS
```Bash
QPATH=./dist q example.q
```
### Windows
```PowerShell
$env:QPATH=".\dist";q example.q
```
