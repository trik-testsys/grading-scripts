import sys
import time
import random
import math

class Program():
  __interpretation_started_timestamp__ = time.time() * 1000

  pi = 3.141592653589793

  def execMain(self):

    
    brick.motor("M3").setPower(100)
    brick.motor("M4").setPower(100)
    
    script.wait(1250)
    
    brick.motor("M1").brake()
    brick.motor("M2").brake()
    brick.motor("M3").brake()
    brick.motor("M4").brake()
    
    brick.stop()
    return

def main():
  program = Program()
  program.execMain()

if __name__ == '__main__':
  main()
