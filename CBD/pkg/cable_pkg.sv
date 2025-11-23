
package cable_pkg;
    
    typedef struct packed {
        logic           is_write_back;
        logic [4 : 0]   rd;
    } write_back_t;

endpackage