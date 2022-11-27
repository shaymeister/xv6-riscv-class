import socket
import time


BASE_ENGINE_CONFIG: dict = {
    'ip': 'localhost',
    'num_iter': 2,
    'port': 25600,
}

CODE_WORDS: dict = {
    'stringStopSM': bytes('stopSM', 'utf-8'),
    'stringEngineStarted': bytes('engineStarted', 'utf-8'),
    'stringEngineNotStarted': bytes('engineStopped', 'utf-8'),
    'stringRunIter': bytes('runIter', 'utf-8'),
    'stringEndSession': bytes('endSession', 'utf-8')
}

BASE_LEARNER_CONFIG: dict = {
    'num_iter': 4
}

class Learner:
    """
    todo: finish documentation
    """
    def __init__(self, config: dict = BASE_LEARNER_CONFIG) -> None:
        """
        todo: finish documentation
        """
        print("Learner.Constructor: initializing...")
        
        self.num_iter: int = config['num_iter']

        self.current_iter: int = 0

        print("Learner.Constructor: Initialized")        

    def is_finished(self) -> bool:
        """
        todo: finish documentation
        """
        return not self.current_iter < self.num_iter

class Engine:
    """
    todo: finish documentation
    """
    def __init__(self, config: dict = BASE_ENGINE_CONFIG) -> None:
        """
        todo: finish documentation
        """

        print("Engine.Constructor: initializing...")
        self.addr: tuple = (config['ip'], config['port'])
        self.num_iter: int = config['num_iter']

        self.raddr: tuple = None
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

        self.init_connection()

        if self.raddr is None:
            raise AttributeError("return address is not initialized")

        for i in range(self.num_iter):
            print(f"Engine: starting iteration {i}")

            self.s.sendto(CODE_WORDS['stringEngineStarted'], self.raddr)
            time.sleep(0.5)

            self.s.sendto(CODE_WORDS['stringRunIter'], self.raddr)
            time.sleep(0.5)

            # receive fake log
            buffer, self.raddr = self.s.recvfrom(4096)
            message: str = buffer.decode("utf-8")
            
            if buffer:
                print(f"Engine.RunIter: received message ( msg = {message} )")
                print(f"Engine.RunIter: success ( raddr = {self.addr} )")

            # return fake process to run
            self.s.sendto(b"1234", self.raddr)
            time.sleep(0.5)


            self.s.sendto(CODE_WORDS['stringEndSession'], self.raddr)
            time.sleep(0.5)

            # signal to reset the state machine for the next iteration
            self.s.sendto(CODE_WORDS['stringEngineNotStarted'], self.raddr)

        # signal to stop the state machine
        self.s.sendto(CODE_WORDS['stringStopSM'], self.raddr)


    def init_connection(self) -> None:
        """
        todo: finish documentation
        """

        print("Engine.InitConn: waiting for message from XV6...")

        buffer, self.raddr = self.s.recvfrom(4096)
        message: str = buffer.decode("utf-8")
            
        if buffer:
            print(f"Engine.InitConn: received message ( msg = {message} )")
            print(f"Engine.InitConn: success ( raddr = {self.addr} )")
        else:
            raise ConnectionError("unable to initialize the connection")

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