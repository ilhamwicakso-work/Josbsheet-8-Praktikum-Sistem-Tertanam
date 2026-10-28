library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bram_1024x8 is
    Port ( clk      : in  STD_LOGIC;
           we       : in  STD_LOGIC;
           addr     : in  STD_LOGIC_VECTOR (9 downto 0);  -- 1024 alamat
           din      : in  STD_LOGIC_VECTOR (7 downto 0);
           dout     : out STD_LOGIC_VECTOR (7 downto 0) );
end bram_1024x8;

architecture Behavioral of bram_1024x8 is
    type ram_type is array (0 to 1023) of STD_LOGIC_VECTOR(7 downto 0);
    signal ram : ram_type := (others => (others => '0'));
    signal dout_reg : STD_LOGIC_VECTOR(7 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;
            dout_reg <= ram(to_integer(unsigned(addr)));
        end if;
    end process;
    dout <= dout_reg;
end Behavioral;
