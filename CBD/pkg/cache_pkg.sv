package cache_pkg;
    
    typedef enum logic [1 : 0] {
        SIZE_BYTE,
        SIZE_HALF,
        SIZE_WORD
    } risk_mem_e;

    typedef struct packed {
        logic       is_load;
        logic       is_store;
        risk_mem_e  size;
        logic       use_unsigned;
    } mem_control_t;

    typedef struct packed {
        logic           enable;
        risk_mem_e      size;
        logic [31 : 0]  address;
        logic [31 : 0]  data;
        logic           use_unsigned;
    } mem_data_t;

endpackage
