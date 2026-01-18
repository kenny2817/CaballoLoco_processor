package mem_pkg;

    typedef struct packed {
        logic [ID_WIDTH   -1 : 0]       id,
        logic [LINE_WIDTH    -1 : 0]    data,
        logic                           valid
    } buffer_results;

endpackage