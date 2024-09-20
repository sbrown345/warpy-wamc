import sys
import math
import pygame
from wapy import Module, Memory, I32, F64
import time

def main():
    # Read the doom.wasm file
    with open('wamc/test/doom/doom.wasm', 'rb') as file:
        wasm = file.read()

    mem = Memory(108)  # Increased initial memory size to match JS version

    # Initialize Pygame
    pygame.init()
    size = width, height = (640, 400)  # Adjusted to match doom_screen_width and doom_screen_height
    screen = pygame.display.set_mode(size)
    pygame.display.set_caption("DOOM")

    # Stats tracking
    getms_calls_total = 0
    getms_calls = 0
    number_of_draws_total = 0
    number_of_draws = 0
    start_time = time.time()

    def get_milliseconds():
        nonlocal getms_calls, getms_calls_total
        getms_calls += 1
        getms_calls_total += 1
        return (time.time() - start_time) * 1000

    def draw_canvas(ptr):
        nonlocal number_of_draws, number_of_draws_total
        doom_screen = pygame.image.frombuffer(mem.read(ptr, width * height * 4), (width, height), 'RGBA')
        screen.blit(doom_screen, (0, 0))
        number_of_draws += 1
        number_of_draws_total += 1

    # Define import functions
    def import_value(module, field):
        return (I32, 0, 0)

    def import_function(module, field, mem, args):
        if module == "js":
            if field == "js_milliseconds_since_start":
                return [(F64, 0, get_milliseconds())]
            elif field == "js_draw_screen":
                draw_canvas(args[0][2])
                return []
        elif module == "env":
            # Add any necessary env functions here
            pass
        
        raise Exception(f"Unknown import: {module}.{field}")

    # Create the Module instance
    m = Module(wasm, import_value, import_function, mem)

    # Call the exported functions
    m.run('main', [(I32, 0, 0), (I32, 0, 0)])

    # Input handling
    def doom_key_code(key):
        key_mapping = {
            pygame.K_BACKSPACE: 127,
            pygame.K_RCTRL: 0x80 + 0x1d,
            pygame.K_RALT: 0x80 + 0x38,
            pygame.K_LEFT: 0xac,
            pygame.K_UP: 0xad,
            pygame.K_RIGHT: 0xae,
            pygame.K_DOWN: 0xaf,
        }
        if key in key_mapping:
            return key_mapping[key]
        if pygame.K_a <= key <= pygame.K_z:
            return key + 32
        if pygame.K_F1 <= key <= pygame.K_F12:
            return key + 75
        return key

    # Game loop
    clock = pygame.time.Clock()
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                m.run('add_browser_event', [(I32, 0, 0), (I32, 0, doom_key_code(event.key))])
            elif event.type == pygame.KEYUP:
                m.run('add_browser_event', [(I32, 0, 1), (I32, 0, doom_key_code(event.key))])

        m.run('doom_loop_step', [])
        pygame.display.flip()
        clock.tick(60)  # Limit to 60 FPS

        # Print stats every second
        if int(time.time()) % 1 == 0:
            print(f"FPS: {number_of_draws}, Total Frames: {number_of_draws_total}, "
                  f"GetMS calls/s: {getms_calls/1000}k, Total GetMS calls: {getms_calls_total}")
            number_of_draws = 0
            getms_calls = 0

    pygame.quit()

if __name__ == "__main__":
    sys.exit(main())