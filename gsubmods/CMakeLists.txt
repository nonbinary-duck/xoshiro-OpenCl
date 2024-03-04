target_sources(${PROJ_NAME} PRIVATE
    incbin/incbin.h
    # Note that incbin.c is an executable program not source for incbin.h
    # It might be a program spesifically for MSVC which lacks inline ASM
)

# add_subdirectory(exampleDir)
