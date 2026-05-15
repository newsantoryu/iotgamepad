#!/usr/bin/env python3

import asyncio
import socket
import time

from evdev import UInput, ecodes as e

# ============================================================
# CONFIG
# ============================================================

UDP_IP = "0.0.0.0"
UDP_PORT = 4210

# cooldown anti-spam no Linux
COOLDOWN = 0.25

# ============================================================
# GAMEPAD VIRTUAL
# ============================================================

capabilities = {
    e.EV_KEY: [
        e.BTN_SOUTH,   # X
        e.BTN_EAST,    # O
        e.BTN_NORTH,   # Triangle
        e.BTN_WEST,    # Square
        e.BTN_TL,
        e.BTN_TR,
        e.BTN_SELECT,
        e.BTN_START,
    ]
}

ui = UInput(capabilities, name="ESP32-DS4-Bridge")

print("[VIRT] Controle virtual criado!")

# ============================================================
# UDP SOCKET
# ============================================================

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

print(f"[UDP] Escutando em {UDP_IP}:{UDP_PORT}")

# ============================================================
# HELPERS
# ============================================================

last_event = 0

def press_button(button, duration=0.05):

    ui.write(e.EV_KEY, button, 1)
    ui.syn()

    time.sleep(duration)

    ui.write(e.EV_KEY, button, 0)
    ui.syn()

# ============================================================
# LOOP
# ============================================================

async def udp_loop():

    global last_event

    while True:

        data, addr = sock.recvfrom(1024)

        msg = data.decode().strip()

        now = time.time()

        if now - last_event < COOLDOWN:
            continue

        print(f"[UDP] {addr[0]} -> {msg}")

        # ====================================================
        # BTN_SQUARE
        # ====================================================

        if msg == "BTN_SQUARE":

            press_button(e.BTN_WEST)

            print("[ACTION] Square")

            last_event = now

        # ====================================================
        # BTN_SQUARE_DOUBLE
        # ====================================================

        elif msg == "BTN_SQUARE_DOUBLE":

            press_button(e.BTN_WEST)
            time.sleep(0.08)
            press_button(e.BTN_WEST)

            print("[ACTION] Double Square")

            last_event = now

        # ====================================================
        # DEBUG
        # ====================================================

        else:
            print(f"[WARN] Evento desconhecido: {msg}")

        await asyncio.sleep(0.001)

# ============================================================
# MAIN
# ============================================================

async def main():

    print("")
    print("[OK] Bridge Wi-Fi rodando")
    print("[OK] Aguardando eventos do ESP32...")
    print("")

    await udp_loop()

# ============================================================
# START
# ============================================================

try:
    asyncio.run(main())

except KeyboardInterrupt:

    print("")
    print("[EXIT] Encerrando bridge")

finally:

    ui.close()
