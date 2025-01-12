# Define the art as a string
art = """
                                                         v
 .-=-.    .-=-,    .-=-,     (^)      -@)      (@<      ( )      (@<
(     )  (  ,' )  (  ,^ )  (`\\~/')  (\\(~)/)  (\\(~)/)  (\\(~)/)   (< )
 ~-=-~    ~-=-~    ~-=-~    ~-=-~    ~-=-~    ~-=-~    ~-=-~     ^^
"""

# Define ENDL as a variable
ENDL = "\', ENDL, \'"

# Convert the art into an ASCII array with the specified format
ascii_array = art.splitlines()
ascii_array_formatted = "\'" + ENDL.join(ascii_array) + "0"

print(ascii_array_formatted)


