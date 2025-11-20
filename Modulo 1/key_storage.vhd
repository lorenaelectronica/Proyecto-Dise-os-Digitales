library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Módulo de almacenamiento de clave
entity key_storage is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           config_mode : in STD_LOGIC;
           save_key : in STD_LOGIC;
           new_key : in STD_LOGIC_VECTOR(3 downto 0);
           stored_key : out STD_LOGIC_VECTOR(3 downto 0));
end key_storage;

architecture Behavioral of key_storage is
    signal key_reg : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal key_saved : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            key_reg <= "0000";
            key_saved <= '0';
        elsif rising_edge(clk) then
            if config_mode = '1' and save_key = '1' then
                key_reg <= new_key;
                key_saved <= '1';
            end if;
        end if;
    end process;
    
    stored_key <= key_reg;

end Behavioral;