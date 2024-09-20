import sys
import math
import pygame
from wapy import Module, Memory, I32, F64

def main():
    # Read the rocket.wasm file
    with open('wamc/test/rocket.wasm', 'rb') as file:
        wasm = file.read()

    mem = Memory(10)

    # Initialize Pygame
    pygame.init()
    size = width, height = (800, 600)
    screen = pygame.display.set_mode(size)

    # Define import functions
    def import_value(module, field):
        return (I32, 0, 0.0)

    def import_function(module, field, mem, args):
        # # Convert NaN values to 0 for args[0][2] and args[1][2]
        # if len(args) > 0 and isinstance(args[0][2], float) and math.isnan(args[0][2]):
        #     args[0] = (args[0][0], args[0][1], 150.0)
        # if len(args) > 1 and isinstance(args[1][2], float) and math.isnan(args[1][2]):
        #     args[1] = (args[1][0], args[1][1], 120.0)
        if module == "env":
            if field == "Math_atan":
                return [(F64, 0, math.atan(args[0][2]))]
            elif field == "clear_screen":
                screen.fill((0, 0, 0))
                return []
            elif field == "cos":
                return [(F64, 0, math.cos(args[0][2]))]
            elif field == "draw_bullet":
                pygame.draw.circle(screen, (255, 255, 255), (int(args[0][2]), int(args[1][2])), 2)
                return []
            elif field == "draw_enemy":
                pygame.draw.circle(screen, (255, 0, 255), (int(args[0][2]), int(args[1][2])), 15, 2)
                return []
            elif field == "draw_particle":
                pygame.draw.circle(screen, (255, 255, 0), (int(args[0][2]), int(args[1][2])), abs(int(args[2][2])))
                return []
            elif field == "draw_player":
                # print(args)   
                pygame.draw.circle(screen, (0, 255, 255), (int(args[0][2]), int(args[1][2])), 10, 2)
                return []
            elif field == "draw_score":
                # print(f"Score: {int(args[0][2])}")
                return []
            elif field == "sin":
                return [(F64, 0, math.sin(args[0][2]))]
        
        raise Exception(f"Unknown import: {module}.{field}")

    # Create the Module instance
    m = Module(wasm, import_value, import_function, mem)

    # Call the exported functions
    m.run('resize', [(F64, 0, 800.0), (F64, 0, 600.0)])

    # Game loop
    clock = pygame.time.Clock()
    last_time = pygame.time.get_ticks() / 1000.0

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return

            if event.type in (pygame.KEYDOWN, pygame.KEYUP):
                print(event)
                key_state = 1 if event.type == pygame.KEYDOWN else 0
                if event.key == pygame.K_SPACE:
                    print('shoot')
                    m.run('toggle_shoot', [(I32, 0, key_state)])
                elif event.key == pygame.K_RIGHT:
                    print('right')
                    m.run('toggle_turn_right', [(I32, 0, key_state)])
                elif event.key == pygame.K_LEFT:
                    print('left')
                    m.run('toggle_turn_left', [(I32, 0, key_state)])
                elif event.key == pygame.K_UP:
                    print('boost')
                    m.run('toggle_boost', [(I32, 0, key_state)])

        current_time = pygame.time.get_ticks() / 1000.0
        dt = current_time - last_time
        last_time = current_time

        m.run('update', [(F64, 0, dt)])
        m.run('draw', [])

        pygame.display.flip()
        clock.tick(60)  # Limit to 60 FPS

if __name__ == "__main__":
    sys.exit(main())