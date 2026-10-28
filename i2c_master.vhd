library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    generic (
        CLK_FREQ : integer := 100_000_000;
        SCL_FREQ : integer := 100_000
    );
    port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        slv_addr : in  STD_LOGIC_VECTOR(6 downto 0);
        rw       : in  STD_LOGIC;                    -- '0' = write, '1' = read
        din      : in  STD_LOGIC_VECTOR(7 downto 0);
        dout     : out STD_LOGIC_VECTOR(7 downto 0);
        busy     : out STD_LOGIC;
        scl      : inout STD_LOGIC;
        sda      : inout STD_LOGIC
    );
end i2c_master;

architecture rtl of i2c_master is

    constant DIVIDER : integer := CLK_FREQ / (SCL_FREQ * 4);

    type i2c_state is (S_IDLE, S_START, S_ADDR, S_ADDR_ACK,
                        S_DATA, S_DATA_ACK, S_STOP);
    signal state : i2c_state := S_IDLE;

    -- scl_phase: 0,3 = SCL low ; 1,2 = SCL high (1 periode SCL = 4 fase)
    signal clk_cnt   : integer range 0 to DIVIDER-1 := 0;
    signal scl_phase : integer range 0 to 3 := 0;

    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0);
    signal bit_cnt    : integer range 0 to 7 := 0;

    signal sda_out : STD_LOGIC := '1';
    signal sda_en  : STD_LOGIC := '0';
    signal scl_out : STD_LOGIC := '1';

begin

    sda <= sda_out when sda_en = '1' else 'Z';
    scl <= scl_out when state /= S_IDLE else 'Z';

    -- clock divider + penggerak fase SCL
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_cnt <= 0;
                scl_phase <= 0;
            elsif clk_cnt = DIVIDER-1 then
                clk_cnt <= 0;
                if state /= S_IDLE then
                    if scl_phase = 3 then
                        scl_phase <= 0;
                    else
                        scl_phase <= scl_phase + 1;
                    end if;
                end if;
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    scl_out <= '0' when (scl_phase = 0 or scl_phase = 3) else '1';

    -- FSM utama, pindah state/bit tiap scl_phase balik ke 0 (1 periode SCL selesai)
    process(clk)
        variable period_done : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state  <= S_IDLE;
                busy   <= '0';
                sda_en <= '0';
                sda_out <= '1';
            elsif clk_cnt = DIVIDER-1 then
                period_done := (scl_phase = 3);

                case state is
                    when S_IDLE =>
                        busy <= '0';
                        sda_en <= '0';
                        if start = '1' then
                            shift_reg <= slv_addr & rw;
                            bit_cnt <= 7;
                            state <= S_START;
                            busy <= '1';
                            sda_en <= '1';
                            sda_out <= '1';
                        end if;

                    when S_START =>
                        -- SDA turun di tengah periode, saat SCL masih tinggi
                        if scl_phase = 1 then
                            sda_out <= '0';
                        elsif period_done then
                            state <= S_ADDR;
                        end if;

                    when S_ADDR =>
                        -- bit stabil saat scl_phase=0 (SCL low, sebelum naik)
                        if scl_phase = 0 then
                            sda_out <= shift_reg(bit_cnt);
                        end if;
                        if period_done then
                            if bit_cnt = 0 then
                                state <= S_ADDR_ACK;
                                sda_en <= '0';           -- lepas bus, slave yang ACK
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;

                    when S_ADDR_ACK =>
                        if period_done then
                            state <= S_DATA;
                            bit_cnt <= 7;
                            sda_en <= '1';
                            shift_reg <= din;
                        end if;

                    when S_DATA =>
                        if scl_phase = 0 then
                            sda_out <= shift_reg(bit_cnt);
                        end if;
                        if period_done then
                            if bit_cnt = 0 then
                                state <= S_DATA_ACK;
                                sda_en <= '0';
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;

                    when S_DATA_ACK =>
                        if period_done then
                            state <= S_STOP;
                            sda_en <= '1';
                            sda_out <= '0';
                        end if;

                    when S_STOP =>
                        -- SDA naik di tengah periode, saat SCL masih tinggi
                        if scl_phase = 1 then
                            sda_out <= '1';
                        elsif period_done then
                            state <= S_IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

    dout <= shift_reg;

end rtl;