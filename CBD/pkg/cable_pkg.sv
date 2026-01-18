
package cable_pkg;
    
    typedef struct packed {
        logic           is_write_back;
        logic [4 : 0]   rd;
    } wb_control_t;

endpackage