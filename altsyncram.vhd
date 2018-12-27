library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity altsyncram is
    generic
    (
        -- mode selection parameter
        operation_mode                      : string    := "SINGLE_PORT";

        -- port A parameters
        width_a                             : natural   := 8;
        widthad_a                           : natural   := 8;
        numwords_a                          : natural   := 1;
        -- registering parameters
        outdata_reg_a                       : string    := "UNREGISTERED";
        -- clearing parameters
        indata_aclr_a                       : string    := "NONE";
        address_aclr_a                      : string    := "NONE";
        wrcontrol_aclr_a                    : string    := "NONE";
        byteena_aclr_a                      : string    := "NONE";
        outdata_aclr_a                      : string    := "NONE";

        -- port B parameters
        width_b                             : natural   := 1;
        widthad_b                           : natural   := 1;
        numwords_b                          : natural   := 1;
        -- registering parameters
        indata_reg_b                        : string    := "CLOCK1";
        wrcontrol_wraddress_reg_b           : string    := "CLOCK1";
        rdcontrol_reg_b                     : string    := "CLOCK1";                 -- Doesn't matter
        address_reg_b                       : string    := "CLOCK1";
        outdata_reg_b                       : string    := "UNREGISTERED";
        byteena_reg_b                       : string    := "CLOCK1";
        -- clearing parameters
        indata_aclr_b                       : string    := "NONE";
        address_aclr_b                      : string    := "NONE";
        wrcontrol_aclr_b                    : string    := "NONE";
        byteena_aclr_b                      : string    := "NONE";
        rdcontrol_aclr_b                    : string    := "NONE";                   -- Doesn't matter
        outdata_aclr_b                      : string    := "NONE";

        -- byte enable parameters
        width_byteena_a                     : natural   := 1;
        width_byteena_b                     : natural   := 1;

        -- RAM block type choices are "AUTO", "SMALL", "MEDIUM" and "LARGE"
        ram_block_type                      : string    := "AUTO";                   -- Doesn't matter

        -- width of a byte for byte enables
        byte_size                           : natural   := 8;

        -- Mixed port feed through mode choices are
        -- OLD_DATA and DONT_CARE
        read_during_write_mode_mixed_ports  : string    := "DONT_CARE";
        read_during_write_mode_port_a       : string    := "NEW_DATA_NO_NBE_READ";   -- Doesn't matter
        read_during_write_mode_port_b       : string    := "NEW_DATA_NO_NBE_READ";
                
        -- General operation parameters
        init_file                           : string    := "UNUSED";                 -- Doesn't matter
        init_file_layout                    : string    := "PORT_A";                 -- Doesn't matter
        maximum_depth                       : integer   := 0;                        -- Doesn't matter
        clock_enable_input_a                : string    := "NORMAL";
        clock_enable_input_b                : string    := "NORMAL";
        clock_enable_output_a               : string    := "NORMAL";
        clock_enable_output_b               : string    := "NORMAL";
        clock_enable_core_a                 : string    := "USE_INPUT_CLKEN";        -- Doesn't matter
        clock_enable_core_b                 : string    := "USE_INPUT_CLKEN";        -- Doesn't matter
        enable_ecc                          : string    := "FALSE";                  -- Doesn't matter
        ecc_pipeline_stage_enabled          : string    := "FALSE";                  -- Doesn't matter
        width_eccstatus                     : natural   := 3;
        device_family                       : string    := "";                       -- Doesn't matter
        intended_device_family              : string    := "";                       -- Doesn't matter
        lpm_type                            : string    := "altsyncram";             -- Doesn't matter
        cbxi_parameter                      : string    := "NOTHING";                -- Doesn't matter
        power_up_uninitialized              : string    := "FALSE"                   -- Doesn't matter
    );
    port
    (
        wren_a              : in    std_logic                                       := '0';
        wren_b              : in    std_logic                                       := '0';
    
        rden_a              : in    std_logic                                       := '1';
        rden_b              : in    std_logic                                       := '1';
    
        data_a              : in    std_logic_vector(width_a - 1 downto 0)          := (others => '1');
        data_b              : in    std_logic_vector(width_b - 1 downto 0)          := (others => '1');
    
        address_a           : in    std_logic_vector(widthad_a - 1 downto 0)        := (others => '1');
        address_b           : in    std_logic_vector(widthad_b - 1 downto 0)        := (others => '1');
    
        addressstall_a      : in    std_logic                                       := '0';
        addressstall_b      : in    std_logic                                       := '0';
    
        aclr0               : in    std_logic                                       := '0';
        aclr1               : in    std_logic                                       := '0';
    
        clock0              : in    std_logic                                       := '1';
        clock1              : in    std_logic                                       := '1';
    
        clocken0            : in    std_logic                                       := '1';
        clocken1            : in    std_logic                                       := '1';
        clocken2            : in    std_logic                                       := '1';
        clocken3            : in    std_logic                                       := '1';
    
        byteena_a           : in    std_logic_vector(width_byteena_a - 1 downto 0)  := (others => '1'); -- Doesn't matter
        byteena_b           : in    std_logic_vector(width_byteena_b - 1 downto 0)  := (others => '1'); -- Doesn't matter
    
        q_a                 : out   std_logic_vector(width_a - 1 downto 0);
        q_b                 : out   std_logic_vector(width_b - 1 downto 0);
    
        eccstatus           : out   std_logic_vector(width_eccstatus - 1 downto 0)
    );
