from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.sessions.backends.db import SessionStore

from .utils import input_validator, file_handler
from .variable import *

import math


def execute_script(request):
    
    """_summary_

    Args:
        request (POST): Function is called when Controller Creation Form is Submitted.

    Returns:
        view: Redirects to index.html after executing useropenstackscript.sh script.
    """
    try:
        
        if request.method=="POST":
            
            #----------GETTING INPUTS-------------
            interface1 = request.POST['network_interface_1']
            interface2 = request.POST['network_interface_2']
            ip_addr = request.POST['IP_addr']
            sd_name = request.POST['storage_device']
            
            #----------VALIDATION PART-------------
            if input_validator.is_valid_ip_addr(ip_addr): #CHECKING IP ADDRESS
                
                if input_validator.is_valid_storage(sd_name): #CHECKING STORAGE NAME
                    
                    #----------SHELL FILE EXECUTION STARTS-------------
                    shell_file_path = "./useropenstackscript.sh" #CONTROLLER SHELL FILE PATH
                    
                    #----------WRITING INTO SHELL FILE-------------
                    file_handler.find_and_replace_string(shell_file_path, "first_interface", interface1)
                    file_handler.find_and_replace_string(shell_file_path, "second_interface", interface2)
                    file_handler.find_and_replace_string(shell_file_path, "internet_protocol", ip_addr)
                    file_handler.find_and_replace_string(shell_file_path, "cinder_storage_device_name", sd_name)
                    
                    #----------EXECUTING SHELL FILE-------------
                    file_handler.execute_shell_file(shell_file_path)
                    
                    #----------REVERTING BACK THE CHANGES-------------
                    file_handler.find_and_replace_string(shell_file_path, interface1, "first_interface")
                    file_handler.find_and_replace_string(shell_file_path, interface2, "second_interface")
                    file_handler.find_and_replace_string(shell_file_path, ip_addr, "internet_protocol")
                    file_handler.find_and_replace_string(shell_file_path, sd_name, "cinder_storage_device_name")
                    
                    #----------SHELL FILE EXECUTION ENDS-------------
                    return render(request, 'complete.html')
                
                else:
                    messages.warning(request, "Invalid Storage Device Name") #ALERT USER FOR INVALID STORAGE NAME
                    return redirect('/')
            
            else:
                messages.warning(request, "Invalid IP Address") #ALERT USER FOR INVALID IP ADDRESS
                return redirect('/')
    except:
        messages.warning(request, "Something Went Wrong.  Please try again.") #ERROR MESSAGE
        
        #----------REVERTING BACK THE CHANGES-------------
        file_handler.find_and_replace_string(shell_file_path, interface1, "first_interface")
        file_handler.find_and_replace_string(shell_file_path, interface2, "second_interface")
        file_handler.find_and_replace_string(shell_file_path, ip_addr, "internet_protocol")
        file_handler.find_and_replace_string(shell_file_path, sd_name, "cinder_storage_device_name")
        
        return redirect('/')


def get_compute_count(request):
    
    """_summary_

    Args:
        request (POST): Function is called when Compute Count Form is Submitted (CONFIRM button clicked).

    Returns:
        view: Gets the number of compute node to be added and returns it.
    """
    
    if request.method=="POST":
        try:
            #------------GETTING INPUT----------------
            nodes = float(request.POST.get('compute_node_counts')) #TYPECASTING TO INT DATATYPE
            
            if nodes is not None:
                nodes = int(math.floor(nodes))
                node_count = list(range(1, nodes + 1)) #TYPECASTING TO LIST
            
            btn_clicked = True #REQUIRED IN HTML & JS 
            
            #---------ASSIGNING NUMBER OF NODES TO 'VARIABLE' IN variable.py------------
            file_handler.find_and_replace_string('./backend_exec/variable.py', "Replace_str", str(nodes)) 

            context = {
                'compute_nodes' : node_count,
                'nodes' : nodes,                    #CONTEXT DATA FOR HTML
                'btn_clicked' : btn_clicked,
            }
        
            return render(request, 'index.html', context)
        
        except:
            messages.warning(request, "Something Went Wrong.  Please try again.") #ERROR MESSAGE
            return redirect('/')
        

