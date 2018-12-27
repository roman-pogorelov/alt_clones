module altsyncram_ver
#(
    // mode selection parameter
    parameter operation_mode                        = "SINGLE_PORT",

    // port A parameters
    parameter width_a                               = 8,
    parameter widthad_a                             = 8,
    parameter numwords_a                            = 1,
    // registering parameters
    parameter outdata_reg_a                         = "UNREGISTERED",
    // clearing parameters
    parameter indata_aclr_a                         = "NONE",
    parameter address_aclr_a                        = "NONE",
    parameter wrcontrol_aclr_a                      = "NONE",
    parameter byteena_aclr_a                        = "NONE",
    parameter outdata_aclr_a                        = "NONE",

    // port B parameters
    parameter width_b                               = 1,
    parameter widthad_b                             = 1,
    parameter numwords_b                            = 1,
    // registering parameters
    parameter indata_reg_b                          = "CLOCK1",
    parameter wrcontrol_wraddress_reg_b             = "CLOCK1",
    parameter rdcontrol_reg_b                       = "CLOCK1",                 // Doesn't matter
    parameter address_reg_b                         = "CLOCK1",
    parameter outdata_reg_b                         = "UNREGISTERED",
    parameter byteena_reg_b                         = "CLOCK1",
    // clearing parameters
    parameter indata_aclr_b                         = "NONE",
    parameter address_aclr_b                        = "NONE",
    parameter wrcontrol_aclr_b                      = "NONE",
    parameter byteena_aclr_b                        = "NONE",
    parameter rdcontrol_aclr_b                      = "NONE",                   // Doesn't matter
    parameter outdata_aclr_b                        = "NONE",

    // byte enable parameters
    parameter width_byteena_a                       = 1,
    parameter width_byteena_b                       = 1,

    //RAM block type choices are "AUTO", "SMALL", "MEDIUM" and "LARGE"
    parameter ram_block_type                        = "AUTO",                   // Doesn't matter

    // width of a byte for byte enables
    parameter byte_size                             = 8,

    // Mixed port feed through mode choices are
    // OLD_DATA and DONT_CARE
    parameter read_during_write_mode_mixed_ports    = "DONT_CARE",
    parameter read_during_write_mode_port_a         = "NEW_DATA_NO_NBE_READ",   // Doesn't matter
    parameter read_during_write_mode_port_b         = "NEW_DATA_NO_NBE_READ",
            
    // General operation parameters
    parameter init_file                             = "UNUSED",                 // Doesn't matter
    parameter init_file_layout                      = "PORT_A",                 // Doesn't matter
    parameter maximum_depth                         = 0,                        // Doesn't matter
    parameter clock_enable_input_a                  = "NORMAL",
    parameter clock_enable_input_b                  = "NORMAL",
    parameter clock_enable_output_a                 = "NORMAL",
    parameter clock_enable_output_b                 = "NORMAL",
    parameter clock_enable_core_a                   = "USE_INPUT_CLKEN",        // Doesn't matter
    parameter clock_enable_core_b                   = "USE_INPUT_CLKEN",        // Doesn't matter
    parameter enable_ecc                            = "FALSE",                  // Doesn't matter
    parameter ecc_pipeline_stage_enabled            = "FALSE",                  // Doesn't matter
    parameter width_eccstatus                       = 3,
    parameter device_family                         = "",                       // Doesn't matter
    parameter intended_device_family                = "",                       // Doesn't matter
    parameter lpm_type                              = "altsyncram",             // Doesn't matter
    parameter cbxi_parameter                        = "NOTHING",                // Doesn't matter
    parameter power_up_uninitialized                = "FALSE"                   // Doesn't matter
)
(
    input  logic                                    wren_a,// = 1'b0,
    input  logic                                    wren_b,// = 1'b0,
    
    input  logic                                    rden_a,// = 1'b1,
    input  logic                                    rden_b,// = 1'b1,
    
    input  logic [width_a - 1 : 0]                  data_a,// = {width_a{1'b1}},
    input  logic [width_b - 1 : 0]                  data_b,// = {width_b{1'b1}},
    
    input  logic [widthad_a - 1 : 0]                address_a,// = {widthad_a{1'b1}},
    input  logic [widthad_b - 1 : 0]                address_b,// = {widthad_b{1'b1}},
    
    input  logic                                    addressstall_a,// = 1'b0,
    input  logic                                    addressstall_b,// = 1'b0,
    
    input  logic                                    aclr0,// = 1'b0,
    input  logic                                    aclr1,// = 1'b0,
    
    input  logic                                    clock0,// = 1'b1,
    input  logic                                    clock1,// = 1'b1,
    
    input  logic                                    clocken0,// = 1'b1,
    input  logic                                    clocken1,// = 1'b1,
    input  logic                                    clocken2,// = 1'b1,
    input  logic                                    clocken3,// = 1'b1,
    
    input  logic [width_byteena_a - 1 : 0]          byteena_a,// = {width_byteena_a{1'b1}},    // Doesn't matter
    input  logic [width_byteena_b - 1 : 0]          byteena_b,// = {width_byteena_b{1'b1}},    // Doesn't matter
    
    output logic [width_a - 1 : 0]                  q_a,
    output logic [width_b - 1 : 0]                  q_b,
    
    output logic [width_eccstatus - 1 : 0]          eccstatus
);
    // Signal declarations
    logic                       a_indata_aclr;
    logic                       a_address_aclr;
    logic                       a_wrcontrol_aclr;
    logic                       a_byteena_aclr;
    logic                       a_outdata_aclr;
    //
    logic                       b_indata_aclr;
    logic                       b_address_aclr;
    logic                       b_wrcontrol_aclr;
    logic                       b_byteena_aclr;
    logic                       b_outdata_aclr;
    //
    logic                       a_outdata_reg_clock;
    //
    logic                       b_indata_reg_clock;
    logic                       b_address_reg_clock;
    logic                       b_wrcontrol_reg_clock;
    logic                       b_byteena_reg_clock;
    logic                       b_outdata_reg_clock;
    //
    logic                       a_clock_enable_input;
    logic                       a_clock_enable_output;
    logic                       b_clock_enable_input;
    logic                       b_clock_enable_output;
    
    
    // ECC isn't used
    assign eccstatus = '0;
    
    
    // Asynchronous clear of the A input data register
    generate
        if (indata_aclr_a == "NONE")
            assign a_indata_aclr = 1'b0;
        else
            assign a_indata_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the A address register
    generate
        if (address_aclr_a == "NONE")
            assign a_address_aclr = 1'b0;
        else
            assign a_address_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the A write control register
    generate
        if (wrcontrol_aclr_a == "NONE")
            assign a_wrcontrol_aclr = 1'b0;
        else
            assign a_wrcontrol_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the A byteena register
    generate
        if (byteena_aclr_a == "NONE")
            assign a_byteena_aclr = 1'b0;
        else
            assign a_byteena_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the A output data register
    generate
        if (outdata_aclr_a == "NONE")
            assign a_outdata_aclr = 1'b0;
        else
            assign a_outdata_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the B input data register
    generate
        if (indata_aclr_b == "NONE")
            assign b_indata_aclr = 1'b0;
        else if (indata_aclr_b == "CLEAR1")
            assign b_indata_aclr = aclr1;
        else
            assign b_indata_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the B address register
    generate
        if (address_aclr_b == "NONE")
            assign b_address_aclr = 1'b0;
        else if (address_aclr_b == "CLEAR1")
            assign b_address_aclr = aclr1;
        else
            assign b_address_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the B write control register
    generate
        if (wrcontrol_aclr_b == "NONE")
            assign b_wrcontrol_aclr = 1'b0;
        else if (wrcontrol_aclr_b == "CLEAR1")
            assign b_wrcontrol_aclr = aclr1;
        else
            assign b_wrcontrol_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the B byteena register
    generate
        if (byteena_aclr_b == "NONE")
            assign b_byteena_aclr = 1'b0;
        else if (byteena_aclr_b == "CLEAR1")
            assign b_byteena_aclr = aclr1;
        else
            assign b_byteena_aclr = aclr0;
    endgenerate
    
    
    // Asynchronous clear of the B output data register
    generate
        if (outdata_aclr_b == "NONE")
            assign b_outdata_aclr = 1'b0;
        else if (outdata_aclr_b == "CLEAR1")
            assign b_outdata_aclr = aclr1;
        else
            assign b_outdata_aclr = aclr0;
    endgenerate
    
    
    // Clock of the A output data register
    generate
        if (outdata_reg_a == "CLOCK1")
            assign a_outdata_reg_clock = clock1;
        else
            assign a_outdata_reg_clock = clock0;
    endgenerate
    
    
    // Clock of the B input data register
    generate
        if (indata_reg_b == "CLOCK1")
            assign b_indata_reg_clock = clock1;
        else
            assign b_indata_reg_clock = clock0;
    endgenerate
    
    
    // Clock of the B address register
    generate
        if (address_reg_b == "CLOCK1")
            assign b_address_reg_clock = clock1;
        else
            assign b_address_reg_clock = clock0;
    endgenerate
    
    
    // Clock of the B write control register
    generate
        if (wrcontrol_wraddress_reg_b == "CLOCK1")
            assign b_wrcontrol_reg_clock = clock1;
        else
            assign b_wrcontrol_reg_clock = clock0;
    endgenerate
    
    
    // Clock of the B byteena register
    generate
        if (byteena_reg_b == "CLOCK1")
            assign b_byteena_reg_clock = clock1;
        else
            assign b_byteena_reg_clock = clock0;
    endgenerate
    

    // Clock of the B output data register
    generate
        if (outdata_reg_b == "CLOCK1")
            assign b_outdata_reg_clock = clock1;
        else
            assign b_outdata_reg_clock = clock0;
    endgenerate
    
    
    // Clock enable of A input
    generate
        if (clock_enable_input_a == "NORMAL")
            assign a_clock_enable_input = clocken0;
        else if (clock_enable_input_a == "ALTERNATE")
            assign a_clock_enable_input = clocken2;
        else
            assign a_clock_enable_input = 1'b1;
    endgenerate
    
    
    // Clock enable of A output
    generate
        if (clock_enable_output_a == "NORMAL")
            if (outdata_reg_a == "CLOCK1")
                assign a_clock_enable_output = clocken1;
            else
                assign a_clock_enable_output = clocken0;
        else
            assign a_clock_enable_output = 1'b1;
    endgenerate
    
    
    // Clock enable of B input
    generate
        if (clock_enable_input_b == "NORMAL")
            if (indata_reg_b == "CLOCK1")
                assign b_clock_enable_input = clocken1;
            else
                assign b_clock_enable_input = clocken0;
        else if (clock_enable_input_b == "ALTERNATE")
            assign b_clock_enable_input = clocken3;
        else
            assign b_clock_enable_input = 1'b1;
    endgenerate
    
    
    // Clock enable of B output
    generate
        if (clock_enable_output_b == "NORMAL")
            if (outdata_reg_b == "CLOCK1")
                assign b_clock_enable_output = clocken1;
            else
                assign b_clock_enable_output = clocken0;
        else
            assign b_clock_enable_output = 1'b1;
    endgenerate
    
    
    // RAM implementation
    generate
        
        
        // Variable declarations
        logic [width_a - 1 : 0]     a_indata_reg;
        logic [widthad_a - 1 : 0]   a_address_reg;
        logic                       a_wren_reg;
        logic [width_a - 1 : 0]     mem[(2**widthad_a) - 1 : 0];
        
        
        // Input data register A
        always @(posedge a_indata_aclr, posedge clock0)
            if (a_indata_aclr)
                a_indata_reg <= '0;
            else if (a_clock_enable_input)
                a_indata_reg <= data_a;
            else
                a_indata_reg <= a_indata_reg;
        
        
        // Address register A
        always @(posedge a_address_aclr, posedge clock0)
            if (a_address_aclr)
                a_address_reg <= '0;
            else if (~addressstall_a)
                a_address_reg <= address_a;
            else
                a_address_reg <= a_address_reg;
        
        
        // Write enable register A
        always @(posedge a_wrcontrol_aclr, posedge clock0)
            if (a_wrcontrol_aclr)
                a_wren_reg <= '0;
            else if (a_clock_enable_input)
                a_wren_reg <= wren_a;
            else
                a_wren_reg <= a_wren_reg;

        
        // Memory block write A
        always @(posedge clock0)
            if (a_wren_reg) begin
                mem[a_address_reg] <= a_indata_reg;
            end
        
        
        // Single port mode
        if (operation_mode == "SINGLE_PORT") begin: single_port_mode
            
            
            // Implementation w/ an output data register
            if (outdata_reg_a == "UNREGISTERED") begin: single_port_mode_no_out_reg
                assign q_a = mem[a_address_reg];
            end
            
            
            // Implementation w/o an output data register
            else begin: single_port_mode_out_reg
                logic [width_a - 1 : 0] a_outdata_reg;
                always @(posedge a_outdata_aclr, posedge a_outdata_reg_clock)
                    if (a_outdata_aclr)
                        a_outdata_reg <= '0;
                    else if (a_clock_enable_output)
                        a_outdata_reg <= mem[a_address_reg];
                    else
                        a_outdata_reg <= a_outdata_reg;
                assign q_a = a_outdata_reg;
            end
            
            
            // Output of B port isn't used
            assign q_b = '0;
            
            
        end
        
        
        // Dual port mode
        else begin: dual_port_mode
            
            
            // Variable declarations
            logic [width_b - 1 : 0]     b_indata_reg;
            logic [widthad_b - 1 : 0]   b_address_reg;
            logic                       b_wren_reg;
            
            
            // Input data register B
            always @(posedge b_indata_aclr, posedge b_indata_reg_clock)
                if (b_indata_aclr)
                    b_indata_reg <= '0;
                else if (b_clock_enable_input)
                    b_indata_reg <= data_b;
                else
                    b_indata_reg <= b_indata_reg;
            
            
            // Address register B
            always @(posedge b_address_aclr, posedge b_address_reg_clock)
                if (b_address_aclr)
                    b_address_reg <= '0;
                else if (~addressstall_b)
                    b_address_reg <= address_b;
                else
                    b_address_reg <= b_address_reg;
            
            
            // Write enable register B
            always @(posedge b_wrcontrol_aclr, posedge b_wrcontrol_reg_clock)
                if (b_wrcontrol_aclr)
                    b_wren_reg <= '0;
                else if (b_clock_enable_input)
                    b_wren_reg <= wren_b;
                else
                    b_wren_reg <= b_wren_reg;
            
            
            // Implementation w/ an output data register
            if (outdata_reg_b == "UNREGISTERED") begin: dual_port_mode_no_out_reg_b
                assign q_b = mem[b_address_reg];
            end
            
            
            // Implementation w/o an output data register
            else begin: dual_port_mode_out_reg_b
                logic [width_b - 1 : 0] b_outdata_reg;
                always @(posedge b_outdata_aclr, posedge b_outdata_reg_clock)
                    if (b_outdata_aclr)
                        b_outdata_reg <= '0;
                    else if (b_clock_enable_output)
                        b_outdata_reg <= mem[b_address_reg];
                    else
                        b_outdata_reg <= b_outdata_reg;
                assign q_b = b_outdata_reg;
            end
            
            
            // Unidir dual port mode
            if (operation_mode == "DUAL_PORT") begin: unidir_dual_port_mode
                
                
                // Output of A port isn't used
                assign q_a = '0;
                
                
            end
            
            
            // Bidir dual port mode
            else if (operation_mode == "BIDIR_DUAL_PORT") begin: bidir_dual_port_mode
            
            
                // Memory block write B
                always @(posedge b_indata_reg_clock)
                    if (b_wren_reg) begin
                        mem[b_address_reg] <= b_indata_reg;
                    end
            
                
                // Implementation w/ an output data register
                if (outdata_reg_a == "UNREGISTERED") begin: dual_port_mode_no_out_reg_a
                    assign q_a = mem[a_address_reg];
                end
                
                
                // Implementation w/o an output data register
                else begin: dual_port_mode_out_reg_a
                    logic [width_a - 1 : 0] a_outdata_reg;
                    always @(posedge a_outdata_aclr, posedge a_outdata_reg_clock)
                        if (a_outdata_aclr)
                            a_outdata_reg <= '0;
                        else if (a_clock_enable_output)
                            a_outdata_reg <= mem[a_address_reg];
                        else
                            a_outdata_reg <= a_outdata_reg;
                    assign q_a = a_outdata_reg;
                end
            
                
            end
            
            
            // Unknown mode
            else begin: unknown_dual_port_mode
            end
            
        end
        
        
    endgenerate

    
endmodule: altsyncram_ver