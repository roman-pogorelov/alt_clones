module dcfifo_ver
#(
    parameter lpm_width                         = 8,
    parameter lpm_numwords                      = 8,
    parameter lpm_widthu                        = 3,
    parameter lpm_showahead                     = "OFF",
    parameter lpm_type                          = "",
    parameter lpm_hint                          = "",
    parameter underflow_checking                = "ON",
    parameter overflow_checking                 = "ON",
    parameter use_eab                           = "ON",
    parameter add_ram_output_register           = "OFF",
    parameter delay_rdusedw                     = 1,
    parameter delay_wrusedw                     = 1,
    parameter rdsync_delaypipe                  = 3,
    parameter wrsync_delaypipe                  = 3,
    parameter clocks_are_synchronized           = "FALSE",
    parameter maximize_speed                    = 5,
    parameter device_family                     = "",
    parameter intended_device_family            = "",
    parameter add_usedw_msb_bit                 = "OFF",
    parameter write_aclr_synch                  = "OFF",
    parameter read_aclr_synch                   = "OFF",
    parameter cbxi_parameter                    = "NOTHING"
)
(
    input  wire [lpm_width - 1 : 0]             data,
    output wire [lpm_width - 1 : 0]             q,
    input  wire                                 rdclk,
    input  wire                                 rdreq,
    input  wire                                 wrclk,
    input  wire                                 wrreq,
    input  wire                                 aclr,
    output wire                                 rdempty,
    output wire                                 rdfull,
    output wire                                 wrempty,
    output wire                                 wrfull,
    output wire [lpm_widthu - 1 : 0]            rdusedw,
    output wire [lpm_widthu - 1 : 0]            wrusedw
);
    
    
    // Constant declarations
    localparam int unsigned CWIDTH = $clog2(lpm_numwords); // Counters width
    
    
    // Memory block declarations
    reg [lpm_width - 1 : 0] buffer [(2**CWIDTH) - 1 : 0];
    
    
    // Signal declarations
    logic                   wr_rst;
    logic                   rd_rst;
    //
    logic                   wr_ena;
    logic                   rd_ena;
    //
    logic [CWIDTH : 0]      wr_cnt;
    logic [CWIDTH : 0]      wr_cnt_next;
    logic [CWIDTH - 1 : 0]  wr_addr;
    logic [CWIDTH : 0]      wr_gray_cnt;
    logic [CWIDTH : 0]      wr_gray_cnt_next;
    logic [CWIDTH : 0]      wr_gray_ptr;
    //
    logic [CWIDTH : 0]      rd_cnt;
    logic [CWIDTH : 0]      rd_cnt_next;
    logic [CWIDTH - 1 : 0]  rd_addr;
    logic [CWIDTH : 0]      rd_gray_cnt;
    logic [CWIDTH : 0]      rd_gray_cnt_next;
    logic [CWIDTH : 0]      rd_gray_ptr;
    //
    logic                   wr_empty_reg;
    logic                   wr_full_reg;
    logic                   rd_empty_reg;
    logic                   rd_full_reg;
    //
    logic [CWIDTH : 0]      wr_used_reg;
    logic [CWIDTH : 0]      rd_used_reg;
    
    
    // Binary to gray conversion
    function automatic logic [CWIDTH : 0] bin2gray(input logic [CWIDTH : 0] bin);
        bin2gray = {1'b0, bin[CWIDTH : 1]} ^ bin;
    endfunction
    
    
    // Gray to binary conversion
    function automatic logic [CWIDTH : 0] gray2bin(input logic [CWIDTH : 0] gray);
        gray2bin[CWIDTH] = gray[CWIDTH];
        for (int i = CWIDTH - 1; i >= 0; i--)
            gray2bin[i] = gray2bin[i + 1] ^ gray[i];
    endfunction
    
    
    // Synchronizer of an asynchronous reset/preset signal (write side)
    dcfifo_areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // Number of extra stages
        .ACTIVE_LEVEL   (1'b1)          // Active level of a reset (preset) signal
    )
    wr_areset_synchronizer
    (
        // Clock
        .clk            (wrclk),       // i
        
        // Asynchronous reset (preset)
        .areset         (aclr),         // i
        
        // Synchronous reset (preset)
        .sreset         (wr_rst)        // o
    ); // wr_areset_synchronizer
    
    
    // Synchronizer of an asynchronous reset/preset signal (read side)
    dcfifo_areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // Number of extra stages
        .ACTIVE_LEVEL   (1'b1)          // Active level of a reset (preset) signal
    )
    rd_areset_synchronizer
    (
        // Clock
        .clk            (rdclk),       // i
        
        // Asynchronous reset (preset)
        .areset         (aclr),         // i
        
        // Synchronous reset (preset)
        .sreset         (rd_rst)        // o
    ); // rd_areset_synchronizer
    
    
    // Write and read strobes
    assign wr_ena = wrreq & ((overflow_checking == "OFF") ? 1'b1 : ~wrfull);
    assign rd_ena = rdreq & ((underflow_checking == "OFF") ? 1'b1 : ~rdempty);
    
    
    // Write address counter
    initial wr_cnt = '0;
    always @(posedge wr_rst, posedge wrclk)
        if (wr_rst)
            wr_cnt <= '0;
        else
            wr_cnt <= wr_cnt_next;
    assign wr_cnt_next = wr_cnt + wr_ena;
    assign wr_addr = wr_cnt[CWIDTH - 1 : 0];
    
    
    // Write gray counter
    initial wr_gray_cnt = '0;
    always @(posedge wr_rst, posedge wrclk)
        if (wr_rst)
            wr_gray_cnt <= '0;
        else
            wr_gray_cnt <= wr_gray_cnt_next;
    assign wr_gray_cnt_next = bin2gray(wr_cnt_next);
    
    
    // Flipflop synchronizer WR -> RD
    dcfifo_ff_synchronizer
    #(
        .WIDTH          (CWIDTH + 1),           // Data width
        .EXTRA_STAGES   (1),                    // Number of extra stages in synchronization circuit
        .RESET_VALUE    ({CWIDTH + 1{1'b0}})    // Value after reset
    )
    wr2rd_synchronizer
    (
        // Сброс и тактирование
        .reset          (rd_rst),               // i
        .clk            (rdclk),               // i
        
        // Асинхронный входной сигнал
        .async_data     (wr_gray_cnt),          // i  [WIDTH - 1 : 0]
        
        // Синхронный выходной сигнал
        .sync_data      (rd_gray_ptr)           // o  [WIDTH - 1 : 0]
    ); // wr2rd_synchronizer
    
    
    // Read address counter
    initial rd_cnt = '0;
    always @(posedge rd_rst, posedge rdclk)
        if (rd_rst)
            rd_cnt <= '0;
        else
            rd_cnt <= rd_cnt_next;
    assign rd_cnt_next = rd_cnt + rd_ena;
    assign rd_addr = rd_cnt[CWIDTH - 1 : 0];
    
    
    // Read gray counter
    initial rd_gray_cnt = '0;
    always @(posedge rd_rst, posedge rdclk)
        if (rd_rst)
            rd_gray_cnt <= '0;
        else
            rd_gray_cnt <= rd_gray_cnt_next;
    assign rd_gray_cnt_next = bin2gray(rd_cnt_next);
    
    
    // Flipflop synchronizer RD -> WR
    dcfifo_ff_synchronizer
    #(
        .WIDTH          (CWIDTH + 1),           // Data width
        .EXTRA_STAGES   (1),                    // Number of extra stages in synchronization circuit
        .RESET_VALUE    ({CWIDTH + 1{1'b0}})    // Value after reset
    )
    rd2wr_synchronizer
    (
        // Сброс и тактирование
        .reset          (wr_rst),               // i
        .clk            (wrclk),               // i
        
        // Асинхронный входной сигнал
        .async_data     (rd_gray_cnt),          // i  [WIDTH - 1 : 0]
        
        // Синхронный выходной сигнал
        .sync_data      (wr_gray_ptr)           // o  [WIDTH - 1 : 0]
    ); // rd2wr_synchronizer
    
    
    // Write empty flag register
    initial wr_empty_reg = '1;
    always @(posedge wr_rst, posedge wrclk)
        if (wr_rst)
            wr_empty_reg <= '1;
        else
            wr_empty_reg <= (wr_gray_cnt_next == wr_gray_ptr);
    assign wrempty = wr_empty_reg;
    
    
    // Write full flag register
    initial wr_full_reg = '0;
    always @(posedge wr_rst, posedge wrclk)
        if (wr_rst)
            wr_full_reg <= '0;
        else
            wr_full_reg <= (wr_gray_cnt_next == ({~wr_gray_ptr[CWIDTH : CWIDTH - 1], wr_gray_ptr[CWIDTH - 2 : 0]}));
    assign wrfull = wr_full_reg;
    
    
    // Read epmty flag register
    initial rd_empty_reg = '1;
    always @(posedge rd_rst, posedge rdclk)
        if (rd_rst)
            rd_empty_reg <= '1;
        else
            rd_empty_reg <= (rd_gray_cnt_next == rd_gray_ptr);
    assign rdempty = rd_empty_reg;
    
    
    // Read full flag register
    initial rd_full_reg = '0;
    always @(posedge rd_rst, posedge rdclk)
        if (rd_rst)
            rd_full_reg <= '0;
        else
            rd_full_reg <= (rd_gray_cnt_next == ({~rd_gray_ptr[CWIDTH : CWIDTH - 1], rd_gray_ptr[CWIDTH - 2 : 0]}));
    assign rdfull = rd_full_reg;
    
    
    // Count of words on the write side
    initial wr_used_reg = '0;
    always @(posedge wr_rst, posedge wrclk)
        if (wr_rst)
            wr_used_reg <= '0;
        else
            wr_used_reg <= wr_cnt_next - gray2bin(wr_gray_ptr);
    assign wrusedw = wr_used_reg;
    
    
    // Count of words on the read side
    initial rd_used_reg = '0;
    always @(posedge rd_rst, posedge rdclk)
        if (rd_rst)
            rd_used_reg <= '0;
        else
            rd_used_reg <= gray2bin(rd_gray_ptr) - rd_cnt_next;
    assign rdusedw = rd_used_reg;
    
    
    // FIFO memory buffer
    always @(posedge wrclk)
        if (wr_ena) begin
            buffer[wr_addr] <= data;
        end
    
    
    // Data to read
    generate
        // "Show ahead" mode - the data becomes available before rdreq is asserted
        if (lpm_showahead == "ON") begin: show_ahead_mode
            assign q = buffer[rd_addr];
        end
        
        // Normal mode - the data becomes available after rdreq is asserted
        else begin: normal_mode
            
            // Data read register
            logic [lpm_width - 1 : 0] rd_data_reg;
            initial rd_data_reg <= '0;
            always @(posedge rd_rst, posedge rdclk)
                if (rd_rst)
                    rd_data_reg <= '0;
                else if (rdreq)
                    rd_data_reg <= buffer[rd_addr];
                else
                    rd_data_reg <= rd_data_reg;
            assign q = rd_data_reg;
            
        end
    endgenerate
    
endmodule: dcfifo_ver




module dcfifo_ff_synchronizer
#(
    parameter int unsigned          WIDTH        = 1,   // Bus width
    parameter int unsigned          EXTRA_STAGES = 0,   // Number of the synchronization stages
    parameter logic [WIDTH - 1 : 0] RESET_VALUE  = 0    // Initial value of the synchronization stages
)
(
    // Reset and clock
    input  logic                    reset,
    input  logic                    clk,
    
    // Asynchronous input bus
    input  logic [WIDTH - 1 : 0]    async_data,
    
    // Synchronous output bus
    output logic [WIDTH - 1 : 0]    sync_data
);
    // Constant declarations
    localparam int unsigned STAGES = 1 + EXTRA_STAGES;  // Whole number of the synchronization stages
    
    
    // Signal declarations
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -to [get_keepers {*dcfifo_ff_synchronizer:*|stage0[*]}]\" "} *) reg [WIDTH - 1 : 0] stage0;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"} *) reg [STAGES - 1 : 0][WIDTH - 1 : 0] stage_chain;
    
    
    // First synchronization stage
    initial stage0 = RESET_VALUE;
    always @(posedge reset, posedge clk)
        if (reset)
            stage0 <= RESET_VALUE;
        else
            stage0 <= async_data;
    
    
    // Rest synchronization stages
    initial stage_chain = {STAGES{RESET_VALUE}};
    always @(posedge reset, posedge clk)
        if (reset)
            stage_chain <= {STAGES{RESET_VALUE}};
        else if (STAGES > 1)
            stage_chain <= {stage_chain[STAGES - 2 : 0], stage0};
        else
            stage_chain <= stage0;
    assign sync_data = stage_chain[STAGES - 1];
    
    
endmodule: dcfifo_ff_synchronizer




module dcfifo_areset_synchronizer
#(
    parameter int unsigned  EXTRA_STAGES = 1,   // Number of extra synchronization stages
    parameter logic         ACTIVE_LEVEL = 1'b1 // Reset/preset active level
)
(
    // Clock
    input  logic            clk,
    
    // Asynchronous reset/preset
    input  logic            areset,
    
    // Synchronous reset/preset
    output logic            sreset
);
    // Constant declarations
    localparam int unsigned STAGES = 1 + EXTRA_STAGES;  // Whole number of synchronization stages
    
    
    // Signal declarations
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -through [get_pins -compatibility_mode {*dcfifo_areset_synchronizer*stage0|clrn}] -to [get_registers {*dcfifo_areset_synchronizer:*|stage0}]\" "} *) reg stage0;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -through [get_pins -compatibility_mode {*dcfifo_areset_synchronizer*stage_chain[*]|clrn}] -to [get_registers {*dcfifo_areset_synchronizer:*|stage_chain[*]}]\" "} *) reg [STAGES - 1 : 0] stage_chain;
    
    
    // Reset/preset
    wire reset = ACTIVE_LEVEL ? areset : ~areset;
    
    
    // First synchronization stage
    initial stage0 = ACTIVE_LEVEL;
    always @(posedge reset, posedge clk)
        if (reset)
            stage0 <= ACTIVE_LEVEL;
        else
            stage0 <= ~ACTIVE_LEVEL;
    
    
    // Rest synchronization stages
    initial stage_chain = {STAGES{ACTIVE_LEVEL}};
    always @(posedge reset, posedge clk)
        if (reset)
            stage_chain <= {STAGES{ACTIVE_LEVEL}};
        else if (STAGES > 1)
            stage_chain <= {stage_chain[STAGES - 2 : 0], stage0};
        else
            stage_chain <= stage0;
    assign sreset = stage_chain[STAGES - 1];
    
    
endmodule: dcfifo_areset_synchronizer
