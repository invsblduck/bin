#!/usr/bin/env python

import os
import signal
import sys
import threading
import time

import readchar
import timeout_decorator


TIMEOUT = 14
event = threading.Event()


@timeout_decorator.timeout(TIMEOUT)
def maybe_getch():
    readchar.readkey()
    event.set()
    print("Resetting.")


def count_down():
    for i in range(TIMEOUT, 0, -1):
        if event.is_set():
            return
        sys.stdout.write("\r{} ".format(i))
        sys.stdout.flush()
        time.sleep(1)

    os.system('mpv /usr/share/kbounce/sounds/death.wav &>/dev/null')


try:
    while True:
        if event.is_set():
            event.clear()
        else:
            print('Press any key to start...')
            readchar.readkey()

        t = threading.Thread(name='timer', target=count_down)
        t.daemon = True
        t.start()

        try:
            maybe_getch()
        except timeout_decorator.timeout_decorator.TimeoutError:
            pass

        if t.is_alive():
            for x in threading.enumerate():
                if x is not threading.main_thread():
                    x.join()

        print("\n")

except KeyboardInterrupt:
    signal.signal(signal.SIGINT, signal.default_int_handler)
    print('Caught Ctrl-C')
    sys.exit(2)
