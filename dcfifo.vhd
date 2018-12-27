library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dcfifo is
    generic
    (
        lpm_width               : integer   := 8;
        lpm_numwords            : integer   := 8;
        lpm_widthu              : integer   := 3;
        lpm_showahead           : string    := "OFF";
        lpm_type                : string    := "";
        lpm_hint                : string    := "";
        underflow_checking      : string    := "ON";
        overflow_checking       : string    := "ON";
        use_eab                 : string    := "ON";
        add_ram_output_register : string    := "OFF";
        delay_rdusedw           : integer   := 1;
        delay_wrusedw           : integer   := 1;
        rdsync_delaypipe        : integer   := 3;
        wrsync_delaypipe        : integer   := 3;
        clocks_are_synchronized : string    := "FALSE";
        maximize_speed          : integer   := 5;
        device_family           : string    := "";
        intended_device_family  : string    := "";
        add_usedw_msb_bit       : string    := "OFF";
        write_aclr_synch        : string    := "OFF";
        read_aclr_synch         : string    := "OFF";
        cbxi_parameter          : string    := "NOTHING"
    );
    port
    (
        data    : in    std_logic_vector(lpm_width - 1 downto 0);
        q       : out   std_logic_vector(lpm_width - 1 downto 0);
        rdclk   : in    std_logic;
        rdreq   : in    std_logic;
        wrclk   : in    std_logic;
        wrreq   : in    std_logic;
        aclr    : in    std_logic := '0';
        rdempty : out   std_logic;
        rdfull  : out   std_logic;
        wrempty : out   std_logic;
        wrfull  : out   std_logic;
        rdusedw : out   std_logic_vector(lpm_widthu - 1 downto 0);
        wrusedw : out   std_logic_vector(lpm_widthu - 1 downto 0)
    );
end dcfifo;

architecture structural of dcfifo is
    
    component dcfifo_ver is
    generic
    (
        lpm_width               : integer   := 8;
        lpm_numwords            : integer   := 8;
        lpm_widthu              : integer   := 3;
        lpm_showahead           : string    := "OFF";
        lpm_type                : string    := "";
        lpm_hint                : string    := "";
        underflow_checking      : string    := "ON";
        overflow_checking       : string    := "ON";
        use_eab                 : string    := "ON";
        add_ram_output_register : string    := "OFF";
        delay_rdusedw           : integer   := 1;
        delay_wrusedw           : integer   := 1;
        rdsync_delaypipe        : integer   := 3;
        wrsync_delaypipe        : integer   := 3;
        clocks_are_synchronized : string    := "FALSE";
        maximize_speed          : integer   := 5;
        device_family           : string    := "";
        intended_device_family  : string    := "";
        add_usedw_msb_bit       : string    := "OFF";
        write_aclr_synch        : string    := "OFF";
        read_aclr_synch         : string    := "OFF";
        cbxi_parameter          : string    := "NOTHING"
    );
    port
    (
        data    : in    std_logic_vector(lpm_width - 1 downto 0);
        q       : out   std_logic_vector(lpm_width - 1 downto 0);
        rdclk   : in    std_logic;
        rdreq   : in    std_logic;
        wrclk   : in    std_logic;
        wrreq   : in    std_logic;
        aclr    : in    std_logic := '0';
        rdempty : out   std_logic;
        rdfull  : out   std_logic;
        wrempty : out   std_logic;
        wrfull  : out   std_logic;
        rdusedw : out   std_logic_vector(lpm_widthu - 1 downto 0);
        wrusedw : out   std_logic_vector(lpm_widthu - 1 downto 0)
    );
    end component;
    
begin
    
    the_dcfifo_ver : dcfifo_ver
    generic map
    (
        lpm_width               => lpm_width,
        lpm_numwords            => lpm_numwords,
        lpm_widthu              => lpm_widthu,
        lpm_showahead           => lpm_showahead,
        lpm_type                => lpm_type,
        lpm_hint                => lpm_hint,
        underflow_checking      => underflow_checking,
        overflow_checking       => overflow_checking,
        use_eab                 => use_eab,
        add_ram_output_register => add_ram_output_register,
        delay_rdusedw           => delay_rdusedw,
        delay_wrusedw           => delay_wrusedw,
        rdsync_delaypipe        => rdsync_delaypipe,
        wrsync_delaypipe        => wrsync_delaypipe,
        clocks_are_synchronized => clocks_are_synchronized,
        maximize_speed          => maximize_speed,
        device_family           => device_family,
        intended_device_family  => intended_device_family,
        add_usedw_msb_bit       => add_usedw_msb_bit,
        write_aclr_synch        => write_aclr_synch,
        read_aclr_synch         => read_aclr_synch,
        cbxi_parameter          => cbxi_parameter
    )
    port map
    (
        data                    => data,
        q                       => q,
        rdclk                   => rdclk,
        rdreq                   => rdreq,
        wrclk                   => wrclk,
        wrreq                   => wrreq,
        aclr                    => aclr,
        rdempty                 => rdempty,
        rdfull                  => rdfull,
        wrempty                 => wrempty,
        wrfull                  => wrfull,
        rdusedw                 => rdusedw,
        wrusedw                 => wrusedw
    );
    
end structural;