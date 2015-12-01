# qubes-mirage-skeleton

An experimental unikernel that can run as a QubesOS VM.
It acts as a qrexec agent, receiving commands sent from dom0.
It uses the [mirage-qubes][] library to implement the Qubes protocols.

To build:

    $ opam install mirage
    $ opam pin add mirage-qubes https://github.com/talex5/mirage-qubes.git
    $ mirage configure --xen
    $ make

You can use this with the [test-mirage][] scripts to deploy the unikernel (`mir-qubes-skeleton.xen`) from your development AppVM. e.g.

    $ test-mirage mir-qubes-skeleton.xen mirage-test
    Waiting for 'Ready'... OK
    Uploading 'mir-qubes-skeleton.xen' (4422320 bytes) to "mirage-test"
    Waiting for 'Booting'... OK
    --> Creating volatile image: /var/lib/qubes/appvms/mirage-test/volatile.img...
    --> Loading the VM (type = AppVM)...
    --> Starting Qubes DB...
    --> Setting Qubes DB info for the VM...
    --> Updating firewall rules...
    --> Starting the VM...
    --> Starting the qrexec daemon...
    Waiting for VM's qrexec agent.connected
    --> Starting Qubes GUId...
    Connecting to VM's GUI agent: .connected
    --> Sending monitor layout...
    --> Waiting for qubes-session...
    Connecting to mirage-test console...
    MirageOS booting...
    Initialising timer interface
    Initialising console ... done.
    2015-12-01 20:58.51: info [qrexec-agent] waiting for client...
    2015-12-01 20:58.51: info [gui-agent] waiting for client...
    2015-12-01 20:58.51: info [qubesDB] connecting to server...
    gnttab_stubs.c: initialised mini-os gntmap
    2015-12-01 20:58.51: info [qubesDB] connected
    2015-12-01 20:58.51: info [qubesDB] "/qubes-vm-updateable" = "False"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-vm-type" = "AppVM"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-vm-persistence" = "rw-only"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-usb-devices" = ""
    2015-12-01 20:58.51: info [qubesDB] "/qubes-timezone" = "Europe/London"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-service/meminfo-writer" = "1"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-secondary-dns" = "10.137.2.254"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-random-seed" = "dqPrqr+0vup8K2WdjyoL+tuR9tq96kgkoZGR8JVP8PjjeJrjNmRkU6kCHDt3ABupRjXoAF9yE4S3qS7EWX1Xwg=="
    2015-12-01 20:58.51: info [qubesDB] "/qubes-netmask" = "255.255.255.0"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-ip" = "10.137.2.11"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-gateway" = "10.137.2.1"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-debug-mode" = "0"
    2015-12-01 20:58.51: info [qubesDB] "/qubes-block-devices" = ""
    2015-12-01 20:58.51: info [qubesDB] "/qubes-base-template" = "fedora-21"
    2015-12-01 20:58.51: info [qubesDB] "/name" = "mirage-test"
    2015-12-01 20:58.52: info [qrexec-agent] client connected, using protocol version 2
    2015-12-01 20:58.52: info [qubesDB] write "/qubes-keyboard" = "xkb_keymap {\n\txkb_keycodes  { include \"evdev+aliases(qwerty)\"\t};\n\txkb_types     { include \"complete\"\t};\n\txkb_compat    { include \"complete\"\t};\n\txkb_symbols   { include \"pc+gb+inet(evdev)\"\t};\n\txkb_geometry  { include \"pc(pc104)\"\t};\n};"
    2015-12-01 20:58.52: info [gui-agent] client connected (screen size: 6720x2160)
    2015-12-01 20:58.52: info [main] agents connected in 0.103 s (CPU time used since boot: 0.009 s)
    2015-12-01 20:58.52: info [main] My IP address is "10.137.2.11"
    2015-12-01 20:58.52: WARN [qrexec-agent] << Unknown command "QUBESRPC qubes.SetMonitorLayout dom0"
    2015-12-01 20:58.52: WARN [qrexec-agent] << Unknown command "QUBESRPC qubes.WaitForSession none"

You can invoke commands from dom0. e.g.

    [tal@dom0 bin]$ qvm-run -p mirage-test echo
    Hi user! Please enter a string:
    Hello
    You wrote "Hello". Bye.


# LICENSE

Copyright (c) 2015, Thomas Leonard
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
gg

[test-mirage]: https://github.com/talex5/qubes-test-mirage
[mirage-qubes]: https://github.com/talex5/mirage-qubes
