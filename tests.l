`(== 64 64)
(load "functions.l")
(seed (in "/dev/urandom" (rd 8)))

(let
   (K (randL 32)
      N (randL 24) 
      C (crypto_lock K N (list 1 2 3)) )
   (test (list 1 2 3) (crypto_unlock K N C)) )
(let
   (N (rand 4096 8192)
      K (randL 32)
      C (encr K N) )
   (test N (decr K C)) )
(msg 'test-OK)
(bye)