def execute_compute_script(request):
    
    """_summary_

    Args:
        request (POST): Function is called when Compute Creation Form is Saved or Submitted.

    Returns:
        view: Redirects to index.html after executing ComputeAddBK.sh script.
    """
    
    if request.method=="POST":
        try:
            shell_file_path = "./ComputeAddBK.sh" #COMPUTE SHELL FILE PATH
            
            node_count = int(VARIABLE) #NUMBER OF COMPUTE NODES TO BE ADDED
            
            for node in range(0, node_count):
                if len(all_node_list) < node_count: #CREATING EMPTY LIST FOR EACH COMPUTE NODE  
                    all_node_list.append(node_list) #APPENDING THE EMPTY LIST TO ANOTHER LIST
                
                if ("save-btn-" + str(node + 1) in request.POST): #EXECUTES IF SAVE & NEXT BUTTON IS CLICKED
                    
                    #-----------GETTING INPUT-------------------
                    compute_username = request.POST.get('compute_username-' + str(node +1))
                    compute_hostname = request.POST.get('compute_hostname-' + str(node +1))
                    compute_network_interface_1 = request.POST.get('compute_network_interface_1-' + str(node +1))
                    compute_network_interface_2 = request.POST.get('compute_network_interface_2-' + str(node +1))
                    compute_ip_addr = request.POST.get('compute_ip_addr-' + str(node +1))
                    
                    #-----------APPENDING INPUT INTO THE NESTED LIST-------------------
                    all_node_list[node] = [compute_username, compute_hostname, compute_network_interface_1, compute_network_interface_2, compute_ip_addr]
                    request.session['next_button_enabled'] = True
                    
                elif ("create-btn" in request.POST): #EXECUTES IF CREATE BUTTON IS CLICKED
                    
                    #-----------GETTING INPUT FOR LAST FORM-------------------
                    compute_username = request.POST.get('compute_username-' + str(node_count))
                    compute_hostname = request.POST.get('compute_hostname-' + str(node_count))
                    compute_network_interface_1 = request.POST.get('compute_network_interface_1-' + str(node_count))
                    compute_network_interface_2 = request.POST.get('compute_network_interface_2-' + str(node_count))
                    compute_ip_addr = request.POST.get('compute_ip_addr-' + str(node_count))
                    
                    #-----------APPENDING INPUT INTO THE NESTED LIST-------------------
                    all_node_list[node_count - 1] = [compute_username, compute_hostname, compute_network_interface_1, compute_network_interface_2, compute_ip_addr]        
                    
                    #--------------SHELL FILE EXECUTION STARTS--------------------
                    if node+1 == node_count:
                        #EXECUTES ONLY FOR LAST ITERATION OF FOR LOOP
                        for i in range(0, len(all_node_list)):
                            print(all_node_list)
                            
                            #----------WRITING INTO SHELL FILE-------------
                            file_handler.find_and_replace_string(shell_file_path, "compute_username", all_node_list[i][0])
                            file_handler.find_and_replace_string(shell_file_path, "compute_hostname", all_node_list[i][1])
                            file_handler.find_and_replace_string(shell_file_path, "compute_network_interface_1", all_node_list[i][2])
                            file_handler.find_and_replace_string(shell_file_path, "compute_network_interface_2", all_node_list[i][3])
                            file_handler.find_and_replace_string(shell_file_path, "compute_ip_addr", all_node_list[i][4])
                            
                            #----------EXECUTING SHELL FILE-------------
                            sample = input("Check now")
                            #file_handler.execute_shell_file(shell_file_path) #TODO:  Uncomment this line later (This line runs the script)
                            #----------REVERTING BACK THE CHANGES-------------
                            
                            file_handler.find_and_replace_string(shell_file_path, all_node_list[i][0], "compute_username")
                            file_handler.find_and_replace_string(shell_file_path, all_node_list[i][1], "compute_hostname")
                            file_handler.find_and_replace_string(shell_file_path, all_node_list[i][2], "compute_network_interface_1")
                            file_handler.find_and_replace_string(shell_file_path, all_node_list[i][3], "compute_network_interface_2")
                            file_handler.find_and_replace_string(shell_file_path, all_node_list[i][4], "compute_ip_addr")
                        else:
                            
                            #-----------REVERTING BACK 'VARIABLE' VALUE-----------
                            file_handler.find_and_replace_string('./backend_exec/variable.py', str(node_count), "Replace_str")
                            messages.success(request, "Nodes Creation Successful") #SUCCESS MESSAGE
                            return redirect('/')
                    #----------SHELL FILE EXECUTION ENDS--------------
        except:
            messages.warning(request, "Something Went Wrong.  Please try again.") #ERROR MESSAGE
            for i in range(0, len(all_node_list)):
                file_handler.find_and_replace_string(shell_file_path, all_node_list[i][0], "compute_username")
                file_handler.find_and_replace_string(shell_file_path, all_node_list[i][1], "compute_hostname")
                file_handler.find_and_replace_string(shell_file_path, all_node_list[i][2], "compute_network_interface_1")
                file_handler.find_and_replace_string(shell_file_path, all_node_list[i][3], "compute_network_interface_2")
                file_handler.find_and_replace_string(shell_file_path, all_node_list[i][4], "compute_ip_addr")
            
            file_handler.find_and_replace_string('./backend_exec/variable.py', str(node_count), "Replace_str")
             
            return redirect('/')
            
    return render(request, 'complete.html')

