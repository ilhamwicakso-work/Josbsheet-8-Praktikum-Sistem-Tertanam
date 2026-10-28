library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_bram_256x8 is
end tb_bram_256x8;

architecture sim of tb_bram_256x8 is
    signal clk  : STD_LOGIC := '0';
    signal we   : STD_LOGIC := '0';
    signal addr : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal din  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal dout : STD_LOGIC_VECTOR(7 downto 0);
begin

    uut: entity work.bram_256x8
        port map (clk => clk, we => we, addr => addr, din => din, dout => dout);

    clk <= not clk after 5 ns;

    process
    begin
        -- tulis ke alamat 0 dan 1
        wait until rising_edge(clk);
        we <= '1'; addr <= x"00"; din <= x"AA";
        wait until rising_edge(clk);
        addr <= x"01"; din <= x"55";
        wait until rising_edge(clk);
        we <= '0';

        -- baca kembali alamat 0 (dout muncul 1 siklus setelah addr diberikan, karena registered output)
        addr <= x"00";
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        assert dout = x"AA" report "Mismatch at addr 0" severity error;

        addr <= x"01";
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        assert dout = x"55" report "Mismatch at addr 1" severity error;

        report "Testbench selesai" severity note;
        wait;
    end process;

end sim;
