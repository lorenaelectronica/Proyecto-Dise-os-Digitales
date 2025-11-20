library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Contador de intentos fallidos
entity attempt_counter is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           failed_attempt : in STD_LOGIC;
           reset_attempts : in STD_LOGIC;
           attempts_left : out STD_LOGIC_VECTOR(1 downto 0);
           max_attempts_reached : out STD_LOGIC);
end attempt_counter;

architecture Behavioral of attempt_counter is
    signal attempts : unsigned(1 downto 0) := "11"; -- 3 intentos
begin

    process(clk, reset)
    begin
        if reset = '1' then
            attempts <= "11"; -- 3 intentos
        elsif rising_edge(clk) then
            if reset_attempts = '1' then
                attempts <= "11"; -- Reiniciar a 3 intentos
            elsif failed_attempt = '1' and attempts > 0 then
                attempts <= attempts - 1;
            end if;
        end if;
    end process;
    
    attempts_left <= std_logic_vector(attempts);
    max_attempts_reached <= '1' when attempts = 0 else '0';

end Behavioral;