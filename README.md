# qubes-mirage-skeleton

A demonstration unikernel that can run as a QubesOS VM. 
It acts as a qrexec agent, receiving commands sent from dom0.
It uses the [mirage-qubes][] library to implement the Qubes protocols.

Note: since the release of mirage 3.0 a lot of the explicit setup done in this codebase is
done automatically by `mirage configure -t qubes`. This repo remains for educational purposes.

The example code queries QubesDB to get the network configuration, resolves "google.com" using its network VM's DNS service and then fetches "http://google.com".
It also responds provides a qrexec command, which can be invoked from dom0 (or other domains, if you allow it).

To build (ensure you have mirage 3.9.0 or later):

    $ opam install mirage
    # NB: We specifically target xen to show explicitly the QubesOS setup independently from the mirage automatic configuration
    $ mirage configure -t xen   
    $ make depend
    $ make

You can use this with the [test-mirage][] scripts to deploy the unikernel (`qubes_skeleton.xen`) from your development AppVM. e.g.

    $ test-mirage qubes_skeleton.xen mirage-test
    Waiting for 'Ready'... OK
    Uploading 'qubes_skeleton.xen' (4422320 bytes) to "mirage-test"
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
    gnttab_table mapped at 0000000002001000.
    Netif: add resume hook
    Netif.connect 0
    Netfront.create: id=0 domid=2
     sg:true gso_tcpv4:false rx_copy:true rx_flip:false smart_poll:false
    MAC: 00:16:3e:5e:6c:09
    Attempt to open(/dev/urandom)!
    Unsupported function getpid called in Mini-OS kernel
    Unsupported function getppid called in Mini-OS kernel
    Manager: connect
    Manager: configuring
    Manager: Interface to 127.0.0.1 nm 255.255.255.255 gw []

    ARP: sending gratuitous from 127.0.0.1
    Manager: configuration done
    2016-06-25 18:30.56: INF [unikernel] Starting
    2016-06-25 18:30.56: INF [qubes.rexec] waiting for client...
    2016-06-25 18:30.56: INF [qubes.gui] waiting for client...
    2016-06-25 18:30.56: INF [qubes.db] connecting to server...
    gnttab_stubs.c: initialised mini-os gntmap
    2016-06-25 18:30.56: INF [qubes.db] connected
    2016-06-25 18:30.56: INF [qubes.rexec] client connected, using protocol version 2
    2016-06-25 18:30.56: INF [qubes.db] got update: "/qubes-keyboard" = "xkb_keymap {\n\txkb_keycodes  { include \"evdev+aliases(qwerty)\"\t};\n\txkb_types     { include \"complete\"\t};\n\txkb_compat    { include \"complete\"\t};\n\txkb_symbols   { include \"pc+gb+inet(evdev)\"\t};\n\txkb_geometry  { include \"pc(pc104)\"\t};\n};"
    2016-06-25 18:30.56: INF [qubes.gui] client connected (screen size: 6720x2160)
    2016-06-25 18:30.56: INF [unikernel] agents connected in 0.101 s (CPU time used since boot: 0.027 s)
    2016-06-25 18:30.56: INF [unikernel] QubesDB "/qubes-ip" = "10.137.3.11"
    2016-06-25 18:30.56: INF [unikernel] QubesDB "/qubes-netmask" = "255.255.255.0"
    2016-06-25 18:30.56: INF [unikernel] QubesDB "/qubes-gateway" = "10.137.3.1"
    ARP: sending gratuitous from 10.137.3.11
    ARP: sending gratuitous from 127.0.0.1
    2016-06-25 18:30.56: INF [unikernel] QubesDB "/qubes-primary-dns" = "10.137.3.1"
    2016-06-25 18:30.56: INF [unikernel] Resolving "google.com"
    Attempt to open(/dev/urandom)!
    Unsupported function getpid called in Mini-OS kernel
    Unsupported function getppid called in Mini-OS kernel
    ARP: transmitting probe -> 10.137.3.1
    Note: cannot write Xen 'control' directory
    ARP: updating 10.137.3.1 -> 00:16:3e:5e:6c:09
    2016-06-25 18:30.56: INF [unikernel] "google.com" has IPv4 address 216.58.198.110
    2016-06-25 18:30.56: INF [unikernel] Opening TCP connection to 216.58.198.110:80
    2016-06-25 18:30.56: WRN [command] << Unknown command "QUBESRPC qubes.SetMonitorLayout dom0"
    2016-06-25 18:30.56: INF [unikernel] Connected!
    2016-06-25 18:30.56: WRN [command] << Unknown command "QUBESRPC qubes.WaitForSession none"
    2016-06-25 18:30.56: INF [unikernel] Received "HTTP/1.0 302 Found\r\nCache-Control: private\r\nContent-Type: text/html; charset=UTF-8\r\nLocation: http://www.google.co.uk/?gfe_rd=cr&ei=4s1uV_XdAYvW8AfCwKv4AQ\r\nContent-Length: 261\r\nDate: Sat, 25 Jun 2016 18:30:58 GMT\r\n\r\n<HTML><HEAD><meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\">\n<TITLE>302 Moved</TITLE></HEAD><BODY>\n<H1>302 Moved</H1>\nThe document has moved\n<A HREF=\"http://www.google.co.uk/?gfe_rd=cr&amp;ei=4s1uV_XdAYvW8AfCwKv4AQ\">here</A>.\r\n</BODY></HTML>\r\n"
    2016-06-25 18:30.56: INF [unikernel] Closing TCP connection
    2016-06-25 18:30.56: INF [unikernel] Network test done. Waiting for qrexec commands...

You can invoke commands from dom0. e.g.

    [tal@dom0 bin]$ qvm-run -p mirage-test echo
    Hi user! Please enter a string:
    Hello
    You wrote "Hello". Bye.


# LICENSE

Copyright (c) 2020, Thomas Leonard
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
gg

[test-mirage]: https://github.com/talex5/qubes-test-mirage
[mirage-qubes]: https://github.com/mirage/mirage-qubes