end altsyncram;

architecture structural of altsyncram is

    component altsyncram_ver
    generic
    (
        -- mode selection parameter
        operation_mode                      : string    := "SINGLE_PORT";

        -- port A parameters
        width_a                             : natural   := 8;
        widthad_a                           : natural   := 8;
        numwords_a                          : natural   := 1;
        -- registering parameters
        outdata_reg_a                       : string    := "UNREGISTERED";
        -- clearing parameters
        indata_aclr_a                       : string    := "NONE";
        address_aclr_a                      : string    := "NONE";
        wrcontrol_aclr_a                    : string    := "NONE";
        byteena_aclr_a                      : string    := "NONE";
        outdata_aclr_a                      : string    := "NONE";

        -- port B parameters
        width_b                             : natural   := 1;
        widthad_b                           : natural   := 1;
        numwords_b                          : natural   := 1;
        -- registering parameters
        indata_reg_b                        : string    := "CLOCK1";
        wrcontrol_wraddress_reg_b           : string    := "CLOCK1";
        rdcontrol_reg_b                     : string    := "CLOCK1";                 -- Doesn't matter
        address_reg_b                       : string    := "CLOCK1";
        outdata_reg_b                       : string    := "UNREGISTERED";
        byteena_reg_b                       : string    := "CLOCK1";
        -- clearing parameters
        indata_aclr_b                       : string    := "NONE";
        address_aclr_b                      : string    := "NONE";
        wrcontrol_aclr_b                    : string    := "NONE";
        byteena_aclr_b                      : string    := "NONE";
        rdcontrol_aclr_b                    : string    := "NONE";                   -- Doesn't matter
        outdata_aclr_b                      : string    := "NONE";

        -- byte enable parameters
        width_byteena_a                     : natural   := 1;
        width_byteena_b                     : natural   := 1;

        -- RAM block type choices are "AUTO", "SMALL", "MEDIUM" and "LARGE"
        ram_block_type                      : string    := "AUTO";                   -- Doesn't matter

        -- width of a byte for byte enables
        byte_size                           : natural   := 8;

        -- Mixed port feed through mode choices are
        -- OLD_DATA and DONT_CARE
        read_during_write_mode_mixed_ports  : string    := "DONT_CARE";
        read_during_write_mode_port_a       : string    := "NEW_DATA_NO_NBE_READ";   -- Doesn't matter
        read_during_write_mode_port_b       : string    := "NEW_DATA_NO_NBE_READ";
                
        -- General operation parameters
        init_file                           : string    := "UNUSED";                 -- Doesn't matter
        init_file_layout                    : string    := "PORT_A";                 -- Doesn't matter
        maximum_depth                       : integer   := 0;                        -- Doesn't matter
        clock_enable_input_a                : string    := "NORMAL";
        clock_enable_input_b                : string    := "NORMAL";
        clock_enable_output_a               : string    := "NORMAL";
        clock_enable_output_b               : string    := "NORMAL";
        clock_enable_core_a                 : string    := "USE_INPUT_CLKEN";        -- Doesn't matter
        clock_enable_core_b                 : string    := "USE_INPUT_CLKEN";        -- Doesn't matter
        enable_ecc                          : string    := "FALSE";                  -- Doesn't matter
        ecc_pipeline_stage_enabled          : string    := "FALSE";                  -- Doesn't matter
        width_eccstatus                     : natural   := 3;
        device_family                       : string    := "";                       -- Doesn't matter
        intended_device_family              : string    := "";                       -- Doesn't matter
        lpm_type                            : string    := "altsyncram";             -- Doesn't matter
        cbxi_parameter                      : string    := "NOTHING";                -- Doesn't matter
        power_up_uninitialized              : string    := "FALSE"                   -- Doesn't matter
    );
    port
    (
        wren_a              : in    std_logic                                       := '0';
        wren_b              : in    std_logic                                       := '0';
    
        rden_a              : in    std_logic                                       := '1';
        rden_b              : in    std_logic                                       := '1';
    
        data_a              : in    std_logic_vector(width_a - 1 downto 0)          := (others => '1');
        data_b              : in    std_logic_vector(width_b - 1 downto 0)          := (others => '1');
    
        address_a           : in    std_logic_vector(widthad_a - 1 downto 0)        := (others => '1');
        address_b           : in    std_logic_vector(widthad_b - 1 downto 0)        := (others => '1');
    
        addressstall_a      : in    std_logic                                       := '0';
        addressstall_b      : in    std_logic                                       := '0';
    
        aclr0               : in    std_logic                                       := '0';
        aclr1               : in    std_logic                                       := '0';
    
        clock0              : in    std_logic                                       := '1';
        clock1              : in    std_logic                                       := '1';
    
        clocken0            : in    std_logic                                       := '1';
        clocken1            : in    std_logic                                       := '1';
        clocken2            : in    std_logic                                       := '1';
        clocken3            : in    std_logic                                       := '1';
    
        byteena_a           : in    std_logic_vector(width_byteena_a - 1 downto 0)  := (others => '1'); -- Doesn't matter
        byteena_b           : in    std_logic_vector(width_byteena_b - 1 downto 0)  := (others => '1'); -- Doesn't matter
    
        q_a                 : out   std_logic_vector(width_a - 1 downto 0);
        q_b                 : out   std_logic_vector(width_b - 1 downto 0);
    
        eccstatus           : out   std_logic_vector(width_eccstatus - 1 downto 0)
    );
    end component;
    
