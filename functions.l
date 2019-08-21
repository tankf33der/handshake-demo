(de randL (N)
   (make (do N (link (rand 0 255)))) )
(de hexify (L)
   (lowc
      (pack
         (mapcar '((B) (pad 2 (hex B))) L) ) ) )
(de hex2L (H)
   (make
      (for (L (chop H) L (cddr L))
         (link (hex (pack (car L) (cadr L)))) ) ) )
(de x25519_public_key (S)
   (let P NIL
      (native
         "libmonocypher.so"
         "crypto_x25519_public_key"
         NIL
         '(P (32 B . 32))
         (cons NIL (32) S) )
      P ) )
(de crypto_request (C Seed SP CS CP)
   (let R NIL
      (native
         "libmh.so"
         "crypto_handshake_request"
         NIL
         C
         (cons NIL (32) Seed) # XXX ?
         '(R (32 B . 32))
         (cons NIL (32) SP)
         (cons NIL (32) CS)
         (cons NIL (32) CP) )
      R ) )
(de crypto_respond (C Seed M SS SP)
   (let R NIL
      (native
         "libmh.so"
         "crypto_handshake_respond"
         NIL
         C
         (cons NIL (32) Seed) # XXX ?
         '(R (48 B . 48))
         (cons NIL (32) M)
         (cons NIL (32) SS)
         (cons NIL (32) SP) )
      R ) )
(de crypto_confirm (C M)
   ~(assert (= 48 (length M)))
   (let (K NIL  R NIL)
      (and
         (=0
            (native
               "libmh.so"
               "crypto_handshake_confirm"
               'I
               C
               '(K (32 B . 32))
               '(R (48 B . 48))
               (cons NIL (48) M) ) )
         (conc K R) ) ) )
(de crypto_accept (C M)
   ~(assert (= 48 (length M)))
   (let (K NIL  R NIL)
      (and
         (=0
            (native
               "libmh.so"
               "crypto_handshake_accept"
               'I
               C
               '(K (32 B . 32))
               '(R (32 B . 32))
               (cons NIL (48) M) ) )
         (conc K R) ) ) )
(de requestor (Sock SP CS CP)
   (let
      (Ctx (native "@" "malloc" 'N 424)
         Seed (randL 32)
         Msg3 NIL )
      (out Sock (pr (crypto_request Ctx Seed SP CS CP)))
      (setq Msg3 (crypto_confirm Ctx (in Sock (rd))))
      ~(assert (= 80 (length Msg3)))
      (and
         Msg3
         (out Sock (pr (tail 48 Msg3))) )
      (native "@" "free" NIL Ctx)
      (head 32 Msg3) ) )
(de responder (Sock SS SP)
   (let
      (Ctx (native "@" "malloc" 'N 424)
         Seed (randL 32)
         Msg1 (in Sock (rd))
         Msg5 NIL )
      (println 'Msg1 Msg1)
      ~(assert (= 32 (length Msg1)))
      (out Sock (pr (crypto_respond Ctx Seed Msg1 SS SP)))
      (setq Msg5 (crypto_accept Ctx (in Sock (rd))))
      ~(assert (= 64 (length Msg5)))
      (native "@" "free" NIL Ctx)
      (and Msg5) ) )
(de crypto_lock (K N P)
   (let (PL (length P)  C NIL  M NIL)
      (native
         "libmonocypher.so"
         "crypto_lock"
         NIL
         '(M (16 B . 16))
         (list 'C (cons PL 'B PL))
         (cons NIL (32) K)
         (cons NIL (24) N)
         (cons NIL (cons PL) P)
         PL )
      (conc C M) ) )
(de crypto_unlock (K N C)
   (let (CL (- (length C) 16)  P)
      (and
         (=0
            (native
               "libmonocypher.so"
               "crypto_unlock"
               'N
               (list 'P (cons CL 'B CL))
               (cons NIL (32) K)
               (cons NIL (24) N)
               (cons NIL (16) (tail 16 C))
               (cons NIL (cons CL) (head CL C))
               CL ) ) 
         P ) ) )
(de pliopr (L)
   (pipe
      (out NIL (pr L))
      (make
         (while (rd 1)
            (link @) ) ) ) ) 
(de pliord (L)
   (pipe (out NIL (mapc wr L)) (rd)) )
(de encr (K D)
   (let N (range 1 24)
      (conc N (crypto_lock K N (pliopr D))) ) )
(de decr (K D)
   (pliord (crypto_unlock K (head 24 D) (tail -24 D))) )
(de read_net (S K)
   (in S (decr K (rd))) )
(de write_net (S K D)
   (out S (pr (encr K D))) )

