`(== 64 64)

# Parent
(load "functions.l")
(seed (in "/dev/urandom" (rd 8)))

(let
   (P (port 12345)
      SrvPrvt (range 1 32) # XXX
      SrvPubl (x25519_public_key SrvPrvt)
      Sock NIL ) 
   (prinl "Server started.")
   (prinl "Public key: " (hexify SrvPubl))
   (loop
      (setq Sock (listen P))
      (NIL (fork) (close P))
      (close Sock) ) 

# Child
(seed (in "/dev/urandom" (rd 8)))
# Key = 32:32 = key:client_public
(let Key (responder Sock SrvPrvt SrvPubl)
   (prinl 
      "Connected. Client's public key starts at " 
      (hexify (head 5 (tail 32 Key))) 
      "..." )
   (in Sock
      (while (rd)
         (out Sock
            (pr
               (encr 
                  Key 
                  (eval (decr Key @)) ) ) ) ) )
   (prinl (stamp) " -- (Pid " *Pid ") disconnect")
   (bye) ) )