begin

    the_altsyncram_ver : altsyncram_ver
    generic map
    (
        -- mode selection parameter
        operation_mode                      => operation_mode,

        -- port A parameters
        width_a                             => width_a,
        widthad_a                           => widthad_a,
        numwords_a                          => numwords_a,
        -- registering parameters
        outdata_reg_a                       => outdata_reg_a,
        -- clearing parameters
        indata_aclr_a                       => indata_aclr_a,
        address_aclr_a                      => address_aclr_a,
        wrcontrol_aclr_a                    => wrcontrol_aclr_a,
        byteena_aclr_a                      => byteena_aclr_a,
        outdata_aclr_a                      => outdata_aclr_a,

        -- port B parameters
        width_b                             => width_b,
        widthad_b                           => widthad_b,
        numwords_b                          => numwords_b,
        -- registering parameters
        indata_reg_b                        => indata_reg_b,
        wrcontrol_wraddress_reg_b           => wrcontrol_wraddress_reg_b,
        rdcontrol_reg_b                     => rdcontrol_reg_b,                     -- Doesn't matter
        address_reg_b                       => address_reg_b,
        outdata_reg_b                       => outdata_reg_b,
        byteena_reg_b                       => byteena_reg_b,
        -- clearing parameters
        indata_aclr_b                       => indata_aclr_b,
        address_aclr_b                      => address_aclr_b,
        wrcontrol_aclr_b                    => wrcontrol_aclr_b,
        byteena_aclr_b                      => byteena_aclr_b,
        rdcontrol_aclr_b                    => rdcontrol_aclr_b,                    -- Doesn't matter
        outdata_aclr_b                      => outdata_aclr_b,

        -- byte enable parameters
        width_byteena_a                     => width_byteena_a,
        width_byteena_b                     => width_byteena_b,

        -- RAM block type choices are "AUTO", "SMALL", "MEDIUM" and "LARGE"
        ram_block_type                      => ram_block_type,                      -- Doesn't matter

        -- width of a byte for byte enables
        byte_size                           => byte_size,

        -- Mixed port feed through mode choices are
        -- OLD_DATA and DONT_CARE
        read_during_write_mode_mixed_ports  => read_during_write_mode_mixed_ports,  -- Doesn't matter
        read_during_write_mode_port_a       => read_during_write_mode_port_a,       -- Doesn't matter
        read_during_write_mode_port_b       => read_during_write_mode_port_b,       -- Doesn't matter
                
        -- General operation parameters
        init_file                           => init_file,                           -- Doesn't matter
        init_file_layout                    => init_file_layout,                    -- Doesn't matter
        maximum_depth                       => maximum_depth,                       -- Doesn't matter
        clock_enable_input_a                => clock_enable_input_a,
        clock_enable_input_b                => clock_enable_input_b,
        clock_enable_output_a               => clock_enable_output_a,
        clock_enable_output_b               => clock_enable_output_b,
        clock_enable_core_a                 => clock_enable_core_a,                 -- Doesn't matter
        clock_enable_core_b                 => clock_enable_core_b,                 -- Doesn't matter
        enable_ecc                          => enable_ecc,                          -- Doesn't matter
        ecc_pipeline_stage_enabled          => ecc_pipeline_stage_enabled,          -- Doesn't matter
        width_eccstatus                     => width_eccstatus,
        device_family                       => device_family,                       -- Doesn't matter
        intended_device_family              => intended_device_family,              -- Doesn't matter
        lpm_type                            => lpm_type,                            -- Doesn't matter
        cbxi_parameter                      => cbxi_parameter,                      -- Doesn't matter
        power_up_uninitialized              => power_up_uninitialized               -- Doesn't matter
    )
    port map
    (
        wren_a              => wren_a,
        wren_b              => wren_b,
    
        rden_a              => rden_a,
        rden_b              => rden_b,
    
        data_a              => data_a,
        data_b              => data_b,
    
        address_a           => address_a,
        address_b           => address_b,
    
        addressstall_a      => addressstall_a,
        addressstall_b      => addressstall_b,
    
        aclr0               => aclr0,
        aclr1               => aclr1,
    
        clock0              => clock0,
        clock1              => clock1,
    
        clocken0            => clocken0,
        clocken1            => clocken1,
        clocken2            => clocken2,
        clocken3            => clocken3,
    
        byteena_a           => byteena_a,   -- Doesn't matter
        byteena_b           => byteena_b,   -- Doesn't matter
    
        q_a                 => q_a,
        q_b                 => q_b,
    
        eccstatus           => eccstatus
    );
    
end structural;
