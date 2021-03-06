# pgAdmin Windows Builds

These notes describe how to setup a Windows development/build environment for
pgAdmin. Only 64 bit builds are supported from v4.30 onwards, however 32 bit
builds may still work with suitable adjustments.

## Installing build requirements

1. Install Visual Studio 2017 Pro from https://my.visualstudio.com/Downloads?q=Visual%20Studio%202017

Choose the Desktop development with C++ option.

2. Install Chocolatey from https://chocolatey.org/install#individual

3. Install various command line tools:

        choco install -y  bzip2 cmake diffutils dotnet3.5 gzip git innosetup nodejs-lts python strawberryperl wget yarn

4. Upgrade pip (this may give a permissions error that can be ignored):

        pip install --upgrade pip

5. Install virtualenv:

        pip install virtualenv

## Building dependencies

The following steps should be run from a Visual Studio 2017 64bit command
prompt.

1. Create a directory for the dependencies:

        mkdir c:\build64

2. Download the zlib source code, unpack, and build it:

        wget https://zlib.net/zlib-1.2.11.tar.gz
        tar -zxvf zlib-1.2.11.tar.gz
        cd zlib-1.2.11
        cmake -DCMAKE_INSTALL_PREFIX=C:/build64/zlib -G "Visual Studio 15 2017 Win64" .
        msbuild RUN_TESTS.vcxproj /p:Configuration=Release
        msbuild INSTALL.vcxproj /p:Configuration=Release
        copy C:\build64\zlib\lib\zlib.lib C:\build64\zlib\lib\zdll.lib

3. Download the OpenSSL source code, unpack and build it:

        wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz
        tar -zxvf openssl-1.1.1g.tar.gz
        cd openssl-1.1.1g
        perl Configure VC-WIN64A no-asm --prefix=C:\build64\openssl no-ssl2 no-ssl3 no-comp
        nmake
        nmake test
        nmake install

Note that if you are not working in an administrative account, you may need to
create and give your regular account appropriate permissions to write/modify
files in *C:\Program Files\Common Files\SSL*. This is the default directory used
for the *OPENSSLDIR*, and should not be changed to a directory that un-privileged
users could potentially write to.

4. Download the MIT Kerberos source code, unpack and build it:

   In a *32bit* Visual Studio 2017 command prompt:

        mkdir C:\build64\krb5
        cd krb5-1.18.3\src
        set KRB_INSTALL_DIR=C:\build64\krb5
        nmake -f Makefile.in prep-windows

   Optionally, if you want 32bit binaries as well as 64bit:

        nmake NODEBUG=1
        nmake install NODEBUG=1

   In a *64bit* Visual Studio 2017 command prompt:

        cd krb5-1.18.3\src
        set PATH=%PATH%;"%WindowsSdkVerBinPath%"\x86
        set KRB_INSTALL_DIR=C:\build64\krb5
        nmake NODEBUG=1
        nmake install NODEBUG=1

5. Download the PostgreSQL source code, unpack and build it:

        wget https://ftp.postgresql.org/pub/source/v12.3/postgresql-13.1.tar.bz2
        tar -zxvf postgresql-13.1.tar.gz
        cd postgresql-13.1\src\tools\msvc
        
        >> config.pl echo # Configuration arguments for vcbuild.
        >> config.pl echo use strict;
        >> config.pl echo use warnings;
        >> config.pl echo.
        >> config.pl echo our $config = {
        >> config.pl echo 	asserts   =^> 0,        # --enable-cassert
        >> config.pl echo 	ldap      =^> 1,        # --with-ldap
        >> config.pl echo 	extraver  =^> undef,    # --with-extra-version=^<string^>
        >> config.pl echo 	gss       =^> undef,    # --with-gssapi=^<path^>
        >> config.pl echo 	icu       =^> undef,    # --with-icu=^<path^>
        >> config.pl echo 	nls       =^> undef,    # --enable-nls=^<path^>
        >> config.pl echo 	tap_tests =^> undef,    # --enable-tap-tests
        >> config.pl echo 	tcl       =^> undef,    # --with-tcl=^<path^>
        >> config.pl echo 	perl      =^> undef,    # --with-perl
        >> config.pl echo 	python    =^> undef,    # --with-python=^<path^>
        >> config.pl echo 	openssl   =^> 'C:\build64\openssl',    # --with-openssl=^<path^>
        >> config.pl echo 	uuid      =^> undef,    # --with-ossp-uuid
        >> config.pl echo 	xml       =^> undef,    # --with-libxml=^<path^>
        >> config.pl echo 	xslt      =^> undef,    # --with-libxslt=^<path^>
        >> config.pl echo 	iconv     =^> undef,    # (not in configure, path to iconv)
        >> config.pl echo 	zlib      =^> 'C:\build64\zlib'     # --with-zlib=^<path^>
        >> config.pl echo };
        >> config.pl echo.
        >> config.pl echo 1;
        
        >> buildenv.pl echo $ENV{PATH} = "C:\\build64\\openssl\\bin;C:\\build64\\zlib\\bin;$ENV{PATH}";
        
        perl build.pl Release
        perl vcregress.pl check
        perl install.pl C:\build64\pgsql
        copy C:\build64\zlib\bin\zlib.dll C:\build64\pgsql\bin"
        copy C:\build64\openssl\bin\libssl-1_1-x64.dll C:\build64\pgsql\bin"
        copy C:\build64\openssl\bin\libcrypto-1_1-x64.dll C:\build64\pgsql\bin"

## Setting up a dev environment

This section describes the steps to setup and run pgAdmin for the first time in
a development environment. You do not need to complete this section if you just
want to build an installer.

1. Check out the source code:

        git clone https://git.postgresql.org/git/pgadmin4.git

2. Install and build the JS dependencies:

        cd pgadmin4\web
        yarn install
        yarn run bundle

3. Create a virtual env:

        cd pgadmin4
        python -m venv venv
        pip install -r web\regression\requirements.txt
        pip install sphinx

You should now be able to run the pgAdmin Python application, or build the
desktop runtime.

## Building an installer

1. Set the required environment variables, either system-wide, or in a Visual
Studio 2017 64bit command prompt. Note that the examples shown below are the
defaults for the build system, so if they match your requirements you don't
need to set them:

        SET "PGADMIN_POSTGRES_DIR=C:\Program Files\PostgreSQL\13"
        SET "PGADMIN_PYTHON_DIR=C:\Python39"
        SET "PGADMIN_KRB5_DIR=C:\jenkins\build64\krb5"
        SET "PGADMIN_INNOTOOL_DIR=C:\Program Files (x86)\Inno Setup 6"
        SET "PGADMIN_SIGNTOOL_DIR=C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64"
        SET "PGADMIN_VCREDIST_DIR=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Redist\MSVC\14.16.27012"

2. Run:

        make

If you have a code signing certificate, this will automatically be used if
found in the Windows Certificate Store to sign the installer.

3. Find the completed installer in the dist/ subdirectory of your source tree.
