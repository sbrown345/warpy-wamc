# rocket_wapy.py
# thanks https://gist.github.com/dabeaz/7d8838b54dba5006c58a40fc28da9d5a

import sys
from wapy import Module, Memory, I32, F64

def main():
    # Read the rocket.wasm file
    with open('wamc/test/rocket.wasm', 'rb') as file:
        wasm = file.read()

    # Create a memory instance with 256 pages (16MB)
    mem = Memory(256)

    # Define import functions
    def import_value(module, field):
        # You may need to implement this based on your specific needs
        return (I32, 0, 0.0)

    def import_function(module, field, mem, args):
        print(f"import_function: {module}, {field}, {args}")
        # Implement the required imported functions
        if module == "env":
            if field == "Math_atan":
                import math
                return [(F64, 0, math.atan(args[0][2]))]
            elif field == "clear_screen":
                print("clear_screen")
                return []
            elif field == "cos":
                import math
                return [(F64, 0, math.cos(args[0][2]))]
            elif field == "draw_bullet":
                print(f"draw_bullet: {args[0][2]}, {args[1][2]}")
                return []
            elif field == "draw_enemy":
                print(f"draw_enemy: {args[0][2]}, {args[1][2]}")
                return []
            elif field == "draw_particle":
                print(f"draw_particle: {args[0][2]}, {args[1][2]}, {args[2][2]}")
                return []
            elif field == "draw_player":
                print(f"draw_player: {args[0][2]}, {args[1][2]}, {args[2][2]}")
                return []
            elif field == "draw_score":
                print(f"draw_score: {args[0][2]}")
                return []
            elif field == "sin":
                import math
                return [(F64, 0, math.sin(args[0][2]))]
        
        raise Exception(f"Unknown import: {module}.{field}")

    # Create the Module instance
    m = Module(wasm, import_value, import_function, mem)

    # Call the exported functions
    if 'resize' in m.export_map:
        m.run('resize', [(F64, 0, 280.0), (F64, 0, 280.0)])
    
    # Simple game loop (for demonstration)
    for _ in range(10):  # Run 10 frames
        if 'update' in m.export_map:
            m.run('update', [(F64, 0, 0.016)])  # 60 FPS
        if 'draw' in m.export_map:
            m.run('draw', [])

if __name__ == "__main__":
    sys.exit(main())