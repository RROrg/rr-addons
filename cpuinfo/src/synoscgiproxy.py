# -*- coding: utf-8 -*-
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

import os, re, glob, socket, logging, argparse, selectors

localAddr = "/run/synoscgi_rr.sock"
remoteAddr = "/run/synoscgi.sock"

logging.basicConfig(level=logging.INFO)


def getCpuTemp():
    thermals = glob.glob("/sys/class/hwmon/hwmon*/temp*_input")
    temps = []

    for zonePath in thermals:
        labelPath = zonePath.replace("_input", "_label")
        if not os.path.exists(labelPath):
            continue

        with open(labelPath, "r") as f:
            label = f.read().strip().lower()

        if any(keyword in label for keyword in ["tctl", "tdie", "core"]):
            with open(zonePath, "r") as f:
                tempData = f.read().strip()
            try:
                temp = int(tempData) // 1000  # Convert to Celsius
                temps.append(temp)
            except ValueError:
                logging.error(f"Error converting temperature to integer: {tempData}")

    if temps:
        return sum(temps) // len(temps)  # Return average temperature
    return 0


def modifyInfo(data):
    temp = getCpuTemp()
    data = re.sub(r'"sys_temp":\d+', f'"sys_temp":{temp}', data)
    return data


def isIgnorableError(err):
    return isinstance(err, (socket.timeout, ConnectionResetError, BrokenPipeError))


def handleConnection(localConn, remoteAddr):
    try:
        remoteConn = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        remoteConn.connect(remoteAddr)
    except socket.error as e:
        logging.error(f"Failed to connect to remote socket: {e}")
        localConn.close()
        return

    sel = selectors.DefaultSelector()
    sel.register(localConn, selectors.EVENT_READ, data=remoteConn)
    sel.register(remoteConn, selectors.EVENT_READ, data=localConn)

    try:
        while True:
            events = sel.select()
            for key, _ in events:
                src = key.fileobj
                dst = key.data
                data = src.recv(32 * 1024)
                if not data:
                    return
                if b'"sys_temp"' in data:
                    data = modifyInfo(data.decode()).encode()
                dst.sendall(data)
    except socket.error as e:
        if not isIgnorableError(e):
            logging.error(f"Socket error: {e}")
    finally:
        localConn.close()
        remoteConn.close()


def listenAndProxy(localAddr, remoteAddr):
    if os.path.exists(localAddr):
        os.remove(localAddr)

    localListener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    localListener.bind(localAddr)
    localListener.listen(5)
    os.chmod(localAddr, 0o777)
    logging.info(f"Listening on {localAddr}, proxying to {remoteAddr}")

    while True:
        localConn, _ = localListener.accept()
        handleConnection(localConn, remoteAddr)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="CPU Temperature Proxy")
    parser.add_argument(
        "-t", action="store_true", help="Read and print CPU Temperature"
    )
    args = parser.parse_args()

    if args.t:
        temp = getCpuTemp()
        if temp != 0:
            print(temp)
            exit(0)
        else:
            exit(1)

    listenAndProxy(localAddr, remoteAddr)
