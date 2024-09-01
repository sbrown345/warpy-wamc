import os
import json
import sys
import logging
import subprocess
import shutil
from wadze.wadze import parse_module, ExportFunction # todo: use warpy
from wapy_parse import sanitize_class_name
import struct
import logging

from wapy_parse import generate_monkeyc

import struct
import logging

def wasm_value_to_monkeyc(wasm_type, wasm_value):
    """
    Convert a WebAssembly value to its MonkeyC equivalent.
    
    :param wasm_type: String representing the WebAssembly type ('i32', 'i64', 'f32', 'f64')
    :param wasm_value: String representation of the WebAssembly value
    :return: String representation of the equivalent MonkeyC value
    """
    if wasm_type == 'i32':
        value = int(wasm_value)
        max_signed = 2**31 - 1
        
        if value > max_signed:
            return f"i32({value - 2**32})"
        else:
            return f"i32({value})"
    elif wasm_type == 'i64':
        value = int(wasm_value)
        max_signed = 2**63 - 1
        
        if value > max_signed:
            return f"i64({value - 2**64})"
        else:
            return f"i64({value})"
    elif wasm_type == 'f32':
        # Convert f32 to float and then to string
        float_value = struct.unpack('!f', struct.pack('!I', int(wasm_value)))[0]
        return f"f32({float_value})"
    elif wasm_type == 'f64':
        # Convert f64 to double and then to string
        double_value = struct.unpack('!d', struct.pack('!Q', int(wasm_value)))[0]
        return f"f64({double_value})"
    else:
        logging.warning(f"Unhandled WASM type: {wasm_type}")
        return wasm_value

def parse_wast(wast_file):
    if not os.path.isfile(wast_file):
        logging.error(f"File not found: {wast_file}")
        return

    logging.info(f"Parsing WAST file: {wast_file}")
    
    wast_dir = os.path.dirname(wast_file)
    wast_name = os.path.splitext(os.path.basename(wast_file))[0]
    logging.info(f"WAST name: {wast_name}")
    
    # Create output directory if it doesn't exist, or clear it if it does
    output_dir = os.path.join(wast_dir, f"{wast_name}_output")
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    os.makedirs(output_dir)
    
    json_file = os.path.join(output_dir, f"{wast_name}.json")
    
    # Run wast2json
    try:
        subprocess.run(['wast2json', wast_file, '-o', json_file], check=True)
        logging.info(f"Successfully ran wast2json on {wast_file}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to run wast2json on {wast_file}: {e}")
        return
    
    # Parse the JSON file
    with open(json_file, 'r') as f:
        wast_data = json.load(f)
    
    # Process each module
    for module_index, command in enumerate(wast_data['commands']):
        if command['type'] == 'module':
            wasm_file = os.path.join(output_dir, command['filename'])
            process_module(wasm_file, wast_name, module_index, wast_data['commands'], output_dir, wast_data['source_filename'])

def process_module(wasm_file, wast_name, module_index, commands, output_dir, source_filename):
    logging.info(f"Processing module {module_index} from {wasm_file}")
    
    # Parse the WASM module
    with open(wasm_file, 'rb') as f:
        wasm_data = f.read()
    parsed_module = parse_module(wasm_data)

    safe_class_name = sanitize_class_name(wast_name)
    factory_name = f"{safe_class_name}_factory_{module_index}"
    
    # Generate the MonkeyC factory file
    factory_filename = os.path.join(output_dir, f"{factory_name}.mc")
    logging.info(f"Generating factory file: {factory_filename}")
    
    monkeyc_code = generate_monkeyc(wasm_file, class_name=factory_name)
    
    with open(factory_filename, 'w') as f:
        f.write(monkeyc_code)
    
    # Create a mapping of exported function names to their indices
    export_map = {}
    function_count = 0
    if 'export' in parsed_module:
        for export in parsed_module['export']:
            if isinstance(export, ExportFunction):
                export_map[export.name] = export.ref
    if 'function' in parsed_module:
        function_count = len(parsed_module['function'])
    
    # Generate the MonkeyC test file
    test_filename = os.path.join(output_dir, f"{safe_class_name}_test_{module_index}.mc")
    logging.info(f"Generating test file: {test_filename}")
    
    with open(test_filename, 'w') as f:
        f.write(f"""
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Tests generated from {source_filename}

class WasmTests_{safe_class_name}_{module_index} {{
""")
        for assertion_index, command in enumerate(commands):
            if command['type'].startswith('assert_'):
                f.write(create_monkeyc_test(wast_name, module_index, assertion_index, command, source_filename, export_map, function_count, factory_name))
        f.write("}\n")

