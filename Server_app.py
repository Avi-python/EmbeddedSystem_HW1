import time
import serial
import numpy as np
from socket import *
import threading

Start_Byte = 0x7E
Version_Byte = 0xFF
Command_Length = 0x06
End_Byte = 0xEF
Acknowledge = 0x00

serverPort = 12000
serverIP = '0.0.0.0'
sockSrv = socket(AF_INET, SOCK_STREAM)

sockSrv.bind((serverIP, serverPort))
sockSrv.listen(1)

tracks_number = 0

def execute_CMD(CMD, Par1, Par2):
    checksum = -(Version_Byte + Command_Length + CMD + Acknowledge + Par1 + Par2)
    high = (checksum >> 8) & 0xFF
    low = checksum & 0xFF
    Command_line = [ bytes([Start_Byte]), bytes([Version_Byte]), bytes([Command_Length]), bytes([CMD]), bytes([Acknowledge]), bytes([Par1]), bytes([Par2]), bytes([high]), bytes([low]), bytes([End_Byte]) ]
    for i in range(10):
        ser.write(Command_line[i])

def setVolume(volume):
    execute_CMD(0x06, 0, volume)  #Set the volume (0x00~0x30)
    time.sleep(0.5)

def play_first():
    init_mini()
    setVolume(10)
    time.sleep(0.5)
    # execute_CMD(0x11,0,1)
    # time.sleep(0.5)

def init_mini():
    execute_CMD(0x3F, 0, 0)
    time.sleep(0.5)

def play():
    execute_CMD(0x0D, 0, 1)
    time.sleep(0.5)
    
def pause():
    execute_CMD(0x0E, 0, 0)
    time.sleep(0.5)

def pause_play(args):
    if(args == 1):
        play()
    else:
        pause()

def stop():
    execute_CMD(0x16, 0, 1)
    time.sleep(0.5)


def play_next():
    execute_CMD(0x01,0,1)
    time.sleep(0.5)

def play_previous():
    execute_CMD(0x02,0,1)
    time.sleep(0.5)

def play_specific(n):
    execute_CMD(0x03,0,n)
    time.sleep(0.5)

def play_all():
    execute_CMD(0x11,0,1)
    time.sleep(0.5)
    
def voice_up():
    execute_CMD(0x04,0,1)
    time.sleep(0.5)
    
def voice_down():
    execute_CMD(0x05,0,1)
    time.sleep(0.5)

def get_tracks_number():
    global tracks_number
    execute_CMD(0x48,0,1)
    time.sleep(0.5)
    data = ser.read(10)
    try:
        if(int(data[3]) == 72): # 0x48 = 72 base 10
            print(int(data[6]))
            tracks_number = int(data[6])
    except Exception as e:
        print("No data")
    time.sleep(0.5)

ser = serial.Serial(
    port='/dev/ttyS0', #Replace ttyS0 with ttyAM0 for Pi1,Pi2,Pi0
    baudrate = 9600,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1
)

init_mini()
number = 0

def input_keyboard(number, args = "0"):
    #number = input()
    global isPlaying
    number = int(number)
    args = int(args)
    
    if(number == 1):    #pause/play
        pause_play(args)
    elif(number == 2):   #next
        play_next()
    elif(number == 3):   #previous
        play_previous()
    elif(number == 4):   #voice up
        voice_up()
    elif(number == 5):   #voice down
        voice_down()
    elif(number == 6):   # choose song
        play_specific(args)
    elif(number == 7):   # get number of track in SD card
        get_tracks_number()
    elif(number == 8):   # set volume
        setVolume(args)
        #Set the volume (0x00~0x30)
    else:
        print("InValid")
    #number = 0

client_threads = {}
thread_id = 0
lock = threading.Lock()

def pop_dict_safely(thread_id):
    lock.acquire()
    client_threads.pop(thread_id)
    print("Pop thread id:", thread_id)
    lock.release()


def listen_client(sockCli, addrCli, thread_id):
    while(1):
        try:
            rcvMsg = sockCli.recv(1024)
            
        except ConnectionResetError:
            print(addrCli, ": Disconnect")
            sockCli.close()
            pause()
            break

        if not rcvMsg:
            print(addrCli, ": Disconnect")
            pause()
            sockCli.close()
            break

        msg = rcvMsg.decode()
        args = 0
        if(msg.find('|') != -1):
            msg, args = msg.split('|')
        print(msg, "from:", addrCli, " | args:", args)
        input_keyboard(msg, args)

    pop_dict_safely(thread_id)

accept_enable = True
sockCli = None

def Accept_Loop():
    global tracks_number
    global thread_id
    global sockCli
    while(accept_enable):
        try:
            sockCli, addrCli = sockSrv.accept()
            accept_one = True
            get_tracks_number()
            print("tracks_number: ", str(tracks_number))
            sockCli.send(str(tracks_number).encode())
            thread = threading.Thread(target=listen_client, args=(sockCli, addrCli, thread_id))
            client_threads[thread_id] = thread 
            thread_id += 1
            print("new thread")
            thread.start()
        except Exception as e: # cannot 
            print("error")
            continue
        


    print("Stop accept")

Accept_thread = threading.Thread(target=Accept_Loop)
Accept_thread.start()

print("0 to Exit")

while(1): # for command
    
    cmd = int(input())

    #cmd = 1

    if(cmd == 0):

        accept_enable = False
        sockSrv.close()

        if(sockCli != None):
            sockCli.close()

        tmp = socket(AF_INET, SOCK_STREAM)
        tmp.connect((serverIP, serverPort))
        time.sleep(0.5)
        tmp.close()

        for i, t in client_threads.items():
            t.join()
        
        stop()

        break


