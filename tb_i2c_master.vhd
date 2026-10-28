library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_i2c_master is
end tb_i2c_master;

architecture sim of tb_i2c_master is
    signal clk      : STD_LOGIC := '0';
    signal rst      : STD_LOGIC := '1';
    signal start    : STD_LOGIC := '0';
    signal slv_addr : STD_LOGIC_VECTOR(6 downto 0) := "1001000";
    signal rw       : STD_LOGIC := '0';
    signal din      : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal dout     : STD_LOGIC_VECTOR(7 downto 0);
    signal busy     : STD_LOGIC;
    signal scl      : STD_LOGIC;
    signal sda      : STD_LOGIC;
begin

    uut: entity work.i2c_master
        generic map (CLK_FREQ => 1000, SCL_FREQ => 100)  -- dipercepat untuk simulasi
        port map (clk, rst, start, slv_addr, rw, din, dout, busy, scl, sda);

    clk <= not clk after 5 ns;

    process
    begin
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;
        start <= '1';
        wait for 50 ns;
        start <= '0';

        wait until busy = '0';
        report "Transaksi selesai, amati waveform SCL/SDA" severity note;
        wait;
    end process;

end sim;