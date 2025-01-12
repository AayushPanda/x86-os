# Initialize the registers as specified
cx = 0b0000000000111111 # 0x003F (in binary)
ax = 0b0000001001000101  # 0xAAAA (in binary)

# First sequence: shl ax, 6 followed by or cx, ax
ax1 = ax << 6
cx1 = cx | ax1

# Second sequence: mov ch, al, shl al, and or cl, al
# mov ch, al: Move the value of AL (lower byte of AX) to CH (upper byte of CX)
al = ax & 0XFF  # AL = lower byte of AX
ch = al  # CH gets AL's value
# shl al, 6: Shift AL left by 6 bits
al = al << 6
# or cl, al: Perform OR operation between CL (which is initially 0) and AL
cl = al  # After OR operation, CL will be the shifted value of AL

# Combine the final values into CX for both sequences
cx2 = (ch << 8) | cl

# Results
print(f"{cx1:b}", f"{cx2:b}")
1001000101111111 
101010101000000