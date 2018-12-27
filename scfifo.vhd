library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scfifo is
    generic
    (
        lpm_width               : integer   := 8;           -- width of the FIFO in bits
        lpm_numwords            : integer   := 5;           -- depth of the FIFO (must be at least 2 level deep)
        lpm_widthu              : integer   := 4;           -- LPM_WIDTHU = CEIL(LOG2(LPM_NUMWORDS))
        lpm_showahead           : string    := "OFF";       -- allow the data to appear on q[] before RdReq is asserted, "ON" or "OFF" (default)
        lpm_type                : string    := "";          --
        lpm_hint                : string    := "";          --
        underflow_checking      : string    := "ON";        -- disable reading an empty FIFO, "ON" (default) or "OFF"
        overflow_checking       : string    := "ON";        -- disable writing a full FIFO, "ON" (default) or "OFF"
        allow_rwcycle_when_full : string    := "OFF";       -- allow read/write cycles to an already full FIFO, so that it remains full, "ON" or "OFF" (default)
        add_ram_output_register : string    := "OFF";       -- 
        almost_full_value       : integer   := 0;           -- almost_full = true if usedw[]>=ALMOST_FULL_VALUE
        almost_empty_value      : integer   := 0;           -- almost_empty = true true if usedw[]<ALMOST_EMPTY_VALUE
        use_eab                 : string    := "ON";        -- selects between EAB or LE-based FIFO, "ON" (default) or "OFF"
        maximize_speed          : integer   := 5;           -- 
        device_family           : string    := "";          --
        intended_device_family  : string    := "";          --
        optimize_for_speed      : integer   := 5;           --
        cbxi_parameter          : string    := "NOTHING"    --
    );
    port
    (
        data            : in    std_logic_vector(lpm_width - 1 downto 0);
        q               : out   std_logic_vector(lpm_width - 1 downto 0);

        wrreq           : in    std_logic;
        rdreq           : in    std_logic;
        clock           : in    std_logic;
        aclr            : in    std_logic := '0';
        sclr            : in    std_logic := '0';

        empty           : out   std_logic;
        full            : out   std_logic;
        almost_full     : out   std_logic;
        almost_empty    : out   std_logic;
        usedw           : out   std_logic_vector(lpm_widthu - 1 downto 0)
    );
end scfifo;

architecture structural of scfifo is

    component scfifo_ver is
    generic
    (
        lpm_width               : integer   := 8;           -- width of the FIFO in bits
        lpm_numwords            : integer   := 5;           -- depth of the FIFO (must be at least 2 level deep)
        lpm_widthu              : integer   := 4;           -- LPM_WIDTHU = CEIL(LOG2(LPM_NUMWORDS))
        lpm_showahead           : string    := "OFF";       -- allow the data to appear on q[] before RdReq is asserted, "ON" or "OFF" (default)
        lpm_type                : string    := "";          --
        lpm_hint                : string    := "";          --
        underflow_checking      : string    := "ON";        -- disable reading an empty FIFO, "ON" (default) or "OFF"
        overflow_checking       : string    := "ON";        -- disable writing a full FIFO, "ON" (default) or "OFF"
        allow_rwcycle_when_full : string    := "OFF";       -- allow read/write cycles to an already full FIFO, so that it remains full, "ON" or "OFF" (default)
        add_ram_output_register : string    := "OFF";       -- 
        almost_full_value       : integer   := 0;           -- almost_full = true if usedw[]>=ALMOST_FULL_VALUE
        almost_empty_value      : integer   := 0;           -- almost_empty = true true if usedw[]<ALMOST_EMPTY_VALUE
        use_eab                 : string    := "ON";        -- selects between EAB or LE-based FIFO, "ON" (default) or "OFF"
        maximize_speed          : integer   := 5;           -- 
        device_family           : string    := "";          --
        intended_device_family  : string    := "";          --
        optimize_for_speed      : integer   := 5;           --
        cbxi_parameter          : string    := "NOTHING"    --
    );
    port
    (
        data            : in    std_logic_vector(lpm_width - 1 downto 0);
        q               : out   std_logic_vector(lpm_width - 1 downto 0);

        wrreq           : in    std_logic;
        rdreq           : in    std_logic;
        clock           : in    std_logic;
        aclr            : in    std_logic := '0';
        sclr            : in    std_logic := '0';

        empty           : out   std_logic;
        full            : out   std_logic;
        almost_full     : out   std_logic;
        almost_empty    : out   std_logic;
        usedw           : out   std_logic_vector(lpm_widthu - 1 downto 0)
    );
    end component;

begin

    the_scfifo_ver : scfifo_ver
    generic map
    (
        lpm_width               => lpm_width,               -- width of the FIFO in bits
        lpm_numwords            => lpm_numwords,            -- depth of the FIFO (must be at least 2 level deep)
        lpm_widthu              => lpm_widthu,              -- LPM_WIDTHU = CEIL(LOG2(LPM_NUMWORDS))
        lpm_showahead           => lpm_showahead,           -- allow the data to appear on q[] before RdReq is asserted, "ON" or "OFF" (default)
        lpm_type                => lpm_type,                --
        lpm_hint                => lpm_hint,                --
        underflow_checking      => underflow_checking,      -- disable reading an empty FIFO, "ON" (default) or "OFF"
        overflow_checking       => overflow_checking,       -- disable writing a full FIFO, "ON" (default) or "OFF"
        allow_rwcycle_when_full => allow_rwcycle_when_full, -- allow read/write cycles to an already full FIFO, so that it remains full, "ON" or "OFF" (default)
        add_ram_output_register => add_ram_output_register, -- 
        almost_full_value       => almost_full_value,       -- almost_full = true if usedw[]>=ALMOST_FULL_VALUE
        almost_empty_value      => almost_empty_value,      -- almost_empty = true true if usedw[]<ALMOST_EMPTY_VALUE
        use_eab                 => use_eab,                 -- selects between EAB or LE-based FIFO, "ON" (default) or "OFF"
        maximize_speed          => maximize_speed,          -- 
        device_family           => device_family,           --
        intended_device_family  => intended_device_family , --
        optimize_for_speed      => optimize_for_speed,      --
        cbxi_parameter          => cbxi_parameter           --
    )
    port map
    (
        data                    => data,
        q                       => q,

        wrreq                   => wrreq,
        rdreq                   => rdreq,
        clock                   => clock,
        aclr                    => aclr,
        sclr                    => sclr,

        empty                   => empty,
        full                    => full,
        almost_full             => almost_full,
        almost_empty            => almost_empty,
        usedw                   => usedw
    );

end structural;