def create_monkeyc_test(wast_name, module_index, assertion_index, assertion, source_filename, export_map, function_count, factory_name):
    print(f"WAST Name: {wast_name}, Module Index: {module_index}, Assertion Index: {assertion_index},  Source Filename: {source_filename}, Function Count: {function_count}")
    logging.info(f"Creating MonkeyC test for assertion: {assertion}")
    
    assertion_type = assertion['type']
    
    if assertion_type in ["assert_return", "assert_trap"]:
        function_name = assertion['action']['field']
        function_index = get_function_index(function_name, export_map, function_count)
        if function_index is None:
            logging.warning(f"Function '{function_name}' not found in exports. Skipping test.")
            return ""

    if assertion_type == "assert_return":
        function_name = assertion['action']['field']
        args = [f"{wasm_value_to_monkeyc(arg['type'], arg['value'])}" for arg in assertion['action']['args']]
        expected_result = wasm_value_to_monkeyc(assertion['expected'][0]['type'], assertion['expected'][0]['value']) if assertion['expected'] else "null"
        expected_type = assertion['expected'][0]['type'] if assertion['expected'] else "void"
        assertion_check = f"return assertEqual(result, {expected_result});"
    elif assertion_type == "assert_trap":
        function_name = assertion['action']['field']
        args = [f"{wasm_value_to_monkeyc(arg['type'], arg['value'])}" for arg in assertion['action']['args']]
        expected_result = f'"{assertion["text"]}"'
        expected_type = "trap"
        assertion_check = f'return assertTrap("{assertion["text"]}", result);'
    elif assertion_type == "assert_invalid":
        # function_name = f"invalid_module_{assertion_index}"
        # args = []
        # expected_error = assertion["text"]
        # expected_type = "invalid"
        # assertion_check = f'return assertInvalid("{expected_error}");'
        return ""
    else:
        logging.warning(f"Unhandled assertion type: {assertion_type}")
        return ""

    function_index = export_map.get(function_name, 0)  # Default to 0 if not found
    test_name = f"test_{sanitize_class_name(wast_name)}_{module_index}_{assertion_index}_{sanitize_class_name(function_name)}___"
    
    test_function = f"""
    (:test)
    static function {test_name}(logger as Test.Logger) as Boolean {{
        // Test from {source_filename}:{assertion['line']}
        // Field: {function_name}
        // Expected type: {expected_type}
        var m = {factory_name}.createModule();
        var result = m.run("{function_name}", [{', '.join(args)}]);

        logger.debug("Result = " + result);
        {assertion_check}
    }}
"""
    logging.info(f"Generated test function:\n{test_function}")
    return test_function

def get_function_index(function_name, export_map, function_count):
    if function_name in export_map:
        return export_map[function_name]
    elif function_name.startswith("$"):
        # Handle function index directly specified in WAST
        try:
            index = int(function_name[1:])
            if 0 <= index < function_count:
                return index
        except ValueError:
            pass
    
    logging.warning(f"Function '{function_name}' not found in exports and is not a valid index.")
    return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python parse_wast.py <wast_file>")
        sys.exit(1)
    
    wast_file = sys.argv[1]
    parse_wast(wast_file)
    logging.info("Finished parsing WAST file and generating MonkeyC files.")