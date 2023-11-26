import re
import shutil
import os
import subprocess

class InputValidator():
    def is_valid_ip_addr(self, ip_addr):
        pattern = r'^(\d{1,3}\.){3}\d{1,3}$'  # Regex pattern for IP address validation
        if re.match(pattern, ip_addr):
            return True
        else:
            return False

    
    def is_valid_storage(self, storage_name):
        pattern = "/dev/"
        
        if pattern in storage_name:
            return True
        else: 
            return False
        

class FileHandler():
    def read_shell_file(self, file_path):
        try:
            with open(file_path, 'r') as file:
                contents = file.read()
                return contents
        except FileNotFoundError:
            print(f"File '{file_path}' not found.")
            return None
        except IOError:
            print(f"Error reading file '{file_path}'.")
            return None
        
        
    def find_and_replace_string(self, file_path, target_string, replacement_string):
        try:
            with open(file_path, 'r') as file:
                contents = file.read()
            
            modified_contents = contents.replace(target_string, replacement_string)
            
            with open(file_path, 'w') as file:
                file.write(modified_contents)
            
            print("String replacement completed successfully.")
            return True
        
        except FileNotFoundError:
            print(f"File '{file_path}' not found.")
            return False
        
        except IOError:
            print(f"Error occurred while reading or writing '{file_path}'.")
            return False
        
        
    def copy_shell_file(self, source_dir, destination_dir):
        file_name = os.path.basename(source_dir)
        destination_path = os.path.join(destination_dir, file_name)
        try:
            shutil.copy2(source_dir, destination_path)
            print(f"Shell file '{file_name}' copied successfully.")
            return True
        except FileNotFoundError:
            print(f"Source file '{file_name}' not found.")
            return False
        except IOError:
            print(f"Error occurred while copying '{file_name}'.")
            return False
        
    
    def execute_shell_file(self, file_path):
        try:
            subprocess.run(['sh', file_path], check=True)
            print("Shell file executed successfully.")
            return True
        except FileNotFoundError:
            print(f"Shell file '{file_path}' not found.")
            return False
        except subprocess.CalledProcessError:
            print(f"Error occurred while executing '{file_path}'.")
            return False


    def delete_shell_file(self, file_path):
        try:
            os.remove(file_path)
            print(f"Shell file '{file_path}' deleted successfully.")
            return True
        except FileNotFoundError:
            print(f"Shell file '{file_path}' not found.")
            return False
        except OSError:
            print(f"Error occurred while deleting '{file_path}'.")
            return False
    
input_validator = InputValidator()
file_handler = FileHandler()