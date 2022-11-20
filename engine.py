import socket
import sys
import time

"""
-- ping.py --
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
addr = ('localhost', int(sys.argv[1]))
buf = "this is a ping!".encode('utf-8')

while True:
	print("pinging...", file=sys.stderr)
	sock.sendto(buf, ("127.0.0.1", int(sys.argv[1])))
	time.sleep(1)

-- engine.py --
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
addr = ('localhost', int(sys.argv[1]))
print('listening on %s port %s' % addr, file=sys.stderr)
sock.bind(addr)

while True:
    buf, raddr = sock.recvfrom(4096)
    print(buf.decode("utf-8"), file=sys.stderr)
    if buf:
        sent = sock.sendto(b'this is the host!', raddr)
"""

BASE_ENGINE_CONFIG: dict = {
    'ip': 'localhost',
    'port': 2000
}

class Engine:
    """
    todo: finish documentation
    """
    def __init__(self, config: dict = BASE_ENGINE_CONFIG) -> None:
        """
        todo: finish documentation
        """

        print("Engine.Constructor: initializing...")
        self.addr = (config['ip'], config['port'])
        print("Engine.Constructor: initialized\n")

    def start(self) -> None:
        """
        todo: finish documentation
        """

        print("Engine.Start: starting...")
        self.s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.s.bind(self.addr)
        print(f"Engine.Start: listening on {self.addr}")
        print("Engine.Start: running...")

        while True:
            pass

    def stop(self) -> None:
        """
        todo: finish documentation
        """
        
        print("\nEngine.Close: shutting down...")
        if hasattr(self, 's'):
            self.s.close()
        print("Engine: Goodbye :)")

def main() -> None:
    """
    todo: finish documentation
    """
    
    e = Engine()
    
    try:
        e.start()
    except KeyboardInterrupt:
        e.stop()

if __name__ == "__main__":
    main()