Demo of [monocypher](https://monocypher.org/) library for handshake protocol on PicoLisp.

Goal: add encryption layer to distributed programming task from [Rosetta](https://rosettacode.org/wiki/Distributed_programming#PicoLisp).

### How to repeat
* PicoLisp (64bit only, aka pil64)
* Download and install monocypher as shared library
* test.l should pass test(s)
* run 'pil server.l'
* and run 'pil client.l'

### Description
Server listen port `12345` over TCP and client initialize handshake for session keys after connection.

When session keys successfully created on both sides, client sends tasks to server for execution.

Native server and client chatting over PLIO (PicoLisp Input Output) subsystem.
Encoding and decoding of any types processing automagically, number 1024 is a list (8 0 8) internally.

### PLIO encryption example
* Sessions keys after handshake are equal on both sides (32 bytes)
* Send a lisp list:
```
'((1 2) (((a) (3) 44)))
```
* Encoded by PLIO to list of bytes:
```
(1 1 4 2 4 4 3 1 1 1 5 97 3 1 4 6 3 4 88 3 3 3)
```
* Encrypted by Chacha20 with key and always-unique nonce, list becames:
```
(<24 bytes nonce><22 bytes encrypted bytes><16 bytes MAC>)
```
* Send and do reverse steps on other side to get list back.

### Live demo
* Server starting and accept new connections on localhost. Public key known to clients: 
```
$ pil server.l +
Server started.
Public key: 07a37cbc142093c8b755dc1b10e86cb426374ad16aa853ed0bdfc0b2b86d1c7c
```
* Client connected and request server's fork PID and calculate (** 2 77)
```
# pil client.l +
Client started.
Public key: 2df65e55d4cffe0b8207868c528580c5f42df41d3f4ae9a0e287ba10a6554568

Requesting server's Pid.
Reply: 878

Requesting (** 2 77) calculation.
Reply: 151115727451828646838272
Exiting
ok
```
* Server logs successfully connections and public key of client:
```
Connected. Client's public key starts at 2df65e55d4...
2018-09-31 22:29:12 -- (Pid 878) disconnect
```
