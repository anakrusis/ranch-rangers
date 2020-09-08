# This script converts what you type into a series of hex values which can be placed in the assembly code directly (along with a label)
# Written by ameliafafafafa 8/17/20

stringIn = input("Enter string: ")
stringOut = ".db "
for i in range(len(stringIn)):
    stringOut += "$"
    charVal  = ord(stringIn[i])
    newValue = 0x24

    if charVal >= 0x30 and charVal < 0x3a: # numbers
        newValue = charVal - 0x30

    elif charVal >= 0x41 and charVal < 0x5b: # uppercase (flattened to lowercase, the game only uses lowercase letters)
        newValue = charVal - 55

    elif charVal >= 0x61 and charVal < 0x7b: # lowercase
        newValue = charVal - 87

    stringOut += format(newValue, '02x')
    stringOut += ", "

print(stringOut + "$ff")
wait = input("Press enter to exit")
