import sys
import time
import random
import math

class Program():
  __interpretation_started_timestamp__ = time.time() * 1000

  pi = 3.141592653589793
  x = None

  def execMain(self):

    
    self.x = 0
    brick.motor("M3").setPower(100)
    brick.motor("M4").setPower(100)
    
    script.wait(1250)
    
    while True:
      if brick.sensor("A1").read() < 10:
        break
      if brick.sensor("A1").read() < 40:
        self.x = self.x + 1
        if self.x < 3:
          script.wait(500)
          
          brick.motor("M1").brake()
          brick.motor("M2").brake()
          brick.motor("M3").brake()
          brick.motor("M4").brake()
          
          script.wait(1000)
          
          brick.motor("M3").setPower(100)
          brick.motor("M4").setPower(100)
          
          script.wait(500)
          
    script.wait(500)
    
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
