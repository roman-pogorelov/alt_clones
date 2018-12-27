module scfifo_ver
#(
    parameter lpm_width                         = 8,        // width of the FIFO in bits
    parameter lpm_numwords                      = 5,        // depth of the FIFO (must be at least 2 level deep)
    parameter lpm_widthu                        = 4,        // LPM_WIDTHU = CEIL(LOG2(LPM_NUMWORDS))
    parameter lpm_showahead                     = "OFF",    // allow the data to appear on q[] before RdReq is asserted, "ON" or "OFF" (default)
    parameter lpm_type                          = "",       //
    parameter lpm_hint                          = "",       //
    parameter underflow_checking                = "ON",     // disable reading an empty FIFO, "ON" (default) or "OFF"
    parameter overflow_checking                 = "ON",     // disable writing a full FIFO, "ON" (default) or "OFF"
    parameter allow_rwcycle_when_full           = "OFF",    // allow read/write cycles to an already full FIFO, so that it remains full, "ON" or "OFF" (default)
    parameter add_ram_output_register           = "OFF",    // 
    parameter almost_full_value                 = 0,        // almost_full = true if usedw[]>=ALMOST_FULL_VALUE
    parameter almost_empty_value                = 0,        // almost_empty = true true if usedw[]<ALMOST_EMPTY_VALUE
    parameter use_eab                           = "ON",     // selects between EAB or LE-based FIFO, "ON" (default) or "OFF"
    parameter maximize_speed                    = 5,        // 
    parameter device_family                     = "",       //
    parameter intended_device_family            = "",       //
    parameter optimize_for_speed                = 5,        //
    parameter cbxi_parameter                    = "NOTHING" //
)
(
    input  logic [lpm_width - 1 : 0]            data,
    output logic [lpm_width - 1 : 0]            q,

    input  logic                                wrreq,
    input  logic                                rdreq,
    input  logic                                clock,
    input  logic                                aclr,
    input  logic                                sclr,

    output logic                                empty,
    output logic                                full,
    output logic                                almost_full,
    output logic                                almost_empty,
    output logic [lpm_widthu - 1 : 0]           usedw
);
    
    
    // Memory block declarations
    reg [lpm_width - 1 : 0] buffer [lpm_numwords - 1 : 0];
    
    
    // Signal declarations
    logic                                       wr_ena;
    logic                                       rd_ena;
    logic [$clog2(lpm_numwords) - 1 : 0]        wr_cnt;
    logic [$clog2(lpm_numwords) - 1 : 0]        rd_cnt;
    logic [$clog2(lpm_numwords + 1) - 1 : 0]    used_cnt;
    logic                                       full_reg;
    logic                                       empty_reg;
    
    
    // Write and read strobes
    assign wr_ena = wrreq & ((overflow_checking == "OFF") ? 1'b1 : ~full);
    assign rd_ena = rdreq & ((underflow_checking == "OFF") ? 1'b1 : ~empty);
    
    
    // Write address counter
    initial wr_cnt = '0;
    always @(posedge aclr, posedge clock)
        if (aclr)
            wr_cnt <= '0;
        else if (sclr)
            wr_cnt <= '0;
        else if (wr_ena)
            wr_cnt <= (wr_cnt == (lpm_numwords - 1)) ? '0 : wr_cnt + 1'b1;
        else
            wr_cnt <= wr_cnt;
    
    
    // Read address counter
    initial rd_cnt = '0;
    always @(posedge aclr, posedge clock)
        if (aclr)
            rd_cnt <= '0;
        else if (sclr)
            rd_cnt <= '0;
        else if (rd_ena)
            rd_cnt <= (rd_cnt == (lpm_numwords - 1)) ? '0 : rd_cnt + 1'b1;
        else
            rd_cnt <= rd_cnt;
    
    
    // Used words counter
    initial used_cnt = '0;
    always @(posedge aclr, posedge clock)
        if (aclr)
            used_cnt <= '0;
        else if (sclr)
            used_cnt <= '0;
        else if (wr_ena & ~rd_ena)
            used_cnt <= used_cnt + 1'b1;
        else if (~wr_ena & rd_ena)
            used_cnt <= used_cnt - 1'b1;
        else
            used_cnt <= used_cnt;
    assign usedw = used_cnt;
    
    
    // Full flag register
    initial full_reg = '0;
    always @(posedge aclr, posedge clock)
        if (aclr)
            full_reg <= '0;
        else if (sclr)
            full_reg <= '0;
        else if (full_reg)
            full_reg <= ~rdreq;
        else
            full_reg <= (used_cnt == (lpm_numwords - 1)) & wr_ena & ~rd_ena;
    assign full = full_reg;
    
    
    // Programmable full flag
    generate
        
        // Programmable full flag is always 1
        if (almost_full_value == 0) begin: wr_progfull_is_always_1
            assign almost_full = 1'b1;
        end
        
        // Extra logic is needed to assert the programmable full flag
        else if (almost_full_value < lpm_numwords) begin: wr_progfull_is_extra_logic
            
            // Programmable full flag register
            logic progfull_reg;
            initial progfull_reg = '0;
            always @(posedge aclr, posedge clock)
                if (aclr)
                    progfull_reg <= '0;
                else if (sclr)
                    progfull_reg <= '0;
                else if (progfull_reg)
                    progfull_reg <= ~((used_cnt == almost_full_value) & ~wr_ena & rd_ena);
                else
                    progfull_reg <= (used_cnt == (almost_full_value - 1)) & wr_ena & ~rd_ena;
            
            assign almost_full = progfull_reg;
        end
        
        // Programmable full flag is the same as the full flag
        else if (almost_full_value == lpm_numwords) begin: wr_progfull_is_wr_full
            assign almost_full = full;
        end
        
        // Programmable full flag is always 0
        else begin: wr_progfull_is_always_0
            assign almost_full = 1'b0;
        end
        
    endgenerate
    
    
    // Empty flag register
    initial empty_reg = '1;
    always @(posedge aclr, posedge clock)
        if (aclr)
            empty_reg <= '1;
        else if (sclr)
            empty_reg <= '1;
        else if (empty_reg)
            if (use_eab == "ON")
                empty_reg <= ~($unsigned(used_cnt) > 0);
            else
                empty_reg <= ~wrreq;
        else
            if (use_eab == "ON")
                empty_reg <= (used_cnt == 1) & rd_ena;
            else
                empty_reg <= (used_cnt == 1) & ~wr_ena & rd_ena;
    assign empty = empty_reg;
    
    
    // Programmable empty flag
    generate
        
        // Programmable empty flag is always 0
        if (almost_empty_value == 0) begin: rd_progempty_is_always_0
            assign almost_empty = 1'b0;
        end
        
        // Programmable empty flag is the same as the empty flag
        else if (almost_empty_value == 1) begin: rd_progempty_is_rd_empty
            assign almost_empty = empty;
        end
        
        // Extra logic is needed to assert the programmable empty flag
        else if (almost_empty_value <= lpm_numwords) begin: rd_progempty_is_extra_logic
            
            // Programmable empty flag register
            logic progempty_reg;
            initial progempty_reg = 1'b1;
            always @(posedge aclr, posedge clock)
                if (aclr)
                    progempty_reg <= '1;
                else if (sclr)
                    progempty_reg <= '1;
                else if (progempty_reg)
                    progempty_reg <= ~((used_cnt == (almost_empty_value - 1)) & wr_ena & ~rd_ena);
                else
                    progempty_reg <= (used_cnt == almost_empty_value) & ~wr_ena & rd_ena;
            assign almost_empty = progempty_reg;
            
        end
        
        // Programmable empty flag is always 1
        else begin: rd_progempty_is_always_1
            assign almost_empty = 1'b1;
        end
        
    endgenerate
    
    
    // FIFO memory buffer
    always @(posedge clock)
        if (wr_ena) begin
            buffer[wr_cnt] <= data;
        end
    
    
    // Data to read
    generate
        // "Show ahead" mode - the data becomes available before rdreq is asserted
        if (lpm_showahead == "ON") begin: show_ahead_mode
            assign q = buffer[rd_cnt];
        end
        
        // Normal mode - the data becomes available after rdreq is asserted
        else begin: normal_mode
            
            // Data read register
            logic [lpm_width - 1 : 0] rd_data_reg;
            initial rd_data_reg <= '0;
            always @(posedge aclr, posedge clock)
                if (aclr)
                    rd_data_reg <= '0;
                else if (sclr)
                    rd_data_reg <= '0;
                else if (rdreq)
                    rd_data_reg <= buffer[rd_cnt];
                else
                    rd_data_reg <= rd_data_reg;
            
            assign q = rd_data_reg;
        end
    endgenerate

        
endmodule: scfifo_ver